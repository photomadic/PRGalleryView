//
//  PRBrandedImage.swift
//  Photomadic
//
//  Created by Albert Martin on 10/28/15.
//  Copyright © 2015 Praxent. All rights reserved.
//

import UIKit
import CoreImage
import CoreGraphics
import Foundation

public extension UIImage {

    private func makeContext(size: CGSize, image: CGImage) -> CGContext {
        var bitmapInfo = image.bitmapInfo.rawValue
        if (bitmapInfo == 3) {
            bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        }

        return CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace!,
            bitmapInfo: bitmapInfo
        )!
    }

    ///
    /// Calculate the drawing offset based on target dimensions.
    ///
    private func drawingOffset(size: CGSize, dimension: CGFloat) -> CGPoint {
        return self.drawingOffset(size: size, dimension: dimension, gravity: .center)
    }

    ///
    /// Calculate the drawing offset based on target dimensions and cropping gravity.
    ///
    private func drawingOffset(size: CGSize, dimension: CGFloat, gravity: UIImageCropGravity) -> CGPoint {

        let centerX: CGFloat = 0 - ((size.width - dimension) / 2)
        let centerY: CGFloat = 0 - ((size.height - dimension) / 2)

        switch (gravity) {

        case .left:
            return CGPoint(x: 0, y: centerY)

        case .right:
            return CGPoint(x: 0 - (size.width - dimension), y: centerY)

        case .topLeft:
            return CGPoint(x: 0, y: 0 - (size.height - dimension))

        case .top:
            return CGPoint(x: centerX, y: 0 - (size.height - dimension))

        case .topRight:
            return CGPoint(x: 0 - (size.width - dimension), y: 0 - (size.height - dimension))

        case .bottomLeft:
            return .zero

        case .bottom:
            return CGPoint(x: centerX, y: 0)

        case .bottomRight:
            return CGPoint(x: 0 - (size.width - dimension), y: 0)

        default: // Center
            return CGPoint(x: centerX, y: centerY)

        }
    }

    enum UIImageCropGravity: Int {
        case topLeft = 8
        case left = 7
        case bottomLeft = 6
        case top = 5
        case center = 4
        case bottom = 3
        case topRight = 2
        case right = 1
        case bottomRight = 0
        case detect = -1
    }

    ///
    /// Get all faces contained in an image.
    ///
    private func allFaces() -> [CIFeature] {
        let image = CoreImage.CIImage(cgImage: self.cgImage!)

        let options = [CIDetectorAccuracy: CIDetectorAccuracyLow]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)

        return faceDetector!.features(in: image)
    }

    ///
    /// Gets the primary face based on size of detected features.
    ///
    private func primaryFace(faces: [CIFeature]) -> CIFeature {
        var largestSize: CGFloat = 0
        var primary: CIFeature = faces.first!

        for face in faces {
            let faceSize: CGFloat = face.bounds.width * face.bounds.height
            if (faceSize > largestSize) {
                largestSize = faceSize
                primary = face
            }
        }

        return primary
    }

    ///
    /// Determine a cropping gravity based on the first face detected.
    ///
    func gravityFromFaces() -> UIImageCropGravity {
        let imageRect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        let faces = self.allFaces()

        // If no faces are found, crop to center.
        if (faces.first == nil) {
            return .center
        }

        let primaryFace = self.primaryFace(faces: faces)
        primaryFace.bounds.origin

        var columns: [CGRect] = []
        var sectors: [CGRect] = []

        var remaining: CGRect = imageRect

        // First we slice the image into three equal columns.
        repeat {
            let (slice, remainder) = remaining.divided(atDistance: self.size.width / 3, from: .minXEdge)
            columns.append(slice)
            remaining = remainder
        } while (remaining.width > 0)

        // Each column is sliced into three equal rows.
        for index in 0...2 {
            var remaining: CGRect = columns[index]
            repeat {
                let (slice, remainder) = remaining.divided(atDistance: self.size.height / 3, from: .minYEdge)
                sectors.append(slice)
                remaining = remainder
            } while (remaining.height > 0)
        }

        // Test each of the sectors to determine where the face is located.
        for index in 0...11 {
            if (sectors[index].contains(primaryFace.bounds.origin)) {
                return UIImageCropGravity(rawValue: index)!
            }
        }

        // Fall back to Center in case of strangeness.
        return .center
    }

    ///
    /// Produces a square-cropped image from the input with cropping gravity.
    ///
    func square(gravity: UIImageCropGravity) -> UIImage {
        var gravity = gravity
        if (gravity == .detect) {
            gravity = self.gravityFromFaces()
        }

        var dimension: CGFloat = 0
        if (self.size.height > self.size.width) {
            dimension = self.size.width
        } else {
            dimension = self.size.height
        }

        let imageRef = self.cgImage!
        let bitmap: CGContext = makeContext(size: CGSize(width: dimension, height: dimension), image: imageRef)

        let offset: CGPoint = drawingOffset(size: self.size, dimension: dimension, gravity: gravity)
        bitmap.draw(imageRef, in: CGRect(x: offset.x, y: offset.y, width: self.size.width, height: self.size.height))

        return UIImage(cgImage: bitmap.makeImage()!)
    }

    ///
    /// Build a square preview grid containing up to four images.
    ///
    func previewGrid(images: Array<UIImage>) -> UIImage {

        switch images.count {

        case 0:
            return UIImage()

        case 1:
            return images[0].square(gravity: .detect)

        case 2:
            let left = images[0].square(gravity: .detect)
            let right = images[1].square(gravity: .detect)
            let imageWidth = left.size.width / 2

            UIGraphicsBeginImageContextWithOptions(left.size, false, 0.0)
            left.draw(in: CGRect(origin: .zero, size: CGSize(width: imageWidth, height: left.size.height)))
            right.draw(in: CGRect(x: imageWidth, y: 0, width: imageWidth, height: left.size.height))
            let twoUp = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return twoUp!

        default:
            let topLeft = images[0].square(gravity: .detect)
            let topRight = images[1].square(gravity: .detect)
            let bottomLeft = images[2].square(gravity: .detect)

            let quarterSize = topLeft.size.width / 2

            UIGraphicsBeginImageContextWithOptions(topLeft.size, false, 0.0)
            UIColor.black.set()
            UIRectFill(CGRect(origin: .zero, size: topLeft.size));
            topLeft.draw(in: CGRect(origin: .zero, size: CGSize(width: quarterSize, height: quarterSize)))
            topRight.draw(in: CGRect(x: quarterSize, y: 0, width: quarterSize, height: quarterSize))
            bottomLeft.draw(in: CGRect(x: 0, y: quarterSize, width: quarterSize, height: quarterSize))

            if images.count == 4 {
                let bottomRight = images[3].square(gravity: .detect)
                bottomRight.draw(in: CGRect(x: quarterSize, y: quarterSize, width: quarterSize, height: quarterSize))
            }

            if images.count > 4 {
                let font: UIFont = UIFont.boldSystemFont(ofSize: quarterSize / 2)
                let text: NSString = NSString(format: "+%i", images.count - 3)
                let attr = [
                    NSFontAttributeName: font,
                    NSForegroundColorAttributeName: UIColor.white
                ]
                let size: CGSize = text.size(attributes: attr)
                text.draw(at: CGPoint(x: quarterSize + ((quarterSize - size.width) / 2), y: quarterSize + ((quarterSize - size.height) / 2)), withAttributes: attr)
            }

            let fourUp = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return fourUp!

        }
    }

    ///
    /// Resize the square image to a particular size.
    ///
    func squareWithSize(size: CGFloat) -> UIImage {
        let square = self.square()
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0.0)
        square.draw(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized!
    }

    ///
    /// Produces a simple square-cropped image from the input.
    ///
    func square() -> UIImage {
        return self.square(gravity: .center)
    }

    ///
    /// Produces a square image scaled with a matte color.
    ///
    func square(matteColor: UIColor) -> UIImage {
        var dimension: CGFloat = 0
        if (self.size.height > self.size.width) {
            dimension = self.size.height
        } else {
            dimension = self.size.width
        }

        let imageRef = self.cgImage!
        let bitmap: CGContext = makeContext(size: CGSize(width: dimension, height: dimension), image: imageRef)

        bitmap.setFillColor(matteColor.cgColor)
        bitmap.fill(CGRect(origin: .zero, size: CGSize(width: dimension, height: dimension)));

        let offset: CGPoint = drawingOffset(size: self.size, dimension: dimension)
        bitmap.draw(imageRef, in: CGRect(origin: offset, size: self.size))

        return UIImage(cgImage: bitmap.makeImage()!)
    }

    ///
    /// Produces an image branded by another image as an overlay.
    ///
    func branded(overlay: UIImage) -> UIImage {

        if (overlay.size == .zero) {
            return self
        }

        let imageRef = self.cgImage!
        let bitmap: CGContext = makeContext(size: self.size, image: imageRef)

        let drawRect = CGRect(origin: .zero, size: self.size)

        bitmap.draw(imageRef, in: drawRect)
        bitmap.draw(overlay.cgImage!, in: drawRect)

        return UIImage(cgImage: bitmap.makeImage()!)
    }

    ///
    /// Produces an image with the appropriate branding based on the image orientation.
    ///
    func branded(landscape: UIImage, portrait: UIImage) -> UIImage {

        if (self.size.width > self.size.height) {
            return self.branded(overlay: landscape)
        }

        return self.branded(overlay: portrait)
    }

}
