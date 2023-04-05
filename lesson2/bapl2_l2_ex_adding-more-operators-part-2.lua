local lu    = require("luaunit")
local lpeg  = require("lpeg")
local pt    = require("pt")

local DEBUG = false

local function printTable(tbl)
  print(pt.pt(tbl))
  print("-----------------------")
end

---------------- FRONTEND -----------------
local function numNode(num)
  return {
    tag = "number",
    val = tonumber(num),
  }
end

local function hexNode(num)
  return {
    tag = "hex",
    val = tonumber(num),
  }
end

local function foldBinary(list)
  local tree = list[1]
  for i = 2, #list, 2 do
    tree = {
      tag = "binop",
      e1  = tree,
      op  = list[i],
      e2  = list[i + 1],
    }
  end

  return tree
end

local P  = lpeg.P
local S  = lpeg.S
local R  = lpeg.R
local C  = lpeg.C
local Ct = lpeg.Ct
local V  = lpeg.V

local space = S("\r\n\t ")^0

local sign    = S("+-")^-1
local number  = (sign * R("09")^1 / numNode) * -R("AZ", "az") * space
local hex     = (P("0") * S("xX") * R("09", "AF", "af")^1 / hexNode) * space
local numeral = (hex + number) * space

local expOp       = C(S("^")) * space
local mulDivModOp = C(S("*/%")) * space
local addSubOp    = C(S("+-")) * space

local eqOp    = S("<>!=") * S("=")
local gtLtOp  = S("<>")
local compOp  = C(eqOp + gtLtOp) * space

local OP = P("(") * space
local CP = P(")") * space

local exp0 = V("exp0")
local exp1 = V("exp1")
local exp2 = V("exp2")
local exp3 = V("exp3")
local exp4 = V("exp4")

local g = P({"exp4",
  exp0 = numeral + (OP * exp4 * CP),
  exp1 = space * (Ct(exp0 * (expOp * exp0)^0) / foldBinary),
  exp2 = space * (Ct(exp1 * (mulDivModOp * exp1)^0) / foldBinary),
  exp3 = space * (Ct(exp2 * (addSubOp * exp2)^0) / foldBinary),
  exp4 = space * (Ct(exp3 * (compOp * exp3)^0) / foldBinary),
})

g = g * -lpeg.P(1)

local function parse(input)
  return g:match(input)
end
---------------- FRONTEND -----------------

----------------- BACKEND -----------------
local function addCode(state, val)
  local code = state.code
  code[#code + 1] = val
end

local binOps = {
  ["+"]  = "add",
  ["-"]  = "sub",
  ["*"]  = "mul",
  ["/"]  = "div",
  ["^"]  = "exp",
  ["%"]  = "mod",
  ["<"]  = "lt",
  [">"]  = "gt",
  ["<="] = "lte",
  [">="] = "gte",
  ["!="] = "neq",
  ["=="] = "eq",
}

local function codeExp(state, ast)
  if ast.tag == "number" or ast.tag == "hex" then
    addCode(state, "push")
    addCode(state, ast.val)
  elseif ast.tag == "binop" then
    codeExp(state, ast.e1)
    codeExp(state, ast.e2)
    addCode(state, binOps[ast.op])
  else
    error("invalid tree")
  end
end

local function compile(ast)
  local state = { code = {} }
  codeExp(state, ast)
  return state.code
end

local function run(code, stack)
  if DEBUG then
    print("----------------")
  end

  local pc = 1
  local top = 0

  while pc <= #code do
    if code[pc] == "push" then
      pc = pc + 1
      top = top + 1

      if DEBUG then
        print("push ", code[pc])
      end

      stack[top] = code[pc]
    elseif code[pc] == "add" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("add ", a, b)
      end

      stack[top - 1] = a + b
      top = top - 1
    elseif code[pc] == "sub" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("sub ", a, b)
      end

      stack[top - 1] = a - b
      top = top - 1
    elseif code[pc] == "mul" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("mul ", a, b)
      end

      stack[top - 1] = a * b
      top = top - 1
    elseif code[pc] == "div" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("div ", a, b)
      end

      stack[top - 1] = a / b
      top = top - 1
    elseif code[pc] == "exp" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("exp ", a, b)
      end

      stack[top - 1] = a^b
      top = top - 1
    elseif code[pc] == "mod" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("mod ", a, b)
      end

      stack[top - 1] = a % b
      top = top - 1
    elseif code[pc] == "lt" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("lt ", a, b)
      end

      stack[top - 1] = a < b and 1 or 0 
      top = top - 1
    elseif code[pc] == "gt" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("gt ", a, b)
      end

      stack[top - 1] = a > b and 1 or 0 
      top = top - 1
    elseif code[pc] == "lte" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("lte ", a, b)
      end

      stack[top - 1] = a <= b and 1 or 0 
      top = top - 1
    elseif code[pc] == "gte" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("gte ", a, b)
      end

      stack[top - 1] = a >= b and 1 or 0 
      top = top - 1
    elseif code[pc] == "neq" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("neq ", a, b)
      end

      stack[top - 1] = a ~= b and 1 or 0 
      top = top - 1
    elseif code[pc] == "eq" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        print("neq ", a, b)
      end

      stack[top - 1] = a == b and 1 or 0 
      top = top - 1
    else
      error("unknown instruction")
    end
    pc = pc + 1
  end
end
----------------- BACKEND -----------------

------------------ TEST -------------------
Test = {}
function Test:testEvaluating()
  local cases = {
    { input = "1", output = 1 },
    { input = " 1", output = 1 },
    { input = " 1 ", output = 1 },
    { input = "01 ", output = 1 },
    { input = " 010", output = 10 },
    { input = " -010", output = -10 },
    { input = " +010", output = 10 },
    { input = "11+ +22", output = 33 },
    { input = "11+ -22", output = -11 },
    { input = "+13 +-25 +    +36", output = 24 },
    { input = "1 - 2", output = -1 },
    { input = "1 - -2", output = 3 },
    { input = "1 - -2 + 3 - 4", output = 2 },
    { input = "1a", output = nil },
    { input = "0xF", output = 15 },
    { input = "0xFF", output = 255 },
    { input = "0xff", output = 255 },
    { input = "3 * 5", output = 15 },
    { input = "0xF / 3", output = 5.0 },
    { input = "0xA / 2", output = 5.0 },
    { input = "0xF + 0xA", output = 25 },
    { input = "0xF - 0xA", output = 5 },
    { input = "2 + 14 * 2 / 2", output = 16 },
    { input = "10 % 8", output = 2 },
    { input = "4 + 10 % 8", output = 6 },
    { input = "4 + 5 * 2 ^ 3 / 10", output = 8 },
    { input = "4 + 5 * 2 ^ 3 / 10 % 2", output = 4.0 },
    { input = "2 * (2 + 4) * 10", output = 120 },
    { input = "1 < 2", output = 1 },
    { input = "1 > 2", output = 0 },
    { input = "1 <= 2", output = 1 },
    { input = "2 <= 2", output = 1 },
    { input = "1 >= 2", output = 0 },
    { input = "1 == 2", output = 0 },
    { input = "2 == 2", output = 1 },
    { input = "2 != 2", output = 0 },
  }

  for _, case in ipairs(cases) do
    if case.output == nil then
      local parsed = parse(case.input)
      lu.assertEquals(parsed, nil)
    else
      local parsed = parse(case.input)
      local code = compile(parsed)

      local stack = {}
      run(code, stack)

      local result = stack[1]
      lu.assertEquals(result, case.output)
    end
  end
end

-- Uncomment to get print statement
-- DEBUG = true
lu.run()
------------------ TEST -------------------