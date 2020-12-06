module(..., package.seeall)

session = require("lua.session")

function string:length() return #self end
function string:getBytes() return self end


HT = {}
hmethods = {
     get = function (self, k)
         return self[k]
     end
 }
setmetatable(HT, {__index = hmethods})


function run(headers, metadata, body)
    request = {
        ["headers"] = HT,
        ["metadata"] = metadata,
        ["body"] = body
    }

    for k, v in pairs(headers) do
        request["headers"][k] = v
    end

    Handle = {}

--[[
    function Handle:logDebug(x) print("DEBUG",x) end
    function Handle:logInfo(x)  print("INFO",x) end
    function Handle:logError(x) print("ERROR",x) end
    function Handle:logErr(x) print("ERROR",x) end
  ]]

    function Handle:logDebug(x) return end
    function Handle:logInfo(x)  return end
    function Handle:logError(x) return end
    function Handle:logErr(x) return end

    function Handle:_set_request(t) self.request = t end
    function Handle:headers(t) return self.request.headers end
    function Handle:metadata(t) return self.request.metadata end
    function Handle:body(t) return self.request.body end


    handle = Handle
    handle:_set_request(request)

    session.inspect(handle)

end
