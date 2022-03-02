//
//  Types.swift
//  Timeline CMMS
//
//  Created by Zachary DeGeorge on 9/23/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation

// JSON Types

public typealias JSONObject = AnyObject
public typealias JSON = [String: JSONObject]

let EMPTY_JSON: JSON = [:]

// Other Types

typealias Enclosure = () -> Void
