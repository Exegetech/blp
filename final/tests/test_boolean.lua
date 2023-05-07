local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")
local util = require("../util")

Test = {}

function Test:testBoolean()
  local cases = {
    { input = "true", output = 1 },
    { input = "false", output = 0 },
    { input = "!false", output = 1 },
    { input = "!true", output = 0 },
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

