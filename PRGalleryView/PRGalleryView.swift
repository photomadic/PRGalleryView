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

    var media: NSURL = NSURL()
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

    ///
    /// Helper function to clean up the view stack after new media is loaded.
    ///
    /// - parameter type: The type of loaded media; non-necessary views will be removed.
    ///
    func cleanup(type: String) {
        if (type == "video") {
            videoController.view.frame = bounds
            imageView.removeFromSuperview()
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

        media = url

        galleryType = typeForPath(media.path!)

        switch galleryType {

        case "video":
            if (shouldAllowPlayback) {
                player = AVPlayer(URL: media)
                return
            }

            image = self.imageThumbnailFromVideo(media)
            break

        case "gif":
            if (shouldAllowPlayback) {
                animatedImage = self.animatedImageFromPath(media.path!)
                return
            }

            image = self.imageFromPath(media.path!)
            break

        default:
            image = self.imageFromPath(media.path!)

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

    func startAnimating() {
        if (galleryType != "gif") {
            return
        }

        if (imageView.animatedImage == nil) {
            animatedImage = self.animatedImageFromPath(media.path!)
            image = nil
        }

        imageView.startAnimating()
    }

    func stopAnimating() {
        if (galleryType != "gif") {
            return
        }

        imageView.stopAnimating()
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
