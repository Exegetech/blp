local lu = require("luaunit")
local lpeg = require("lpeg")

local space = lpeg.S("\r\n\t ")^0
local number = lpeg.C(lpeg.R("09")^1)

local summation = space * number * (space * '+' * space * number)^0

TestLPeg = {}
function TestLPeg:testSummation()
  local cases = {
    { input = " 1", output = {"1"} },
    { input = "1", output = {"1"} },
    { input = "10", output = {"10"} },
    { input = "1+2", output = {"1", "2"} },
    { input = "11+22", output = {"11", "22"} },
    { input = "1 + 2", output = {"1", "2"} },
    { input = "13 + 25", output = {"13", "25"} },
    { input = "13       +        25", output = {"13", "25"} },
    { input = "1       + 25", output = {"1", "25"} },
    { input = "13 + 25 + 36", output = {"13", "25", "36"} },
    { input = "13 +25 +    36", output = {"13", "25", "36"} },
  }

  for _, case in ipairs(cases) do
    lu.assertEquals(summation:match(case.input), table.unpack(case.output))
  end
end

lu.run()
