local parser = require("./parser")
local ast = require("./ast")
local vm = require("./vm")

function readFile(filename)
  local file = io.open(filename, "r")
  if not file then
      return nil, "Failed to open file: " .. filename
  end

  local content = file:read("*a")

  file:close()

  return content
end

function execute()
  if #arg < 1 then
      print("Usage: lua selene.lua <filename>")
      return
  end

  local filename = arg[1]
  local content = readFile(filename)

  local parsed = parser.parse(content)
  local code = ast.compile(parsed)

  local stack = {}
  local memory = {}

  vm.run(code, memory, stack, false, 0)

  local result = stack[1]
  print(result)
end

execute()
