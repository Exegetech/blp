# Exercises Ch 5
## 5.1

Because `t.sunday` 

This is how it evaluates

```
t = {
  sunday = "monday",
  ["monday"] = "sunday"
}

t.sunday -> "monday"
t[sunday] -> t["monday"] -> "sunday"
t[t.sunday] -> t["monday"] -> "sunday"
```

It will print

```sh
monday
sunday
sunday
```

## 5.2

It will be the address of the table itself. The even position a is different because it is just a key for the table a.

The value of `a.a.a.a` will be stack traceback

## 5.3

```lua
escape = {
  ['\t'] = "TAB",
  ['\n'] = "NEWLINE"
}
```

## 5.4

```lua
function polynomial (x, coefficients)
  local sum = 0

  for k, v in ipairs(coefficients) do
    sum = sum + x^v
  end

  return sum
end 
```

## 5.5

```lua
function polynomial (x, coefficients)
  local sum = 0

  for k, v in ipairs(coefficients) do
    local curr = x
    for i = 1, v do
      curr = curr * x
    end

    sum = sum + curr
  end

  return sum
end 
```

## 5.6

```lua
function is_valid_sequence(seq)
  local i = 1

  for k, v in pairs(tbl) do
    if k ~= i then
      return false
    end
    
    i = i + 1
  end

  return true
end
```

## 5.7

```lua
function insert_list(list1, list2, index)
  for i = 1, #list1 do
    table.insert(list2, index + i - 1, list1[i])
  end
end
```

## 5.8

```lua
function concat(list)
  local str = ""
  for k, v in pairs(list) do
    str = str .. v
  end

  return str
end
```







