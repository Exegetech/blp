# Exercises Ch. 1
## 1.1 

When I enter a negative number, the program stack overflowed.

```lua
function fact (n)
  if n < -1 then
    return 0
  elseif n == 0 then
    return 1
  else
    return n * fact(n - 1)
  end
end
```

## 1.2

I like both

## 1.3

Other languages that use `--` comments:
- SQL
- Ada

## 1.4

The ones that are valid identifiers:
- `___`
- `_end`
- `End`
- `NULL`

## 1.5

The resulting value is `true`. Because `type(nil)` results in `nil`. `nil == nil` results in `true`

## 1.6

You can do something like

```lua
x == true or x == false
```

## 1.7

The parentheses aren't necessary actually, because `not` binds tighter than `and`, and `and` binds tighter than `or`.

However, to make code clearer and to remove ambiguity, it is better to use parentheses.

## 1.8

```lua
print(arg[0])
```








