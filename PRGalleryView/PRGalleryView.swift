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

enum PRGalleryType {
    case Image
    case Animated
    case Video
}

class PRGalleryView: UIView {

    let imageView: FLAnimatedImageView = FLAnimatedImageView()
    let videoController: AVPlayerViewController = AVPlayerViewController()

    var shouldAllowPlayback: Bool = true

    ///
    // MARK: Generic Media
    ///

    var type: PRGalleryType = .Image

    ///
    /// Load any supported media into the gallery view by URL.
    ///
    var media: NSURL! {

        didSet {
            if (media == nil) {
                return
            }

            type = typeForPath(media.path!)

            switch type {

            case .Video:
                image = nil
                animatedImage = nil

                if (shouldAllowPlayback) {
                    player = AVPlayer(URL: media)
                    return
                }

                image = thumbnailFromVideo(media)
                break

            case .Animated:
                if (shouldAllowPlayback) {
                    animatedImage = animatedImageFromURL(media)
                    return
                }

                image = imageFromURL(media)
                break

            default:
                image = imageFromURL(media)

            }
        }
    }

    ///
    /// Determines the type of file being loaded in order to use the appropriate view.
    ///
    /// - parameter path: The path to the file.
    /// - returns: `video` for any media requiring playback controls or `gif`/`photo` for images.
    ///
    func typeForPath(path: NSString) -> PRGalleryType {

        let utiTag = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, path.pathExtension, nil)!
        let utiType = utiTag.takeRetainedValue() as String

        if (AVURLAsset.audiovisualTypes().contains(String(utiType))) {
            return .Video
        }

        if (String(utiType) == "com.compuserve.gif") {
            return .Animated
        }

        return .Image
    }

    ///
    /// Helper function to clean up the view stack after new media is loaded.
    ///
    /// - parameter type: The type of loaded media; non-necessary views will be removed.
    ///
    func cleanupView(type: PRGalleryType) {
        if (type == .Video) {
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
    // MARK: Playback
    ///

    ///
    /// Start playback of a video or animated GIF.
    ///
    func play() {
        if (type != .Video && type != .Animated) {
            return
        }

        switch type {

        case .Video:
            if (imageView.image != nil) {
                player = AVPlayer(URL: media)
            }

            player!.play()

        case .Animated:
            if (imageView.animatedImage == nil) {
                animatedImage = animatedImageFromURL(media)
                image = nil
            }

            imageView.startAnimating()

        default: break

        }
    }

    ///
    /// Pause playback (resumable) of a video or animated GIF.
    ///
    func pause() {
        if (type != .Video && type != .Animated) {
            return
        }

        imageView.stopAnimating()
        player!.pause()
    }

    ///
    /// Stop playback of a video or animated GIF. Returns the video to it's static
    /// thumbnail representation if `shouldAllowPlayback` is `false`.
    ///
    func stop() {
        if (type != .Video && type != .Animated) {
            return
        }

        if (type == .Video && !shouldAllowPlayback && videoController.player?.currentItem != nil) {
            image = thumbnailFromVideo(media)
        }

        imageView.stopAnimating()
        player!.pause()
    }

    ///
    // MARK: Animated GIF
    ///

    var animatedImage: FLAnimatedImage? {
        set {
            imageView.animatedImage = newValue
            cleanupView(.Image)
        }
        get {
            return imageView.animatedImage
        }
    }

    ///
    /// Creates an instance of FLAnimatedImage for animated GIF images.
    ///
    /// - parameter url: The URL to the file.
    /// - returns: `FLAnimatedImage`
    ///
    func animatedImageFromURL(url: NSURL) -> FLAnimatedImage {
        let image = FLAnimatedImage(animatedGIFData: NSData(contentsOfURL: url))

        if (image == nil) {
            print("Unable to create animated image from URL", url)
            return FLAnimatedImage()
        }

        return image!
    }

    ///
    // MARK: Static Image
    ///

    var image: UIImage? {
        set {
            imageView.image = newValue
            cleanupView(.Image)
        }
        get {
            return imageView.image
        }
    }

    ///
    /// Creates a UIImage for static images.
    ///
    /// - parameter url: The URL to the file.
    /// - returns: `UIImage`
    ///
    func imageFromURL(url: NSURL) -> UIImage {
        let image = UIImage(data: NSData(contentsOfURL: url)!)

        if (image == nil) {
            print("Unable to create image from URL", url)
            return UIImage()
        }

        return image!
    }

    ///
    // MARK: Video
    ///

    var player: AVPlayer? {
        set {
            videoController.player = newValue
            cleanupView(.Video)
        }
        get {
            return videoController.player
        }
    }

    var thumbnailInSeconds: Float64 = 5


    ///
    /// Returns a thumbnail image for display when playback is disabled.
    ///
    /// - parameter url: The URL of the file.
    /// - returns: `UIImage`
    ///
    func thumbnailFromVideo(url: NSURL) -> UIImage {
        let video = AVURLAsset(URL: url)
        let time = CMTimeMakeWithSeconds(thumbnailInSeconds, 60)
        let thumbGenerator = AVAssetImageGenerator(asset: video)
        thumbGenerator.appliesPreferredTrackTransform = true

        do {
            let thumbnail = try thumbGenerator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: thumbnail)
        } catch {
            print("Unable to generate thumbnail from video", url)
            return UIImage()
        }
    }

}
