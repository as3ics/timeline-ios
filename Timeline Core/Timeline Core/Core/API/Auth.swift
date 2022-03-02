//
//  Auth.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/23/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import KeychainAccess
import CoreLocation

class Auth: KeychainAccessProtocol {
    
    static var description: String = "Auth"
    
    static let shared = Auth()

    var firstName: String?
    var lastName: String?
    var smsCode: String?
    
    var phonenumber: String? {
        get {
            return getFromKeychain("phonenumber")
        }
        set {
            storeInKeychain("phonenumber", value: newValue)
        }
    }
    
    var user: User? {
        didSet {
            id = user?.id
            orgId = user?.organization
        }
    }

    var id: String? {
        get {
            return getFromKeychain("id")
        }
        set {
            storeInKeychain("id", value: newValue)
        }
    }

    var orgId: String? {
        get {
            return getFromKeychain("orgId")
        }
        set {
            storeInKeychain("orgId", value: newValue)
        }
    }

    var authToken: String? {
        get {
            return getFromKeychain("authToken")
        }
        set {
            storeInKeychain("authToken", value: newValue)
            APIClient.shared.authToken = newValue
        }
    }

    var deviceToken: String? {
        get {
            return getFromKeychain("deviceToken")
        }
        set {
            storeInKeychain("deviceToken", value: newValue)
        }
    }

    var authed: Bool {
        guard authToken != nil, id != nil, orgId != nil else {
            return false
        }

        return true
    }

    func flush() {
        authToken = nil
        id = nil
        orgId = nil
        deviceToken = nil
        phonenumber = nil
    }

    func beginAuthentication(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "beginAuthentication"

        let start = Date()

        guard let phonenumber = self.phonenumber, phonenumber.characters.count == 14 else {
            APIDiagnostics.shared.ERROR(_classDescription: type(of: self).description,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        let number = "1" + phonenumber.replacingOccurrences(
            of: "\\D", with: "", options: .regularExpression,
            range: phonenumber.startIndex ..< phonenumber.endIndex)

        var url: String!
        if let inputValue = initialValue as? JSON, let push = inputValue["push"] as? Bool, push == true {
            url = String(format: "/authenticate/user?push=true", arguments: [])
        } else {
            url = String(format: "/authenticate/user", arguments: [])
        }

        let params: JSON = [
            "phoneNumber": number as JSONObject,
        ]

        APIClient.shared.POST(url: url, parameters: params, callback: { (_, response, body) -> Void in

            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).description,
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

            guard let data = body as? JSON, let firstName = data["firstName"] as? String, let lastName = data["lastName"] as? String else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).description,
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

            self.firstName = firstName
            self.lastName = lastName

            APIDiagnostics.shared.SUCCESS(_classDescription: type(of: self).description,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)

            callback(nil, initialValue)
            return
        })
    }

    func finishAuthentication(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "finishAuthentication"

        let start = Date()

        guard let phonenumber = self.phonenumber, phonenumber.characters.count == 14, let smsCode = self.smsCode else {
            APIDiagnostics.shared.ERROR(_classDescription: type(of: self).description,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }

        let url = String(format: "/authenticate/user/%@", arguments: [smsCode])

        let number = "1" + phonenumber.replacingOccurrences(
            of: "\\D", with: "", options: .regularExpression,
            range: phonenumber.startIndex ..< phonenumber.endIndex)
        
        let params: JSON = [
            "phoneNumber": number as JSONObject,
        ]

        APIClient.shared.POST(url: url, parameters: params, callback: { (_, response, body) -> Void in

            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).description,
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

            guard let authToken = response?.allHeaderFields["Authorization"] as? String, let data = body as? JSON else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).description,
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

            let user = User(attrs: data)
            
            if user.id != self.id || user.organization != self.orgId {
                App.shared.clearAssetsCoreData()
                App.shared.clearPhotosCoreData()
                App.shared.cleanseData()
            }
            
            self.user = user
            self.authToken = authToken

            APIDiagnostics.shared.SUCCESS(_classDescription: type(of: self).description,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)

            callback(nil, initialValue)
        })
    }
}
