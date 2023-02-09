# AppStoreVersionDetector

Detects the app version from AppStore.

[![CI Status](https://img.shields.io/travis/chenxing640/AppStoreVersionDetector.svg?style=flat)](https://travis-ci.org/chenxing640/AppStoreVersionDetector)
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
    case .success(let hasNew, _):
        print("hasNew: \(hasNew)")
        break
    case .failure(let message):
        print("message: \(message)")
        break
    }
}
```

- Open AppStore

```
AppStoreVDetector.openAppStore(with: "15674646463")
```


## Author

chenxing, chenxing640@foxmail.com


## License

AppStoreVersionDetector is available under the MIT license. See the LICENSE file for more info.
