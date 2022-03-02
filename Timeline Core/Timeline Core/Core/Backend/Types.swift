//
//  Types.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation

// JSON Types

public typealias JSONObject = AnyObject
public typealias JSON = [String: JSONObject]

let EMPTY_JSON: JSON = [:]

// Other Types

typealias Enclosure = () -> Void

// iPhone Types

enum iPhone: String {
    case iPhone5 = "iPhone 5 or 5S or 5C"
    case iPhone = "iPhone 6/6S/7/8"
    case iPhonePlus = "iPhone 6+/6S+/7+/8+"
    case iPhoneX = "iPhone X/iPhoneXS"
    case iPhoneXR = "iPhone XR"
    case iPhoneMax = "iPhone XS Max"
    case unknown = "Unknown"
}

enum iOS: String {
    case iOS11 = "iOS 11"
    case iOS12 = "iOS 12"
    case unknown = "unknown"
}
