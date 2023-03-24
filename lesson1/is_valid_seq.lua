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
