module(..., package.seeall)

local os        = require "os"
local redis     = require "lua.redis"

local redishost = os.getenv("REDIS_HOST") or "redis"
local redisport = os.getenv("REDIS_PORT") or 6379

function _connection()
    return redis.connect(redishost, redisport)
end

function list_length(key)
    local redis_conn = _connection()
    return redis_conn:llen(key)
end

function list_push(key, value)
    return _connection():lpush(key, value)
end

function set_length(key)
    local redis_conn = _connection()
    return redis_conn:scard(key)
end

function set_add(key, value)
    return _connection():sadd(key, value)
end

function check_limit(request_map, key, threshold, ttl, set_value)
    local retval = 200
    local redis_conn = _connection()

    if not redis_conn then
        return retval
    end

    if not set_value then
        retval = check_simple(request_map, redis_conn, key, threshold, ttl)
    else
        retval = check_set(request_map, redis_conn, key, threshold, set_value, ttl)
    end

    -- local ok, err = redis_conn:set_keepalive(max_idle_timeout, redis_pool_size)
    return retval
end

function check_simple(request_map, redis_conn, key, threshold, ttl)
    local handle = request_map.handle
    local current = 0
    local force_expire = false

    local result = redis_conn:pipeline(
        function(pipe)
            -- pipe:multi()
            pipe:incr(key)
            pipe:ttl(key)
        end
    )

    -- handle:logDebug(string.format("limit check_simple -- type(%s), [%s]", type(result), result))
    if type(result) == "table" then
        current = result[1]
        expire = result[2]

        -- handle:logDebug(string.format("limit check_simple -- current (%s), expire[%s]", current, expire))

        if "userdata: NULL" == tostring(current) then
            current = 0
        else
            current = tonumber(current)
        end

        if "userdata: NULL" == tostring(expire) then
            expire = -1
        else
            expire = tonumber(expire)
        end

        if expire < 0 then
            value, err = redis_conn:expire(key, ttl)
        end

        if current ~= nil and current > threshold then
            return 503
        else
            -- handle:logDebug(string.format("limit --- %s < %s", current, threshold))
            return 200
        end
    else
        -- handle:logDebug(string.format("limit --- not a table, 200 is the answer"))
        return 200
    end
end

function check_set(request_map, redis_conn, key, threshold, set_value, ttl)
    local current = 0
    set_value = md5(set_value)

    local result = redis_conn:pipeline(
        function(pipe)
            -- pipe:multi()
            pipe:sadd(key, set_value)
            pipe:scard(key)
            pipe:ttl(key)
        end
    )

    if type(result) == "table" then
        current = result[2]
        expire = result[3]

        if "userdata: NULL" == tostring(current) then
            current = 0
        else
            current = tonumber(current)
        end

        if "userdata: NULL" == tostring(expire) then
            expire = -1
        else
            expire = tonumber(expire)
        end

        if expire < 0 then
            value, err = redis_conn:expire(key, ttl)
        end

        if current ~= nil and current > threshold then
            return 503
        else
            local value, err = redis_conn:sadd(key, set_value)
            if not value then
                error("failed expanding set: " .. tostring(err))
                return -1
            end
            return 200
        end
    else
        return 200
    end
end
