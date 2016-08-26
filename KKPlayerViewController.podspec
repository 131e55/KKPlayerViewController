#
# Be sure to run `pod lib lint KKPlayerViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KKPlayerViewController'
  s.version          = '0.1'
  s.summary          = 'A video player library written in Swift for easier and more convenient to use AVPlayerViewController'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                       KKPlayerViewController is a video player library for easier and more convenient to use AVPlayerViewController.
                       - Simple API
                       - Load video data asynchronously
                       - Easily manage playback status
                       - Background playback
                       - AVPlayerViewController features
                       ----- System playback controls
                       ----- Picture in Picture (iPad, iOS 9.0+)
                       - And more
                       DESC

  s.homepage         = 'https://github.com/131e55/KKPlayerViewController'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Keisuke Kawamura' => '' }
  s.source           = { :git => 'https://github.com/131e55/KKPlayerViewController.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/131e55'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Sources/**/*.swift'

  # s.resource_bundles = {
  #   'KKPlayerViewController' => ['KKPlayerViewController/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
