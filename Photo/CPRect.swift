
#if os(iOS)
import UIKit
public typealias CPRect = CGRect
#elseif os(OSX)
import Cocoa
public typealias CPRect = NSRect
#endif

extension CPRect {
    
    var simpleDescription: String {
        "{(x: \(self.origin.x.twoDigits), y: \(self.origin.y.twoDigits)), (width: \(self.width.twoDigits), height: \(self.height.twoDigits))}"
    }

}
