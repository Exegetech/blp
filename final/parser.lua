local lpeg = require("lpeg")
local util = require("util")

local numNode = util.createNode("number", "val")
local hexNode = util.createNode("hex", "val")
local varNode = util.createNode("variable", "val")
local assignmentNode = util.createNode("assignment", "lhs", "exp")
local returnNode = util.createNode("return", "exp")
local printNode = util.createNode("print", "exp")
local negNode = util.createNode("not", "exp")
local whileNode = util.createNode("while1", "cond", "body")
local indexedNode = util.createNode("indexed", "array", "index")
local funcNode = util.createNode("function", "name", "params", "body")
local callNode = util.createNode("call", "fname", "args")
local blockNode = util.createNode("block", "body")

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

local function foldIfNode(...)
  local args = table.pack(...)
  local base = {
    tag = "if1",
    cond = args[1],
    th = args[2]
  }

  local i = 3
  local curr = base
  while i < #args do
    curr.el = {
      tag = "if1",
      cond = args[i],
      th = args[i + 1],
    }

    curr = curr.el
    i = i + 2
  end

  -- handle last else
  curr.el = args[i]

  return base
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

local function foldLogicalBinary(list)
  local tree = list[1]
  for i = 2, #list, 2 do
    local op = list[i]:gsub("%s+", "")
    tree = {
      tag = "logicalop",
      e1  = tree,
      op  = op,
      e2  = list[i + 1],
    }
  end

  return tree
end

local function foldIndex(list)
  local tree = list[1]
  for i = 2, #list do
    tree = {
      tag = "indexed",
      array = tree,
      index = list[i]
    }
  end

  return tree
end

local function foldNew(list)
  local tree = {
    tag = "new",
    size = {},
    dimensions = numNode(#list)
  }

  table.insert(tree.size, list[#list])

  for i = #list - 1, 1, -1 do
    table.insert(tree.size, list[i])
  end

  return tree
end

local function localVarNode(name, init)
  if init == nil then
    return {
      tag = "local",
      name = name,
      init = {
        tag = 'number';
        val = 0;
      };
    }
  end

  return {
    tag = "local",
    name = name,
    init = init,
  }
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
  "function",
  "elseif",
  "return",
  "while",
  "else",
  "new",
  "and",
  "var",
  "if",
  "or",
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

local andOp       = Rw("and")
local orOp        = Rw("or")
local logicalOp   = C(andOp + orOp) * space

-- Original implementation
-- local ID = (C(alphaunderscore * alphanum^0) - excluded)  * space

-- Alternative implementation
local ID = V("ID")
local var = ID / varNode

local lhs  = V("lhs")
local call = V("call")
local exp0 = V("exp0")
local exp1 = V("exp1")
local exp2 = V("exp2")
local exp3 = V("exp3")
local exp4 = V("exp4")
local exp5 = V("exp5")
local exp6 = V("exp6")
local expTop = V("expTop")
local statementOrExp    = V("statementOrExp")
local statementsOrExps  = V("statementsOrExps")
local assignStat  = V("assignStat")
local returnStat  = V("returnStat")
local printStat   = V("printStat")
local ifStat      = V("ifStat")
local whileStat   = V("whileStat")
local callStat    = V("callStat")
local block = V("block")
local funcDec = V("funcDec")
local localVar = V("localVar")
local params = V("params")
local args = V("args")

local g = P({"program",
  program           = space * Ct(funcDec^1) * -P(1),

  funcDec           = Rw("function") * ID * T("(") * params * T(")") * (block + T(";")) / funcNode,

  params            = Ct((ID * (T(",") * ID)^0)^-1),

  statementsOrExps  = statementOrExp * ((T(";") * statementsOrExps) + T(";"))^-1 / sequenceNode,

  block             = T("{") * statementsOrExps * T(";")^-1 * T("}") / blockNode,

  statementOrExp    = block
                    + localVar
                    + ifStat
                    + whileStat
                    + callStat
                    + assignStat
                    + returnStat
                    + printStat
                    + expTop,

  localVar          = Rw("var") * ID * (T("=") * expTop)^-1 / localVarNode,

  ifStat            = Rw("if") * expTop * block
                    * (Rw("elseif") * expTop * block)^0
                    * (Rw("else") * block)^-1
                    / foldIfNode,

  whileStat         = Rw("while") * expTop * block / whileNode,

  callStat          = call,

  assignStat        = lhs * T("=") * expTop / assignmentNode,

  returnStat        = Rw("return") * expTop / returnNode,

  printStat         = printOp * expTop / printNode,

  expTop            = exp6,

  exp6              = space * (Ct(exp5 * (logicalOp * exp5)^0) / foldLogicalBinary),
  
  exp5              = space * (Ct(exp4 * (compOp * exp4)^0) / foldBinary),

  exp4              = (negOp * exp4 / negNode)
                    + exp3,

  exp3              = space * (Ct(exp2 * (addSubOp * exp2)^0) / foldBinary),

  exp2              = space * (Ct(exp1 * (mulDivModOp * exp1)^0) / foldBinary),

  exp1              = space * (Ct(exp0 * (expOp * exp0)^0) / foldBinary),

  exp0              = Ct(Rw("new") * (T("[") * expTop * T("]"))^0) / foldNew
                    + numeral
                    + (T("(") * expTop * T(")"))
                    + call
                    + lhs,


  lhs               = Ct(var * (T("[") * expTop * T("]"))^0) / foldIndex
                    + var,

  call              = ID * T("(") * args * T(")") / callNode,

  args              = Ct((expTop * (T(",") * expTop)^0)^-1),

  space             = (blockComment + S("\r\n\t ") + comment)^0
                    * P(function(match, position)
                        local newlineCount = util.countNewLine(match)
                        maxnewline = newlineCount + 1

                        maxmatch = math.max(maxmatch, position)
                        return true
                      end),

  ID                 = C(Cmt(
                        alphaunderscore * alphanum^0,
                        function(str, pos, match)
                          if excluded:match(match) ~= nil then
                            return false
                          else
                            return pos
                          end
                        end))
                      * space

})


local function syntaxError(input, maxmatch, maxnewline)
  io.stderr:write("syntax error on line ", maxnewline, "\n")
  local before = string.sub(input, maxmatch - 10, maxmatch, - 1)
  local after = string.sub(input, maxmatch, maxmatch + 11)
  io.stderr:write(before, "|", after, "\n")
end

local function parse(input, debug, exitOnError)
  local result = g:match(input)
  
  if debug then
    if not result then
      syntaxError(input, maxmatch, maxnewline)
      if exitOnError then
        os.exit(1)
      end
    end
  end

  return result
end

return {
  parse = parse,
}
