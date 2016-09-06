//
//  KKPlayerView.swift
//  Pods
//
//  Created by 131e55 on 2016/09/06.
//
//

import UIKit
import AVFoundation

internal class KKPlayerView: UIView {

    var player: AVPlayer? {

        get {

            return playerLayer.player
        }
        set {

            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer {

        return self.layer as! AVPlayerLayer
    }

    override class func layerClass() -> AnyClass {

        return AVPlayerLayer.self
    }
}
