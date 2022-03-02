//
//  Protocols.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import KeychainAccess
import MapKit
import CoreLocation
import UIKit

// Note: KEYCHAIN_ID must be defined

protocol KeychainAccessProtocol {
    
    func getFromKeychain(_ key: String) -> String?
    func storeInKeychain(_ key: String, value: String?)
    
}

protocol RegionProtocol {
    
    var region: MKCoordinateRegion? { get set }
}

protocol ThemeSupportedProtocol {

    func applyTheme()
}

protocol SidebarSectionProtocol {
    
    static var section: String { get }
}

