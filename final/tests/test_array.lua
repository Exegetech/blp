local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")
local util = require("../util")

Test = {}

function Test:testArray()
  local cases = {
    { input = [[
      a = new[10];
      a[10] = 23;
      return a[10];
    ]], output = 23 },
    { input = [[
      a = new[5][2];
      a[5][2] = 23;
      return a[5][2];
    ]], output = 23 },
    { input = [[
      a = new[10];
      b = new[5];
      a[10] = b;
      a[10][5] = 3;
      return a[10][5];
    ]], output = 3 },
    -- { input = [[
    --   a = new[3];
    --   b = 10;
    --   a[1] = 5;
    --   a[2] = 6;
    --   a[3] = 7;
    --   @ a;
    --   @ b;
    --   return 0;
    -- ]], output = 0 },
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
