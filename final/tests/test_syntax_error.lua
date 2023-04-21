local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testSyntaxError()
  -- TODO: How to capture print statement in Luaunit?
  local cases = {
    { input = [[
      a = 3;
      a x x x b
    ]] },
    { input = [[
      a = 3;

      a x x x b
    ]]},
    { input = [[
      a = 3;
      return return
    ]]},
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input, true)

    lu.assertEquals(true, true)
  end
end

