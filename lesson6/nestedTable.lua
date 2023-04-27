local pt    = require("pt")

function createNestedTable(numbers)
  local nestedTable = {}
  local currentTable = nestedTable
  
  for i = 1, #numbers do
    local num = numbers[i]
    
    for j = 1, num do
      if j == num then
        currentTable[j] = {}
        currentTable = currentTable[j]
      else
        if not currentTable[j] then
          currentTable[j] = {}
        end
        
        currentTable = currentTable[j]
      end
    end
    
    currentTable = nestedTable
  end
  
  return nestedTable
end

print(pt.pt(createNestedTable({2, 3, 1})))
