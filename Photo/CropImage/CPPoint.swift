
#if os(iOS)
import UIKit
public typealias CPPoint = CGPoint
#elseif os(OSX)
import Cocoa
public typealias CPPoint = NSPoint
#endif

extension CPPoint {
    func scaled(xScaleFactor: CGFloat, yScaleFactor: CGFloat) -> CGPoint {
        return CGPoint(x: self.x * xScaleFactor, y: self.y * yScaleFactor)
    }
}
