//
//  AVPlayerView.swift
//  KKPlayerViewController
//
//  Created by 131e55 on 2016/09/06.
//
//

import UIKit
import AVFoundation

internal class AVPlayerView: UIView {

    var player: AVPlayer? {

        get {

            return playerLayer.player
        }
        set {

            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer {

        return layer as! AVPlayerLayer
    }

    override static var layerClass: AnyClass {

        return AVPlayerLayer.self
    }
}
