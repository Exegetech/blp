local util = require("./util")

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

local function currentPosition(state)
  return #state.code
end

local function codeJumpForward(state, op)
  addCode(state, op)
  addCode(state, 0)
  return currentPosition(state)
end

local function codeJumpBackward(state, op, label)
  addCode(state, op)
  addCode(state, label)
end

local function fixJump2Here(state, loc)
  -- relative jump
  -- state.code[loc] = currentPosition(state) - loc
  -- absolute jump
  state.code[loc] = currentPosition(state)
end

local function codeCall(state, ast)
  local func = state.funcs[ast.fname]
  if not func then
    error("undefined function " .. ast.fname)
  end

  addCode(state, "call")
  addCode(state, func.code)
end

local function codeExp(state, ast)
  if ast.tag == "number" or ast.tag == "hex" then
    addCode(state, "push")
    addCode(state, ast.val)
  elseif ast.tag == "call" then
    codeCall(state, ast)
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
  elseif ast.tag == "logicalop" then
    if ast.op == "and" then
      codeExp(state, ast.e1)
      local jump = codeJumpForward(state, "jumpZP")
      codeExp(state, ast.e2)
      fixJump2Here(state, jump)
    elseif ast.op == "or" then
      codeExp(state, ast.e1)
      local jump = codeJumpForward(state, "jumpNZP")
      codeExp(state, ast.e2)
      fixJump2Here(state, jump)
    end
  elseif ast.tag == "indexed" then
    codeExp(state, ast.array)
    codeExp(state, ast.index)
    addCode(state, "getarray")
  elseif ast.tag == "new" then
    for i = 1, #ast.size do
      codeExp(state, ast.size[i])
    end

    codeExp(state, ast.dimensions)
    addCode(state, "newarray")
  else
    error("invalid tree")
  end
end

local function codeAssignment(state, ast)
  local lhs = ast.lhs
  if lhs.tag == "variable" then
    if state.funcs[lhs.val] then
      error("cannot have global variable with the same name as a function")
    end

    codeExp(state, ast.exp)
    addCode(state, "store")

    local number = storeVar2Num(state, lhs.val)
    addCode(state, number)
  elseif lhs.tag == "indexed" then
    codeExp(state, lhs.array)
    codeExp(state, lhs.index)
    codeExp(state, ast.exp)
    addCode(state, "setarray")
  else
    error("unknown tag")
  end
end

local function codeBlock(state, ast)
  codeStatement(ast.body)
end

local function codeStatement(state, ast)
  if ast.tag == "sequence" then
    codeStatement(state, ast.st1)
    codeStatement(state, ast.st2)
  elseif ast.tag == "call" then
    codeCall(state, ast)
    addCode(state, "pop")
    addCode(state, "1")
  elseif ast.tag == "block" then
    codeBlock(state, ast)
  elseif ast.tag == "assignment" then
    codeAssignment(state, ast)
  elseif ast.tag == "return" then
    codeExp(state, ast.exp)
    addCode(state, "return")
  elseif ast.tag == "print" then
    codeExp(state, ast.exp)
    addCode(state, "print")
  elseif ast.tag == "if1" then
    codeExp(state, ast.cond)
    local jump = codeJumpForward(state, "jumpZ")
    codeStatement(state, ast.th)

    if ast.el == nil then
      fixJump2Here(state, jump)
    else
      local jump2 = codeJumpForward(state, "jump")
      fixJump2Here(state, jump)
      codeStatement(state, ast.el)
      fixJump2Here(state, jump2)
    end
  elseif ast.tag == "while1" then
    local initLabel = currentPosition(state) 
    codeExp(state, ast.cond)
    local jump = codeJumpForward(state, "jumpZ")
    codeStatement(state, ast.body)
    codeJumpBackward(state, "jump", initLabel)
    fixJump2Here(state, jump)
  else
    codeExp(state, ast)
  end
end

local function codeFunction(state, ast)
  local func = state.funcs[ast.name]
  if type(func) == "table" then
    error("already has function with name " .. ast.name)
  end

  local code = {}
  state.funcs[ast.name] = {
    code = code,
  }

  state.code = code

  codeStatement(state, ast.body)

  -- All functions return 0
  addCode(state, "push")
  addCode(state, 0)
  addCode(state, "return")
end

local function compile(ast)
  local state = {
    funcs = {},
    variables = {},
    numOfVariables = 0
  }

  for i = 1, #ast do
    codeFunction(state, ast[i])
  end

  local main = state.funcs["main"]
  if not main then
    error("no function main")
  end

  return main.code
end

return {
  compile = compile
}
