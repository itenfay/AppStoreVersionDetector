//
//  ViewController.swift
//  AppStoreVersionDetector
//
//  Created by chenxing on 09/21/2022.
//  Copyright (c) 2022 chenxing. All rights reserved.
//

import UIKit
import AppStoreVersionDetector

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("hasNewVersion: \(AppStoreVDetector.default.hasNewVersion)")
        
        AppStoreVDetector.default.onDetect(id: "15674646463", delayToExecute: 5) { result in
            switch result {
            case .success(let hasNew):
                print("hasNew: \(hasNew)")
                break
            case .failure(let message):
                print("message: \(message)")
                break
            }
        }
        
        //AppStoreVDetector.gotoAppStore(id: "15674646463")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

