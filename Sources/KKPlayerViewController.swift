//
//  KKPlayerViewController.swift
//  KKPlayerViewController
//
//  Created by Keisuke Kawamura a.k.a. 131e55 on 2016/08/23.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Keisuke Kawamura ( https://twitter.com/131e55 )
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import AVFoundation
import AVKit
import MediaPlayer

// MARK: Public enumerations

/// PlayerStatus is a wrapper of [AVPlayerStatus](https://developer.apple.com/reference/avfoundation/avplayerstatus).
@objc public enum PlayerStatus: Int, CustomStringConvertible {

    case unknown
    case readyToPlay
    case failed

    public var description: String {

        switch self {

        case .unknown:     return "unknown"
        case .readyToPlay: return "readyToPlay"
        case .failed:      return "failed"
        }
    }
}

/**
 PlaybackStatus indicates playback status of current item.
 
 unstarted: Not yet started playback or Not set any player item.

 playing: The current player item is playing.

 paused: The current player item is paused.
 
 ended: The current player item is ended.
 
 stalled: The player can not continue to playback because bufferred data is not enough.
*/
@objc public enum PlaybackStatus: Int, CustomStringConvertible {

    case unstarted
    case playing
    case paused
    case ended
    case stalled

    public var description: String {

        switch self {

        case .unstarted: return "unstarted"
        case .playing:   return "playing"
        case .paused:    return "paused"
        case .ended:     return "ended"
        case .stalled:   return "stalled"
        }
    }
}

// MARK: - Public KKPlayerViewControllerDelegate protocol

@objc public protocol KKPlayerViewControllerDelegate: AVPlayerViewControllerDelegate {

    func playerViewController(_ playerViewController: KKPlayerViewController, didChangePlayerStatus status: PlayerStatus)
    func playerViewController(_ playerViewController: KKPlayerViewController, didChangePlaybackStatus status: PlaybackStatus)
    func playerViewControllerDidReadyForDisplay(_ playerViewController: KKPlayerViewController)

    @objc optional func playerViewController(_ playerViewController: KKPlayerViewController, didChangeCurrentTime time: Double)
}

// MARK: - Public KKPlayerViewController class

open class KKPlayerViewController: UIViewController {

    // MARK: Public properties

    private(set) open var playerStatus: PlayerStatus = .unknown {

        didSet {

            if self.playerStatus != oldValue {

                DispatchQueue.main.async {

                    self.delegate?.playerViewController(self, didChangePlayerStatus: self.playerStatus)
                }
            }
        }
    }

    private(set) open var playbackStatus: PlaybackStatus = .unstarted {

        didSet {

            if self.playbackStatus != oldValue {

                DispatchQueue.main.async {

                    self.delegate?.playerViewController(self, didChangePlaybackStatus: self.playbackStatus)
                }
            }
        }
    }

    open var readyForDisplay: Bool {

        return self.playerView.playerLayer.isReadyForDisplay
    }

    open var videoRect: CGRect {

        return self.playerView.playerLayer.videoRect
    }

    open var videoGravity: String {

        get {

            return self.playerView.playerLayer.videoGravity
        }
        set {

            self.playerView.playerLayer.videoGravity = newValue
        }
    }

    open var videoNaturalSize: CGSize {

        let track = self.player?.currentItem?.asset.tracks(withMediaType: AVMediaTypeVideo).first

        return track?.naturalSize ?? CGSize.zero
    }

    open var duration: Double {

        let duration = CMTimeGetSeconds(self.player?.currentItem?.duration ?? kCMTimeZero)

        return duration.isFinite ? duration : 0
    }

    open var currentTime: Double {

        let currentTime = CMTimeGetSeconds(self.player?.currentTime() ?? kCMTimeZero)

        return currentTime.isFinite ? currentTime : 0
    }

    open var isMuted: Bool = false {

        didSet {

            self.player?.isMuted = self.isMuted
        }
    }

    open var volume: Float = 1.0 {

        didSet {

            self.player?.volume = self.volume
        }
    }

    /// Specifies whether the player automatically repeats if playback is ended.
    open var repeatPlayback: Bool = false

    open var allowsPictureInPicturePlayback = true

    open var minimumBufferDuration: Double = 5.0

    /// The interval of calling playerViewControllerDidChangeCurrentTime delegate method.
    /// Specify the value as milliseconds.
    open var intervalOfTimeObservation: Int = 500

    open weak var delegate: KKPlayerViewControllerDelegate?

    // MARK: Private properties

    private var asset: AVAsset?
    private var playerItem: AVPlayerItem?

    private var player: AVPlayer? {

        didSet {

            self.player?.isMuted = self.isMuted
            self.player?.volume = self.volume
        }
    }

    private var playerView: AVPlayerView {

        return self.view as! AVPlayerView
    }

    private var timeObserver: Any?

    private var _pictureInPictureController: AnyObject?
    @available(iOS 9.0, *)
    private var pictureInPictureController: AVPictureInPictureController? {

        get {

            return self._pictureInPictureController as? AVPictureInPictureController
        }
        set {

            self._pictureInPictureController = newValue
        }
    }

    private var observationContext = 0

    // MARK: Initialization methods

    public convenience init() {

        self.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        self.commonInit()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInit()
    }

    private func commonInit() {

        self.addApplicationNotificationObservers()
    }

    deinit {

        self.playerView.playerLayer.removeObserver(
            self,
            forKeyPath: playerLayerReadyForDisplayKey,
            context: &self.observationContext
        )

        self.clear()

        self.removeApplicationNotificationObservers()
    }

    // MARK: UIViewController

    open override func loadView() {

        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "\(type(of: self))", bundle: bundle)
        self.view = nib.instantiate(withOwner: self, options: nil).first as! AVPlayerView

        self.playerView.playerLayer.addObserver(
            self,
            forKeyPath: playerLayerReadyForDisplayKey,
            options: [.initial, .new],
            context: &self.observationContext
        )
    }

    // MARK: Public methods

    open func clear() {

        DispatchQueue.global().async {

            self.asset?.cancelLoading()
            self.asset = nil

            if let playerItem = self.playerItem {

                playerItem.cancelPendingSeeks()

                self.removeObservers(from: playerItem)
            }

            self.playerItem = nil

            if let player = self.player {

                player.cancelPendingPrerolls()

                self.removeObservers(from: player)
            }

            self.playerView.player = nil
            self.player = nil

            if #available(iOS 9.0, *) {

                self.pictureInPictureController = nil
            }

            self.playerStatus = .unknown
            self.playbackStatus = .unstarted
        }
    }

    open func load(url: URL) {

        self.clear()
        self.setupAsset(url: url)
    }

    open func play(from seconds: Double? = nil) {

        guard let player = self.player else {

            return
        }

        if let seconds = seconds {

            self.seek(to: seconds)
        }
        
        player.play()
    }

    open func pause() {

        guard let player = self.player else {

            return
        }

        player.pause()
    }

    open func seek(to seconds: Double) {

        guard let player = self.player else {

            return
        }

        let time = CMTimeMakeWithSeconds(seconds, 1)
        player.seek(to: time)
    }

    // MARK: Private methods

    private func setupAsset(url: URL) {

        DispatchQueue.global().async {

            self.asset = AVURLAsset(url: url, options: nil)

            let keys = ["playable", "duration"]

            self.asset!.loadValuesAsynchronously(
                forKeys: keys,
                completionHandler: { [weak self] in

                    guard let `self` = self, let asset = self.asset else {

                        return
                    }

                    var error: NSError?
                    let failed = keys.filter {

                        asset.statusOfValue(forKey: $0, error: &error) == .failed
                    }

                    guard failed.isEmpty else {

                        self.playerStatus = .failed
                        return
                    }

                    self.setupPlayerItem(asset: asset)
                }
            )
        }
    }

    private func setupPlayerItem(asset: AVAsset) {

        self.playerItem = AVPlayerItem(asset: asset)

        self.addObservers(to: self.playerItem!)

        self.setupPlayer(playerItem: self.playerItem!)
    }

    private func setupPlayer(playerItem: AVPlayerItem) {

        DispatchQueue.main.async {

            self.player = AVPlayer(playerItem: playerItem)

            self.addObservers(to: self.player!)

            self.playerView.player = self.player

            if #available(iOS 9.0, *) {

                self.setupPictureInPictureController(playerLayer: self.playerView.playerLayer)
            }
        }
    }

    @available (iOS 9.0, *)
    private func setupPictureInPictureController(playerLayer: AVPlayerLayer) {

        if AVPictureInPictureController.isPictureInPictureSupported() && self.allowsPictureInPicturePlayback {

            self.pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
        }
        else {


        }
    }

    // MARK: KVO

    private func addObservers(to playerItem: AVPlayerItem) {

        playerItem.addObserver(
            self,
            forKeyPath: playerItemLoadedTimeRangesKey,
            options: ([.initial, .new]),
            context: &self.observationContext
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.playerItemDidPlayToEndTime(_:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.playerItemPlaybackStalled(_:)),
            name: NSNotification.Name.AVPlayerItemPlaybackStalled,
            object: playerItem
        )
    }

    private func removeObservers(from playerItem: AVPlayerItem) {

        playerItem.removeObserver(
            self,
            forKeyPath: playerItemLoadedTimeRangesKey,
            context: &self.observationContext
        )

        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.AVPlayerItemPlaybackStalled,
            object: playerItem
        )
    }

    private func addObservers(to player: AVPlayer) {

        player.addObserver(
            self,
            forKeyPath: playerStatusKey,
            options: ([.initial, .new]),
            context: &self.observationContext
        )
        player.addObserver(
            self,
            forKeyPath: playerRateKey,
            options: ([.initial, .new]),
            context: &self.observationContext
        )

        let interval = CMTimeMake(1, 1000 / Int32(self.intervalOfTimeObservation))
        self.timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: DispatchQueue.main,
            using: { [weak self] time in

                guard let `self` = self else {

                    return
                }

                let currentTime = CMTimeGetSeconds(time)

                self.delegate?.playerViewController?(self, didChangeCurrentTime: currentTime)
            }
        )
    }

    private func removeObservers(from player: AVPlayer) {

        player.removeObserver(
            self,
            forKeyPath: playerStatusKey,
            context: &self.observationContext
        )
        player.removeObserver(
            self,
            forKeyPath: playerRateKey,
            context: &self.observationContext
        )
        
        player.removeTimeObserver(self.timeObserver!)
        self.timeObserver = nil
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        guard context == &self.observationContext else {

            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        guard let keyPath = keyPath else {

            fatalError()
        }

        switch keyPath {

        case playerItemLoadedTimeRangesKey:

            guard let playerItem = object as? AVPlayerItem,
                self.playerItem == playerItem else {

                    fatalError()
            }

            if let timeRange = playerItem.loadedTimeRanges.first?.timeRangeValue {

                let duration = CMTimeGetSeconds(timeRange.duration)

                if self.playbackStatus == .stalled
                    && duration >= self.minimumBufferDuration {

                    self.play()
                }
            }

        case playerStatusKey:

            guard let player = object as? AVPlayer,
                self.player == player else {

                    fatalError()
            }

            self.playerStatus = PlayerStatus(rawValue: player.status.rawValue)!

        case playerRateKey:

            guard let player = object as? AVPlayer,
                let currentItem = player.currentItem,
                self.player == player else {

                    fatalError()
            }

            if fabs(player.rate) > 0 {

                self.playbackStatus = .playing
            }
            else if self.playbackStatus != .unstarted {

                if !currentItem.isPlaybackLikelyToKeepUp {

                    // Do nothing. PlaybackStatus will be Stalled.
                }
                else if player.currentTime() < currentItem.duration {

                    self.playbackStatus = .paused
                }
                else {

                    // Do nothing. PlaybackStatus will be Ended.
                }
            }
            
        case playerLayerReadyForDisplayKey:

            guard let playerLayer = object as? AVPlayerLayer,
                self.playerView.playerLayer == playerLayer else {

                    fatalError()
            }

            if playerLayer.isReadyForDisplay {

                self.delegate?.playerViewControllerDidReadyForDisplay(self)
            }

        default:
            
            fatalError()
        }
    }

    // MARK: AVPlayerItem notifications

    open func playerItemDidPlayToEndTime(_ notification: Notification) {

        self.playbackStatus = .ended

        if self.repeatPlayback {

            self.play(from: 0)
        }
    }

    open func playerItemPlaybackStalled(_ notification: Notification) {

        self.playbackStatus = .stalled
    }

    // MARK: UIApplication notifications

    private func addApplicationNotificationObservers() {

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(_:)),
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground(_:)),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
    }

    private func removeApplicationNotificationObservers() {

        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
    }

    func applicationDidEnterBackground(_ notification: Notification) {

        func remove() {

            self.playerView.player = nil
        }

        if #available(iOS 9.0, *) {

            if AVPictureInPictureController.isPictureInPictureSupported()
                && self.allowsPictureInPicturePlayback {

                // Do nothing. Keep the reference from AVPlayerViewController for Picture in Picture.
            }
            else {

                remove()
            }
        }
        else {

            remove()
        }
    }

    func applicationWillEnterForeground(_ notification: Notification) {

        // Refer again for case of background playback
        self.playerView.player = self.player
    }
}

// MARK: Private KVO keys

private let playerItemLoadedTimeRangesKey = "loadedTimeRanges"
private let playerStatusKey = "status"
private let playerRateKey = "rate"
private let playerLayerReadyForDisplayKey = "readyForDisplay"
