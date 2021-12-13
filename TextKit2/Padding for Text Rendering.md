## Add padding to text

Control margins and paddings is essential for text rendering on iPhone or iPad as we don't want text is to close to the edges of the device.

But I couldn't found any clew about how to set a proper margin or padding after went through many TextKit related documents. The words I got related most is

> Line fragment padding is not designed to express text margins. Instead, you should use insets on your text view, adjust the paragraph margin attributes, or change the position of the text view within its superview.

Also, in the example project of the 2021 WWDC video *Meet TextKit 2*, TextKit team used a property of CALayer to control padding:

```swift
class TextLayoutFragmentLayer: CALayer {
  ...
  func updateGeometry() {
    ...
    position = layoutFragment.layoutFragmentFrame.origin
    position.x += padding
  }
  ...
  init(layoutFragment: NSTextLayoutFragment, padding: CGFloat, showFrames: Bool) {
    self.layoutFragment = layoutFragment
    self.padding = padding
    showLayerFrames = showFrames
    super.init()
    contentsScale = 2
    updateGeometry()
    setNeedsDisplay()
  }
  ...
}
```

Since I didn't found any better solution than the above one, I temporarily adopted it in my app.

The padding is set in the view controller:

```swift
class TextDocumentViewController {
  ...
  override func viewDidLoad() {
    ...
    textDocumentView.padding = 30.0
    ...
   }
  ...
}
```

This padding value is then passed to the TextLayoutFragmentLayer when it is created in textDocumentView:

```swift
let layer = TextLayoutFragmentLayer(layoutFragment: textLayoutFragment,
                                    padding: padding,
                                    showFrames: showFrames)
```
