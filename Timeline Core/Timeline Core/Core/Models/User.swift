//
//  User.swift
//  Timeline Software, LLC
//
//  Created by Timeline Software, LLC on 3/23/16.
//  Copyright © 2016 Timeline Software, LLC. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Material
import CoreLocation
import CoreData

enum UserRole: String {
    case Admin = "ADMIN"
    case Supervisor = "SUPERVISOR"
    case User = "USER"
}

// MARK: - Users

@objcMembers class Users: APIContainer<User>, APIContainerSingletonProtocol {
    
    // MARK: - API Container
    
    typealias Shared = Users

    static var shared = Shared()
    
    // MARK: - Descriptors

    override var modelType: ModelType {
        return ModelType.Users
    }
    
    override var descriptor: String {
        return "Users"
    }
    
    override var entityName: String {
        return "CoreUser"
    }
    
    // MARK: - Initializers
    
    override init() {
        super.init()
        
        restoreAllEntities()
    }
    
    init(lean: Bool) {
        super.init()
        
    }
    
    // MARK: - API Protocol Values
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/users", arguments: [orgId])
    }
    
    override var retrieveParams: JSON? {
        
        let params: JSON = [
            "includeTimeSheets": false as JSONObject,
            "populate": true as JSONObject,
            "photos": true as JSONObject
        ]
        
        return params
    }
    
    // MARK: - API Protocol Handlers
    
    override func process(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard let data = initialValue as? [JSON] else {
            callback(nil, nil)
            return
        }
        
        items.removeAll()
        self.deleteAllEntities()
        
        for (index, value) in data.enumerated() {
            let item = Item(attrs: value)
            
            if item.id != Auth.shared.id {
                item.tag = index + 1
                item.entity = item.createEntity()
                items.append(item)
                
                if let entity = item.entity {
                    self.entities.append(entity)
                }
            }
        }
    
        self.sort()
        
        callback(nil, nil)
    }
    
    // MARK: - Other Methods

    override func sort() {
        items.sort(by: { $0.lastName! < $1.lastName! })
    }
}

// MARK: - Users Extension

extension Users {

    var favorites: [User] {
        var array = [User]()

        for user in items {
            if user.favorite == true {
                array.append(user)
            }
        }

        return array
    }
    
    var active: [User] {
    
        var matches = items.filter { (item) -> Bool in
            if let stream = Stream.shared[item.id], stream.sheet != nil {
                return true
            }
            
            return false
        }
        
        matches.sort(by: { $0.userRole.rawValue < $1.userRole.rawValue })
        
        return matches
    }
    
    var inactive: [User] {
        
        var matches = items.filter { (item) -> Bool in
            if let stream = Stream.shared[item.id], stream.sheet != nil {
                return false
            }
            
            return true
        }
        
        matches.sort(by: { $0.lastName! < $1.lastName! })
        
        return matches
        
    }

    var sectionTitles: [String] {
        var values = [String]()
        sort()

        for user in items {
            let name = user.lastName!.uppercased()
            let character = name.characters.first

            var found: Bool = false
            for value in values {
                if value.characters.first == character {
                    found = true
                    break
                }
            }

            if found == false {
                values.append(String(character!))
            }
        }

        return values
    }

    func sectionValues(_ section: String) -> [User] {
        var values = [User]()

        let character = section.characters.first

        for value in items {
            if value.lastName?.uppercased().characters.first == character {
                values.append(value)
            }
        }

        return values
    }
}

// MARK: - User

@objcMembers class User: APIModel, AssetsProtocol {
    
    // MARK: - Descriptors
    
    override var entityName: String {
        return "CoreUser"
    }
    
    override var modelType: ModelType {
        return ModelType.User
    }
    
    override var descriptor: String {
        return "User"
    }
    
    override var keys: [String] {
        return [ "id", "timestamp", "firstName", "lastName", "phoneNumber", "deviceToken", "password", "email", "photo", "role", "organization", "notes", "orgName"]
    }
    
    
    // MARK: - Initializers
    
    required public init() {
        super.init()
    }
    
    required public init(object: NSManagedObject) {
        super.init(object: object)
    }
    
    required public init(attrs: JSON) {
        super.init(attrs: attrs)
        
        if let phoneNumbers = attrs["phoneNumbers"] as? [String] {
            phoneNumber = phoneNumbers[0]
        }
        
        if let organization = attrs["organization"] as? JSON {
            self.organization = organization["id"] as? String
            self.orgName = organization["name"] as? String
            self.registrationCode = organization["registrationCode"] as? String
        }
        
        if let values = attrs["subscriptions"] as? [JSON], self.id == Auth.shared.id {
            Subscriptions.shared.items.removeAll()
            for value in values {
                let subscription = Subscription(attrs: value)
                Subscriptions.shared.items.append(subscription)
                
                guard let id = subscription.user else {
                    continue
                }
                
                DeviceSettings.shared.setUserFavoritedSetting(id, value: true)
            }
        }
    }
    
    // MARK: - Asset Properties
    
    static var assetKeys: [String] = [ "Card" ]
    
    var assets: JSON = JSON()

    // MARK: - Other Properties
    
    var firstName: String?
    var lastName: String?
    var phoneNumber: String?
    var role: String?
    var deviceToken: String?
    var password: String?
    var email: String?
    var photo: String?
    var organization: String?
    var orgName: String?
    var registrationCode: String?
    var notes: String?
    
    var statistics: UserStatistics?
    
    var sheet: Sheet? {
        willSet {
            if newValue == nil {
                sheet?.cleanse()
            }
        }
    }
    
    var profilePicture: UIImage? {
        guard let image = photo?.base64Image() else {
            return Assets.shared.avatar
        }
        
        return image
    }
    
    var fullName: String? {
        guard let first = firstName, let last = lastName else {
            return nil
        }
        
        return String(format: "%@ %@", first, last)
    }
    
    var favorite: Bool {
        get {
            guard let id = self.id else {
                return false
            }
            
            return DeviceSettings.shared.getUserFavoritedSetting(id)
        }
        set {
            guard let id = self.id else {
                return
            }
            
            DeviceSettings.shared.setUserFavoritedSetting(id, value: newValue)
        }
    }
    
    var userRole: UserRole {
        
        get {
            guard let role = role else {
                return .User
            }
            
            return UserRole(rawValue: role)!
        }
        
        set {
            role = newValue.rawValue
        }
    }
    
    var chatUser: ChatUser {
        var attrs = JSON()
        
        attrs["connected"] = false as AnyObject
        attrs["user"] = toJson() as AnyObject
        
        return ChatUser(attrs: attrs)
    }
    
    var readablePhoneNumber: String? {
        var value: String?
        if let phoneNumber = self.phoneNumber, phoneNumber.characters.count == 11 {
            let index1 = phoneNumber.index(phoneNumber.startIndex, offsetBy: 1)
            let index2 = phoneNumber.index(phoneNumber.startIndex, offsetBy: 4)
            let index3 = phoneNumber.index(phoneNumber.startIndex, offsetBy: 7)
            let index4 = phoneNumber.index(phoneNumber.startIndex, offsetBy: 11)
            let part1: String = String(phoneNumber[index1 ..< index2])
            let part2: String = String(phoneNumber[index2 ..< index3])
            let part3: String = String(phoneNumber[index3 ..< index4])
            
            value = String(format: "(%@) %@-%@", part1, part2, part3)
        }
        
        return value
    }
    
    // MARK: - API Protocol Values
    
    override var createUrl: String? {
        guard let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "/organizations/%@/users", arguments: [orgId])
    }
    
    override var createParams: JSON? {
        guard let firstName = self.firstName, let lastName = self.lastName, let phoneNumber = self.phoneNumber, let createdBy = Auth.shared.id else {
            return nil
        }
        
        let params: JSON = [
            "firstName": firstName as JSONObject,
            "lastName": lastName as JSONObject,
            "phoneNumbers": [phoneNumber] as JSONObject,
            "role": userRole.rawValue as JSONObject,
            "createdBy": createdBy as JSONObject
            ]
        
        return params
    }
    
    override func processCreate(data: JSON) -> Bool {
        guard let id = data["id"] as? String else {
            return false
        }
        
        self.id = id
        
        return true
    }
    
    override var retrieveUrl: String? {
         guard let orgId = Auth.shared.orgId, let userId = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/users/%@", arguments: [orgId, userId])
    }
    
    override var retrieveParams: JSON? {
        
        var params: JSON = [
            "populate" : true as JSONObject
        ]
        
        if self.photo == nil {
            params["photos"] = true as JSONObject
        }
        
        return params
    }
    
    override func processRetrieve(data: JSON) -> JSON? {
        let user = User(attrs: data)
        
        guard user.id != Auth.shared.id else {
            let container: JSON = [
                "model": user as JSONObject,
                ]
            
            return container
        }

        if let entity = Users.shared.entity(id: user.id) {
            user.entity = entity
            user.saveEntity()
        } else {
            user.entity = user.createEntity()
        }
        
        let container: JSON = [
            "model": user as JSONObject,
            ]
        
        return container
    }
    
    override var updateUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/users/%@", arguments: [orgId, id])
    }
    
    override var updateParams: JSON? {
        guard let updatedBy = Auth.shared.id else {
            return nil
        }
        
        var params = toJson()
        params["updatedBy"] = updatedBy as JSONObject
        return params
    }

    override var deleteUrl: String? {
         guard let orgId = Auth.shared.orgId, let userId = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/users/%@", arguments: [orgId, userId])
    }
    
    // MARK: - Other Methods
    
    func retrieveStatistics(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        let function: String = "retrieveStatistics"
        
        let start = Date()
        
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        let url = String(format: "/organizations/%@/users/%@/statistics", arguments: [orgId, id])
        
        let params: JSON = EMPTY_JSON
        
        APIClient.shared.GET(url: url, parameters: params) { (_, response, body) -> Void in
            
            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.StatusError,
                                            _response: response,
                                            _body: body)
                callback(APIClientErrors.StatusError, initialValue)
                return
            }
            
            guard let data = body as? JSON else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.DataError,
                                            _response: response,
                                            _body: body)
                callback(APIClientErrors.DataError, initialValue)
                return
            }
            
            let statistics = UserStatistics(attrs: data)
            statistics.userId = self.id
            self.statistics = statistics
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            APIUpdater.shared.post(type: .Statistics, action: .Retrieve)
            callback(nil, initialValue)
        }
    }
    
    
    func retrieveTimesheet(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "retrieveTimesheet"
        
        let start = Date()
        
        guard let orgId = Auth.shared.orgId, let userId = self.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        sheet?.cleanse()
        sheet = nil
        
        if self === DeviceUser.shared.user {
            DeviceUser.shared.sheet?.cleanse()
            DeviceUser.shared.sheet = nil
        }
        
        let params: JSON = EMPTY_JSON
        
        let url = String(format: "/organizations/%@/timesheets/users/%@", arguments: [orgId, userId])
        
        APIClient.shared.GET(url: url, parameters: params) { (_, response, body) -> Void in
            
            guard response?.statusCode == 200 || response?.statusCode == 202 else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.StatusError,
                                            _response: response,
                                            _body: body)
                callback(APIClientErrors.StatusError, initialValue)
                return
            }
            
            if response?.statusCode == 202 {
                APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                              _functionDescriptor: function,
                                              _url: url,
                                              _params: params,
                                              _start: start,
                                              _body: body,
                                              _response: response)
                callback(nil, initialValue)
                return
            }
            
            guard let data = body as? JSON else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: params,
                                            _start: start,
                                            _error: APIClientErrors.DataError,
                                            _response: response,
                                            _body: body)
                callback(APIClientErrors.DataError, initialValue)
                return
            }
            
            self.sheet = Sheet(attrs: data)
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            callback(nil, initialValue)
        }
    }
    
    
    func focus() {
        
        if let _ = Subscriptions.shared.get(userId: self.id) {
            Notifications.shared.map_focus_user.post(["user": self.id! as JSONObject])
        } else {
            Subscriptions.shared.retrieve(self.id) { _ in }
        }
    }
}


class UserStatistics {
    var userId: String?
    var shifts: Int?
    var hours: Double?
    var distance: Double?
    
    convenience init(attrs: JSON) {
        self.init()
        
        shifts = attrs["shifts"] as? Int ?? 0
        distance = attrs["distance"]?.doubleValue ?? 0.0
        if let time = attrs["time"]?.doubleValue { hours = time / (60.0 * 60.0) }
    }
}

