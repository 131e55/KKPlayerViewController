//
//  ViewController.swift
//  KKPlayerViewController
//
//  Created by 131e55 on 2016/08/23.
//  Copyright © 2016年 131e55. All rights reserved.
//

import UIKit
import KKPlayerViewController

class ViewController: UIViewController {

    let url = NSURL(string: "https://video.twimg.com/ext_tw_video/768701846240104449/pu/vid/720x1280/FW9MWNMhhdKfdygm.mp4")!

    override func viewDidLoad() {

        super.viewDidLoad()

        let playerViewController = self.childViewControllers.first as! KKPlayerViewController
        playerViewController.delegate = self
        playerViewController.setup(self.url)
    }
}

extension ViewController: KKPlayerViewControllerDelegate {

    func playerViewControllerDidChangePlayerStatus(playerViewController: KKPlayerViewController, status: PlayerStatus) {

        print(status)
    }

    func playerViewControllerDidChangePlaybackStatus(playerViewController: KKPlayerViewController, status: PlaybackStatus) {

        print(status)
    }

    func playerViewControllerDidReadyForDisplay(playerViewController: KKPlayerViewController) {

        playerViewController.play()
        playerViewController.showsPlaybackControls = true
    }
}
