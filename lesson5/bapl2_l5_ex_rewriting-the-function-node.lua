local lu    = require("luaunit")
local lpeg  = require("lpeg")
local pt    = require("pt")

local DEBUG = false
local TEST = false
local EXIT_ON_ERROR = false

local function printTable(tbl)
  print(pt.pt(tbl))
  print("-----------------------")
end

local function I(msg)
  return lpeg.P(function ()
    print(msg)
    return true
  end)
end

-- Using metaprogramming
-- local function node (tag, ...)
--   local labels = table.pack(...)
--   local params = table.concat(labels, ", ")
--   local fields = string.gsub(params, "(%w+)", "%1 = %1")
--   local code = string.format(
--     "return function (%s) return { tag = '%s', %s } end",
--     params, tag, fields
--   )

--   return load(code)()
-- end

-- Without using meta programming
local function node(tag, ...)
	local labels = table.pack(...)

	return function(...)
		local params = table.pack(...)
		local result = { tag = tag }

		for i = 1, #labels do
			result[labels[i]] = params[i]
		end

		return result
  end
end

local function countNewLine(str)
  local count = 0

  for i = 1, #str do
    if string.sub(str, i, i) == "\n" then
      count = count + 1
    end
  end

  if string.sub(str, -1) == "\n" then
    count = count + 1
  end

  return count
end

---------------- FRONTEND -----------------
local numNode = node("number", "val")
local hexNode = node("hex", "val")
local varNode = node("variable", "val")
local assignmentNode = node("assignment", "id", "exp")

local function sequenceNode(st1, st2)
  if st2 == nil then
    return st1
  else
    return {
      tag = "sequence",
      st1 = st1,
      st2 = st2,
    }
  end
end

local returnNode = node("return", "exp")
local printNode = node("print", "exp")
local negNode = node("not", "exp")

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

local P   = lpeg.P
local S   = lpeg.S
local R   = lpeg.R
local C   = lpeg.C
local Ct  = lpeg.Ct
local Cmt = lpeg.Cmt
local V   = lpeg.V

local maxmatch = 0
local maxnewline = 0

local anyChar = P(1)

local comment       = P("#") * (anyChar - P("\n"))^0

local startComment  = P("#{") 
local endComment    = P("#}") 
local blockComment  = startComment * (anyChar - endComment)^0 * endComment 

local space = V("space")

local alpha       = R("AZ", "az")
local underscore  = S("_")
local digit       = R("09")
local alphanum        = alpha + digit
local alphaunderscore = alpha + underscore

local sign          = S("+-")^-1
local numberChar    = digit
local hexNumberChar = numberChar + R("AF", "af")
local hexadecimal   = (P("0") * S("xX") * hexNumberChar^1) / tonumber / hexNode
local decimalInt    = sign * numberChar^1
local decimalFloat  = sign * (numberChar^1 * S(".") * numberChar^0) + (numberChar^0 * S(".") * numberChar^1)
local decimal       = (decimalFloat + decimalInt) / tonumber / numNode
local scientific    = ((decimalFloat + decimalInt) * S("eE") * decimalInt) / tonumber / numNode
local numeral       = (hexadecimal + scientific + decimal) * space

local expOp       = C(S("^")) * space
local mulDivModOp = C(S("*/%")) * space
local addSubOp    = C(S("+-")) * space

local eqOp    = S("<>!=") * S("=")
local gtLtOp  = S("<>")
local compOp  = C(eqOp + gtLtOp) * space

local printOp = P("@")
local negOp = P("!")

local function T(t)
  return P(t) * space
end

local reserved = {
  "return",
  "if",
}

local excluded = lpeg.P(false)
for i = 1, #reserved do
  excluded = excluded + reserved[i]
end
excluded = excluded * -alphanum

local function Rw(t)
  assert(excluded:match(t))
  return P(t) * -alphanum * space
end

-- Original implementation
-- local ID = (C(alphaunderscore * alphanum^0) - excluded)  * space

-- Alternative implementation
local ID = C(Cmt(
  alphaunderscore * alphanum^0,
  function(str, pos, match)
    if excluded:match(match) ~= nil then
      return false
    else
      return pos
    end
  end)) * space

local var = ID / varNode

local exp0 = V("exp0")
local exp1 = V("exp1")
local exp2 = V("exp2")
local exp3 = V("exp3")
local exp4 = V("exp4")
local exp5 = V("exp5")
local statementOrExp    = V("statementOrExp")
local statementsOrExps  = V("statementsOrExps")
local block = V("block")

local g = P({"program",
  program           = space * statementsOrExps * -P(1),
  statementsOrExps  = statementOrExp * ((T(";") * statementsOrExps) + T(";"))^-1 / sequenceNode,

  block             = T("{") * statementsOrExps * T(";")^-1 * T("}"),

  statementOrExp    = block
                    + (ID * T("=") * exp5 / assignmentNode)
                    + (Rw("return") * exp5 / returnNode)
                    + (printOp * exp5 / printNode)
                    + exp5,

  exp5              = space * (Ct(exp4 * (compOp * exp4)^0) / foldBinary),

  exp4              = (negOp * exp4 / negNode)
                    + exp3,

  exp3              = space * (Ct(exp2 * (addSubOp * exp2)^0) / foldBinary),

  exp2              = space * (Ct(exp1 * (mulDivModOp * exp1)^0) / foldBinary),

  exp1              = space * (Ct(exp0 * (expOp * exp0)^0) / foldBinary),

  exp0              = numeral
                    + (T("(") * exp4 * T(")"))
                    + var,

  space             = (blockComment + S("\r\n\t ") + comment)^0
                    * P(function(match, position)
                        local newlineCount = countNewLine(match)
                        maxnewline = newlineCount + 1

                        maxmatch = math.max(maxmatch, position)
                        return true
                      end)
})

local function syntaxError(input, maxmatch, maxnewline)
  io.stderr:write("syntax error on line ", maxnewline, "\n")
  local before = string.sub(input, maxmatch - 10, maxmatch, - 1)
  local after = string.sub(input, maxmatch, maxmatch + 11)
  io.stderr:write(before, "|", after, "\n")
end

local function parse(input)
  local result = g:match(input)
  
  if DEBUG then
    if not result then
      syntaxError(input, maxmatch, maxnewline)
      if EXIT_ON_ERROR then
        os.exit(1)
      end
    end
  end

  return result
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

local function loadVar2Num(state, id)
  local number = state.variables[id]
  if not number then
    error("undefined variable " .. id)
  end

  return number
end

local function storeVar2Num(state, id)
  local number = state.variables[id]
  if not number then
    number = state.numOfVariables + 1
    state.numOfVariables = number
    state.variables[id] = number
  end

  return number
end

local function codeExp(state, ast)
  if ast.tag == "number" or ast.tag == "hex" then
    addCode(state, "push")
    addCode(state, ast.val)
  elseif ast.tag == "binop" then
    codeExp(state, ast.e1)
    codeExp(state, ast.e2)
    addCode(state, binOps[ast.op])
  elseif ast.tag == "variable" then
    addCode(state, "load")
    number = loadVar2Num(state, ast.val)
    addCode(state, number)
  elseif ast.tag == "not" then
    codeExp(state, ast.exp)
    addCode(state, "not")
  else
    error("invalid tree")
  end
end

local function codeStatement(state, ast)
  if ast.tag == "sequence" then
    codeStatement(state, ast.st1)
    codeStatement(state, ast.st2)
  elseif ast.tag == "assignment" then
    codeExp(state, ast.exp)
    addCode(state, "store")

    number = storeVar2Num(state, ast.id)
    addCode(state, number)
  elseif ast.tag == "return" then
    codeExp(state, ast.exp)
    addCode(state, "return")
  elseif ast.tag == "print" then
    codeExp(state, ast.exp)
    addCode(state, "print")
  else
    codeExp(state, ast)
  end
end

local function compile(ast)
  local state = {
    code = {},
    variables = {},
    numOfVariables = 0
  }

  codeStatement(state, ast)

  -- All programs return 0
  addCode(state, "push")
  addCode(state, 0)
  addCode(state, "return")

  return state.code
end

local function negate(val)
  if val == 0 then
    return 1
  else
    return 0
  end
end

local function run(code, memory, stack)
  if DEBUG then
    print("----------------")
  end

  local pc = 1
  local top = 0

  while true do

    if DEBUG  then
      io.write("stack --> ")
      for i = 1, top do
        io.write(tostring(stack[i]), " ")
      end

      io.write("\n")
    end

    if code[pc] == "return" then
      return
    elseif code[pc] == "print" then
      if DEBUG then
        io.write("print ", stack[top])
      end
      print(stack[top])
    elseif code[pc] == "not" then
      if DEBUG then
        io.write("not ", stack[top])
      end

      stack[top] = negate(stack[top])
    elseif code[pc] == "push" then
      pc = pc + 1
      top = top + 1

      if DEBUG then
        io.write("push ", code[pc])
      end

      stack[top] = code[pc]
    elseif code[pc] == "add" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("add ", a, b)
      end

      stack[top - 1] = a + b
      top = top - 1
    elseif code[pc] == "sub" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("sub ", a, b)
      end

      stack[top - 1] = a - b
      top = top - 1
    elseif code[pc] == "mul" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("mul ", a, b)
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
        io.write("exp ", a, b)
      end

      stack[top - 1] = a^b
      top = top - 1
    elseif code[pc] == "mod" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("mod ", a, b)
      end

      stack[top - 1] = a % b
      top = top - 1
    elseif code[pc] == "lt" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("lt ", a, b)
      end

      stack[top - 1] = a < b and 1 or 0 
      top = top - 1
    elseif code[pc] == "gt" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("gt ", a, b)
      end

      stack[top - 1] = a > b and 1 or 0 
      top = top - 1
    elseif code[pc] == "lte" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("lte ", a, b)
      end

      stack[top - 1] = a <= b and 1 or 0 
      top = top - 1
    elseif code[pc] == "gte" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("gte ", a, b)
      end

      stack[top - 1] = a >= b and 1 or 0 
      top = top - 1
    elseif code[pc] == "neq" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("neq ", a, b)
      end

      stack[top - 1] = a ~= b and 1 or 0 
      top = top - 1
    elseif code[pc] == "eq" then
      a = stack[top - 1]
      b = stack[top]

      if DEBUG then
        io.write("neq ", a, b)
      end

      stack[top - 1] = a == b and 1 or 0 
      top = top - 1
    elseif code[pc] == "load" then
      pc = pc + 1
      local id = code[pc]
      top = top + 1
      stack[top] = memory[id]

      if DEBUG then
        io.write("load ", stack[top], " from ", id)
      end
    elseif code[pc] == "store" then
      pc = pc + 1
      local id = code[pc]
      memory[id] = stack[top]

      if DEBUG then
        io.write("store ", stack[top], " to ", id)
      end

      top = top - 1
    else
      error("unknown instruction")
    end

    if DEBUG then
      io.write("\n")
    end

    pc = pc + 1
  end
end
----------------- BACKEND -----------------

------------------ TEST -------------------
Test = {}

function Test:testArithmetic()
  local cases = {
    { input = "1", output = 1 },
    { input = " 1", output = 1 },
    { input = " 1 ", output = 1 },
    { input = "01 ", output = 1 },
    { input = " 010", output = 10 },
    { input = " -010", output = -10 },
    { input = " +010", output = 10 },
    { input = "0.5", output = 0.5 },
    { input = ".3", output = 0.3 },
    { input = "3.", output = 3.0 },
    { input = "1.3", output = 1.3 },
    { input = "000.9", output = 0.9 },
    { input = "000.8b", output = nil },
    { input = "+0000.7", output = 0.7 },
    { input = "-0000.7", output = -0.7 },
    { input = "2e3", output = 2000.0 },
    { input = "2.3e-5", output = 0.000023 },
    { input = "2.3e-5.3", output = nil },
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
      local memory = {}
      run(code, memory, stack)

      local result = stack[1]
      lu.assertEquals(result, case.output)
    end
  end
end

function Test:testVariableExpression()
  local cases = {
    { input = "k1 = 1; k1 + k1", output = 2 },
    { input = "k0 = 0; k1 = 1; k1 + k0", output = 1 },
    { input = "k1 = 1; k10 = 10; (k1 + k1) * k10", output = 20 },
    { input = "_k2 = -2; _k2", output = -2 },
  }

  for _, case in ipairs(cases) do
    local parsed = parse(case.input)
    local code = compile(parsed)

    local stack = {}
    local memory = {}

    run(code, memory, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end

function Test:testStatementSequenceBlock()
  local cases = {
    { input = "result = 3", result = 3 },
    { input = "{ result = 5 }", result = 5 },
    { input = "{ result = 6; result2 = 7; }", result = 6, result2 = 7 },
    { input = "{ result = 9;; }", result = 9 },
    { input = "{ result = 9;   ; }", result = 9 },
  }

  for _, case in ipairs(cases) do
    local parsed = parse(case.input)
    local code = compile(parsed)

    local stack = {}
    local memory = {}

    run(code, memory, stack)

    lu.assertEquals(memory[1], case.result)
    if case.result2 then
      lu.assertEquals(memory[2], case.result2)
    end
  end
end

function Test:testReturn()
  local cases = {
    { input = "return 3", output = 3 },
    { input = "x = 3; return x", output = 3 },
    { input = "a = 2; return a + 3", output = 5 },
    { input = "returned = 4; return returned", output = 4 },
  }

  for _, case in ipairs(cases) do
    local parsed = parse(case.input)
    local code = compile(parsed)

    local stack = {}
    local memory = {
      k0 = 0,
      k1 = 1,
      _k2 = -2,
      k10 = 10,
    }

    run(code, memory, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end

function Test:testPrint()
  -- TODO: How to capture print statement in Luaunit?
  local cases = {
    { input = "@ 3" },
    { input = "@ 4 + 4" },
    { input = "x = 2; @ x + 4" },
    { input = "x = 2; @ x + 4; y = 8 + x; @ y" },
  }

  for _, case in ipairs(cases) do
    local parsed = parse(case.input)
    local code = compile(parsed)

    local stack = {}
    local memory = {}

    run(code, memory, stack)
    lu.assertEquals(true, true)
  end
end

function Test:testUndefinedVariables()
  local cases = {
    { input = "return x" },
  }

  for _, case in ipairs(cases) do
    local parsed = parse(case.input)

    local helper = function()
      compile(parsed)
    end

    lu.assertErrorMsgContains("undefined variable x", helper)
  end
end

function Test:testSyntaxErrorPrint()
  -- TODO: How to capture print statement in Luaunit?
  local cases = {
    { input = [[
      a = 3;
      a x x x b
    ]] },
    { input = [[
      a = 3;

      a x x x b
    ]]},
    { input = [[
      a = 3;
      return return
    ]]},
  }

  for _, case in ipairs(cases) do
    DEBUG = true
    local parsed = parse(case.input)
    DEBUG = false

    lu.assertEquals(true, true)
  end
end

function Test:testCommentsBlockComments()
  local cases = {
    { input = [[
      a = 1; # hello world;
      a + 2
    ]], output = 3 },
    { input = [[
      a = 1; # hello world
      a + 2
    ]], output = 3 },
    { input = [[
      return 2 #{ hello world #};
    ]], output = 2 },
    { input = [[
      return 2; #{ hello world #}
    ]], output = 2 },
    { input = [[
     #{ hello world #} return 2;
    ]], output = 2 },
    { input = [[
     #{ #} return 2;
    ]], output = 2 },
    { input = [[
     #{#} return 2;
    ]], output = 2 },
    { input = [[
     #{##} return 2;
    ]], output = 2 },
    { input = [[
     #{#{#} return 2;
    ]], output = 2 },
    { input = [[
      a = 1;
      #{ hello world #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello
      world #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello
      world
      #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello world #} #{ foo bar #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello world #} y = 2; #{ foo bar #}
      a + y
    ]], output = 3 },
    { input = [[
      a = 1;
      #{ hello world #}
      #{ foo bar #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello world; a = 2 #}
      a + 4
    ]], output = 5 },
    { input = [[
      a = 1;
      #{ hello world #}
      return a;
    ]], output = 1 },
    { input = [[
      a = 1;
      return a #{ hello world #};
    ]], output = 1 },
    { input = [[
      a = 1;
      #{ hello world #} return a;
    ]], output = 1 },
    { input = [[
      a = 1;
      #{ hello world #} b = 10;
      a + b
    ]], output = 11 },
    { input = [[
      a = 1;
      #{ hello world #} b = 1 #{ foo bar #};
      a + b
    ]], output = 2 },
  }

  for _, case in ipairs(cases) do
    local parsed = parse(case.input)
    local code = compile(parsed)

    local stack = {}
    local memory = {}

    run(code, memory, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end

function Test:testNotExpression()
  local cases = {
    { input = "!0", output = 1 },
    { input = "!!0", output = 0 },
    { input = "k1 = 1; !k1", output = 0 },
    { input = "k1 = 0; !k1", output = 1 },
    { input = "k1 = 0; !!k1", output = 0 },
    { input = "k1 = 0; !!!k1", output = 1 },
  }

  for _, case in ipairs(cases) do
    local parsed = parse(case.input)
    local code = compile(parsed)

    local stack = {}
    local memory = {}

    run(code, memory, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end
------------------ TEST -------------------

-- Uncomment to get print statement
-- DEBUG = true

-- Uncomment to run test
TEST = true

if TEST then
  lu.run()
end
