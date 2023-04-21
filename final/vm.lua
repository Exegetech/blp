local util = require("util")

local function run(code, memory, stack, debug)
  if debug then
    print("----------------")
  end

  local pc = 1
  local top = 0

  while true do

    if debug  then
      io.write("stack --> ")
      for i = 1, top do
        io.write(tostring(stack[i]), " ")
      end

      io.write("\n")
    end

    if code[pc] == "return" then
      return
    elseif code[pc] == "print" then
      if debug then
        io.write("print ", stack[top])
      end
      print(stack[top])
    elseif code[pc] == "not" then
      if debug then
        io.write("not ", stack[top])
      end

      stack[top] = util.negate(stack[top])
    elseif code[pc] == "push" then
      pc = pc + 1
      top = top + 1

      if debug then
        io.write("push ", code[pc])
      end

      stack[top] = code[pc]
    elseif code[pc] == "add" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("add ", a, b)
      end

      stack[top - 1] = a + b
      top = top - 1
    elseif code[pc] == "sub" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("sub ", a, b)
      end

      stack[top - 1] = a - b
      top = top - 1
    elseif code[pc] == "mul" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("mul ", a, b)
      end

      stack[top - 1] = a * b
      top = top - 1
    elseif code[pc] == "div" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        print("div ", a, b)
      end

      stack[top - 1] = a / b
      top = top - 1
    elseif code[pc] == "exp" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("exp ", a, b)
      end

      stack[top - 1] = a^b
      top = top - 1
    elseif code[pc] == "mod" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("mod ", a, b)
      end

      stack[top - 1] = a % b
      top = top - 1
    elseif code[pc] == "lt" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("lt ", a, b)
      end

      stack[top - 1] = a < b and 1 or 0 
      top = top - 1
    elseif code[pc] == "gt" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("gt ", a, b)
      end

      stack[top - 1] = a > b and 1 or 0 
      top = top - 1
    elseif code[pc] == "lte" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("lte ", a, b)
      end

      stack[top - 1] = a <= b and 1 or 0 
      top = top - 1
    elseif code[pc] == "gte" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("gte ", a, b)
      end

      stack[top - 1] = a >= b and 1 or 0 
      top = top - 1
    elseif code[pc] == "neq" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("neq ", a, b)
      end

      stack[top - 1] = a ~= b and 1 or 0 
      top = top - 1
    elseif code[pc] == "eq" then
      a = stack[top - 1]
      b = stack[top]

      if debug then
        io.write("neq ", a, b)
      end

      stack[top - 1] = a == b and 1 or 0 
      top = top - 1
    elseif code[pc] == "load" then
      pc = pc + 1
      local id = code[pc]
      top = top + 1
      stack[top] = memory[id]

      if debug then
        io.write("load ", stack[top], " from ", id)
      end
    elseif code[pc] == "store" then
      pc = pc + 1
      local id = code[pc]
      memory[id] = stack[top]

      if debug then
        io.write("store ", stack[top], " to ", id)
      end

      top = top - 1
    elseif code[pc] == "jump" then
      pc = pc + 1
      -- relative jump
      -- pc = pc + code[pc]
      -- absolute jump
      pc = code[pc]
    elseif code[pc] == "jumpZ" then
      pc = pc + 1

      if stack[top] == 0 or stack[top] == nil then
        -- relative jump
        -- pc = pc + code[pc]
        -- absolute jump
        pc = code[pc]
      end

      top = top - 1
    elseif code[pc] == "jumpZP" then
      pc = pc + 1

      if stack[top] == 0 or stack[top] == nil then
        -- relative jump
        -- pc = pc + code[pc]
        -- absolute jump
        pc = code[pc]
      else
        top = top - 1
      end
    elseif code[pc] == "jumpNZP" then
      pc = pc + 1

      if not (stack[top] == 0 or stack[top] == nil) then
        -- relative jump
        -- pc = pc + code[pc]
        -- absolute jump
        pc = code[pc]
      else
        top = top - 1
      end
    else
      error("unknown instruction")
    end

    if debug then
      io.write("\n")
    end

    pc = pc + 1
  end
end

return {
  run = run
}
