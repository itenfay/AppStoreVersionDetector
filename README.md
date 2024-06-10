# AppStoreVersionDetector

Detect the app version from AppStore and support Objective-C.

[![CI Status](https://img.shields.io/travis/itenfay/AppStoreVersionDetector.svg?style=flat)](https://travis-ci.org/itenfay/AppStoreVersionDetector)
[![Version](https://img.shields.io/cocoapods/v/AppStoreVersionDetector.svg?style=flat)](https://cocoapods.org/pods/AppStoreVersionDetector)
[![License](https://img.shields.io/cocoapods/l/AppStoreVersionDetector.svg?style=flat)](https://cocoapods.org/pods/AppStoreVersionDetector)
[![Platform](https://img.shields.io/cocoapods/p/AppStoreVersionDetector.svg?style=flat)](https://cocoapods.org/pods/AppStoreVersionDetector)


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

AppStoreVersionDetector is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AppStoreVersionDetector'
```


## Usage

- Detect the app version

```
AppStoreVDetector.default.onDetect(id: "15674646463", delayToExecute: 5) { result in
    switch result {
    case .success(let hasNewVersion, let response):
        print("hasNewVersion: \(hasNewVersion), response: \(response ?? [:])")
        break
    case .failure(let message):
        print("message: \(message)")
        break
    }
}
```

- Go to AppStore

```
AppStoreVDetector.default.toAppStore(withAppId: "15674646463")
```

- Go AppStore to write the review.

```
AppStoreVDetector.default.toWriteReview(withAppId: "15674646463")
```

To learn the usage in Objective-C, please view the file(VersionDetectObjcInvokeSample.m) in this project.


## License

AppStoreVersionDetector is available under the MIT license. See the LICENSE file for more info.
