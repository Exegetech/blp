local lu = require("luaunit")
local lpeg = require("lpeg")

local space = lpeg.S("\r\n\t ")^0
local number = lpeg.R("09")^1

local summation = space * number * (space * '+' * space * number)^0

TestLPeg = {}
function TestLPeg:testSummation()
  local cases = {
    { input = "1", output = 2 },
    { input = " 1", output = 3 },
    { input = "10", output = 3 },
    { input = "1+2", output = 4 },
    { input = "11+22", output = 6 },
    { input = "1 + 2", output = 6 },
    { input = "13 + 25", output = 8 },
    { input = "13       +        25", output = 21 },
    { input = "1       + 25", output = 13 },
    { input = "13 + 25 + 36", output = 13 },
    { input = "13 +25 +    36", output = 15 },
  }

  for _, case in ipairs(cases) do
    lu.assertEquals(summation:match(case.input), case.output)
  end
end

lu.run()
