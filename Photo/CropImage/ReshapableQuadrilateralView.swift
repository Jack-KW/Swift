import SwiftUI

struct ReshapableQuadrilateral: UIViewRepresentable {
    
    // @Binding and init(: Binding<>) work together helps we pass value up
    // to the parent view
    @Binding var quadrilateral: Quadrilateral
    
    init(quadrilateral: Binding<Quadrilateral>) {
        self._quadrilateral = quadrilateral
    }
    
    func makeUIView(context: Context) -> ReshapableQuadrilateralView {
        let reshapableRectangleView = ReshapableQuadrilateralView()
        reshapableRectangleView.quadrilateralUpdateHandler = { newQuardrilateral in
            self.quadrilateral = newQuardrilateral
        }
        return reshapableRectangleView
    }
    
    func updateUIView(_ uiView: ReshapableQuadrilateralView, context: Context) {
    }
    
}

/**
 * This code creates a custom UIView subclass that draws a rectangle with draggable corners. 
 * It uses UIPanGestureRecognizer to handle drag gestures. When a drag begins, it checks which 
 * corner view is being dragged. If the target location of the drag is valid, it updates that 
 * corner's position as the gesture moves. When any corner view moves, the quadrilateral formed
 * from the corner views is redrawn accordingly.
 */
class ReshapableQuadrilateralView: UIView {
    
    var quadrilateralUpdateHandler: ((Quadrilateral) -> Void)?
    
    private var topLeftCorner = DraggableCornerView(cornerPoint: .topLeft)
    private var topRightCorner = DraggableCornerView(cornerPoint: .topRight)
    private var bottomLeftCorner = DraggableCornerView(cornerPoint: .bottomLeft)
    private var bottomRightCorner = DraggableCornerView(cornerPoint: .bottomRight)
    
    private var quadrilateral = Quadrilateral()
    
    private let padding = 10.0
    private let cornerHandlerSize = 50.0
    
    private var cornerViews: [UIView] {
        return [topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner]
    }
    
    private var currentDraggingView: UIView?
    
    override init(frame: CPRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupCorners()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupCorners()
    }
    
    private func setupCorners() {
        cornerViews.forEach { cornerView in
            cornerView.frame = CPRect(x: 0, y: 0,
                                      width: cornerHandlerSize, height: cornerHandlerSize)
            cornerView.backgroundColor = .clear
            cornerView.isUserInteractionEnabled = true
            addSubview(cornerView)
        }
        
        initCorners()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(cornerPan(_:)))
        addGestureRecognizer(panGesture)
    }
  
    private func initCorners() {
        
        let centerOffset = padding + cornerHandlerSize/2
        
        topLeftCorner.center = CPPoint(x: bounds.minX, y: bounds.minY)
            .addOffset(offsetX: centerOffset, offsetY: centerOffset)
        topRightCorner.center = CPPoint(x: bounds.maxX, y: bounds.minY)
            .addOffset(offsetX: -centerOffset, offsetY: centerOffset)
        bottomLeftCorner.center = CPPoint(x: bounds.minX, y: bounds.maxY)
            .addOffset(offsetX: centerOffset, offsetY: -centerOffset)
        bottomRightCorner.center = CPPoint(x: bounds.maxX, y: bounds.maxY)
            .addOffset(offsetX: -centerOffset, offsetY: -centerOffset)
        
        refreshQuadrilateral()
    }
    
    @objc
    func cornerPan(_ gesture: UIPanGestureRecognizer) {

        let location = gesture.location(in: self)
        
        switch gesture.state {
            
        case .began:
            currentDraggingView = cornerViews.first(where: { $0.frame.contains(location) })
            if let targetView = currentDraggingView as? DraggableCornerView {
                updateCornerView(targetView, isDragging: true)
            }
            
        case .changed:
            guard let draggingView = currentDraggingView as? DraggableCornerView,
                  quadrilateral.newLocation(location, validFor: draggingView.cornerPoint,
                                            in: self.bounds) 
            else { return }
            
            draggingView.center = location
            
            refreshQuadrilateral()
            
        case .ended, .cancelled:
            if let targetView = currentDraggingView as? DraggableCornerView {
                updateCornerView(targetView, isDragging: false)
            }
            currentDraggingView = nil
            
        default:
            break
        }
        setNeedsDisplay()
    }
    
    /**
     * refresh the quadrilaberal value based on the four corner handler views
     * also refresh the parent view's quadrilaberal value
     */
    private func refreshQuadrilateral() {
        quadrilateral = Quadrilateral(topLeft: topLeftCorner.center,
                                      topRight: topRightCorner.center,
                                      bottomLeft: bottomLeftCorner.center,
                                      bottomRight: bottomRightCorner.center)
        quadrilateral.parentBounds = bounds
        quadrilateralUpdateHandler?(quadrilateral)
    }
    
    /**
     * update the given corner view for whether it is being dragging
     */
    private func updateCornerView(_ cornerView: DraggableCornerView, isDragging: Bool) {
        cornerView.isDragging = isDragging
        cornerView.setNeedsDisplay()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        initCorners()
    }
    
    override func draw(_ rect: CPRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.clear(rect)
        
        context.setStrokeColor(UIColor.yellow.cgColor)
        context.setLineWidth(1)
        
        context.beginPath()
        context.move(to: topLeftCorner.center)
        context.addLine(to: topRightCorner.center)
        context.addLine(to: bottomRightCorner.center)
        context.addLine(to: bottomLeftCorner.center)
        context.addLine(to: topLeftCorner.center)
        
        context.strokePath()
    }
    
}

class DraggableCornerView: UIView {
    
    let cornerPoint: CornerPoint
    var isDragging = false
    
    init(cornerPoint: CornerPoint) {
        self.cornerPoint = cornerPoint
        super.init(frame: CPRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        //super.init(coder: aDecoder)
    }
    
    /**
     * draw the circle shape on the view
     * the radius of the circle is enlarged when this view is being dragged
     */
    override func draw(_ rect: CPRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.clear(rect)
        
        let lineWidth = 1.0
        context.setLineWidth(lineWidth)
        let strokeColor = isDragging ? UIColor.green.cgColor : UIColor.yellow.cgColor
        context.setStrokeColor(strokeColor)
        
        let center = CPPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = (isDragging ? rect.width / 2 : rect.width / 4) - lineWidth
        context.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        context.strokePath()
    }
}

enum CornerPoint {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

/**
 * Defines a quadrilateral, regular or irregular with four corner points
 */
struct Quadrilateral {
    let topLeft: CPPoint
    let topRight: CPPoint
    let bottomLeft: CPPoint
    let bottomRight: CPPoint
    var parentBounds: CPRect?
    
    init() {
        topLeft = .zero
        topRight = .zero
        bottomLeft = .zero
        bottomRight = .zero
    }
    
    init(topLeft: CPPoint, topRight: CPPoint,
         bottomLeft: CPPoint, bottomRight: CPPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }
    
    /**
     * test whether a given new location is valid for the given corner point
     */
    func newLocation(_ location: CPPoint, validFor cornerPoint: CornerPoint,
                     in bounds: CPRect) -> Bool {
        guard location.x > 0 && location.x < bounds.width,
              location.y > 0 && location.y < bounds.height
        else { return false }
        switch cornerPoint {
        case .topLeft:
            return (location.x < topRight.x && location.y < bottomLeft.y) &&
                   (location.x < bottomRight.x && location.y < bottomRight.y)
        case .topRight:
            return (location.x > topLeft.x && location.y < bottomRight.y &&
                    location.x > bottomLeft.x && location.y < bottomLeft.y)
        case .bottomLeft:
            return (location.x < bottomRight.x && location.y > topLeft.y) &&
                    (location.x < topRight.x && location.y > topRight.y)
        case .bottomRight:
            return (location.x > bottomLeft.x && location.y > topRight.y &&
                    location.x > topLeft.x && location.y > topLeft.y)
        }
    }
}
