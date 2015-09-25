//
//  PRGalleryView.swift
//  ⌘ Praxent
//
//  A single view type which accepts video, GIF and photo media for display in a gallery.
//
//  Created by Albert Martin on 9/25/15.
//  Copyright © 2015 Praxent. All rights reserved.
//

import AVFoundation
import AVKit
import MobileCoreServices

class PRGalleryView: UIView {

    let imageView: FLAnimatedImageView = FLAnimatedImageView()
    let videoController: AVPlayerViewController = AVPlayerViewController()

    var galleryType: String = ""

    ///
    /// Load any supported media into the gallery view.
    ///
    /// - parameter url: The URL to the media being loaded.
    ///
    func loadMedia(url: NSURL) {
        if (url.path == nil) {
            return
        }

        // Reset any previous view heirarchy if this is a recycled view.
        galleryType = self.typeForPath(url.path!)
        imageView.removeFromSuperview()
        videoController.view.removeFromSuperview()

        if (galleryType == "video") {
            videoController.player = AVPlayer(URL: url)
            videoController.view.frame = self.bounds
            self.addSubview(videoController.view)
            return
        }

        videoController.player = AVPlayer()

        imageView.frame = self.bounds
        imageView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.addSubview(imageView)

        if (galleryType == "gif") {
            imageView.animatedImage = self.animatedImageFromPath(url.path!)
        }
        else {
            imageView.image = self.imageFromPath(url.path!)
        }
    }

    ///
    /// Determines the type of file being loaded in order to use the appropriate view.
    ///
    /// - parameter path: The path to the file.
    /// - returns: `video` for any media requiring playback controls or `gif`/`photo` for images.
    ///
    func typeForPath(path: NSString) -> String {

        let utiTag = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, path.pathExtension, nil)!
        let utiType = utiTag.takeRetainedValue() as String

        if (AVURLAsset.audiovisualTypes().contains(String(utiType))) {
            return "video"
        }

        if (String(utiType) == "com.compuserve.gif") {
            return "gif"
        }

        return "photo"
    }

    ///
    /// Creates an instance of FLAnimatedImage for animated GIF images.
    ///
    /// - parameter path: The path to the file.
    /// - returns: `FLAnimatedImage`
    ///
    func animatedImageFromPath(path: String) -> FLAnimatedImage {
        let image = FLAnimatedImage(animatedGIFData: NSData(contentsOfFile: path))

        if (image == nil) {
            print("Unable to create animated image from path", path)
            return FLAnimatedImage()
        }

        return image!
    }

    ///
    /// Creates a UIImage for static images.
    ///
    /// - parameter path: The path to the file.
    /// - returns: `UIImage`
    ///
    func imageFromPath(path: String) -> UIImage {
        let image = UIImage(contentsOfFile: path)

        if (image == nil) {
            print("Unable to create image from path", path)
            return UIImage()
        }

        return image!
    }

}
