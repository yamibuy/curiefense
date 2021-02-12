module(..., package.seeall)

local globals   = require "lua.globals"
local utils     = require "lua.utils"

local cjson     = require "cjson"
local json_safe = require "cjson.safe"

local table_keys    = utils.table_keys

local ACLNoMatch    = globals.ACLNoMatch
local ACLForceDeny  = globals.ACLForceDeny
local ACLBypass     = globals.ACLBypass
local ACLAllowBot   = globals.ACLAllowBot
local ACLDenyBot    = globals.ACLDenyBot
local ACLAllow      = globals.ACLAllow
local ACLDeny       = globals.ACLDeny

function check_policy (policy, request)
    local tags = table_keys(request.attrs.tags)
    for _, tag in ipairs(tags) do
        if policy[tag] then
            -- local msg = string.format("acl-tag: %s", tag)
            return tag
        end
    end

    return nil
end

function acl_result( action, reason, active)
    local action_params  = { ["initiator"] = "acl", ["action"] = action, ["reason"] = reason }
    action_params.block_mode = active
    return action, action_params
end

function check(profile, request)
    local msg = nil
    -- request.handle:logDebug(string.format("ACL Check -- Request details \n%s\n", json_safe.encode(request.attrs)))
    -- request.handle:logDebug(string.format("ACL Check -- Profile \n%s\n", json_safe.encode(profile)))
    msg = check_policy(profile.force_deny, request)
    if msg then return acl_result(ACLForceDeny, msg) end

    msg = check_policy(profile.bypass, request)
    if msg then return acl_result(ACLBypass, msg) end

    msg = check_policy(profile.allow, request)
    if msg then return acl_result(ACLAllow, msg) end

    msg = check_policy(profile.deny, request)
    if msg then return acl_result(ACLDeny, msg) end

end

function check_bot(profile, request)
    local msg = nil

    msg = check_policy(profile.allow_bot, request)
    if msg then return acl_result(ACLAllowBot, msg) end

    msg = check_policy(profile.deny_bot, request)
    if msg then return acl_result(ACLDenyBot, msg) end

end
