# Final Project Report: Selene

This is a final project for "Building a Programming Language" by Roberto Ierusalimschy.

To run this language,

``` 
$ lua selene.lua input.sel
```

## Language Syntax

- Comment
  - Single Line

    ```
    # this is a comment
    ```

  - Multi Line

    ```
    #{ this
    is a
    comment
    #}
    ```

- Primitives
  - Number

    ```
    1     # integer
    -1    # negative integer
    2.5   # float
    -2.5  # negative float
    .5    # float
    5.    # float
    2.3e4 # scientific
    0xFF  # hex
    ```

  - Boolean

    ```
    true  # true
    false # false
    ```

- Variable assignment

  ```
  a = 1
  ```

- Arrays

  ```
  a = new[5];    # one dimensional array
  a[1] = 3; 
  a[2] = 4; 
  a[3] = 5; 
  a[4] = 6; 
  a[5] = 7; 

  b = new[5][2]; # multi dimensional array
  ```

- Arithmetic Operations

  ```
  4 + 5 * 2 ^ 3 / 10 % 2   # 4.0
  ```

- Negation 

  ```
  !true # false
  !false # true
  ```

- Logical Short Circuit Operations

  ```
  4 and 5  # 5
  2 or 3   # 2
  ```

- Comparison

  ```
  1 == 1   # true
  1 != 1   # false
  1 < 2    # true
  1 > 2    # false
  1 <= 2   # true
  1 >= 2   # false

  true == true   # true
  false == false # true
  ```

- Print

  ```
  a = 5;
  @ a;    # print 5
  ```

- If Else
  
  ```
  a = true;
  b = false;

  if 1 + 1 == 2 {

  } else if 2 < 3 {

  } else {

  }
  ```

- While Loop

  ```
  n = 6;
  r = 1;
  while n {
    r = r * n;
    n = n - 1;
  };
  ```

- Unless

  ```
  a = 0;
  unless a {
   b = 5; 
  };
  ```

- Function

  ```
  function foo() {
    return 33
  }

  function main() {
    a = foo();
    return 2 + a
  }
  ```

  ```
  function subtract(x, y) {
    return x - y;
  }

  function main() {
    return subtract(10, 2);
  }
  ```

  ```
  function fact(n) {
    if n {
      return n  * fact(n - 1)
    } else {
      return 1
    }
  }

  function main() {
    return fact(6);
  }
  ```

- Scope

  ```
  function main() {
    { var x = 10;
      var y = 20;
      { var z = 30;
        return x / y + z;
      }
    }
  }
  ```

## New Features/Changes

On top of the exercises, I added two more features:
- Boolean data type

  We can express boolean by writing `true` or `false`

  ```
  a = true
  b = false
  c = !a
  d = !b
  ```

  ```
  if true {
    # do something
  }
  ```

  Underlying it, it is just `1` (for `true`) and `0` for (`false`). So we can actually compare

  ```
  1 == true  # true
  0 == false # false
  ```
  
- Unless

  Unless is like `if` statement, but it executes when it the expression evaluates to `false`. It also doesn't have `else` statement unlike `if` statement.

  ```
  function doSomething(a) {
    a = true;
    b = 2;

    unless a {
     b = 5;
    };

    return b;
  }
  ```

## Future

For this language to be production ready, there are lots of other things that need to be implemented:
- `string` and `null` data type
- Type system
- Module system
- Standard library and data structures

## Self assessment

* Self assessment of your project: for each criteria described on the final project specs, choose a score (1, 2, 3) and explain your reason for the score in 1-2 sentences.

I didn't go beyond the base requirement. This is my first exposure to building a programming language, and I still have knowledge gaps that I need to address first before tackling more advanced features. I am planning to watch the videos again and rebuild this from scratch. 
