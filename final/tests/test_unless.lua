local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testIf()
  local cases = {
    { input = [[
      a = 0;
      unless a { b = 5; };
      return b;
    ]], output = 5 },
  }

  for _, case in ipairs(cases) do
    local input = "function main() {" .. case.input .. "}"
    local parsed = parser.parse(input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack, false, 0)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end
