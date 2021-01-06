


local sessionutils = require ("sessionutils")

local buildkey = sessionutils.buildkey
local should_exclude = sessionutils.should_exclude
local should_include = sessionutils.should_include


--[===[
[
  {
    "id": "b7323e78a3ec",
    "name": "New Flow Control",
    "ttl": 60,
    "active": true,
    "notes": "New Flow Control Notes and Remarks",
    "key": [
      {
        "attrs": "ip"
      }
    ],
    "action": {
      "type": "default",
      "params": {
        "action": {
          "type": "default",
          "params": {}
        }
      }
    },
    "exclude": [],
    "include": [
      "all"
    ],
    "sequence": [
      {
        "method": "GET",
        "uri": "/",
        "cookies": {},
        "headers": {
          "host": "www.example.com"
        },
        "args": {}
      },
      {
        "method": "GET",
        "uri": "/assets/app.js",
        "cookies": {},
        "headers": {
          "host": "www.example.com"
        },
        "args": {}
      },
      {
        "method": "POST",
        "uri": "/api/v1/login",
        "cookies": {},
        "headers": {
          "host": "api.example.com"
        },
        "args": {}
      }
    ]
  }
]
]===]--


--[[
Flow controls are globals
hence can cause huge performance hurdle.
to minimize the risk, given Host, Method Path are mandatory
    map for each request those for quick relevant check

    only if match, start the actual checks with optionally other entries matching (headers, attrs)
    and redis state etc.

In other words, given the above example
    {
        "id": "b7323e78a3ec",
        "name": "New Flow Control",
        "quickmatch": {
            "www.example.comGET/": true,
            "www.example.comGET/assets/app.js": true,
            "api.example.comPOST/api/v1/login": true
        },
        "ttl": 60,
        "active": true,
        "notes": "New Flow Control Notes and Remarks",
        "key": [
          {
            "attrs": "ip"
          }
        ],
        ...
    }


chronological order matter to some extent
sequence matter

    if not should exclude and should include

        scan sequence from end to start

        if match the last entry of the sequence
            redis set should be at length of (sequence -1 or sequence).

        for each item in the seq
            if match item
                if redis set length  equals to index - 1
                    add to redis
]]

function flow_check(flow_ids, request_map)
    local must_match = false
    for _, id in ipairs(flow_ids) do
        local rule = globals.FlowControlRules[id]
        if rule then
            if     should_exclude(rule.exclude, request_map) then return false end
            if not should_include(rule.include, request_map) then return false end

            local rule_sequence = rule.sequence
            local seqlen = #rule_sequence
            local pre_entries = slice(rule_sequence, 1, seqlen - 1)
            local last_entry = rule_sequence[seqlen]

            if request_sequence_entry_matched(request_map, last_entry) then
                must_match = true
                if redis_list_length ~= seqlen then
                    -- BLOCK
                else
                    -- reset list
                end
            end

            for idx, sequence in ipairs(pre_entries) do
                if request_sequence_entry_matched(request_map, sequence) then
                    -- check redis current state for this key and
                    -- compare list length vs idx.
                    -- length ~= idx ignore // user can refresh the page, hit "back", etc.
                    if idx == redis_list_length then
                        -- add to the list
                        add_to_sequence(sequence, request_map)
                    end
                end
            end


        end
    end

end