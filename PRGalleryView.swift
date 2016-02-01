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
import FLAnimatedImage

public enum PRGalleryType {
    case Image
    case Animated
    case Video
}

public class PRGalleryView: UIView {

    public let imageView: FLAnimatedImageView = FLAnimatedImageView()
    public let videoController: AVPlayerViewController = AVPlayerViewController()

    public var type: PRGalleryType = .Image
    public var shouldAllowPlayback: Bool = true
    public var thumbnailInSeconds: Float64 = 5

    public var branded: Bool = false
    public var overlayLandscape: UIImage = UIImage()
    public var overlayPortrait: UIImage = UIImage()

    ///
    /// Load any supported media into the gallery view by URL.
    ///
    public var media: NSURL! {

        didSet {
            if (self.media == nil || self.media.path == nil) {
                image = UIImage()
                return
            }

            type = typeForPath(self.media.path!)

            switch type {

            case .Video:
                image = nil
                animatedImage = nil

                if (shouldAllowPlayback) {
                    player = AVPlayer(URL: self.media)
                    return
                }

                image = self.imageThumbnailFromVideo(self.media)
                break

            case .Animated:
                if (shouldAllowPlayback) {
                    animatedImage = self.animatedImageFromPath(self.media.path!)
                    return
                }

                image = self.imageFromPath(self.media.path!)
                break

            default:
                image = self.imageFromPath(self.media.path!)

            }
        }
    }

    ///
    /// Helper function to clean up the view stack after new media is loaded.
    ///
    /// - parameter type: The type of loaded media; non-necessary views will be removed.
    ///
    public func cleanupView(type: PRGalleryType) {
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
    /// Determines the type of file being loaded in order to use the appropriate view.
    ///
    /// - parameter path: The path to the file.
    /// - returns: `video` for any media requiring playback controls or `gif`/`photo` for images.
    ///
    public func typeForPath(path: NSString) -> PRGalleryType {

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
    // MARK: Positioning and Measurement
    ///

    public func sizeOfMedia() -> CGSize {
        if (type == .Video) {
            return videoController.view.frame.size
        }

        var scale: CGFloat = 1.0;
        if (imageView.image!.size.width > imageView.image!.size.height) {
            scale = imageView.frame.size.width / imageView.image!.size.width
        } else {
            scale = imageView.frame.size.height / imageView.image!.size.height
        }
        return CGSizeMake(imageView.image!.size.width * scale, imageView.image!.size.height * scale)
    }

    ///
    // MARK: Playback
    ///

    ///
    /// Start playback of a video or animated GIF.
    ///
    public func play() {
        if (type != .Video && type != .Animated) {
            return
        }

        switch type {

        case .Video:
            if (imageView.image != nil) {
                player = AVPlayer(URL: self.media)
            }

            player!.play()

        case .Animated:
            if (imageView.animatedImage == nil) {
                animatedImage = self.animatedImageFromPath(media!.path!)
                image = nil
            }

            imageView.startAnimating()

        default: break

        }
    }

    ///
    /// Pause playback (resumable) of a video or animated GIF.
    ///
    public func pause() {
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
    public func stop() {
        if (type != .Video && type != .Animated) {
            return
        }

        if (type == .Video && !shouldAllowPlayback && videoController.player?.currentItem != nil) {
            image = self.imageThumbnailFromVideo(self.media)
        }

        imageView.stopAnimating()
        player!.pause()
    }

    ///
    // MARK: Animated GIF
    ///

    public var animatedImage: FLAnimatedImage? {
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
    /// - parameter path: The path to the file.
    /// - returns: `FLAnimatedImage`
    ///
    public func animatedImageFromPath(path: String) -> FLAnimatedImage {
        let image = FLAnimatedImage(animatedGIFData: NSData(contentsOfFile: path))

        if (image == nil) {
            print("Unable to create animated image from path", path)
            return FLAnimatedImage()
        }

        return image!
    }

    ///
    // MARK: Static Image
    ///

    public var image: UIImage? {
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
    /// - parameter path: The path to the file.
    /// - returns: `UIImage`
    ///
    public func imageFromPath(path: String) -> UIImage {
        let image = UIImage(contentsOfFile: path)

        if (image == nil) {
            print("Unable to create image from path", path)
            return UIImage()
        }

        if (branded) {
            return image!.branded(overlayLandscape, portrait: overlayPortrait)
        }

        return image!
    }

    ///
    // MARK: Video
    ///

    public var player: AVPlayer? {
        set {
            videoController.player = newValue
            cleanupView(.Video)
        }
        get {
            return videoController.player
        }
    }


    ///
    /// Returns a thumbnail image for display when playback is disabled.
    ///
    /// - parameter url: The URL of the file.
    /// - returns: `UIImage`
    ///
    public func imageThumbnailFromVideo(url: NSURL) -> UIImage {
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
