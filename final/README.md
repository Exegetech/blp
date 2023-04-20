# Final Project

Sample file structure

```
-- module1.lua
local module1 = {}

function module1.function1(param1, param2)
  -- code for function1
end

function module1.function2(param1, param2)
  -- code for function2
end

return module1

-- module2.lua
local module2 = {}

function module2.function1(param1, param2)
  -- code for function1
end

function module2.function2(param1, param2)
  -- code for function2
end

return module2

-- main.lua
local module1 = require("module1")
local module2 = require("module2")

function main()
  -- code for main function
  local result1 = module1.function1(param1, param2)
  local result2 = module2.function2(param1, param2)
  -- more code for main function
end

main()
```

```

my_project/
├── main.lua
├── module1/
│   ├── module1.lua
│   └── submodule1.lua
├── module2/
│   ├── module2.lua
│   └── submodule2.lua
├── utils/
│   ├── util1.lua
│   └── util2.lua
└── tests/
    ├── test_module1.lua
    └── test_module2.lua
``` 

```
-- main.lua
local module1 = require("module1.module1")  -- require the module1.lua file inside the module1 directory

function main()
  module1.function1()
  module1.function2()
end

main()
```

```
my_project/
├── main.lua
├── module1.lua
├── module2.lua
└── tests/
    ├── test_module1.lua
    └── test_module2.lua
```
