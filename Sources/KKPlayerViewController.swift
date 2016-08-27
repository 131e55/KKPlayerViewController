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

// MARK: Public enumerations

@objc public enum PlayerStatus: Int, CustomStringConvertible {

    case Unknown
    case ReadyToPlay
    case Failed

    public var description: String {

        switch self {

        case .Unknown:     return "Unknown"
        case .ReadyToPlay: return "ReadyToPlay"
        case .Failed:      return "Failed"
        }
    }
}

@objc public enum PlaybackStatus: Int, CustomStringConvertible {

    case Unstarted
    case Playing
    case Paused
    case Ended
    case Stalled

    public var description: String {

        switch self {

        case .Unstarted: return "Unstarted"
        case .Playing:   return "Playing"
        case .Paused:    return "Paused"
        case .Ended:     return "Ended"
        case .Stalled:   return "Stalled"
        }
    }
}

// MARK: - Public KKPlayerViewControllerDelegate protocol

@objc public protocol KKPlayerViewControllerDelegate: AVPlayerViewControllerDelegate {

    func playerViewControllerDidChangePlayerStatus(playerViewController: KKPlayerViewController, status: PlayerStatus)
    func playerViewControllerDidChangePlaybackStatus(playerViewController: KKPlayerViewController, status: PlaybackStatus)
    func playerViewControllerDidReadyForDisplay(playerViewController: KKPlayerViewController)

    optional func playerViewControllerDidChangeCurrentTime(playerViewController: KKPlayerViewController, currentTime: Double)
}

// MARK: - Public KKPlayerViewController class

public class KKPlayerViewController: UIViewController {

    // MARK: Public properties

    private(set) public var playerStatus: PlayerStatus = .Unknown {

        didSet {

            if self.playerStatus != oldValue {

                self.delegate?.playerViewControllerDidChangePlayerStatus(self, status: playerStatus)
            }
        }
    }

    private(set) public var playbackStatus: PlaybackStatus = .Unstarted {

        didSet {

            if self.playbackStatus != oldValue {

                self.delegate?.playerViewControllerDidChangePlaybackStatus(self, status: playbackStatus)
            }
        }
    }

    public var showsPlaybackControls: Bool {

        get {

            return self.avPlayerViewController.showsPlaybackControls
        }
        set {

            self.avPlayerViewController.showsPlaybackControls = newValue
        }
    }

    @available(iOS 9.0, *)
    public var allowsPictureInPicturePlayback: Bool {

        get {

            return self.avPlayerViewController.allowsPictureInPicturePlayback
        }
        set {

            self.avPlayerViewController.allowsPictureInPicturePlayback = newValue
        }
    }

    public var contentOverlayView: UIView? {

        return self.avPlayerViewController.contentOverlayView
    }

    public var readyForDisplay: Bool {

        return self.avPlayerViewController.readyForDisplay
    }

    public var videoBounds: CGRect {

        return self.avPlayerViewController.videoBounds
    }

    public var videoGravity: String {

        get {

            return self.avPlayerViewController.videoGravity
        }
        set {

            self.avPlayerViewController.videoGravity = newValue
        }
    }

    public var backgroundColor: UIColor = UIColor.blackColor() {

        didSet {
            self.view.backgroundColor = self.backgroundColor
            self.avPlayerViewController.view.backgroundColor = self.backgroundColor
        }
    }

    public var videoNaturalSize: CGSize {

        return self.player?.currentItem?.asset
            .tracksWithMediaType(AVMediaTypeVideo).first?.naturalSize ?? CGSizeZero
    }

    public var duration: Double {

        return CMTimeGetSeconds(self.player?.currentItem?.duration ?? kCMTimeZero)
    }

    public var currentTime: Double {

        return CMTimeGetSeconds(self.player?.currentTime() ?? kCMTimeZero)
    }

    public var muted: Bool = false {

        didSet {

            self.player?.muted = self.muted
        }
    }

    public var volume: Float = 1.0 {

        didSet {

            self.player?.volume = self.volume
        }
    }

    public var minimumBufferDuration: Double = 5.0

    /// The interval of calling playerViewControllerDidChangeCurrentTime delegate method.
    /// Specify the value as milliseconds.
    public var intervalOfTimeObservation: Int = 500

    public weak var delegate: KKPlayerViewControllerDelegate? {

        didSet {

            if #available(iOS 9.0, *) {

                self.avPlayerViewController.delegate = self.delegate
            }
        }
    }

    // MARK: Private properties

    private var avPlayerViewController = AVPlayerViewController()
    private var asset: AVAsset?
    private var playerItem: AVPlayerItem?

    // AVPlayerViewController.player paused by AVPlayerViewController when going into the background.
    // So, on the background, remove the reference from AVPlayerViewController.
    private var player: AVPlayer? {

        didSet {

            self.player?.muted = self.muted
            self.player?.volume = self.volume
        }
    }

    private var timeObserver: AnyObject?

    // MARK: Initialization methods

    public convenience init() {

        self.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        self.commonInit()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInit()
    }

    private func commonInit() {

        self.avPlayerViewController.addObserver(
            self,
            forKeyPath: avPlayerViewControllerReadyForDisplayKey,
            options: [.New],
            context: &kkPlayerViewControllerObservationContext
        )

        self.addApplicationNotificationObservers()

        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }

    deinit {

        self.avPlayerViewController.removeObserver(
            self,
            forKeyPath: avPlayerViewControllerReadyForDisplayKey,
            context: &kkPlayerViewControllerObservationContext
        )

        self.clear()

        self.removeApplicationNotificationObservers()

        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
    }

    // MARK: UIViewController

    public override func loadView() {

        self.view = UIView()

        self.avPlayerViewController.showsPlaybackControls = false
        self.avPlayerViewController.view.frame = self.view.bounds
        self.addChildViewController(self.avPlayerViewController)
        self.view.addSubview(self.avPlayerViewController.view)
        self.avPlayerViewController.didMoveToParentViewController(self)

        self.backgroundColor = UIColor.blackColor()
    }

    // MARK: Public methods

    public func clear() {

        self.asset?.cancelLoading()
        self.asset = nil

        if let playerItem = self.playerItem {

            playerItem.cancelPendingSeeks()

            self.removePlayerItemObservers(playerItem)
        }

        self.playerItem = nil

        if let player = self.player {

            player.cancelPendingPrerolls()

            self.removePlayerObservers(player)
        }

        self.player = nil
        self.avPlayerViewController.player = nil

        self.playerStatus = .Unknown
        self.playbackStatus = .Unstarted
    }

    public func setup(url: NSURL) {

        self.clear()
        self.setupAsset(url)
    }

    public func play() {

        guard let player = self.player else {

            return
        }
        
        player.play()
    }

    public func pause() {

        guard let player = self.player else {

            return
        }

        player.pause()
    }

    public func seek(to seconds: Double) {

        guard let player = self.player else {

            return
        }

        let time = CMTime(
            seconds: seconds,
            preferredTimescale: Int32(NSEC_PER_SEC)
        )
        player.seekToTime(time)
    }

    // MARK: Private methods

    private func setupAsset(url: NSURL) {

        self.asset = AVURLAsset(URL: url, options: nil)

        let keys = ["playable", "duration", "tracks"]

        self.asset!.loadValuesAsynchronouslyForKeys(
            keys,
            completionHandler: { [weak self] in

                guard let `self` = self, asset = self.asset else {

                    return
                }

                var error: NSError?
                let failed = keys.filter {

                    asset.statusOfValueForKey($0, error: &error) == .Failed
                }

                guard failed.isEmpty else {

                    self.playerStatus = .Failed
                    return
                }

                self.setupPlayerItem(asset)
            }
        )
    }

    private func setupPlayerItem(asset: AVAsset) {

        self.playerItem = AVPlayerItem(asset: asset)

        self.addPlayerItemObservers(self.playerItem!)

        self.setupPlayer(self.playerItem!)
    }

    private func addPlayerItemObservers(playerItem: AVPlayerItem) {

        playerItem.addObserver(
            self,
            forKeyPath: playerItemLoadedTimeRangesKey,
            options: ([.New]),
            context: &kkPlayerViewControllerObservationContext
        )

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTime(_:)),
            name: AVPlayerItemDidPlayToEndTimeNotification,
            object: playerItem
        )
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(playerItemPlaybackStalled(_:)),
            name: AVPlayerItemPlaybackStalledNotification,
            object: playerItem
        )
    }

    private func removePlayerItemObservers(playerItem: AVPlayerItem) {

        playerItem.removeObserver(
            self,
            forKeyPath: playerItemLoadedTimeRangesKey,
            context: &kkPlayerViewControllerObservationContext
        )

        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: AVPlayerItemDidPlayToEndTimeNotification,
            object: playerItem
        )
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: AVPlayerItemPlaybackStalledNotification,
            object: playerItem
        )
    }

    private func setupPlayer(playerItem: AVPlayerItem) {

        self.player = AVPlayer()
        self.avPlayerViewController.player = self.player

        self.addPlayerObservers(self.player!)

        self.player!.replaceCurrentItemWithPlayerItem(playerItem)
    }

    private func addPlayerObservers(player: AVPlayer) {

        player.addObserver(
            self,
            forKeyPath: playerStatusKey,
            options: ([.New]),
            context: &kkPlayerViewControllerObservationContext
        )
        player.addObserver(
            self,
            forKeyPath: playerRateKey,
            options: ([.New]),
            context: &kkPlayerViewControllerObservationContext
        )

        let interval = CMTimeMake(1, 1000 / Int32(self.intervalOfTimeObservation))
        self.timeObserver = player.addPeriodicTimeObserverForInterval(
            interval,
            queue: dispatch_get_main_queue(),
            usingBlock: { [weak self] time in

                guard let `self` = self else {

                    return
                }

                let currentTime = CMTimeGetSeconds(time)
                self.delegate?.playerViewControllerDidChangeCurrentTime?(self, currentTime: currentTime)
            }
        )
    }

    private func removePlayerObservers(player: AVPlayer) {

        player.removeObserver(
            self,
            forKeyPath: playerStatusKey,
            context: &kkPlayerViewControllerObservationContext
        )
        player.removeObserver(
            self,
            forKeyPath: playerRateKey,
            context: &kkPlayerViewControllerObservationContext
        )

        player.removeTimeObserver(self.timeObserver!)
        self.timeObserver = nil
    }

    // MARK: KVO

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        guard context == &kkPlayerViewControllerObservationContext else {

            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }

        guard let keyPath = keyPath else {

            fatalError()
        }

        switch keyPath {

        case playerItemLoadedTimeRangesKey:

            guard let playerItem = object as? AVPlayerItem
                where self.playerItem == playerItem else {

                fatalError()
            }

            if let timeRange = playerItem.loadedTimeRanges.first?.CMTimeRangeValue {

                let duration = CMTimeGetSeconds(timeRange.duration)

                if self.playbackStatus == .Stalled
                    && duration >= self.minimumBufferDuration {

                    self.play()
                }
            }

        case playerStatusKey:

            guard let player = object as? AVPlayer
                where self.player == player else {

                fatalError()
            }

            self.playerStatus = PlayerStatus(rawValue: player.status.rawValue)!

        case playerRateKey:

            guard let player = object as? AVPlayer,
                let currentItem = player.currentItem
                where self.player == player else {

                fatalError()
            }

            if fabs(player.rate) > 0 {

                self.playbackStatus = .Playing
            }
            else if self.playbackStatus != .Unstarted {

                if !currentItem.playbackLikelyToKeepUp {

                    // Do nothing. PlaybackStatus will be Stalled.
                }
                else if player.currentTime() < currentItem.duration {

                    self.playbackStatus = .Paused
                }
                else {

                    // Do nothing. PlaybackStatus will be Ended.
                }
            }
            
        case avPlayerViewControllerReadyForDisplayKey:
            
            guard let avPlayerViewController = object as? AVPlayerViewController
                where self.avPlayerViewController == avPlayerViewController else {

                fatalError()
            }
            
            if avPlayerViewController.readyForDisplay {
                
                self.delegate?.playerViewControllerDidReadyForDisplay(self)
            }
            
        default:
            
            fatalError()
        }
    }

    // MARK: AVPlayerItem notifications

    public func playerItemDidPlayToEndTime(notification: NSNotification) {

        self.playbackStatus = .Ended
    }

    public func playerItemPlaybackStalled(notification: NSNotification) {

        self.playbackStatus = .Stalled
    }

    // MARK: UIApplication notifications

    private func addApplicationNotificationObservers() {

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(_:)),
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil
        )
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(applicationWillEnterForeground(_:)),
            name: UIApplicationWillEnterForegroundNotification,
            object: nil
        )
    }

    private func removeApplicationNotificationObservers() {

        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil
        )
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIApplicationWillEnterForegroundNotification,
            object: nil
        )
    }

    func applicationDidEnterBackground(notification: NSNotification) {

        func remove() {

            // Remove the reference from AVPlayerViewController for background playback
            self.avPlayerViewController.player = nil
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

    func applicationWillEnterForeground(notification: NSNotification) {

        // Refer again for case of background playback
        self.avPlayerViewController.player = self.player
    }

    // MARK: Remote control

    override public func remoteControlReceivedWithEvent(event: UIEvent?) {

        guard let event = event
            where event.type == .RemoteControl else {

            return
        }

        switch event.subtype {

        case .RemoteControlPause,
             .RemoteControlPlay,
             .RemoteControlTogglePlayPause:

            guard let player = self.player else {

                return
            }

            if playbackStatus == .Playing {

                player.pause()
            }
            else if playbackStatus == .Paused {

                player.play()
            }
            
        default:
            
            break
        }
    }
}

// MARK: Private KVO keys

private var kkPlayerViewControllerObservationContext = 0
private let playerItemLoadedTimeRangesKey = "loadedTimeRanges"
private let playerStatusKey = "status"
private let playerRateKey = "rate"
private let avPlayerViewControllerReadyForDisplayKey = "readyForDisplay"
