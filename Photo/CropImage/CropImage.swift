import SwiftUI
import CoreGraphics

struct CropImage: View {
    
    private let originalImage = UIImage(named: "dish")!
    @State private var croppedImage = UIImage(named: "dish")!
    @State private var quadrilateral = Quadrilateral()
    
    var body: some View {
        VStack {
            Image(uiImage: originalImage)
                .resizable()
                .scaledToFit()
                .overlay(
                    ReshapableRectangle(quadrilateral: $quadrilateral),
                    alignment: .topLeading
                )
            Spacer()
            
            Image(uiImage: croppedImage)
                .resizable()
                .scaledToFit()
            Button("Crop Image") {
                print(quadrilateral)
                if let croppedImage = cropImage(originalImage, by: quadrilateral) {
                    self.croppedImage = croppedImage
                }
            }
        }
    }
    
    
    /**
     * Crop the given image using the given quadrilateral
     * Before cropping, it is necessary to map the specified quadrilateral to the coordinate 
     * space of the given image, as the size of the image may differ from the bounds which 
     * the quadrilateral was created from.
     */
    private func cropImage(_ image: UIImage, by quadrilateral: Quadrilateral) -> UIImage? {
        // Create a context of the correct size
        UIGraphicsBeginImageContext(image.size)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // mapping the given quadrilateral into the image coordinate space
        let alignedQuadrilateral = mappingQuadrilateral(quadrilateral, to: image.size)
        
        // Create a path for the quadrilateral
        let path = CGMutablePath()
        path.move(to: alignedQuadrilateral.topLeft)
        path.addLine(to: alignedQuadrilateral.topRight)
        path.addLine(to: alignedQuadrilateral.bottomRight)
        path.addLine(to: alignedQuadrilateral.bottomLeft)
        path.closeSubpath()
        
        context.addPath(path)
        context.clip()
        
        // Draw the image into the context
        image.draw(at: CGPoint.zero)
        
        // Extract the image
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
    
    private func mappingQuadrilateral(_ quadrilateral: Quadrilateral, 
                                      to imageSize: CPSize) -> Quadrilateral {
        guard let baseSize = quadrilateral.parentBounds?.size else { return quadrilateral }
        
        let xScale = imageSize.width / baseSize.width
        let yScale = imageSize.height / baseSize.height
        
        return Quadrilateral(topLeft: quadrilateral.topLeft.scaled(xScaleFactor: xScale, yScaleFactor: yScale),
                             topRight: quadrilateral.topRight.scaled(xScaleFactor: xScale, yScaleFactor: yScale),
                             bottomLeft: quadrilateral.bottomLeft.scaled(xScaleFactor: xScale, yScaleFactor: yScale),
                             bottomRight: quadrilateral.bottomRight.scaled(xScaleFactor: xScale, yScaleFactor: yScale))
    }
}
