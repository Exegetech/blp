function helper(acc, idx, n) {
  if (idx === n) {
    const array = new Array(
    return;
  }


}

function createNestedArray(numbers) {
  let accumulator = []


  let nestedArray = [];
  let currentArray = nestedArray;

  for (let i = 0; i < numbers.length; i++) {
    // let num = numbers[i];

    // for (let j = 0; j < num; j++) {
    //   if (currentArray[j] === undefined) {
    //     currentArray[j] = [];
    //   }

    //   currentArray = currentArray[j];
    // }

    // currentArray = nestedArray;
  }

  return nestedArray;
}

console.log(createNestedArray([2, 3, 1]))
