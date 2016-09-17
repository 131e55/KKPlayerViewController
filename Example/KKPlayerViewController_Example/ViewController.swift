//
//  ViewController.swift
//  KKPlayerViewController
//
//  Created by 131e55 on 2016/08/23.
//  Copyright © 2016年 131e55. All rights reserved.
//

import UIKit
import KKPlayerViewController
import AVFoundation

class ViewController: UIViewController {

    let url = URL(string:"https://video.twimg.com/ext_tw_video/768701846240104449/pu/vid/720x1280/FW9MWNMhhdKfdygm.mp4")!

    var playerViewController: KKPlayerViewController {

        return self.childViewControllers.first as! KKPlayerViewController
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        self.playerViewController.delegate = self
        self.playerViewController.load(url: self.url)

        // Prepare for background playback or Picture in Picture
        let audioSession = AVAudioSession.sharedInstance()
        do {

            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
        }
        catch {}
    }
}

extension ViewController: KKPlayerViewControllerDelegate {

    public func playerViewController(_ playerViewController: KKPlayerViewController, didChangePlayerStatus status: PlayerStatus) {

        print(status)
    }

    func playerViewController(_ playerViewController: KKPlayerViewController, didChangePlaybackStatus status: PlaybackStatus) {

        print(status)
    }

    func playerViewControllerDidReadyForDisplay(_ playerViewController: KKPlayerViewController) {

        playerViewController.play()
    }
}
