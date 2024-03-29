My app implemented the TextKit 2 layout mechanism soon after WWDC 2021, when Apple introduced it. The reason I adopt TextKit 2 is that it supports the high performance of long text scrolling, as the Apple team states: "TextKit 2 is extremely fast for an incredibly wide range of scenarios, from quickly rendering labels that are only a few lines each to laying out documents that are hundreds of megabytes being scrolled through at interactive rates. " I suppose that scrolling around the whole document had become the nature of e-reading after the mobile internet era. Probably, long text scrolling would provide the user with a better experience. But, back in 2021, Apple still needed to complete their migration to TextKit 2, so there was no TextKit 2 support on UITextView. 

Before WWDC 2022, my App worked fine based on the raw TextKit 2 components. When I say raw TextKit 2, I mean that we programmatically control the text layout process by NSTextLayoutManager, NSTextContentStorage, NSTextContainer, and a general UIScrollView with its controller. That solution was demonstrated in the **Meet TextKit 2** session of WWDC 2021. However, it couldn't benefit from the integrated Swift text components, such as highlighting text and the action menu functions on the UITextView. So, after about two years of waiting, I kicked off the transition from raw TextKit 2 to UITextView.

Compared with the raw TextKit 2 layout, rendering text on UITextView is much easier. However, free meals do not always taste great. The trade-off of implementing UITextView is that you must hand over the full-text rendering control to this view. One very important rendering control for a reading app like mine is scrollRangeToVisible.

# Jump to any location in the document

My solution without UITextView allows me to smoothly scroll the view to any location in huge documents, though the control is very complicated. However, on the TextKit 2 enabled UITextView side, the scrollRangeToVisible(_range: NSRange) function on iOS 16 was unreliable. It not only scrolls to some wrong locations but can also scroll to some random places in a blank background, which absolutely leads to user frustration. So, I had to spend a few weeks experimenting with the mechanism behind the scrollRangeToVisible function and redesign my app to cooperate with it to ensure a smooth user experience.

During the transition, iOS 17 was just released. I didn't test whether the scrollRangeToVisible is working well on iOS 17. However, as I want to provide the best user experience to my users, I decided to implement the transition based on iOS 16 instead of iOS 17. That means I must solve the scrollRangeToVisible problem.

There were some Q&As on the web about the problem of the scrollRangeToVisible in TextKit 2. They said the same thing: the function won't behave well if the text around the target range has been laid out before the scrolling. Therefore, I tried a walk around **forcing** the UITextView to lay the text from the document start location to the target range, which I call jump distance, before calling scrollRangeToVisible. And it works!

```swift
private func preLayoutParagraphs(location: Int, numberOfSamples: Int) {
    let paragraphRanges = sampleParagraphRanges(location: location, numberOfSamples: numberOfSamples)
    for range in paragraphRanges {
        preLayoutParagraph(range)
    }
}

private func sampleParagraphRanges(location: Int, numberOfSamples: Int) -> [NSRange] {

    let paceRange = 1000...10000

    /// when the target location is less 1000 characters away from the current location,
    /// give up the pre layout process
    guard location > pageRange.lowerBound else { return [] }

    /// calculate the pace for sampling
    var pace = location / numberOfSamples

    /// fetch sample ranges based on the pace just calculated
    var ranges = [NSRange]()
    if pace < paceRange.lowerBound {
        /// only take one sample, which is the target location
        if let paragraphRange = paragraphRangeForLocation(location) {
            range.append(paragraphRange)
        }
    } else {
        /// adjust pace if necessary
        if pace > paceRange.upperBound {
            pace = paceRange.uppperBound
        }

        /// sampling
        var sampleLocation = 0
        while sampleLocation <= location {
            if let paragraphRange = paragraphRangeForLocation(sampleLocation) {
                ranges.append(paragraphRange)
            }
            sampleLocation += pace
        }

        /// add the target location to the sample list if necessary
        if sampleLocation - pace != location && abs(location - sampleLocation) > paceRange.lowerBound / 10 {
            if let paragraphRange = paragraphRangeForLocation(sampleLocation) {
                ranges.append(paragraphRange)
            }
        }
    }
    return ranges
}

/**
 * force the UITextView to layout the paragraph for the given NSRange
 */
private func preLayoutParagraph(_ paragraphRange: NSRange) {
    
    guard let paragraphTextRange = textView.textRangeFromNSRange(paragraphRange)
    else { return }
    
    textView.textLayoutManager!.enumerateTextSegments(in: paragraphTextRange, type: .highlight,
                                                      options: []) {(segmentTextRange, segmentFragmentFrame,
                                                                     baselinePosition, textContainer) in
        return true
    }
}
    
private func jumpToLocation(_ targetLocation: Int) {
    guard textView.textStorage.wholeRange.contains(targetLocation) else { return }

    preLayoutParagraphs(location: targetLocation, numberOfSamples: 10)

    let visibleLength = min(minPageLength, textView.textStorage.length - location)
    textView.scrollRangeToVisible(NSRange(location: location, length: visibleLength))
}    
            
```

paragraphRangeForLocation(_ location: Int) is an utility function that fetch paragraph range collected during textContentStorage creates NStextParagraph object.

# Don't touch the text on the fly -- process first, reset after update

After you assign any text to the UITextView, you’d better not touch it or not touch it at least when the view is scrolling, especially in iOS 16. Otherwise, you may experience some “turbulences” - the scroll will move to any place unexpectedly. It may caused by the inconsistency between the re-layout and the auto-scrolling for re-layout. 

Therefore, I update any text for styling before I attach it to the UITextView. Again, I wish the UITextView offers more powerful compatibility for updating text on the fly. Why do I wish so? Because in my RAW TextKit 2 solution, I did achieve that. It's a pity to give up the smooth update text on-the-fly compatibility, which leads better user experience.

In the transition, the most impacted function in my app is font change. When a user initiates a font change, which updates font name or size, I need to process the text on display for the change first, then assign the updated text to the UITextView. The full solution is like this:

1. Update the last reading location.
2. Make a mutable copy of the text content on the display.
3. Update fonts in the mutable copy based on the user's request.
4. Set the content offset of the UITextView to (0, 0). *this step is quite important. It must be done before the jump.*
5. Assign the updated mutable attributed string to the UITextView.attributedText.
6. Use the Task.sleep() function to wait for about 0.3 seconds, allowing the re-layout to complete.
7. Jump to the last reading location.
