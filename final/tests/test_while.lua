local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testWhile()
  local cases = {
    { input = [[
      n = 6;
      r = 1;
      while n {
        r = r * n;
        n = n - 1;
      };
      return r;
    ]], output = 720 },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)
    local code = ast.compile(parsed)

    local stack = {}
    local memory = {}

    vm.run(code, memory, stack)

    local result = stack[1]
    lu.assertEquals(result, case.output)
  end
end

