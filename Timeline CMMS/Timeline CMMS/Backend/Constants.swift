//
//  Constants.swift
//  Timeline CMMS
//
//  Created by Zachary DeGeorge on 9/23/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

// Animation

let DEFAULT_ANIMATION_DURATION: TimeInterval = 0.3

// Time Valuess

let HOUR: TimeInterval = 60.0 * 60.0
let MINUTE: TimeInterval = 60.0
let DAY: TimeInterval = 60.0 * 60.0 * 24.0

// Map Presentation

let DEFAULT_DELTA_REGION_LAT: Double = 0.003
let DEFAULT_DELTA_REGION_LON: Double = 0.003

// Region Calculations

let MIN_DELTA_REGION_LAT: Double = 0.001
let MIN_DELTA_REGION_LON: Double = 0.001

let MAX_NORTH_START: Double = -90.0
let MAX_SOUTH_START: Double = 90.0
let MAX_EAST_START: Double = -180.0
let MAX_WEST_START: Double = 180.0

let ABSOLUTE_MIN_DELTA_LAT: Double = 0.0
let ABSOLUTE_MIN_DELTA_LON: Double = 0.0
let ABSOLUTE_MAX_DELTA_LAT: Double = 180.0
let ABSOLUTE_MAX_DELTA_LON: Double = 360.0
let ABSOLUTE_MAX_LAT: Double = 90.0
let ABSOLUTE_MAX_LON: Double = 180.0

// Styling

let DEFAULT_SEARCHBAR_HEADER_HEIGHT: CGFloat = 65.0

// Table View Formatting

let DEFAULT_HEIGHT_FOR_SECTION_HEADER: CGFloat = 1.0

// Conversions
let CONVERSION_MPH_TO_MPS_MULTIPLIER: Double = 0.44704
let CONVERSION_METERS_TO_MILES_MULTIPLIER: Double = 0.000621371
let CONVERSION_RADIUS_TO_REGION_DIVISOR: CLLocationDegrees = 30000.0

// PKHUD

let DEFAULT_PKHUD_TEXT_TIMEOUT: TimeInterval = 1.5

// Font

let DEFAULT_SYSTEM_FONT_SIZE: CGFloat = 16.0
let DEFAULT_BUTTON_FONT_SIZE: CGFloat = 15.0
let DEFAULT_DESCRIPTION_FONT_SIZE: CGFloat = 13.0

let DEFAULT_SYSTEM_FONT_NAME: String = "BankGothic"
let FONT_APPLE_SD_GOTHIC_NEO: String = "AppleSDGothicNeo-Light"
let HELVETICA_FONT_NAME: String = "HelveticaNeue"
let HELVETICA_THIN_FONT_NAME: String = "HelveticaNeue-Thin"
let HELVETICA_BOLD_FONT_NAME: String = "HelveticaNeue-Bold"
