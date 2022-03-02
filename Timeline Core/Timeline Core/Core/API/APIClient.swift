//
//  APIClient.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/23/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Alamofire
import Foundation
import CoreLocation

class APIClient {
    
    static let shared = APIClient()

    typealias NetworkResponseCallback = (NSError?, HTTPURLResponse?, AnyObject?) -> Void

    let baseURL: String

    var authToken: String? {
        didSet {
            headers["Authorization"] = authToken
        }
    }

    let formatter = DateFormatter()

    fileprivate var defaultManager: SessionManager
    fileprivate var largeRequestManager: SessionManager
    
    var headers = ["Authorization": ""]

    let timeoutForRequest: TimeInterval = 10.0
    let timeoutForResource: TimeInterval = 20.0

    init(_ baseURL: String = App.shared.apiUrl) {
        
        self.baseURL = baseURL

        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"

        let configuration = URLSessionConfiguration.default
        configuration.multipathServiceType = .interactive
        configuration.httpShouldUsePipelining = true
        configuration.waitsForConnectivity = false
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders

        largeRequestManager = SessionManager(configuration: configuration)
        
        configuration.timeoutIntervalForRequest = timeoutForRequest
        configuration.timeoutIntervalForResource = timeoutForResource
        
        defaultManager = SessionManager(configuration: configuration)
    }

    func GET(url: String, parameters: JSON?, largeRequest: Bool = false, callback: NetworkResponseCallback?) {
        _ = largeRequest == false ? makeRequest(method: .get, urlString: baseURL + url, parameters: parameters, callback: callback) : makeLargeRequest(method: .get, urlString: baseURL + url, parameters: parameters, callback: callback)
    }

    func POST(url: String, parameters: JSON?, largeRequest: Bool = false, callback: NetworkResponseCallback?) {
        _ = largeRequest == false ? makeRequest(method: .post, urlString: baseURL + url, parameters: parameters, callback: callback) : makeLargeRequest(method: .post, urlString: baseURL + url, parameters: parameters, callback: callback)
    }

    func PUT(url: String, parameters: JSON?, largeRequest: Bool = false, callback: NetworkResponseCallback?) {
        _ = largeRequest == false ? makeRequest(method: .put, urlString: baseURL + url, parameters: parameters, callback: callback) : makeLargeRequest(method: .put, urlString: baseURL + url, parameters: parameters, callback: callback)
    }

    func DELETE(url: String, parameters: JSON?, largeRequest: Bool = false, callback: NetworkResponseCallback?) {
        _ = largeRequest == false ? makeRequest(method: .delete, urlString: baseURL + url, parameters: parameters, callback: callback) : makeLargeRequest(method: .delete, urlString: baseURL + url, parameters: parameters, callback: callback)
    }

    fileprivate func makeRequest(
        method: HTTPMethod,
        urlString: String,
        parameters: JSON? = nil,
        callback: NetworkResponseCallback?) -> Request {
        let request = defaultManager.request(urlString, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers)

        request.responseJSON { (response) -> Void in
            callback?(response.result.error as NSError?, response.response, response.result.value as AnyObject?)
        }

        return request
    }
    
    fileprivate func makeLargeRequest(
        method: HTTPMethod,
        urlString: String,
        parameters: JSON? = nil,
        callback: NetworkResponseCallback?) -> Request {
        let request = largeRequestManager.request(urlString, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers)
        
        request.responseJSON { (response) -> Void in
            callback?(response.result.error as NSError?, response.response, response.result.value as AnyObject?)
        }
        
        return request
    }
    
    var defaultSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)
    
    var downloadSession: URLSession {
        return URLSession(configuration: sessionConfiguration)
    }
    
    fileprivate var sessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = false
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.httpShouldUsePipelining = true
        configuration.httpAdditionalHeaders = APIClient.shared.headers
        return configuration
    }
}


class APIDiagnostics {
    static let shared = APIDiagnostics()
    
    var log = [APIDiagnostic]()
    
    let max: Int = 1000
    
    func SUCCESS(_classDescription: String,
                 _functionDescriptor: String,
                 _url: String,
                 _params: JSON,
                 _start: Date,
                 _body: AnyObject?,
                 _response: HTTPURLResponse? = nil
        ) {
        let duration = Date().timeIntervalSince(_start)
        
        var index = 1
        if let first = APIDiagnostics.shared.log.first {
            index = first._index + 1
        }
        
        let diagnostic = APIDiagnostic(_index: index,
                                       _classDescriptor: _classDescription,
                                       _functionDescriptor: _functionDescriptor,
                                       _url: _url,
                                       _params: _params,
                                       _timestamp: _start,
                                       _response: _response,
                                       _body: _body,
                                       _success: true,
                                       _duration: duration)
        
        insert(diagnostic)
    }
    
    func ERROR(_classDescription: String,
               _functionDescriptor: String,
               _url: String,
               _params: JSON,
               _start: Date,
               _error: Error,
               _response: HTTPURLResponse? = nil,
               _body: AnyObject? = nil
        ) {
        let duration = Date().timeIntervalSince(_start)
        var index = 1
        if let first = APIDiagnostics.shared.log.first {
            index = first._index + 1
        }
        
        let diagnostic = APIDiagnostic(_index: index,
                                       _classDescriptor: _classDescription,
                                       _functionDescriptor: _functionDescriptor,
                                       _url: _url,
                                       _params: _params,
                                       _timestamp: _start,
                                       _response: _response,
                                       _body: _body,
                                       _error: _error,
                                       _success: false,
                                       _duration: duration)
        
        insert(diagnostic)
    }
    
    func estimatedRowHeight(index: Int) -> CGFloat {
        guard index < APIDiagnostics.shared.log.count else {
            return 0
        }
        
        let diag = APIDiagnostics.shared.log[index]
        
        if diag.success == true {
            return 100.0
        } else {
            return 140.0
        }
    }
    
    internal func insert(_ diagnostic: APIDiagnostic?) {
        
        guard let diag = diagnostic else {
            return
        }
        
        log.insert(diag, at: log.startIndex)
        
        if log.count > max {
            _ = log.popLast()
        }
    }
}

// MARK: - API Client Errors

enum APIClientErrors: Error {
    case ServerError
    case InputError
    case DataError
    case StatusError
    case InternalError
}

extension APIClientErrors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .ServerError:
            return NSLocalizedString("Invalid Server Response", comment: "")
        case .InputError:
            return NSLocalizedString("Invalid Parameters Passed to API Interface", comment: "")
        case .DataError:
            return NSLocalizedString("Invalid Data and/or Values Returned from Server", comment: "")
        case .StatusError:
            return NSLocalizedString("Invalid Status Code from Returned from Server", comment: "")
        case .InternalError:
            return NSLocalizedString("Internal Processing Error", comment: "")
        }
    }
}

// MARK: - API Diagnostic

struct APIDiagnostic {
    
    var _index: Int
    var classDescriptor: String
    var functionDescriptor: String
    var url: String
    var params: JSON
    var timestamp: Date
    var response: HTTPURLResponse?
    var body: AnyObject?
    var error: Error?
    var success: Bool?
    var duration: TimeInterval?
    
    init(
        _index: Int,
        _classDescriptor: String,
        _functionDescriptor: String,
        _url: String,
        _params: JSON,
        _timestamp: Date,
        _response: HTTPURLResponse? = nil,
        _body: AnyObject? = nil,
        _error: Error? = nil,
        _success: Bool? = nil,
        _duration: TimeInterval? = nil
        ) {
        self._index = _index
        classDescriptor = _classDescriptor
        functionDescriptor = _functionDescriptor
        url = _url
        params = _params
        timestamp = _timestamp
        
        if let response = _response { self.response = response }
        if let body = _body { self.body = body }
        if let error = _error { self.error = error }
        if let success = _success { self.success = success }
        if let duration = _duration { self.duration = duration }
    }
}
