# KKPlayerViewController

KKPlayerViewController is a video player library written in Swift 3 for easier and more convenient to use AVPlayer.
Support background playback and Picture in Picture.

## :sunny: Features

- Simple API
- Load video data asynchronously
- Easily manage playback status
- Background playback
- Picture in Picture (iPad, iOS 9.0+)
- And more

## :book: Usage

1. Create KKPlayerViewController instance.
2. Add as container view to your view controller. (More info: [View Controller Programming Guide for iOS](https://developer.apple.com/library/ios/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html#//apple_ref/doc/uid/TP40007457-CH11-SW1))
3. Implement KKPlayerViewControllerDelegate.
4. Load video.
5. If ready for display, play a video.

```swift
class ViewController: UIViewController {

    let url = URL(string:"https://video.twimg.com/ext_tw_video/768701846240104449/pu/vid/720x1280/FW9MWNMhhdKfdygm.mp4")!

    var playerViewController: KKPlayerViewController!

    // viewDidLoad() is an example.
    override func viewDidLoad() {

        super.viewDidLoad()

        // 1.
        self.playerViewController = KKPlayerViewController()

        // 2.
        self.addChildViewController(self.playerViewController)
        self.playerViewController.view.frame = self.view.bounds
        self.view.addSubview(self.playerViewController.view)
        self.playerViewController.didMove(toParentViewController: self)

        // 3.
        self.playerViewController.delegate = self

        // 4.
        self.playerViewController.load(url: url)
    }
}

extension ViewController: KKPlayerViewControllerDelegate {
    func playerViewController(_ playerViewController: KKPlayerViewController, didChangePlayerStatus status: PlayerStatus) {

    }

    func playerViewController(_ playerViewController: KKPlayerViewController, didChangePlaybackStatus status: PlaybackStatus) {

    }

    func playerViewControllerDidReadyForDisplay(_ playerViewController: KKPlayerViewController) {
        // 5.
        playerViewController.play()
    }
}
```

## :cd: Installation

### CocoaPods

KKPlayerViewController is available through [CocoaPods](http://cocoapods.org).

```ruby
platform :ios, '8.0'
use_frameworks!

target 'YOUR_TARGET_NAME' do
  pod 'KKPlayerViewController'
end
```

## :cat: Author

:jp: Keisuke Kawamura, [@131e55](https://twitter.com/131e55)

## :page_facing_up: License

KKPlayerViewController is available under the MIT license. See the LICENSE file for more info.
