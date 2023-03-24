local lu = require("luaunit")
local lpeg = require("lpeg")

local space     = lpeg.S("\r\n\t ")^0
local sign      = (lpeg.P("+") + lpeg.P("-"))^-1
local number    = lpeg.C(sign * lpeg.R("09")^1) * space
local plus      = lpeg.P("+") * space
local summation = space * number * (plus * number)^0 * -lpeg.P(1)

TestLPeg = {}
function TestLPeg:testSummation()
  local cases = {
    { input = " 1", output = {"1", n = 1} },
    { input = " 1 ", output = {"1", n = 1} },
    { input = "-1 ", output = {"-1", n = 1} },
    { input = "+1 ", output = {"+1", n = 1} },
    { input = "10", output = {"10", n = 1} },
    { input = "1+2", output = {"1", "2", n = 2} },
    { input = "1++2", output = {"1", "+2", n = 2} },
    { input = "1+-2", output = {"1", "-2", n = 2} },
    { input = "11+22", output = {"11", "22", n = 2} },
    { input = "11+ +22", output = {"11", "+22", n = 2} },
    { input = "11+ -22", output = {"11", "-22", n = 2} },
    { input = "1 + 2", output = {"1", "2", n = 2} },
    { input = "13 + 25", output = {"13", "25", n = 2} },
    { input = "13       +        25", output = {"13", "25", n = 2} },
    { input = "1       + 25", output = {"1", "25", n = 2} },
    { input = "13 + 25 + 36", output = {"13", "25", "36", n = 3} },
    { input = "13 +25 +    36", output = {"13", "25", "36", n = 3} },
    { input = "+13 +-25 +    +36", output = {"+13", "-25", "+36", n = 3} },
    { input = " 1 a", output = {nil, n = 1} },
    { input = " 1a", output = {nil, n = 1} },
    { input = "1 abc", output = {nil, n = 1} },
    { input = "13 +25 +    36abcd", output = {nil, n = 1} },
    { input = "13 +25 +    36 abcd", output = {nil, n = 1} },
  }

  for _, case in ipairs(cases) do
    lu.assertEquals(table.pack(summation:match(case.input)), case.output)
  end
end

lu.run()
