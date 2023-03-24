function concat(list)
  local str = ""
  for k, v in pairs(list) do
    str = str .. v
  end

  return str
end

concat({"hello", " ", "world"})
