//
//  Theme.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import Material

//import MapKit
//import MapKitGoogleStyler
//import CoreLocation

class ThemeTemplate {
    let primaryBackgroundColor: UIColor
    let secondaryBackgroundColor: UIColor

    let primaryFontColor: UIColor
    let secondaryFontColor: UIColor
    let alternativeFontColor: UIColor

    let rootHeaderBackgroundColor: UIColor
    let rootHeaderFontColor: UIColor
    let subHeaderBackgroundColor: UIColor
    let subHeaderFontColor: UIColor

    let primaryMapOverlayFillColor: UIColor
    let primaryMapOverlayStrokeColor: UIColor

    let lightIconColor: UIColor
    let darkIconColor: UIColor
    let alternateIconColor: UIColor
    let sidebarColor: UIColor
    let placeholderColor: UIColor

    init(_primaryBackgroundColor: UIColor, _secondaryBackgroundColor: UIColor, _primaryFontColor: UIColor, _secondaryFontColor: UIColor, _alternativeFontColor: UIColor, _rootHeaderBackgroundColor: UIColor, _rootHeaderFontColor: UIColor, _subHeaderBackgroundColor: UIColor, _subHeaderFontColor: UIColor, _primaryMapOverlayFillColor: UIColor, _primaryMapOverlayStrokeColor: UIColor, _lightIconColor: UIColor, _darkIconColor: UIColor, _alternateIconColor: UIColor, _sidebarColor: UIColor, _placeholderColor: UIColor) {
        
        primaryBackgroundColor = _primaryBackgroundColor
        secondaryBackgroundColor = _secondaryBackgroundColor

        primaryFontColor = _primaryFontColor
        secondaryFontColor = _secondaryFontColor
        alternativeFontColor = _alternativeFontColor

        rootHeaderBackgroundColor = _rootHeaderBackgroundColor
        rootHeaderFontColor = _rootHeaderFontColor
        subHeaderBackgroundColor = _subHeaderBackgroundColor
        subHeaderFontColor = _subHeaderFontColor

        primaryMapOverlayFillColor = _primaryMapOverlayFillColor
        primaryMapOverlayStrokeColor = _primaryMapOverlayStrokeColor

        lightIconColor = _lightIconColor
        darkIconColor = _darkIconColor
        alternateIconColor = _alternateIconColor
        sidebarColor = _sidebarColor
        placeholderColor = _placeholderColor
    }
}

protocol ThemeSupportedProtocol {
    
    func applyTheme()
}


class Theme {
    
    static let shared = Theme()

    var lightTheme: ThemeTemplate
    var darkTheme: ThemeTemplate
    
    // var darkMapOverlay: MKTileOverlay?
    
    let theme_changed = Notification.Name(rawValue: "theme_changed_notification")
    fileprivate let theme_changed_notification: Notification

    init() {
        
        theme_changed_notification = Notification(name: theme_changed)
        
        lightTheme = ThemeTemplate(
            _primaryBackgroundColor: UIColor(hex: "F0F0F8")!,
            _secondaryBackgroundColor: UIColor.white,
            _primaryFontColor: UIColor.black,
            _secondaryFontColor: UIColor.darkGray,
            _alternativeFontColor: UIColor(hex: "4A90E2")!,
            _rootHeaderBackgroundColor: UIColor(hex: "1F1753")!,
            _rootHeaderFontColor: UIColor.white.withAlphaComponent(0.95),
            _subHeaderBackgroundColor: UIColor(hex: "F0F0F8")!,
            _subHeaderFontColor: UIColor.darkGray,
            _primaryMapOverlayFillColor: Color.blue.darken2,
            _primaryMapOverlayStrokeColor: Color.blue.darken2,
            _lightIconColor: UIColor.white,
            _darkIconColor: UIColor.black,
            _alternateIconColor: UIColor(hex: "4A90E2")!,
            _sidebarColor: UIColor(hex: "06163E")!.withAlphaComponent(0.9),
            _placeholderColor: UIColor.lightGray
        )

        darkTheme = ThemeTemplate(
            _primaryBackgroundColor: UIColor(hex: "1A3646")!,
            _secondaryBackgroundColor: UIColor(hex: "4B6878")!,
            _primaryFontColor: UIColor.white.withAlphaComponent(0.75),
            _secondaryFontColor: UIColor.white.withAlphaComponent(0.45),
            _alternativeFontColor: UIColor(hex: "4A90E2")!,
            _rootHeaderBackgroundColor: UIColor(hex: "1D3146")!,
            _rootHeaderFontColor: UIColor.white.withAlphaComponent(0.95),
            _subHeaderBackgroundColor: UIColor(hex: "1A3646")!,
            _subHeaderFontColor: UIColor.white.withAlphaComponent(0.95),
            _primaryMapOverlayFillColor: Color.yellow.lighten4,
            _primaryMapOverlayStrokeColor: Color.yellow.lighten1,
            _lightIconColor: UIColor.black,
            _darkIconColor: UIColor(hex: "F0F0F8")!,
            _alternateIconColor: UIColor(hex: "4A90E2")!,
            _sidebarColor: UIColor(hex: "1D3146")!,
            _placeholderColor: UIColor.lightGray
        )

        // configureTileOverlay()
    }

    /*
    private func configureTileOverlay() {
        // We first need to have the path of the overlay configuration JSON
        guard let overlayFileURLString = Bundle.main.path(forResource: "darkoverlay", ofType: "json") else {
            return
        }
        let overlayFileURL = URL(fileURLWithPath: overlayFileURLString)

        // After that, you can create the tile overlay using MapKitGoogleStyler
        guard let tileOverlay = try? MapKitGoogleStyler.buildOverlay(with: overlayFileURL) else {
            return
        }

        tileOverlay.minimumZ = NSInteger.min
        tileOverlay.maximumZ = NSInteger.max
        darkMapOverlay = tileOverlay
    }
    */

    var active: ThemeTemplate! {
        //let theme = DeviceSettings.shared.nightMode == true ? darkTheme : lightTheme
        
        return lightTheme //theme
    }

    /*
    var darkMode: Bool! {
        get {
            return DeviceSettings.shared.nightMode
        }

        set {
            DeviceSettings.shared.nightMode = newValue
        }
    }
    */
}
