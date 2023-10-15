//  created by musesum on 7/17/19.

import UIKit

extension UIImage {

    public class func getIconPath(_ path: String, name: String) -> UIImage? {

        var img = UIImage(named: name)
        if img == nil {
            let docPath = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents").absoluteString
            let iconDir = URL(fileURLWithPath: docPath).appendingPathComponent(path).absoluteString
            let iconPath = URL(fileURLWithPath: iconDir).appendingPathComponent(name).absoluteString
            let data = NSData(contentsOfFile: iconPath) as Data?
            if let data = data {
                img = UIImage(data: data)
            }
        }
        return img
    }

    public func circularImage(size: CGSize?) -> UIImage? {
        let newSize = size ?? self.size

        let minEdge = min(newSize.height, newSize.width)
        let size = CGSize(width: minEdge, height: minEdge)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {

            self.draw(in: CGRect(origin: CGPoint.zero, size: size), blendMode: .copy, alpha: 1.0)

            context.setBlendMode(.copy)
            context.setFillColor(UIColor.clear.cgColor)

            let rectPath = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: size))
            let circlePath = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: size))
            rectPath.append(circlePath)
            rectPath.usesEvenOddFillRule = true
            rectPath.fill()

            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return result
        }
        return nil
    }

    func cropImage(toRect rect: CGRect) -> UIImage? {
        if let imageRef = self.cgImage?.cropping(to: rect) {
            return UIImage(cgImage: imageRef)
        }
        return nil
    }
    public func roundIcon(_ diameter: CGFloat) -> UIImage? {

        let w = size.width
        let h = size.height
        let minWH = min(w, h)
        let rescale = diameter / minWH
        let reW = round(w * rescale)
        let reH = round(h * rescale)
        let resize = CGSize(width: reW, height: reH)
        let sizeRect = CGRect(x:(diameter-reW)/2, y:(diameter-reH)/2, width: reW, height: reH)
        let iconRect = CGRect(x: 0, y: 0, width: diameter, height: diameter)

        // Actually do the resizing to the rect using the ImageContext stuff
        var uiImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(resize, false, 1.0)
        UIBezierPath(roundedRect: iconRect, cornerRadius: diameter/2).addClip()
        draw(in: sizeRect)
        if let sizedImage = UIGraphicsGetImageFromCurrentImageContext(),
           let cropImage = sizedImage.cgImage?.cropping(to: iconRect) {
            uiImage = UIImage(cgImage: cropImage, scale: 1, orientation: .up)
        }
        UIGraphicsEndImageContext()
        return uiImage

    }

    public func rounded(radius: CGFloat) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }

    public func scaledTo(_ newSize: CGSize) -> UIImage {

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

}
