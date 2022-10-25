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
final public class AppStoreVersionDetector {
    
    public static let `default` = AppStoreVersionDetector()
    
    private init() {}
    
    public enum Result {
        case success(Bool)
        case failure(String)
    }
    
    /// The app's id.
    private var appId: String = ""
    /// Callbacks the result for the detecting.
    private var completionHandler: ((Result) -> Void)?
    /// Whether to has the new version.
    public private(set) var hasNewVersion: Bool = false
    /// Whether to allow to present the alert controller.
    public var alertAllowed: Bool = true
    
    /// Detect the version only in release product.
    /// - Parameters:
    ///   - id: The app's id.
    ///   - delay: The timeinterval delay to execute.
    ///   - completionHandler: Callbacks the result for the detecting.
    public func onDetect(
        id: String,
        delayToExecute delay: TimeInterval = 0,
        completionHandler: ((Result) -> Void)? = nil)
    {
        self.appId = id
        self.completionHandler = completionHandler
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.onStart()
            }
        } else {
            self.onStart()
        }
    }
    
    private func onStart() {
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
            self.completionHandler?(Result.failure("The url is null."))
            return
        }
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            //debugPrint("[VD] FetchData response: \(String(describing: response))")
            guard let _error = error else {
                if let _data = data {
                    self?.onParse(with: _data)
                } else {
                    debugPrint("[VD] FetchData: data is null.")
                    self?.completionHandler?(Result.failure("The data is null."))
                }
                return
            }
            debugPrint("[VD] FetchData error: \(_error.localizedDescription)")
            self?.completionHandler?(Result.failure(_error.localizedDescription))
            
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
                self.completionHandler?(Result.failure("It cannot unable to parse data."))
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
                return
            }
            let version = "\(subDict["version"] ?? "")"
            let compResult = compareVersion(with: version)
            if compResult == .orderedAscending {
                debugPrint("[VD] The online version is greater than the local.")
                
                let releaseNotes = "\(subDict["releaseNotes"] ?? "")"
                let dateStr = "\(subDict["currentVersionReleaseDate"] ?? "")"
                debugPrint("[VD] date: \(dateStr)")
                
                let dateFormatter = DateFormatter.init()
                dateFormatter.timeZone = NSTimeZone.init(name: "UTC")! as TimeZone
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                var releaseDateStr = ""
                if let releaseDate = dateFormatter.date(from: dateStr) {
                    let dateFormatter = DateFormatter.init()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    releaseDateStr = dateFormatter.string(from: releaseDate)
                }
                debugPrint("[VD] releaseDate: \(releaseDateStr)")
                
                DispatchQueue.main.async {
                    self.hasNewVersion = true
                    self.completionHandler?(Result.success(true))
                    if !self.alertAllowed { return }
                    let alertController = UIAlertController.init(title: "发现新版本", message: "", preferredStyle: .alert)
                    let cancelAction = UIAlertAction.init(title: "下次再说", style: .cancel) { alertAction in }
                    let updateAction = UIAlertAction.init(title: "立即更新", style: .default) { alertAction in
                        AppStoreVersionDetector.gotoAppStore(id: self.appId)
                    }
                    alertController.addAction(cancelAction)
                    alertController.addAction(updateAction)
                    let message = "版本：\n\(version)\n" + "更新时间：\n\(releaseDateStr)\n" + "\n更新说明：\n\(releaseNotes)\n"
                    let attributedMessage = NSMutableAttributedString.init(string: message)
                    let paragraph = NSMutableParagraphStyle.init()
                    paragraph.alignment = .left
                    let font = UIFont.systemFont(ofSize: 13, weight: .regular)
                    attributedMessage.setAttributes(
                        [NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.font: font],
                        range: NSRange.init(location: 0, length: attributedMessage.length)
                    )
                    alertController.setValue(attributedMessage, forKey: "attributedMessage")
                    vd_queryCurrentController()?.present(alertController, animated: true)
                }
            } else if compResult == .orderedSame {
                debugPrint("[VD] The local version is equal to the online.")
                self.completionHandler?(Result.success(false))
            } else {
                debugPrint("[VD] The local version is greater than the online.")
                self.completionHandler?(Result.success(false))
            }
        } catch let error {
            debugPrint("[VD] Parse error: \(error)")
            self.completionHandler?(Result.failure(error.localizedDescription))
        }
    }
    
    /// Go to AppStore by the open url.
    /// - Parameter id: The app's id.
    public static func gotoAppStore(id: String) {
        let appUrl = "https://apps.apple.com/cn/app/id\(id)?mt=8"
        guard let url = URL.init(string: appUrl) else {
            debugPrint("[VD] gotoAppStore: url is null.")
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    /// Compare with the local and online version, then return the comparison result.
    private func compareVersion(with onlineVersion: String) -> ComparisonResult {
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
    var vd_keyWindow: UIWindow? {
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
    
}

/// Queries the current controller.
public func vd_queryCurrentController(
    _ controller: UIViewController? = UIApplication.shared.vd_keyWindow?.rootViewController
) -> UIViewController? {
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
