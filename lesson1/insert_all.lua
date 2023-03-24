function insert_list(list1, list2, index)
  for i = 1, #list1 do
    table.insert(list2, index + i - 1, list1[i])
  end
end
