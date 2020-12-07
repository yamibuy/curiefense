--benchmark.lua

profiler = require("profiler")


profiler.start()


test = require ("lua.test")


for i = 1000,1,-1
do
    test.run({
            ["host"] = "www.example.com",
            [":path"] = "/",
            [":method"] = "POST",
            ["x-forwarded-for"] = "1.2.3.4"
        }, {}, "loremipsum"
    )
end

-- test.run({
--         ["host"] = "www.example.com",
--         [":path"] = "/",
--         [":method"] = "POST",
--         ["x-forwarded-for"] = "1.2.3.4"
--     }, {}, "loremipsum"
-- )

profiler.stop()
profiler.report("profiler.log")