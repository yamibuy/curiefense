module(..., package.seeall)

local globals       = require "lua.globals"
local utils         = require "lua.utils"
local rangesbtree   = require "lua.rangesbtree"
local cjson         = require "cjson"
local json_safe     = require "cjson.safe"

local re_match        = utils.re_match
local tag_request     = utils.tag_request
local json_encode     = cjson.encode

function match_singles(request_map, list_entry)
  for entry_key, list_entries in pairs(list_entry) do
    -- exact request map
    local entry_match = list_entries[request_map[entry_key]]
    if entry_match then
      return entry_match
    end
    -- exact request map's attr
    entry_match = list_entries[request_map.attrs[entry_key]]
    if entry_match then
      return entry_match
    end

    -- pattern matching for all but ip.
    if entry_key ~= 'ip' then
      for pattern, annotation in pairs(list_entries) do
        local value = request_map.attrs[entry_key]
        if value then
          if re_match(value, pattern) then
            request_map.handle:logDebug(string.format("matched >> match_singles - regex %s %s", value, pattern))
            return annotation
          end
        end
      end
    end
  end
  -- no match
  return false
end

function match_pairs(request_map, list_entry)
  for pair_name, match_entries in pairs(list_entry) do
    for key, va in pairs(match_entries) do
      local value, annotation = unpack(va)
      local reqmap_value = request_map[pair_name][key]
      if value and reqmap_value then
        if reqmap_value == value or re_match(reqmap_value, value) then
          request_map.handle:logDebug(string.format("matched >> match_pairs %s %s", reqmap_value, value))
          return annotation
        end
      end
    end
  end
  return false
end

function negate_match_pairs(request_map, list_entry)
  for pair_name, match_entries in pairs(list_entry) do
    for key, va in pairs(match_entries) do
      local value, annotation = unpack(va)
      local reqmap_value = request_map[pair_name][key]
      if value and reqmap_value then
        if reqmap_value ~= value and not re_match(reqmap_value, value) then
          request_map.handle:logDebug(string.format("matched >> negate_match_pairs %s NOT %s", reqmap_value, value))
          return annotation
        end
      end
    end
  end
  return false
end

function eval_section(request_map, section)
  local section_relation_and = (section.relation == "AND")
  local m_singles, m_pairs, m_iprange, nm_singles, nm_pairs, nm_iprange  = true, true, true, true, true, true


  if section.singles then
    request_map.handle:logDebug(string.format("match_or_list section.singles %s", json_encode(section.singles)))
    local annotation, tags = match_singles(request_map, section.singles)
    if not annotation then
      m_singles = false
      if section_relation_and then return false end
    end
  end

  if section.pairs then
    request_map.handle:logDebug(string.format("match_or_list section.pairs %s", json_encode(section.pairs)))
    local annotation, tags = match_pairs(request_map, section.pairs)
    if not annotation then
      m_pairs = false
      if section_relation_and then return false end
    end
  end

  if section.iprange then
    local within = section.iprange:contains(request_map.attrs.ip)
    if not within then
      m_iprange = false
      if section_relation_and then return false end
    end
  end

  -- has entries
  if section.negate_singles and next(section.negate_singles) then
    local annotation, tags = match_singles(request_map, section.negate_singles)
    if annotation then
      nm_singles = false
      if section_relation_and then return false end
    end
  end

  if section.negate_pairs and next(section.negate_pairs) then
    local annotation, tags = negate_match_pairs(request_map, section.negate_pairs)
    if not annotation then
      nm_pairs = false
      if section_relation_and then return false end
    end
  end

  if section.negate_iprange:len() > 0 then
    local within = section.negate_iprange:contains(request_map.attrs.ip)
    if within then
      nm_iprange = false
      if section_relation_and then return false end
    end
  end

  return m_singles or m_pairs or m_iprange or nm_singles or nm_pairs or nm_iprange

end

function tag_lists(request_map)
  for _, list in pairs(globals.ProfilingLists) do
    local list_matched = false
    local sections = list.rule.sections
    local rule_relation_and = (list.rule.relation == "AND")

    for _, section in ipairs(sections) do
      if not eval_section(request_map, section) then
        -- first no match, bounce.
        if rule_relation_and then
          return
        end
        list_matched = false
      else
        if not rule_relation_and then
          tag_request(request_map, list.tags)
          return
        end
        -- OR mode, match and move on.
        list_matched = true
      end
    end
    if rule_relation_and and list_matched then
      tag_request(request_map, list.tags)
    end
  end
end
