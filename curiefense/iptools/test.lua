ipt = require("iptools")


s = ipt.new_ip_set()

print("contains 1.2.3.4:",s:contains("1.2.3.4"))
print("add 1.2.3.4")
s:add("1.2.3.4")
print("contains 1.2.3.4:",s:contains("1.2.3.4"))
print("contains 1.2.3.5:",s:contains("1.2.3.5"))

s:add("192.168.10.0/24")
s:add("192.168.15.0/24")

print("should be true: ", s:contains("192.168.10.0/23"))
print("should be true : ", s:contains("192.168.10.0/24"))
print("should be true : ", s:contains("192.168.10.0/25"))
print("should be false: ", s:contains("192.168.11.0"))
print("should be true : ", s:contains("192.168.10.0"))
print("should be true : ", s:contains("192.168.10.5"))
print("should be true : ", s:contains("192.168.15.5"))
print("size of set:", s:len())
