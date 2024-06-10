#
# Be sure to run `pod lib lint AppStoreVersionDetector.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AppStoreVersionDetector'
  s.version          = '1.0.0'
  s.summary          = 'Detect the app version from AppStore and support Objective-C.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Detect the app version from AppStore and support Objective-C.
                       DESC

  s.homepage         = 'https://github.com/itenfay/AppStoreVersionDetector'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tenfay' => 'hansen981@126.com' }
  s.source           = { :git => 'https://github.com/itenfay/AppStoreVersionDetector.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.swift_versions = ['4.2', '5.0']
  s.ios.deployment_target = '10.0'
  #s.osx.deployment_target = '10.9'
  #s.tvos.deployment_target = '9.0'
  
  s.source_files = 'AppStoreVersionDetector/Classes/**/*'
  
  s.requires_arc = true
  
  # s.resource_bundles = {
  #   'AppStoreVersionDetector' => ['AppStoreVersionDetector/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
