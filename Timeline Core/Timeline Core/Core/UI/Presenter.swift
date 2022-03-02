//
//  Presenter.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import UIKit

class Presenter {
    // MARK: - App Navigation Functions
    
    class func present(_ destination: UIViewController, animated: Bool = true, completion: (() -> Swift.Void)? = nil) {
        UIApplication.shared.keyWindow?.visibleViewController?.present(destination, animated: animated, completion: completion)
    }
    
    class func push(_ destination: UIViewController, animated: Bool = true, completion: (() -> Swift.Void)? = nil) {
        if let navigationController = UIApplication.shared.keyWindow?.visibleViewController?.navigationController {
            navigationController.pushViewController(destination, animated: animated)
        } else {
            Presenter.present(destination, animated: animated, completion: completion)
        }
    }
}
