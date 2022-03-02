//
//  Organization.swift
//  Timeline Core
//
//  Created by Zachary DeGeorge on 11/15/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Organization

@objcMembers open class Organization: APIModel {
    
    static let shared: Organization = Organization()
    
    // MARK: - Descriptors
    
    override open var descriptor: String {
        return "Organization"
    }
    
    override open var modelType: ModelType {
        return ModelType.Organization
    }
    
    override open var keys: [String] {
        return []
    }
    
    override var id: String? {
        get {
            return Auth.shared.orgId
        } set {
            Auth.shared.orgId = newValue
        }
    }
    
    override var name: String? {
        get {
            return DeviceUser.shared.user?.orgName
        } set {
            DeviceUser.shared.user?.orgName = newValue
        }
    }
    
    var registrationCode: String? {
        return DeviceUser.shared.user?.registrationCode
    }
}
