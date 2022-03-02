//
//  KeychainAccess.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import KeychainAccess

protocol KeychainAccessProtocol {
    
    func getFromKeychain(_ key: String) -> String?
    func storeInKeychain(_ key: String, value: String?)
    
}

extension KeychainAccessProtocol {
    
    func getFromKeychain(_ key: String) -> String? {
        let keychain = Keychain(service: App.shared.keychainId)
        let value = keychain[key]
        return value
    }
    
    func storeInKeychain(_ key: String, value: String?) {
        let keychain = Keychain(service: App.shared.keychainId)
        keychain[key] = value
    }
}
