//
//  APIPhotosProtocol.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/27/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation


// MARK: - APIPhotosProtocol

protocol APIPhotosProtocol {
    
    static var descriptor: APIClassDescriptor { get }
    static var modelType: ModelType { get }
    
    var id: String? { get }
    var photos: Photos { get set }
    
    func retrievePhotos(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
}

extension APIPhotosProtocol {
    
    func retrievePhotos(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        let function: APIFunctionDescriptor = "retrievePhotos"
        
        let start = Date()
        
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        let url = String(format: "/organizations/%@/photos/retrieve/%@/%@", arguments: [orgId, type(of: self).modelType.rawValue, id])
        
        let params: JSON = EMPTY_JSON
        
        APIClient.shared.GET(url: url, parameters: params) { (_, response, body) -> Void in
            
            guard response?.statusCode == 200 else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
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
            
            guard let data = body as? [JSON] else {
                APIDiagnostics.shared.ERROR(_classDescription: type(of: self).descriptor,
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
            
            var photos = [Photo]()
            
            for value in data {
                if let photo = PhotoBucket.shared.sharedItem(attrs: value) {
                    photos.append(photo)
                }
            }
            
            self.photos.load(photos)
            
            APIDiagnostics.shared.SUCCESS(_classDescription: type(of: self).descriptor,
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
