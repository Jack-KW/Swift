## Sort a dictionary by Int keys
The result is an array of all the items in the given dictionary, which sorted by their Int keys.
```swift
let aDictionary: [Int: Any] = [1: 0, 3: 5, -6: 9, -9: 2]
let arrayOfDictionaryItems = aDictionary.sorted(by: { $0.0 < $1.0 })
print(arrayOfDictionaryItems)
```
printed result
```
[(key: -9, value: 2), (key: -6, value: 9), (key: 1, value: 0), (key: 3, value: 5)]
```
