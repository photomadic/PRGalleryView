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

    private func makeContext(size: CGSize, image: CGImageRef) -> CGContextRef {
        var bitmapInfo = CGImageGetBitmapInfo(image).rawValue
        if (bitmapInfo == 3) {
            bitmapInfo = CGImageAlphaInfo.PremultipliedLast.rawValue
        }

        return CGBitmapContextCreate(
            nil,
            Int(size.width),
            Int(size.height),
            CGImageGetBitsPerComponent(image),
            0,
            CGImageGetColorSpace(image),
            bitmapInfo
            )!
    }

    ///
    /// Calculate the drawing offset based on target dimensions.
    ///
    private func drawingOffset(size: CGSize, dimension: CGFloat) -> CGPoint {
        return self.drawingOffset(size, dimension: dimension, gravity: .Center)
    }

    ///
    /// Calculate the drawing offset based on target dimensions and cropping gravity.
    ///
    private func drawingOffset(size: CGSize, dimension: CGFloat, gravity: UIImageCropGravity) -> CGPoint {

        let centerX: CGFloat = 0 - ((size.width - dimension) / 2)
        let centerY: CGFloat = 0 - ((size.height - dimension) / 2)

        switch (gravity) {

        case .Left:
            return CGPointMake(0, centerY)

        case .Right:
            return CGPointMake(0 - (size.width - dimension), centerY)

        case .TopLeft:
            return CGPointMake(0, 0 - (size.height - dimension))

        case .Top:
            return CGPointMake(centerX, 0 - (size.height - dimension))

        case .TopRight:
            return CGPointMake(0 - (size.width - dimension), 0 - (size.height - dimension))

        case .BottomLeft:
            return CGPointMake(0, 0)

        case .Bottom:
            return CGPointMake(centerX, 0)

        case .BottomRight:
            return CGPointMake(0 - (size.width - dimension), 0)

        default: // Center
            return CGPointMake(centerX, centerY)

        }
    }

    enum UIImageCropGravity: Int {
        case TopLeft = 8
        case Left = 7
        case BottomLeft = 6
        case Top = 5
        case Center = 4
        case Bottom = 3
        case TopRight = 2
        case Right = 1
        case BottomRight = 0
        case Detect = -1
    }

    ///
    /// Get all faces contained in an image.
    ///
    private func allFaces() -> [CIFeature] {
        let image = CoreImage.CIImage(CGImage: self.CGImage!)

        let options = [CIDetectorAccuracy: CIDetectorAccuracyLow]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)

        return faceDetector.featuresInImage(image)
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
        let imageRect = CGRectMake(0, 0, self.size.width, self.size.height)
        let faces = self.allFaces()

        // If no faces are found, crop to center.
        if (faces.first == nil) {
            return .Center
        }

        let primaryFace = self.primaryFace(faces)
        primaryFace.bounds.origin

        var columns: [CGRect] = []
        var sectors: [CGRect] = []

        var remaining: CGRect = imageRect

        // First we slice the image into three equal columns.
        repeat {
            let (slice, remainder) = remaining.divide(self.size.width / 3, fromEdge: .MinXEdge)
            columns.append(slice)
            remaining = remainder
        } while (remaining.width > 0)

        // Each column is sliced into three equal rows.
        for index in 0...2 {
            var remaining: CGRect = columns[index]
            repeat {
                let (slice, remainder) = remaining.divide(self.size.height / 3, fromEdge: .MinYEdge)
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
        return .Center
    }

    ///
    /// Produces a square-cropped image from the input with cropping gravity.
    ///
    func square(var gravity: UIImageCropGravity) -> UIImage {
        if (gravity == .Detect) {
            gravity = self.gravityFromFaces()
        }

        var dimension: CGFloat = 0
        if (self.size.height > self.size.width) {
            dimension = self.size.width
        } else {
            dimension = self.size.height
        }

        let imageRef = self.CGImage!
        let bitmap: CGContextRef = makeContext(CGSizeMake(dimension, dimension), image: imageRef)

        let offset: CGPoint = drawingOffset(self.size, dimension: dimension, gravity: gravity)
        CGContextDrawImage(bitmap, CGRectMake(offset.x, offset.y, self.size.width, self.size.height), imageRef)

        return UIImage(CGImage: CGBitmapContextCreateImage(bitmap)!)
    }

    ///
    /// Build a square preview grid containing up to four images.
    ///
    func previewGrid(images: Array<UIImage>) -> UIImage {

        switch images.count {

        case 0:
            return UIImage()

        case 1:
            return images[0].square(.Detect)

        case 2:
            let left = images[0].square(.Detect)
            let right = images[1].square(.Detect)
            let imageWidth = left.size.width / 2

            UIGraphicsBeginImageContextWithOptions(left.size, false, 0.0)
            left.drawInRect(CGRectMake(0, 0, imageWidth, left.size.height))
            right.drawInRect(CGRectMake(imageWidth, 0, imageWidth, left.size.height))
            let twoUp = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return twoUp

        default:
            let topLeft = images[0].square(.Detect)
            let topRight = images[1].square(.Detect)
            let bottomLeft = images[2].square(.Detect)

            let quarterSize = topLeft.size.width / 2

            UIGraphicsBeginImageContextWithOptions(topLeft.size, false, 0.0)
            UIColor.blackColor().set()
            UIRectFill(CGRectMake(0.0, 0.0, topLeft.size.width, topLeft.size.height));
            topLeft.drawInRect(CGRectMake(0, 0, quarterSize, quarterSize))
            topRight.drawInRect(CGRectMake(quarterSize, 0, quarterSize, quarterSize))
            bottomLeft.drawInRect(CGRectMake(0, quarterSize, quarterSize, quarterSize))

            if images.count == 4 {
                let bottomRight = images[3].square(.Detect)
                bottomRight.drawInRect(CGRectMake(quarterSize, quarterSize, quarterSize, quarterSize))
            }

            if images.count > 4 {
                let font: UIFont = UIFont.boldSystemFontOfSize(quarterSize / 2)
                let text: NSString = NSString(format: "+%i", images.count - 3)
                let attr = [
                    NSFontAttributeName: font,
                    NSForegroundColorAttributeName: UIColor.whiteColor()
                ]
                let size: CGSize = text.sizeWithAttributes(attr)
                text.drawAtPoint(CGPointMake(quarterSize + ((quarterSize - size.width) / 2), quarterSize + ((quarterSize - size.height) / 2)), withAttributes: attr)
            }

            let fourUp = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return fourUp

        }
    }

    ///
    /// Resize the square image to a particular size.
    ///
    func squareWithSize(size: CGFloat) -> UIImage {
        let square = self.square()
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), false, 0.0)
        square.drawInRect(CGRectMake(0, 0, size, size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }

    ///
    /// Produces a simple square-cropped image from the input.
    ///
    func square() -> UIImage {
        return self.square(.Center)
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

        let imageRef = self.CGImage!
        let bitmap: CGContextRef = makeContext(CGSizeMake(dimension, dimension), image: imageRef)

        CGContextSetFillColorWithColor(bitmap, matteColor.CGColor)
        CGContextFillRect(bitmap, CGRectMake(0.0, 0.0, dimension, dimension));

        let offset: CGPoint = drawingOffset(self.size, dimension: dimension)
        CGContextDrawImage(bitmap, CGRectMake(offset.x, offset.y, self.size.width, self.size.height), imageRef)

        return UIImage(CGImage: CGBitmapContextCreateImage(bitmap)!)
    }

    ///
    /// Produces an image branded by another image as an overlay.
    ///
    func branded(overlay: UIImage) -> UIImage {

        if (overlay.size == CGSizeZero) {
            return self
        }

        let imageRef = self.CGImage!
        let bitmap: CGContextRef = makeContext(self.size, image: imageRef)

        CGContextDrawImage(bitmap, CGRectMake(0, 0, self.size.width, self.size.height), imageRef)
        CGContextDrawImage(bitmap, CGRectMake(0, 0, self.size.width, self.size.height), overlay.CGImage)

        return UIImage(CGImage: CGBitmapContextCreateImage(bitmap)!)
    }

    ///
    /// Produces an image with the appropriate branding based on the image orientation.
    ///
    func branded(landscape: UIImage, portrait: UIImage) -> UIImage {

        if (self.size.width > self.size.height) {
            return self.branded(landscape)
        }

        return self.branded(portrait)
    }

}
