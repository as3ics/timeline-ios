//
//  Registration.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation

extension User {
    
    func registerOrganization(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "registerOrganization"
        
        let start = Date()
        
        guard let organization = self.organization, !organization.isEmpty, let firstName = self.firstName, !firstName.isEmpty, let lastName = self.lastName, !lastName.isEmpty, let email = self.email, !email.isEmpty, let phoneNumber = self.phoneNumber?.lowercased(), !phoneNumber.isEmpty, let password = self.password, !email.isEmpty else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        let url = "/registerOrganization"
        
        let params: JSON = [
            "organization": organization as JSONObject,
            "firstName": firstName as JSONObject,
            "lastName": lastName as JSONObject,
            "email": email as JSONObject,
            "phoneNumber": [phoneNumber] as JSONObject,
            "password": password as JSONObject,
            ]
        
        APIClient.shared.POST(url: url, parameters: params, callback: { _, response, body in
            
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
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: params,
                                          _start: start,
                                          _body: body,
                                          _response: response)
            
            callback(nil, initialValue)
        })
    }
    
    func registerUser(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        let function: String = "registerUser"
        
        let start = Date()
        
        guard let org = self.organization?.lowercased(), !org.isEmpty, let fn = self.firstName, !fn.isEmpty, let ln = self.lastName, !ln.isEmpty, let phone = self.phoneNumber?.lowercased(), !phone.isEmpty else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        let url = "/registerUser"
        
        var params: JSON = [
            "organization": org as JSONObject,
            "firstName": fn as JSONObject,
            "lastName": ln as JSONObject,
            "phoneNumber": phone as JSONObject,
            "role" : userRole.rawValue as JSONObject
        ]
        
        if let email = self.email, !email.isEmpty {
            params["email"] = email as JSONObject
        }
        
        APIClient.shared.POST(url: url, parameters: params) { (_, response, body) -> Void in
            
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
            
            guard let data = body as? JSON, let orgId = data["orgId"]  as? String , let userId = data["userId"] as? String else {
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
            
            self.id = userId
            self.organization = orgId
            
            if App.shared.isLoaded == false {
                Auth.shared.orgId = orgId
                Auth.shared.id = userId
            }
            
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
}
