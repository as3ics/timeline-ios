//
//  External.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import StoreKit
import PKHUD

class External: NSObject, SKStoreProductViewControllerDelegate {
    
    static let shared: External = External()
    
    // MARK: - External App Accessors
    
    func dial(_ number: String?) {
        guard let number = number, let url = URL(string: "tel://\(number)") else {
            return
        }
        
        UIApplication.shared.open(url, options: EMPTY_JSON, completionHandler: nil)
    }
    
    func smsMessage(_ number: String?) {
        guard let number = number,  let url = URL(string: "sms:\(number)") else {
            return
        }
        
        UIApplication.shared.open(url, options: EMPTY_JSON, completionHandler: nil)
    }
    
    func phoneSettings() {
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(url, options: EMPTY_JSON, completionHandler: nil)
        }
    }
    
    func showPrivacy() {
        if let privacy = App.shared.info?["AppPrivacyUrl"] as? String, let url = URL(string: privacy) {
            UIApplication.shared.open(url, options: EMPTY_JSON, completionHandler: nil)
        }
    }
    
    func showTerms() {
        if let terms = App.shared.info?["AppTermsUrl"] as? String, let url = URL(string: terms) {
            UIApplication.shared.open(url, options: EMPTY_JSON, completionHandler: nil)
        }
    }
    
    func showAppStore() {
        
        guard let appStoreId = App.shared.appStoreId else {
            return
        }
        
        PKHUD.loading()
        
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        let parameters = [SKStoreProductParameterITunesItemIdentifier: appStoreId]
        storeViewController.loadProduct(withParameters: parameters) { (loaded, _) -> Void in
            if loaded {
                PKHUD.hide(animated: true)
                
                Presenter.present(storeViewController)
            } else {
                PKHUD.failure()
            }
        }
    }
    
    func requestReview() {
        guard let appId = App.shared.appStoreId, let url = URL(string: String(format: "https://itunes.apple.com/app/id%@?action=write-review",  appId)) else {
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
