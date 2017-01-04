//
//  ViewController.swift
//  PRGalleryView
//
//  Created by Albert Martin on 9/25/15.
//  Copyright © 2015 Albert Martin. All rights reserved.
//

import UIKit
import PRGalleryView
import RSPlayPauseButton

class ViewController: UIViewController {

    @IBOutlet weak var galleryView: PRGalleryView!
    @IBOutlet weak var playPause: RSPlayPauseButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        galleryView.imageView.contentMode = .scaleAspectFill
        galleryView.imageView.clipsToBounds = true

        playPause.addTarget(self, action: #selector(ViewController.togglePlayback(_:)), for: .touchUpInside)

        self.loadGif()
    }

    @IBAction func loadImage() {
        let image = Bundle.main.url(forResource: "dinosaurs", withExtension: "jpg")!
        galleryView.media = image

        showPlaybackButton()
    }

    @IBAction func loadGif() {
        let gif = Bundle.main.url(forResource: "rock", withExtension: "gif")!
        galleryView.media = gif

        showPlaybackButton()
    }

    @IBAction func loadVideo() {
        let video = Bundle.main.url(forResource: "oceans", withExtension: "mp4")!
        galleryView.media = video
        galleryView.videoController.player?.play()

        showPlaybackButton()
    }

    func showPlaybackButton() {
        playPause.alpha = CGFloat(NSNumber(value: galleryView.type == .video || galleryView.type == .animated))
        playPause.isPaused = false
    }

    func togglePlayback(_ playPauseButton: RSPlayPauseButton) {
        if (playPause.isPaused) {
            galleryView.play()
        } else {
            galleryView.pause()
        }

        playPause.setPaused(!playPause.isPaused, animated: true)
    }

}
