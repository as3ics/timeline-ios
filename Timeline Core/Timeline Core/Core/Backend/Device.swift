//
//  Device.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import UIKit

class Device {
    
    static var phoneType: iPhone {
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                return .iPhone5
            case 1334:
                return .iPhone
            case 1792:
                return .iPhoneXR
            case 1920:
                return .iPhonePlus
            case 2436:
                return .iPhoneX
            case 2688:
                return .iPhoneMax
            default:
                return .unknown
            }
        } else {
            return .unknown
        }
    }
    
    static var hasNotch: Bool {
        let phone = Device.phoneType
        
        if (phone == .iPhoneX || phone == .iPhoneMax || phone == .iPhoneXR) {
            return true
        } else {
            return false
        }
    }
    
    static var iPhoneX: Bool {
        return hasNotch
    }
    
    static var osType: iOS {
        let SYS_VERSION_FLOAT = (UIDevice.current.systemVersion as NSString).floatValue
        if ( SYS_VERSION_FLOAT < 12.0 && SYS_VERSION_FLOAT >= 11.0 ) {
            return iOS.iOS11
        } else if  ( SYS_VERSION_FLOAT >= 12.0 )  {
           return iOS.iOS12
        } else {
            return .unknown
        }
    }
    
    static var size: CGSize {
        return UIScreen.main.bounds.size
    }
}
