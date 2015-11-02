//
//  ViewController.swift
//  PRGalleryView
//
//  Created by Albert Martin on 9/25/15.
//  Copyright © 2015 Albert Martin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var galleryView: PRGalleryView!
    @IBOutlet weak var playPause: RSPlayPauseButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        galleryView.imageView.contentMode = .ScaleAspectFill
        galleryView.imageView.clipsToBounds = true

        playPause.addTarget(self, action: "togglePlayback:", forControlEvents: .TouchUpInside)

        self.loadGif()
    }

    @IBAction func loadImage() {
        let image = NSBundle.mainBundle().URLForResource("dinosaurs", withExtension: "jpg")!
        galleryView.media = image

        showPlaybackButton()
    }

    @IBAction func loadGif() {
        let gif = NSBundle.mainBundle().URLForResource("rock", withExtension: "gif")!
        galleryView.media = gif

        showPlaybackButton()
    }

    @IBAction func loadVideo() {
        let video = NSBundle.mainBundle().URLForResource("oceans", withExtension: "mp4")!
        galleryView.media = video
        galleryView.videoController.player?.play()

        showPlaybackButton()
    }

    func showPlaybackButton() {
        playPause.alpha = CGFloat(galleryView.type == .Video || galleryView.type == .Animated)
        playPause.paused = false
    }

    func togglePlayback(playPauseButton: RSPlayPauseButton) {
        if (playPause.paused) {
            galleryView.play()
        } else {
            galleryView.pause()
        }

        playPause.setPaused(!playPause.paused, animated: true)
    }

}
