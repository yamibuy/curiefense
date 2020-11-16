module(..., package.seeall)

local globals   = require "lua.globals"
local utils     = require "lua.utils"

local WAFPass   = globals.WAFPass
local WAFBlock  = globals.WAFBlock

local re_match  = utils.re_match

function store_section(master_dict, key, subkey,  value)
    if master_dict[key] then
        master_dict[key][subkey] = value
    else
        master_dict[key] = { [subkey] = value}
    end
end

function build_section(section_name, profile)
    local name_rules, regex_rules, max_len, max_count

    if section_name == "headers" then
        name_rules = profile.headers.names
        regex_rules = profile.headers.regex
        max_count = profile.max_headers_count
        max_len = profile.max_header_length

    elseif section_name == "cookies" then
        name_rules = profile.cookies.names
        regex_rules = profile.cookies.regex
        max_count = profile.max_cookies_count
        max_len = profile.max_cookie_length

    elseif section_name == "args" then
        name_rules = profile.args.names
        regex_rules = profile.args.regex
        max_count = profile.max_args_count
        max_len = profile.max_arg_length
    end

    return {name_rules, regex_rules, max_len, max_count}

end

function name_check(section, name, name_rule, value, omit_entries, sig_excludes)
    local matched = re_match(value, name_rule.reg)

    if matched then
        store_section(omit_entries, section, name, true)
    else
        if name_rule.restrict then
            return  WAFBlock, string.format("(%s)/%s mismatch with %s", section, name_rule.reg, value)
        elseif #name_rule.exclusions  > 0 then
            store_section(sig_excludes, section, name, name_rule.exclusions)
        end
    end
end

function regex_check(section, name, regex_rules, omit_entries, sig_excludes)

    for name_patt, patt_rule in pairs(regex_rules) do
        if re_match(name, name_patt) then
            local matched = re_match(value, patt_rule.reg)
            if matched then
                store_section(omit_entries, section, name, true)
            else
                if patt_rule.restrict then
                    return WAFBlock, string.format("(%s)/name-patt:%s value-patt:%s mismatch with name: %s value:%s", section, name_patt, patt_rule.reg, name, value)
                elseif #patt_rule.exclusions > 0 then
                    store_section(sig_excludes, section, name, patt_rule.exclusions)
                end
            end
        end
    end

    return nil, nil

end

function waf_regulate(section, profile, request, omit_entries, exclude_sigs)
    -- request.handle:logDebug("WAF regulation - positive security for section: " .. section)
    local name_rules, regex_rules, max_len, max_count = unpack(build_section(section, profile))

    local block_info = {
        ["initiator"] = "waf",
        ["sig_id"] = "-",
        ["sig_category"] = "-",
        ["sig_subcategory"] = "-",
        ["sig_severity"] = "-",
        ["sig_certainity"] = "-",
        ["sig_operand"] = "-",
        ["sig_msg"] = "waf-regulation",
        ["section"] = section,
        ["name"] = "-",
        ["value"] = "-"
    }


    local entries = request[section]
    local check_regex = (#regex_rules > 0)
    local ignore_alphanum = profile.ignore_alphanum

    if #entries > max_count then
        block_info["sig_msg"] = string.format("# of entries (%s) in section %s exceeded max value %s", #entries, section, max_count)
        return WAFBlock, block_info
    end

    for name, value in pairs(entries) do
        if value then
            -- headers/ cookies/args length
            local value_len = value:len()
            
            if value_len > max_len then
                block_info["sig_msg"] = string.format("Length of %s/%s exceeded. Limit: %s, Got: %s", section, name, max_len, value_len)
                block_info["name"] = name
                block_info["value"] = value
                return WAFBlock, block_info
            end

            if ignore_alphanum and re_match(value, "^\\w$") then
                store_section(omit_entries, section, name, true)
            else
                name_rule = name_rules[name]
                if name_rule then
                    local respone, msg = name_check(section, name, name_rule, value, omit_entries, sig_excludes)
                    if WAFBlock == response then
                        block_info["sig_msg"] = msg
                        block_info["name"] = name
                        block_info["value"] = value

                        return response, block_info
                    end
                end
                if check_regex then
                    local response, msg = regex_check(section, name, regex_rules, omit_entries, sig_excludes)
                    if WAFBlock == response then
                        block_info["sig_msg"] = msg
                        block_info["name"] = name
                        block_info["value"] = value

                        return response, block_info
                    end
                end
            end
        end
    end

    return WAFPass, {}
end

function gen_waf_block(category, section, name, value, token)
    return {
        ["initiator"] = "waf",
        ["sig_id"] = "libinjection",
        ["sig_category"] = category,
        ["sig_subcategory"] = category,
        ["sig_severity"] = 5,
        ["sig_certainity"] = 5,
        ["sig_operand"] = "-",
        ["sig_msg"] = token,
        ["section"] = section,
        ["name"] = name,
        ["value"] = value
    }
end
function check(waf_profile, request)
    request.handle:logDebug("WAF inspection starts - with profile %s", waf_profile.name)
    local omit_entries = {}
    local exclude_sigs = {}
    local sections = {"headers", "cookies", "args"}

    for _, section in ipairs(sections) do
        -- request.handle:logDebug("WAF inspecting section: " .. section)
        -- positive security
        local response, msg = waf_regulate(section, waf_profile, request, omit_entries, exclude_sigs)
        if response == WAFBlock then
            return response, msg
        end
        -- negative security
        for name, value in pairs(request[section]) do
            if omit_entries[section] == nil or (not omit_entries[section][name]) then
---
                if exclude_sigs[sections] == nil or (not exclude_sigs[sections][name]["libinjection"]) then
                    local detect, token = detect_sqli(value)
                    if detect then
                        return WAFBlock, gen_waf_block("sqli", section, name, value, token)
                    end
                    detect, token = detect_xss(value)
                    if detect then
                        return WAFBlock, gen_waf_block("xss", section, name, value, token)
                    end
                end
---                
                for _, sig in ipairs(globals.WAFSignatures) do
                    if exclude_sigs[sections] == nil or (not exclude_sigs[sections][name][sig.id]) then

                        if re_match(value, sig.operand) then

                            return WAFBlock, {
                                ["initiator"] = "waf",
                                ["sig_id"] = sig.id,
                                ["sig_category"] = sig.category,
                                ["sig_subcategory"] = sig.subcategory,
                                ["sig_severity"] = sig.severity,
                                ["sig_certainity"] = sig.certainity,
                                ["sig_operand"] = sig.operand,
                                ["sig_msg"] = sig.msg,
                                ["section"] = section,
                                ["name"] = name,
                                ["value"] = value
                            }

                        end
                    end
                end
            end
        end
    end

    return WAFPass, "waf-passed"
end



------

local libinject = require "lua.resty.libinjection"

function detect_sqli(input)
    if (type(input) == 'table') then
        for _, v in ipairs(input) do
            local match, value = detect_sqli(v)

            if match then
                return match, value
            end
        end
    else
        -- yes this is really just one line
        -- libinjection.sqli has the same return values that lookup.operators expects
        return libinject.sqli(input)
    end

    return false, nil
end

function detect_xss(input)
    if (type(input) == 'table') then
        for _, v in ipairs(input) do
            local match, value = detect_xss(v)

            if match then
                return match, value
            end
        end
    else
        -- yes this is really just one line
        -- libinjection.sqli has the same return values that lookup.operators expects
        return libinject.xss(input)
    end

    return false, nil
end

-- function libscan(request_map, scanfunc)
--     local request_uri = ctx._ctx['none']['REQUEST_URI']
--     detect, token = scanfunc(request_uri)
--     if (detect) then
--         return detect, request_uri
--     end

--     request_uri = ctx._ctx['none|urlDecodeUni|cssDecode|htmlEntityDecode|jsDecode|lowercase|compressWhitespace|replaceComments']['REQUEST_URI']
--     detect, token = scanfunc(request_uri)
--     if (detect) then
--         return detect, request_uri
--     end

--     local _args = ctx._ctx['none']['ARGS']
--     if (type(_args) == 'table') then
--         for name, value in ipairs(_args) do
--             detect, token = scanfunc(value)
--             if (detect) then
--                 return detect, "arg/" .. tostring(name) .. "/" .. tostring(value)
--             end
--         end
--     end

--     if ctx.site_global_settings["dpi_inspect_headers"] then
--         local _headers = ctx._ctx['none']['REQUEST_HEADERS']
--         if (type(_headers) == 'table') then
--             for name, value in pairs(_headers) do
--                 if name == "accept" and value:find("/*", 1, true) then
--                     -- skip
--                 else
--                     detect, token = scanfunc(value)
--                     if (detect) then
--                         return detect, "header/" .. tostring(name) .. "/" .. tostring(value)
--                     end
--                 end
--             end
--         end

--         local _cookies = ctx._ctx['none']['REQUEST_COOKIES']
--         if (type(_cookies) == 'table') then
--             for name, value in pairs(_cookies) do
--                 detect, token = scanfunc(value)
--                 if (detect) then
--                     return detect, "cookie/" .. tostring(name) .. "/" .. tostring(value)
--                 end
--             end
--         end
--     end
-- end