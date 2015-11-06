//
//  PRBrandedImage.swift
//  ⌘ Praxent
//
//  Created by Albert Martin on 10/28/15.
//  Copyright © 2015 Praxent. All rights reserved.
//

import UIKit
import CoreImage
import CoreGraphics
import Foundation

extension UIImage {

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
