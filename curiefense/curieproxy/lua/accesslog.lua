module(..., package.seeall)

local cjson = require "cjson"
local utils = require "lua.utils"

local json_encode   = cjson.encode
local json_decode   = cjson.decode

local table_keys    = utils.table_keys

-- dynamic metadata filter name
DMFN = "com.reblaze.curiefense"
LOG_KEY = "request.info"

function log_request(request_map)
  -- handle is userData which is not serilizable
  local request_handle = request_map.handle
  local entries = {
  	["headers"] = "headers",
  	["cookies"] = "cookies",
  	["args"] 	= "arguments",
  	["attrs"] 	= "attributes"
  }

  local log_table = {}

  for luaname, logname in pairs(entries) do
    log_table[logname] = request_map[luaname]
  end

  local tags = entries.attributes.tags

  if tags then
  	entries.attributes.tags = table_keys(tags)
  end

  local str_map = json_encode(log_table)
  request_handle:logDebug(str_map)

  request_handle:streamInfo():dynamicMetadata():set(DMFN, LOG_KEY, str_map)

end

