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

print(polynomial(1, {1, 1}))
