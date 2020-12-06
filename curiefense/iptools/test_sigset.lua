ipt = require("iptools")

ss = ipt.new_sig_set()

ss:add("^A+$","only As")
ss:add("^B+$","only Bs")
ss:add("^C+$","only Cs")
ss:add("^A+","starts with A")
ss:add("B+$","ends with B")
ss:compile()


tests = { "AAAAAAA", "BBBBBB", "AAABBB", "CABC", "ABABAB", "qADAZD" }

print("======= test is_match() ========")

for i,t in pairs(tests) do
   print(t, ss:is_match(t))
end

print("======= test is_match_id() ========")

for i,t in pairs(tests) do
   print(t, ss:is_match_id(t))
end


print("======= test is_match_ids() ========")

for i,t in pairs(tests) do
   r = ss:is_match_ids(t)
   print("--->", t)
   for j,u in pairs(r) do
      print("    ",u)
   end
end

print("======= test clear ========")

ss:clear()
ss:add("^A+$","only As")
ss:add("^B+$","only Bs")
ss:compile()

for i,t in pairs(tests) do
   print(t, ss:is_match(t))
end
