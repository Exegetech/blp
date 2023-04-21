local lu = require("luaunit")
local parser = require("../parser")
local ast = require("../ast")
local vm = require("../vm")

Test = {}

function Test:testUndefinedVariable()
  local cases = {
    { input = "return x" },
  }

  for _, case in ipairs(cases) do
    local parsed = parser.parse(case.input)

    local helper = function()
      ast.compile(parsed)
    end

    lu.assertErrorMsgContains("undefined variable x", helper)
  end
end
