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

    override func viewDidLoad() {
        super.viewDidLoad()

        galleryView.imageView.contentMode = .ScaleAspectFill
        galleryView.imageView.clipsToBounds = true

        self.loadGif()
    }

    @IBAction func loadImage() {
        let image = NSBundle.mainBundle().URLForResource("dinosaurs", withExtension: "jpg")!
        galleryView.loadMedia(image)
    }

    @IBAction func loadGif() {
        let gif = NSBundle.mainBundle().URLForResource("rock", withExtension: "gif")!
        galleryView.loadMedia(gif)
    }

    @IBAction func loadVideo() {
        let video = NSBundle.mainBundle().URLForResource("oceans", withExtension: "mp4")!
        galleryView.loadMedia(video)
        galleryView.videoController.player?.play()
    }

}
