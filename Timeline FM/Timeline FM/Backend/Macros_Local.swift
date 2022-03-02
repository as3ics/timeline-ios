//
//  Macros_Local.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/14/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation

// For use with Pulse

func colorsWithOpacity(_ colors: [CGColor], _ opacity: CGFloat) -> [CGColor] {
    return colors.map({ $0.copy(alpha: $0.alpha * opacity)! })
}

// For Clock Time Conversions

func clockHours(_ seconds: Double) -> Double {
    return floor(seconds / 3600)
}

func clockMinutes(_ seconds: Double) -> Double {
    let remainder = seconds.truncatingRemainder(dividingBy: 3600)
    return floor(remainder / 60)
}

func clockSeconds(_ seconds: Double) -> Double {
    let flr = floor(seconds)
    let remainder = flr.truncatingRemainder(dividingBy: 60)
    return remainder
}

