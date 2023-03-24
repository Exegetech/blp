local lu    = require("luaunit")
local lpeg  = require("lpeg")
local pt    = require("pt")

local P  = lpeg.P
local S  = lpeg.S
local R  = lpeg.R
local C  = lpeg.C
local Ct = lpeg.Ct
local V  = lpeg.V

function fold(list)
  local acc = list[1]
  for i = 2, #list, 2 do
    if list[i] == "+" then
      acc = acc + list[i + 1]
    elseif list[i] == "-" then
      acc = acc - list[i + 1]
    elseif list[i] == "*" then
      acc = acc * list[i + 1]
    elseif list[i] == "/" then
      acc = acc / list[i + 1]
    elseif list[i] == "%" then
      acc = acc % list[i + 1]
    elseif list[i] == "^" then
      acc = acc ^ list[i + 1]
    else
      error("unknown operator")
    end
  end

  return acc
end

local space = S("\r\n\t ")^0

local sign   = (P("+") + P("-"))^-1
local number = (sign * R("09")^1 / tonumber) * space

local op1 = C(S("^")) * space
local op2 = C(S("*/%")) * space
local op3 = C(S("+-")) * space

local OP = P("(") * space
local CP = P(")") * space

local exp0 = V("exp0")
local exp1 = V("exp1")
local exp2 = V("exp2")
local exp3 = V("exp3")

local g = P({"exp3",
  exp0 = number + (OP * exp3 * CP),
  exp1 = space * (Ct(exp0 * (op1 * exp0)^0) / fold),
  exp2 = space * (Ct(exp1 * (op2 * exp1)^0) / fold),
  exp3 = space * (Ct(exp2 * (op3 * exp2)^0) / fold),
})

g = g * -lpeg.P(1)

TestLPeg = {}
function TestLPeg:testSummation()
  local cases = {
    { input = " 1", output = 1 },
    { input = " 1 ", output = 1 },
    { input = "-1 ", output = -1 },
    { input = "+1 ", output = 1 },
    { input = "10", output = 10 },
    { input = "1+2", output = 3 },
    { input = "1++2", output = 3 },
    { input = "1+-2", output = -1 },
    { input = "11+22", output = 33 },
    { input = "11+ +22", output = 33 },
    { input = "11+ -22", output = -11 },
    { input = "1 + 2", output = 3 },
    { input = "13 + 25", output = 38 },
    { input = "13       +        25", output = 38 },
    { input = "1       + 25", output = 26 },
    { input = "13 + 25 + 36", output = 74 },
    { input = "13 +25 +    36", output = 74 },
    { input = "+13 +-25 +    +36", output = 24 },
    { input = " 1 a", output = nil },
    { input = " 1a", output = nil },
    { input = "1 abc", output = nil },
    { input = "13 +25 +    36abcd", output = nil },
    { input = "13 +25 +    36 abcd", output = nil },
    { input = "1 - 2", output = -1 },
    { input = "1 - -2", output = 3 },
    { input = "1 - -2 + 3 - 4", output = 2 },
    { input = "3 * 4", output = 12 },
    { input = "12 / 4", output = 3 },
    { input = "2 + 14 * 2", output = 30 },
    { input = "2 + 14 * 2 / 2", output = 16 },
    { input = "2 + 14 * 2 / 2", output = 16 },
    { input = "10 % 8", output = 2 },
    { input = "4 + 10 % 8", output = 6 },
    { input = "2 ^ 3", output = 8 },
    { input = "3 + 5 * 2 ^ 3", output = 43 },
    { input = "4 + 5 * 2 ^ 3 / 10", output = 8 },
    { input = "4 + 5 * 2 ^ 3 / 10 % 2", output = 4.0 },
    { input = "2 * (2 + 4) * 10", output = 120 },
  }

  for _, case in ipairs(cases) do
    lu.assertEquals(g:match(case.input), case.output)
  end
end

lu.run()
