//
//  AppStoreVersionDetector.swift
//  AppStoreVersionDetector
//
//  Created by chenxing on 2021/7/20.
//

import UIKit

/// Define the alias for the `AppStoreVersionDetector` class.
public typealias AppStoreVDetector = AppStoreVersionDetector

/// Detect the online version from AppStore.
final public class AppStoreVersionDetector: NSObject {
    
    public static let `default` = AppStoreVersionDetector()
    
    @objc public class func defaultDetector() -> AppStoreVersionDetector {
        return Self.default
    }
    
    private override init() {
        super.init()
    }
    
    public enum Result {
        case success(Bool, [String : String]?)
        case failure(String)
    }
    
    /// The app's id.
    @objc public private(set) var appId: String = ""
    /// Whether to has the new version.
    @objc public private(set) var hasNewVersion: Bool = false
    /// Whether to allow to present the alert controller.
    @objc public var alertAllowed: Bool = true
    
    /// Callback the result for the detecting.
    private var completionHandler: ((Result) -> Void)?
    private var successBlock: ((Bool, [String : String]?) -> Void)?
    private var failureBlock: ((String) -> Void)?
    
    /// Detect the version only in your app.
    ///
    /// - Parameters:
    ///   - id: The app's id.
    ///   - delay: The timeinterval delay to execute.
    ///   - completionHandler: Callback the result for the detecting.
    public func onDetect(
        id: String,
        delayToExecute delay: TimeInterval = 0,
        completionHandler: ((Result) -> Void)? = nil)
    {
        self.appId = id
        self.completionHandler = completionHandler
        self.prepareToDetect(withDelay: delay)
    }
    
    /// Detect the version only in your app.
    ///
    /// - Parameters:
    ///   - id: The app's id.
    ///   - delay: The timeinterval delay to execute.
    ///   - success: Callback the result for success.
    ///   - failure: Callback the error information for failure.
    @objc public func onDetect(
        id: String,
        delayToExecute delay: TimeInterval = 0,
        success: @escaping (Bool, [String : String]?) -> Void,
        failure: @escaping (String) -> Void)
    {
        self.appId = id
        self.successBlock = success
        self.failureBlock = failure
        self.prepareToDetect(withDelay: delay)
    }
    
    private func prepareToDetect(withDelay delay: TimeInterval) {
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.startDetecting()
            }
        } else {
            self.startDetecting()
        }
    }
    
    private func startDetecting() {
        DispatchQueue.global(qos: .default).async {
            self.onFetchData()
        }
    }
    
    /// Fetch the data from the iTunes.
    private func onFetchData() {
        //do {
        //    let itsUrl = "https://itunes.apple.com/lookup?id=" + appId
        //    let url = URL.init(string: itsUrl)!
        //    let data = try Data.init(contentsOf: url)
        //    self.onParse(with: data)
        //} catch let error {
        //    debugPrint("[VD] FetchData error: \(error)")
        //}
        /// iTunes link: "https://itunes.apple.com/lookup?id=xxx"
        let itsUrl = "https://itunes.apple.com/lookup?id=" + appId
        guard let url = URL.init(string: itsUrl) else {
            debugPrint("[VD] FetchData: url is null.")
            self.completionHandler?(Result.failure("The requested url is null."))
            self.failureBlock?("The requested url is null.")
            return
        }
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            //debugPrint("[VD] FetchData response: \(String(describing: response))")
            guard let _error = error else {
                if let _data = data {
                    self?.onParse(with: _data)
                } else {
                    debugPrint("[VD] FetchData: data is null.")
                    self?.completionHandler?(Result.failure("The response data is null."))
                    self?.failureBlock?("The response data is null.")
                }
                return
            }
            debugPrint("[VD] FetchData: error=\(_error.localizedDescription)")
            self?.completionHandler?(Result.failure(_error.localizedDescription))
            self?.failureBlock?(_error.localizedDescription)
        }
        dataTask.resume()
    }
    
    /// Parse the data, and detect the bundle identifier, and compare the version, then judge to update.
    private func onParse(with jsonData: Data) {
        do {
            let jObject = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            //debugPrint("[VD] Parse jObject: \(jObject)")
            guard let dict = jObject as? NSDictionary,
                  let results = dict["results"] as? NSArray,
                  let subDict = results.firstObject as? NSDictionary
            else {
                self.completionHandler?(Result.failure("It cannot unable to parse the response data."))
                self.failureBlock?("It cannot unable to parse the response data.")
                return
            }
            
            //"bundleId" = "....";
            //"version" = "1.2.16"
            //"releaseNotes" = "..."
            //"releaseDate": "2021-04-26T07:00:00Z",
            //"currentVersionReleaseDate": "2022-01-26T18:25:02Z"
            let localBundleId = Bundle.main.bundleIdentifier ?? ""
            let onlineBundleId = "\(subDict["bundleId"] ?? "")"
            debugPrint("[VD] Local BID: \(localBundleId), Online BID: \(onlineBundleId)")
            if localBundleId != onlineBundleId {
                self.completionHandler?(Result.failure("The local and online bundle identifier is not same."))
                self.failureBlock?("The local and online bundle identifier is not same.")
                return
            }
            let version = "\(subDict["version"] ?? "")"
            let compResult = self.compare(withOnlineVersion: version)
            if compResult == .orderedAscending {
                debugPrint("[VD] The online version is greater than the local.")
                let releaseNotes = "\(subDict["releaseNotes"] ?? "")"
                let vReleaseDate = "\(subDict["currentVersionReleaseDate"] ?? "")"
                debugPrint("[VD] date: \(vReleaseDate)")
                
                let dateFormatter = DateFormatter.init()
                dateFormatter.timeZone = NSTimeZone.init(name: "UTC")! as TimeZone
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                var releaseDate = ""
                if let _releaseDate = dateFormatter.date(from: vReleaseDate) {
                    let dateFormatter = DateFormatter.init()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    releaseDate = dateFormatter.string(from: _releaseDate)
                }
                debugPrint("[VD] releaseDate: \(releaseDate)")
                
                DispatchQueue.main.async {
                    self.hasNewVersion = true
                    let updatedInfo = ["version" : version, "releaseDate" : releaseDate, "releaseNotes" : releaseNotes]
                    self.completionHandler?(Result.success(true, updatedInfo))
                    self.successBlock?(true, updatedInfo)
                    if !self.alertAllowed { return }
                    let app = UIApplication.shared
                    let message = "版本号：\(version)\n" + "更新时间：\n\(releaseDate)\n" + "\n更新说明：\n\(releaseNotes)"
                    let alertController = app.vd_makeAlertController(title: "发现新版本，是否前往更新？", message: message, alignment: .left, cancelTitle: "下次再说", defaultTitle: "立即更新") { _ in
                        let vDetector = AppStoreVersionDetector.default
                        vDetector.toAppStore(withAppId: vDetector.appId)
                    }
                    app.vd_queryCurrentController?.present(alertController, animated: true)
                }
            } else if compResult == .orderedSame {
                debugPrint("[VD] The local version is equal to the online.")
                self.completionHandler?(Result.success(false, nil))
                self.successBlock?(false, nil)
            } else {
                debugPrint("[VD] The local version is greater than the online.")
                self.completionHandler?(Result.success(false, nil))
                self.successBlock?(false, nil)
            }
        } catch let error {
            debugPrint("[VD] Parse error: \(error)")
            self.completionHandler?(Result.failure(error.localizedDescription))
            self.failureBlock?(error.localizedDescription)
        }
    }
    
    /// Go to AppStore by the open url.
    ///
    /// - Parameter id: The app's identifier.
    @objc public func toAppStore(withAppId appId: String) {
        //"https://apps.apple.com/cn/app/id\(appId)?mt=8"
        let appUrl = "itms-apps://itunes.apple.com/app/id\(appId)?mt=8"
        guard let url = URL.init(string: appUrl) else {
            debugPrint("[VD] toAppStore: url is null.")
            return
        }
        //if UIApplication.shared.canOpenURL(url) {}
        self.openUrl(url)
    }
    
    /// Go AppStore to write the review.
    ///
    /// - Parameter appId: The app's identifier.
    @objc public func toWriteReview(withAppId appId: String) {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review")
        else {
            debugPrint("[VD] toWriteReview: url is null.")
            return
        }
        self.openUrl(url)
    }
    
    /// Attempts to asynchronously open the resource at the specified URL.
    ///
    /// - Parameters:
    ///   - url: A URL (Universal Resource Locator).
    ///   - completion: The block to execute with the results. Provide a value for this parameter if you want to be informed of the success or failure of opening the URL.
    @objc public func openUrl(_ url: URL, completionHandler completion: ((Bool) -> Void)? = nil) {
        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }
    
    /// Compare with the local and online version, then return the comparison result.
    @objc public func compare(withOnlineVersion onlineVersion: String) -> ComparisonResult {
        let infoDictionary = Bundle.main.infoDictionary!
        let majorVersion = infoDictionary["CFBundleShortVersionString"] as! String
        let appVerNums = majorVersion.components(separatedBy: ".")
        let onlineVerNums = onlineVersion.components(separatedBy: ".")
        
        for (i, e) in appVerNums.enumerated() {
            let appNum = Int(e) ?? 0
            if i < onlineVerNums.count {
                let onlineNum = Int(onlineVerNums[i]) ?? 0
                if appNum < onlineNum {
                    return .orderedAscending
                } else if appNum > onlineNum {
                    return .orderedDescending
                }
            }
        }
        
        if appVerNums.count > onlineVerNums.count {
            return .orderedDescending
        } else if appVerNums.count < onlineVerNums.count {
            return .orderedAscending
        } else {
            return .orderedSame
        }
    }
    
}

public extension UIApplication {
    
    /// The app's key window.
    @objc var vd_keyWindow: UIWindow? {
        var keyWindow: UIWindow?
        if #available(iOS 13.0, *) {
            keyWindow = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .map({ $0 as? UIWindowScene })
                .compactMap({ $0 })
                .first?.windows
                .filter({ $0.isKeyWindow }).first
        } else {
            keyWindow = UIApplication.shared.windows
                .filter({ $0.isKeyWindow }).first
        }
        return keyWindow
    }
    
    /// Return the current controller.
    @objc var vd_queryCurrentController: UIViewController? {
        return self.vd_queryCurrentController(self.vd_keyWindow?.rootViewController)
    }
    
    /// Query the current controller.
    @objc func vd_queryCurrentController(_ controller: UIViewController?) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return vd_queryCurrentController(navigationController.visibleViewController)
        }
        if let tabBarController = controller as? UITabBarController {
            if let selectedController = tabBarController.selectedViewController {
                return vd_queryCurrentController(selectedController)
            }
        }
        if let presentedController = controller?.presentedViewController {
            return vd_queryCurrentController(presentedController)
        }
        return controller
    }
    
    /// Make an `UIAlertController` object that displays an alert message.
    @objc func vd_makeAlertController(title: String, message: String, alignment: NSTextAlignment = .center, font: UIFont = UIFont.systemFont(ofSize: 13, weight: .regular), cancelTitle: String?, cancelAction: ((String?) -> Void)? = nil, defaultTitle: String, defaultAction: ((String?) -> Void)? = nil) -> UIAlertController {
        return self.vd_makeAlertController(title: title,
                                           message: message,
                                           alignment: alignment,
                                           font: font,
                                           destructiveTitle: nil,
                                           destructiveAction: nil,
                                           cancelTitle: cancelTitle,
                                           cancelAction: cancelAction,
                                           defaultTitle: defaultTitle,
                                           defaultAction: defaultAction)
    }
    
    /// Make an `UIAlertController` object that displays an alert message.
    @objc func vd_makeAlertController(title: String, message: String, alignment: NSTextAlignment = .center, font: UIFont = UIFont.systemFont(ofSize: 13, weight: .regular), destructiveTitle: String? = nil, destructiveAction: ((String?) -> Void)? = nil, cancelTitle: String? = nil, cancelAction: ((String?) -> Void)? = nil, defaultTitle: String, defaultAction: ((String?) -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController.init(title: title, message: "", preferredStyle: .alert)
        
        if let _destructiveTitle = destructiveTitle, !_destructiveTitle.isEmpty {
            let _destructiveAction = UIAlertAction.init(title: _destructiveTitle, style: .destructive) { action in
                destructiveAction?(action.title)
            }
            alertController.addAction(_destructiveAction)
        }
        if let _cancelTitle = cancelTitle, !_cancelTitle.isEmpty {
            let _cancelAction = UIAlertAction.init(title: _cancelTitle, style: .cancel) { action in
                cancelAction?(action.title)
            }
            alertController.addAction(_cancelAction)
        }
        let _defaultAction = UIAlertAction.init(title: defaultTitle, style: .default) { action in
            defaultAction?(action.title)
        }
        alertController.addAction(_defaultAction)
        
        let attributedMessage = NSMutableAttributedString.init(string: message)
        let paragraph = NSMutableParagraphStyle.init()
        paragraph.alignment = alignment
        attributedMessage.setAttributes(
            [NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.font: font],
            range: NSRange.init(location: 0, length: attributedMessage.length)
        )
        alertController.setValue(attributedMessage, forKey: "attributedMessage")
        
        return alertController
    }
    
}
