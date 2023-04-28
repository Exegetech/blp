local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testLogical()
  local cases = {
    { input = [[
      return 4 and 5;
    ]], output = 5 },
    { input = [[
      return 0 and 3;
    ]], output = 0 },
    { input = [[
      return 0 or 10;
    ]], output = 10 },
    { input = [[
      return 2 or 3;
    ]], output = 2 },
  }

  for _, case in ipairs(cases) do
    local input = "function main() {" .. case.input .. "}"
    local parsed = parser.parse(input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end
