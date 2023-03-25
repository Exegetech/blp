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

local function foldBin(list)
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

local space = S("\r\n\t ")^0

local sign    = S("+-")^-1
local number  = (sign * R("09")^1 / numNode) * -R("AZ", "az") * space
local hex     = (P("0") * S("xX") * R("09", "AF", "af")^1 / hexNode) * space
local numeral = (hex + number) * space

local op1 = C(S("^")) * space
local op2 = C(S("*/%")) * space
local op3 = C(S("+-")) * space

local exp1 = space * (Ct(numeral * (op1 * numeral)^0) / foldBin)
local exp2 = space * (Ct(exp1 * (op2 * exp1)^0) / foldBin)
local exp3 = space * (Ct(exp2 * (op3 * exp2)^0) / foldBin)

local function parse(input)
  return exp3:match(input)
end
---------------- FRONTEND -----------------

----------------- BACKEND -----------------
local function addCode(state, val)
  local code = state.code
  code[#code + 1] = val
end

local ops = {
  ["+"] = "add",
  ["-"] = "sub",
  ["*"] = "mul",
  ["/"] = "div",
  ["^"] = "exp",
  ["%"] = "mod",
}

local function codeExp(state, ast)
  if ast.tag == "number" or ast.tag == "hex" then
    addCode(state, "push")
    addCode(state, ast.val)
  elseif ast.tag == "binop" then
    codeExp(state, ast.e1)
    codeExp(state, ast.e2)
    addCode(state, ops[ast.op])
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
