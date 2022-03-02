//
//  TSWWaterfall.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 6/23/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation

//
//  Waterfall.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/26/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//  Source: https://gist.github.com/Gujci/5628f873ffe6365ead9da3f689440a7c


class Async {
    
    /// Error first callback
    /// The problem with throwing are async, non-rethowing functions 😨 .. so we need both
    ///
    /// - Parameters:
    ///   - initialValue: initial passed value of the chain
    ///   - chain: chain of closures to process
    ///   - end: last callback. Called after the chain finished or in an error occures
    ///
    /// - Note: Each callback should be called only once during executon
    class func waterfall(_ initialValue: Any? = nil,_ chain:[(@escaping (Error?, Any?) -> (), Any?) -> ()],end: @escaping (Error?, Any?) -> () ) {
        guard let function = chain.first else {
            end(nil, initialValue)
            return
        }
        function({ (err: Error?, newResult: Any?) in
            if let err = err {
                end(err, nil)
                return
            }
            waterfall(newResult, Array(chain.dropFirst()), end: end)
        }, initialValue)
    }
}
