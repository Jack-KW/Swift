import SwiftUI

extension NSAttributedString {
  
    var wholeRange: NSRange {
        get { NSRange(location: 0, length: self.length) }
    }
    
    func substringIn(_ range: NSRange) -> String? {
        var text: String?
        if let stringRange = Range(range, in: self.string) {
            text = String(self.string[stringRange])
        }
        return text
    }
    
    func subAttributedStringIn(_ range: NSRange) -> NSAttributedString {
        
        guard !NSEqualRanges(range, self.wholeRange),
              self.wholeRange.containsRange(range)
        else { return self }
        
        let matchString = self.mutableCopy() as! NSMutableAttributedString
        let remainRanges = self.wholeRange.cutBy(range)
        for remainRange in remainRanges.sorted(by: { $0.location > $1.location }) {
            matchString.deleteCharacters(in: remainRange)
        }
        return matchString
    }
    
    func fontsInfoInRange(_ range: NSRange) -> [CPFont: FontHolder] {
        // find all the font attributes and record the number of characters their affect
        var fontsInfo: Dictionary<CPFont, FontHolder> = [CPFont: FontHolder]()
        
        self.enumerateAttribute(.font, in: range,
                                options: .longestEffectiveRangeNotRequired) { (optionalFont, fontRange, nil) in
            
            guard let font = optionalFont as? CPFont else { return }
            
            var fontFound = false
            for storedFont in fontsInfo.keys {
                if font.isEqual(storedFont) {
                    fontsInfo[storedFont]!.appendRange(fontRange)
                    fontFound = true
                    break
                }
            }
            if !fontFound {
                fontsInfo[font] = FontHolder(font: font)
                fontsInfo[font]!.appendRange(fontRange)
            }
        }
        
        return fontsInfo
    }
    
    func paragraphStylesInfoInRange(_ range: NSRange) -> [Int: ParagraphStyleHolder] {
        var paragraphStylesInfo = [Int: ParagraphStyleHolder]()
        var holderID = 0
        
        self.enumerateAttribute(.paragraphStyle, in: range,
                                options: .longestEffectiveRangeNotRequired) { (optionalParagraphStyle, styleRange, nil) in
            
            guard let paragraphStyle = optionalParagraphStyle as? NSParagraphStyle else { return }
            
            var styleFound = false
            for key in paragraphStylesInfo.keys {
                if paragraphStyle.isEqual(paragraphStylesInfo[key]!.paragraphStyle) {
                    paragraphStylesInfo[key]!.appendRange(styleRange)
                    styleFound = true
                    break
                }
            }
            if !styleFound {
                holderID += 1
                paragraphStylesInfo[holderID] = ParagraphStyleHolder(paragraphStyle: paragraphStyle)
                paragraphStylesInfo[holderID]!.appendRange(styleRange)
            }
        }
        return paragraphStylesInfo
    }
    
    func titleTextRangesIn(_ range: NSRange) -> [NSRange] {
        var ranges = [NSRange]()
        
        self.enumerateAttribute(.isTitle, in: range,
                                options: .longestEffectiveRangeNotRequired) { (optionalValue, titleRange, nil) in
            if let value = optionalValue as? NSNumber, value == NSNumber(value: 1) {
                ranges.append(titleRange)
            }
        }
        return ranges
    }
}

extension NSRange {
    
    func cutBy(_ bladeRange: NSRange) -> [NSRange] {
        guard self.containsRange(bladeRange) else { return [] }
        
        var ranges = [NSRange]()
        ranges.append(NSRange(location: self.location,
                              length: bladeRange.location - self.location))
        let endLocation = bladeRange.location + bladeRange.length
        ranges.append(NSRange(location: endLocation,
                              length: self.length - endLocation))
        return ranges
    }
    
    func adjustByOffset(_ offset: Int) -> NSRange? {
        guard self.location + offset >= 0 else { return nil }
        return NSRange(location: self.location + offset, length: self.length)
    }
    
    func containsRange(_ nsRange: NSRange) -> Bool {
        nsRange == NSIntersectionRange(self, nsRange)
    }
    
    /**
     * NSRange is not safe for asynchronization.
     * So, when passing it around in asynchronous computing, we need to convert it to RangeInfo that complies NSSecureCoding and NSCopying protocols
     */
    init(_ rangeInfo: RangeInfo) {
        self.init(location: rangeInfo.location, length: rangeInfo.length)
    }
    
    func simpleDescription() -> String {
        return "{\(self.location), \(self.length)}"
    }
    
    func intersects(_ range: NSRange) -> Bool {
        // Check if the end of the first range is before the start of the second range
        if self.location + self.length <= range.location {
            return false
        }
        
        // Check if the start of the first range is after the end of the second range
        if self.location >= range.location + range.length {
            return false
        }
        
        // If the above conditions are not met, the ranges intersect
        return true
    }
}

public class RangeInfo: NSObject, NSSecureCoding, NSCopying {
    public static var supportsSecureCoding = true
    
    public var location: Int
    public var length: Int
    
    enum RangeInfoKey: String {
        case location = "location"
        case length = "length"
    }
    
    init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }
    
    init(nsRange: NSRange) {
        self.location = nsRange.location
        self.length = nsRange.length
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        let dLocation = aDecoder.decodeInt32(forKey: RangeInfoKey.location.rawValue)
        let dLength = aDecoder.decodeInt32(forKey: RangeInfoKey.length.rawValue)
        
        self.init(location: Int(dLocation), length: Int(dLength))
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(location, forKey: RangeInfoKey.location.rawValue)
        aCoder.encode(length, forKey: RangeInfoKey.length.rawValue)
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return RangeInfo(location: location, length: length)
    }
    
    static func == (lhs: RangeInfo, rhs: RangeInfo) -> Bool {
        return lhs.location == rhs.location && lhs.length == rhs.length
    }
    
    var simpleDescription: String {
        "{\(self.location), \(self.length)}"
    }
}

/**
 * Hold information about font attributes extracted from NSAttributedString.
 * Also calculate effected character number when information are accumulating.
 */
struct FontHolder {
    var font: CPFont
    var ranges: Array<NSRange> = [NSRange]()
    var effectCharacterCounter = 0
    var targetFont: CPFont?
    
    init(font: CPFont) {
        self.font = font
    }
    
    mutating func appendRange(_ range: NSRange) {
        ranges.append(range)
        effectCharacterCounter += range.length
    }
    
    static func popularFontIn(_ fontsInfo: [CPFont: FontHolder]) -> CPFont? {
        var popularFont: CPFont?
        var maxEffectCharacterNumber = 0
        for key in fontsInfo.keys {
            if fontsInfo[key]!.effectCharacterCounter > maxEffectCharacterNumber {
                maxEffectCharacterNumber = fontsInfo[key]!.effectCharacterCounter
                popularFont = key
            }
        }
        return popularFont
    }
}

/**
 * Hold information about paragraphStyles extracted from NSAttrtibutedString
 * Also calculate titleScore and mainContentScore when information are accumulating.
 */
struct ParagraphStyleHolder {
    
    let paragraphStyle: NSParagraphStyle
    var ranges: Array<NSRange> = [NSRange]()
    
    // we want to separate title and other content (main content)
    // therefore, we create two variable to count the weight of whether
    // a text is title or main content
    var titleScore: Double = 0
    var mainContentScore: Double = 0
    
    init(paragraphStyle: NSParagraphStyle) {
        
        self.paragraphStyle = paragraphStyle
        
        // if the current paragraph style with a header level over 0
        // we mark the corresponding text as title by increase the title score
        // by 1
        if let headerLevel = paragraphStyle.value(forKey: "headerLevel") as? Int {
            if headerLevel > 0 { // header level values: 0, 1, 2, 3
                titleScore += 1
            }
        }
        
        switch paragraphStyle.alignment {
        // we mark text with center alignment as title
        case .center:   // value is 1
            titleScore += 1
        // for other paragraph styles we mark the text as main content
        case .justified, .left, .natural, .right: // case-values: left-0; right-2; justified-3; natural-4
            mainContentScore += 1
        default:
            mainContentScore += 1
        }
        
        if paragraphStyle.paragraphSpacing > 0 {
            titleScore += 0.5
        }
        
        if paragraphStyle.firstLineHeadIndent > 0 {
            mainContentScore += 0.5
        }
    }
    
    mutating func appendRange(_ range: NSRange) {
        ranges.append(range)
        mainContentScore += 0.1
        mainContentScore += Double(range.length / 500)
    }
    
    func isTitle() -> Bool {
        return titleScore > mainContentScore
    }
}

extension NSAttributedString.Key {
    
    public static var isTitle: NSAttributedString.Key {
        return NSAttributedString.Key("keepreading.isTitle")
    }
    
}

