local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testNegation()
  local cases = {
    { input = "!0", output = 1 },
    { input = "!!0", output = 0 },
    { input = "k1 = 1; !k1", output = 0 },
    { input = "k1 = 0; !k1", output = 1 },
    { input = "k1 = 0; !!k1", output = 0 },
    { input = "k1 = 0; !!!k1", output = 1 },
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

