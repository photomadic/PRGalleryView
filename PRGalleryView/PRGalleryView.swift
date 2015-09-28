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
    var shouldAllowPlayback: Bool = true
    var thumbnailInSeconds: Float64 = 5

    var image: UIImage? {
        set {
            imageView.image = newValue
            cleanup("image")
        }
        get {
            return imageView.image
        }
    }

    var animatedImage: FLAnimatedImage? {
        set {
            imageView.animatedImage = newValue
            cleanup("image")
        }
        get {
            return imageView.animatedImage
        }
    }

    var player: AVPlayer? {
        set {
            videoController.player = newValue
            cleanup("video")
        }
        get {
            return videoController.player
        }
    }

    func cleanup(type: String) {
        if (type == "video") {
            videoController.view.frame = bounds
            addSubview(videoController.view)
            return
        }

        imageView.frame = bounds
        imageView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]

        videoController.view.removeFromSuperview()
        videoController.player = AVPlayer()
        addSubview(imageView)
    }

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

            if (shouldAllowPlayback) {
                videoController.player = AVPlayer(URL: url)
                videoController.view.frame = self.bounds
                self.addSubview(videoController.view)
                return
            }

            image = self.imageThumbnailFromVideo(url)
            return
        }

        if (galleryType == "gif") {
            animatedImage = self.animatedImageFromPath(url.path!)
        }
        else {
            image = self.imageFromPath(url.path!)
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

    func imageThumbnailFromVideo(url: NSURL) -> UIImage {
        let video = AVURLAsset(URL: url)
        let time = CMTimeMakeWithSeconds(thumbnailInSeconds, 60)
        let thumbGenerator = AVAssetImageGenerator(asset: video)
        thumbGenerator.appliesPreferredTrackTransform = true

        do {
            let thumbnail = try thumbGenerator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: thumbnail)
        } catch {
            print("Unable to generate thumbnail from video", url.path)
            return UIImage()
        }
    }

}
