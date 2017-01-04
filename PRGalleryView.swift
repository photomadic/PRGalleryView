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
    case image
    case animated
    case video
}

public class PRGalleryView: UIView {

    public let imageView: FLAnimatedImageView = FLAnimatedImageView()
    public let videoController: AVPlayerViewController = AVPlayerViewController()

    public var type: PRGalleryType = .image
    public var shouldAllowPlayback: Bool = true
    public var thumbnailInSeconds: Float64 = 5

    public var branded: Bool = false
    public var overlayLandscape: UIImage = UIImage()
    public var overlayPortrait: UIImage = UIImage()

    ///
    /// Load any supported media into the gallery view by URL.
    ///
    public var media: URL? {

        didSet {
            if (self.media == nil || self.media!.path == nil) {
                image = UIImage()
                return
            }

            type = type(from: self.media!)

            switch type {

            case .video:
                image = nil
                animatedImage = nil

                if (shouldAllowPlayback) {
                    player = AVPlayer(url: self.media!)
                    return
                }

                image = self.imageThumbnail(from: self.media!)
                break

            case .animated:
                if (shouldAllowPlayback) {
                    animatedImage = self.animatedImage(from: self.media!)
                    return
                }

                image = self.image(from: self.media!.path)
                break

            default:
                image = self.image(from: self.media!.path)

            }
        }
    }

    ///
    /// Helper function to clean up the view stack after new media is loaded.
    ///
    /// - parameter type: The type of loaded media; non-necessary views will be removed.
    ///
    public func cleanupView(type: PRGalleryType) {
        if (type == .video) {
            videoController.view.frame = bounds
            imageView.removeFromSuperview()
            addSubview(videoController.view)
            return
        }

        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

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
    public func type(from url: URL) -> PRGalleryType {
        let utiTag = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil)!
        let utiType = utiTag.takeRetainedValue() as String

        if (AVURLAsset.audiovisualTypes().contains(String(utiType))) {
            return .video
        }

        if (String(utiType) == "com.compuserve.gif") {
            return .animated
        }

        return .image
    }

    ///
    // MARK: Positioning and Measurement
    ///

    public func sizeOfMedia() -> CGSize {
        if (type == .video) {
            return videoController.view.frame.size
        }

        var scale: CGFloat = 1.0;
        if (imageView.image!.size.width > imageView.image!.size.height) {
            scale = imageView.frame.size.width / imageView.image!.size.width
        } else {
            scale = imageView.frame.size.height / imageView.image!.size.height
        }
        return CGSize(width: imageView.image!.size.width * scale, height: imageView.image!.size.height * scale)
    }

    ///
    // MARK: Playback
    ///

    ///
    /// Start playback of a video or animated GIF.
    ///
    public func play() {
        if (type != .video && type != .animated) {
            return
        }

        switch type {

        case .video:
            if (imageView.image != nil) {
                player = AVPlayer(url: self.media!)
            }

            player!.play()

        case .animated:
            if (imageView.animatedImage == nil) {
                animatedImage = self.animatedImage(from: media!)
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
        if (type != .video && type != .animated) {
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
        if (type != .video && type != .animated) {
            return
        }

        if (type == .video && !shouldAllowPlayback && videoController.player?.currentItem != nil) {
            image = self.imageThumbnail(from: self.media!)
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
            cleanupView(type: .image)
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
    public func animatedImage(from url: URL) -> FLAnimatedImage {
        do {
            let image = try FLAnimatedImage(animatedGIFData: Data(contentsOf: url))
            return image!
        } catch {
            print("Unable to create animated image from URL", url)
            return FLAnimatedImage()
        }
    }

    ///
    // MARK: Static Image
    ///

    public var image: UIImage? {
        set {
            imageView.image = newValue
            cleanupView(type: .image)
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
    public func image(from path: String) -> UIImage {
        let image = UIImage(contentsOfFile: path)

        if (image == nil) {
            print("Unable to create image from path", path)
            return UIImage()
        }

        if (branded) {
            return image!.branded(landscape: overlayLandscape, portrait: overlayPortrait)
        }

        return image!
    }

    ///
    // MARK: Video
    ///

    public var player: AVPlayer? {
        set {
            videoController.player = newValue
            cleanupView(type: .video)
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
    public func imageThumbnail(from url: URL) -> UIImage {
        let video = AVURLAsset(url: url)
        let time = CMTimeMakeWithSeconds(thumbnailInSeconds, 60)
        let thumbGenerator = AVAssetImageGenerator(asset: video)
        thumbGenerator.appliesPreferredTrackTransform = true

        do {
            let thumbnail = try thumbGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: thumbnail)
        } catch {
            print("Unable to generate thumbnail from video", url.path)
            return UIImage()
        }
    }

}
