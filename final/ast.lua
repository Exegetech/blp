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

local function findLocal(state, name)
  local loc = state.locals
  for i = #loc, 1, -1 do
    if name == loc[i] then
      return i
    end
  end

  local params = state.params
  for i = 1, #params do
    if name == params[i] then
      return -(#params - i)
    end
  end

  return nil
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

-- for recursion calling
-- between codeExp
-- and codeCall
local codeExp

local function codeCall(state, ast)
  local func = state.funcs[ast.fname]
  if not func then
    error("undefined function " .. ast.fname)
  end

  local args = ast.args

  if #func.params ~= #args then
    error("wrong number of arguments to " .. ast.fname)
  end

  for i = 1, #args do
    codeExp(state, args[i])
  end

  addCode(state, "call")
  addCode(state, func.code)
end

codeExp = function(state, ast)
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
    local idx = findLocal(state, ast.val)
    if idx then
      addCode(state, "loadLocal")
      addCode(state, idx)
    else
      addCode(state, "load")
      number = loadVar2Num(state, ast.val)
      addCode(state, number)
    end
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
    codeExp(state, ast.exp)

    local idx = findLocal(state, lhs.val)
    if idx then
      addCode(state, "storeLocal")
      addCode(state, idx)
    else
      if state.funcs[lhs.val] then
        error("cannot have global variable with the same name as a function")
      end

      addCode(state, "store")

      local number = storeVar2Num(state, lhs.val)
      addCode(state, number)
    end
  elseif lhs.tag == "indexed" then
    codeExp(state, lhs.array)
    codeExp(state, lhs.index)
    codeExp(state, ast.exp)
    addCode(state, "setarray")
  else
    error("unknown tag")
  end
end

-- for recursion calling
-- between codeBlock
-- and codeStatement
local codeStatement

local function codeBlock(state, ast)
  local oldLevel = #state.locals
  codeStatement(state, ast.body)

  local diff = #state.locals - oldLevel
  if diff > 0 then
    for i = 1, diff do
      table.remove(state.locals)
    end

    addCode(state, "pop")
    addCode(state, diff)
  end
end

codeStatement = function(state, ast)
  if ast.tag == "sequence" then
    codeStatement(state, ast.st1)
    codeStatement(state, ast.st2)
  elseif ast.tag == "call" then
    codeCall(state, ast)
    addCode(state, "pop")
    addCode(state, "1")
  elseif ast.tag == "local" then
    -- print(util.pt(state.locals))

    -- if state.locals[#state.locals] == ast.name then
    -- end

    -- for i = #state.locals, 1, -1 do
    --   if state.locals[i] == ast.name then
    --     error("already have variable declared")
    --   end
    -- end

    codeExp(state, ast.init)
    state.locals[#state.locals + 1] = ast.name
  elseif ast.tag == "block" then
    codeBlock(state, ast)
  elseif ast.tag == "assignment" then
    codeAssignment(state, ast)
  elseif ast.tag == "return" then
    codeExp(state, ast.exp)
    addCode(state, "return")
    addCode(state, #state.locals + #state.params)
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
  if ast.body == nil then
    -- is a function forward declaration
    local code = {}

    if ast.name == "main" and #ast.params > 0 then
      error("main function cannot have parameters")
    end

    state.funcs[ast.name] = {
      code = code,
      params = ast.params,
    }

    state.code = code
    state.params = ast.params
  else
    -- is a function declaration
    local funcData = state.funcs[ast.name]
    if funcData ~= nil then
      if #(funcData.code) > 0 then
        error("already has function with name " .. ast.name)
      else
        state.code = funcData.code
        codeStatement(state, ast.body)

        addCode(state, "push")
        addCode(state, 0)
        addCode(state, "return")
        addCode(state, #state.locals)
      end
    end

    local code = {}

    if ast.name == "main" and #ast.params > 0 then
      error("main function cannot have parameters")
    end

    state.funcs[ast.name] = {
      code = code,
      params = ast.params,
    }

    state.code = code
    state.params = ast.params

    codeStatement(state, ast.body)

    -- All functions return 0
    addCode(state, "push")
    addCode(state, 0)
    addCode(state, "return")
    addCode(state, #state.locals + #state.params)
  end
end

local function compile(ast)
  local state = {
    funcs = {},
    variables = {},
    numOfVariables = 0,
    locals = {},
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
