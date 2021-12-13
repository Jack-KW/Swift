## baselineOffset

If there is any text element in an attributed string that needs to be set horizontal aglignment individually. We can add a baselineOffset for that.

from ![without baselineOffset](https://i.stack.imgur.com/86Oe3.png)  to  ![with baselineOffset](https://i.stack.imgur.com/dl3M1.png)

```swift
let cuisine = NSMutableAttributedString(string: "Cuisine")
let asterisk = NSAttributedString(string: "*", attributes: [.baselineOffset: -3])
cuisine.append(asterisk)
```
For some special characters like asterisk, there could be many different version to choose from. For example, we can choose any of ⁎, ∗, ✱, ✲, ❋, ＊ as asterisk.

reference: https://stackoverflow.com/questions/52336075/how-to-add-padding-to-a-nsmutableattributedstring
