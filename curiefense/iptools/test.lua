ipt = require("iptools")


s = ipt.new_ip_set()

nets = {
   ["1.2.3.4"] = "this is ip 1.2.3.4",
   ["192.168.10.0/24"] = "this is net 192.168.10.0/24",
   ["192.168.15.0/24"] = "this is net 192.168.15.0/24"
}

for k,v in pairs(nets) do
   print("Adding ", k, "  ", v)
   s:add(k,v)
end

tests = {
   ["1.2.3.4"] = true,
   ["1.2.3.5"] = false,
   ["192.168.10.0/24"] = true,
   ["192.168.11.0/24"] = false,
   ["192.168.15.0/24"] = true,
   ["192.168.10.0/23"] = true,
   ["192.168.10.0/25"] = true,
}

for k,v in pairs(tests) do
   print("get ", k, "=>", s:get(k))
   if s:contains(k) == v then print("ok") else print("KO") end
end


