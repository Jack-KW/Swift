My App implemented TextKit 2 layout mechanism soon after WWDC 2021, when Apple introduced it. The reason I adopt TextKit 2 is that it supports the high performance of long text scrolling, as the Apple team states: "TextKit 2 is extremely fast for an incredibly wide range of scenarios, from quickly rendering labels that are only a few lines each to laying out documents that are hundreds of megabytes being scrolled through at interactive rates. " But, back in 2021, Apple hadn't completed their migration to TextKit 2 yet, which means there was no TextKit 2 support on UITextView. 

Before WWDC 2022, my App worked fine based on the raw TextKit 2 components. When I say raw TextKit 2, I mean that we programmatically control the text layout process by NSTextLayoutManager, NSTextContentStorage, NSTextContainer, and a general UIScrollView with its controller. That solution was demonstrated in the **Meet TextKit 2** session of WWDC 2021. However, it couldn't benefit from the integrated Swift text components, such as highlighting text and the action menu functions on the UITextView. So, after about two years of waiting, I kicked off the transition from raw TextKit 2 to UITextView.

Compared with the raw TextKit 2 layout, rendering text on UITextView is much easier. However, free meals do not always taste great. The trade-off of implementing UITextView is that you must hand over the full text rendering control to this view. One very important rendering control for a reading App like mine is scrollRangeToVisible.

My solution without UITextView allows me to smoothly scroll the view to any location in huge documents, though the control is very complicated. However, the scrollRangeToVisible on iOS 16 was un-reliable. It not only scrolls to some wrong locations but can also scroll to some random places in a blank background. So, I had to spend a few weeks on experimenting with the mechanism behind scrollRangeToVisible and designing my App to cooperate with it to ensure a smooth user experience.

During the transition, iOS 17 was just released. I didn't test whether the scrollRangeToVisible is working well on iOS 17. However, as I want to provide the best user experience to my users, I decided to implement the transition based on iOS 16.

There were some Q&As on the web about the problem of the scrollRangeToVisible in TextKit 2. They said the same thing: the function won't behave well if the text around the target range has been laid out before the scrolling. Therefore, I tried a walk around forcing the UITextView to lay the text from the document start location to the target range before calling scrollRangeToVisible. And it works!

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

paragraphRangeForLocation(_ location: Int) is an utility function that fetch paragraph range collected during textContentStorage create NStextParagraph object.
