//
//  Photo.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/25/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Alamofire
import AlamofireImage
import Foundation
import PKHUD
import UIKit
import CoreLocation
import CoreData
import ChattoAdditions

enum PhotoMode {
    case Date
    case User
    case Zone
}

// MARK: - Photos

@objcMembers class Photos: APIContainer<Photo> {

    // MARK: - Descriptors
    
    override var modelType: ModelType {
        return ModelType.Photos
    }
    
    override var descriptor: String {
        return "Photos"
    }
    
    // MARK: - Cache Files
    
    var allPhotos: JSON = JSON()
    var userPhotos: JSON = JSON()
    var zonePhotos: JSON = JSON()
    
    // MARK: - Additional Update Methods

    func load(_ photos: [Photo]?) {
        if let photos = photos {
            items.removeAll()
            
            for photo in photos {
                items.append(photo)
            }
        }
    }
    
    // MARK: - Additional Subscripts
    
    func get(uid: String?) -> Photo? {
        guard let uid = uid else {
            return nil
        }
        
        let matches = items.filter { (item) -> Bool in
            return item.uid == uid
        }
        
        return matches.first
    }
    
    func get(filename: String?) -> Photo? {
        guard let filename = filename else {
            return nil
        }
        
        let matches = items.filter { (item) -> Bool in
            return item.filename == filename
        }
        
        return matches.first
        
    }
    
    // MARK: - API Protocol
    
    override func retrieve(_ callback: @escaping (Error?, Any?) -> Void, _ initialValue: Any?) {
        
        unload()
        
        let session = APIClient.shared.downloadSession
        
        for photo in items {
            photo.observePlaceholderUpdates = true
            Async.waterfall(session, [photo.downloadPlaceholder], end: {_, _ in})
        }
        
        callback(nil, nil)
    }
    
    // MARK: - Other Methods
    
    func unload() {
        
        self.allPhotos.removeAll()
        self.userPhotos.removeAll()
        self.zonePhotos.removeAll()
        
        for item in items {
            item.nytPhoto.image = nil
        }
    }
    
    override func sort() {
        items.sort(by: { $0.timestamp ?? Date() < $1.timestamp ?? Date() })
    }
    
    func sectionTitles(mode: PhotoMode) -> [String] {
        
        var sections: [String] = [String]()
        
        guard items.count > 0 else {
            return sections
        }
        
        switch mode {
        case .Date:
            sort()
            
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            let start: Date = items.first!.timestamp?.lean() ?? Date().lean()
            let end: Date = items.last!.timestamp?.lean() ?? Date().lean()
            
            sections.append(start.dateString())
            
            guard start != end else {
                return sections
            }
            
            var date = start
            while calendar.isDate(date, inSameDayAs: end) == false {
                
                date.incrementDay()
                
                let matches = items.filter { (item) -> Bool in
                    guard let timestamp = item.timestamp else {
                        return false
                    }
                    
                    return calendar.isDate(timestamp, inSameDayAs: date)
                }
                
                if matches.count > 0 {
                    sections.append(date.dateString())
                }
            }
            
           return sections
        case .User:
            
            for item in self.items {
                
                guard let user = item.user else {
                    continue
                }
                
                if sections.contains(user) == false {
                    sections.append(user)
                }
            }
            
            return sections
        case .Zone:
            
            var locations: [String] = [String]()
            var sections: [String] = [String]()
            for item in self.items {
                guard let location = item.location else {
                    if sections.contains("Unassigned") == false {
                        sections.insert("Unassigned", at: 0)
                    }
                    continue
                }
                
                if locations.contains(location) == false {
                    locations.append(location)
                }
            }
            
            for location in locations {
                guard location != "Unassigned" else {
                    continue
                }
                
                let matches = self.items.filter { (item) -> Bool in
                    guard let locationId = item.location else {
                        return false
                    }
                    
                    return locationId == location
                }
                
                for match in matches {
                    guard let zone = match.location_zone else {
                        let section: String = String(format: "%@~Unassigned", location)
                        
                        if sections.contains(section) == false {
                            sections.append(section)
                        }
                        
                        continue
                    }
                    
                    let section: String = String(format: "%@~%@", location, zone)
                    
                    if sections.contains(section) == false {
                        sections.append(section)
                    }
                }
            }
            
            return sections
        }
    }
    
    func sectionValues(mode: PhotoMode, value: Any?) -> [Item] {
        
        switch mode {
        case .Date:
            
            guard let string = value as? String, let date = string.dateString() else {
                return []
            }
            
            if let cache = allPhotos[string] as? [Item] {
                return cache
            } else {
                var calendar = Calendar.current
                calendar.timeZone = TimeZone.current
                
                var matches = self.items.filter { (item) -> Bool in
                    guard let timestamp = item.timestamp else {
                        return false
                    }
                    
                    return calendar.isDate(timestamp, inSameDayAs: date)
                }
                
                matches.sort(by: { $0.timestamp! < $1.timestamp! })
                allPhotos[string] = matches as JSONObject
                return matches
            }
        case .User:
            
            guard let user = value as? String else {
                return []
            }

            if let cache = userPhotos[user] as? [Item] {
                return cache
            } else {
                var matches = self.items.filter { (item) -> Bool in
                    guard let userId = item.user else {
                        return false
                    }
                    
                    return userId == user
                }
                
                matches.sort(by: { $0.timestamp! < $1.timestamp! })
                userPhotos[user] = matches as JSONObject
                return matches
            }
        case .Zone:
            
            guard let zoneString = value as? String else {
                return []
            }
            
            if let cache = zonePhotos[zoneString] as? [Item] {
                return cache
            } else {
                guard zoneString != "Unassigned" else {
                    var matches = self.items.filter { (item) -> Bool in
                        return item.location == nil
                    }
                    
                    matches.sort(by: { $0.timestamp! < $1.timestamp! })
                    zonePhotos[zoneString] = matches as JSONObject
                    return matches
                }
                
                let components = zoneString.components(separatedBy: "~")
                
                guard components.count == 2 else {
                    return []
                }
                
                let locationId = components[0]
                let zone = components[1]
                
                if zone == "Unassigned" {
                    var matches = items.filter { (item) -> Bool in
                        return item.location == locationId && item.location_zone == nil
                    }
                    
                    matches.sort(by: { $0.timestamp! < $1.timestamp! })
                    zonePhotos[zoneString] = matches as JSONObject
                    return matches
                } else {
                    var matches = items.filter { (item) -> Bool in
                        return item.location == locationId && item.location_zone == zone
                    }
                    
                    matches.sort(by: { $0.timestamp! < $1.timestamp! })
                    zonePhotos[zoneString] = matches as JSONObject
                    return matches
                }
                
            }
        }
    }
}

// MARK: - Photo

@objcMembers class Photo: APIModel, LocationProtocol {

    // MARK: - Descriptors
    
    override var descriptor: String {
        return "Photo"
    }
    
    override var modelType: ModelType {
        return ModelType.Photo
    }
    
    override var entityName: String {
        return "CorePhoto"
    }
    
    override var keys: [String] {
        return [ "id", "timestamp", "filename", "organization", "title", "notes", "user", "location", "sheet", "entry", "chatroom", "message", "activity", "latitude", "longitude", "location_zone", "source"]
    }
    
    // MARK: - Initializers
    
    override func commonInit() {
        super.commonInit()
        
        nytPhoto = NYTPhotoBox(info: NYTPhotoInfo(photo: self))
    }
    
    // MARK: - Other Properties

    var filename: String?
    var title: String?
    var message: String?
    var notes: String?
    var user: String?
    var location: String?
    var sheet: String?
    var entry: String?
    var activity: String?
    var chatroom: String?
    var location_zone: String?
    var source: String?
    var latitude: String?
    var longitude: String?
    var organization: String?
    
    var model: String?
    var modelId: String?
    var uid: String?
    var index: Int = -1
    
    var observePlaceholderUpdates: Bool = false
    
    var nytPhoto: NYTPhotoBox!

    var base64Image: String? {
        
        get {
            return PhotoAssets.retrieveValue(id: id, key: "base64Image") as? String
        }
        
        set {
            guard let data = newValue else {
                return
            }
            
            PhotoAssets.setValue(id: id, key: "base64Image", value: data)
        }
    }
    
    var base64Placeholder: String? {
        
        get {
            return PhotoAssets.retrieveValue(id: id, key: "base64Placeholder") as? String
        }
        
        set {
            guard let data = newValue else {
                return
            }
            
            PhotoAssets.setValue(id: id, key: "base64Placeholder", value: data)
        }
    }
    
    var image: UIImage? {
        
        get {
            guard let data = base64Image else {
                return nil
            }
            
            return data.base64Image()
        }
        
        set {
            guard let image = newValue else {
                return
            }
            
            base64Image = image.base64String()
        }
    }
    
    var placeholder: UIImage? {
        
        get {
            guard let data = base64Placeholder else {
                return nil
            }
            
            return data.base64Image()
        }
        
        set {
            guard let image = newValue else {                return
            }
            
            base64Placeholder = image.base64String()
        }
    }
    

    var url: String? {
        guard let filename = self.filename, let orgId = Auth.shared.orgId else {
            return nil
        }

        return String(format: "https://d8g600943jepr.cloudfront.net/serverless-image-handler-ui/img/%@/%@", arguments: [orgId, filename])
    }
    
    var placeholderUrl: String? {
        guard let filename = self.filename, let orgId = Auth.shared.orgId else {
            return nil
        }
        
        return String(format: "https://d8g600943jepr.cloudfront.net/fit-in/300x300/serverless-image-handler-ui/img/%@/%@", arguments: [orgId, filename])
    }
    
    // MARK: - API Protocol Values
    
    override var createUrl: String? {
        guard let orgId = Auth.shared.orgId, let model = self.model, let modelId = self.modelId else {
            return nil
        }
        
        return String(format: "%@/organizations/%@/photos/upload/%@/%@", arguments: [APIClient.shared.baseURL, orgId, model, modelId])
    }

    override func create(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        let function: String = "create"

        let start = Date()

        guard let authToken = Auth.shared.authToken, let url = createUrl, var image = initialValue as? UIImage, let createdBy = Auth.shared.id else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(APIClientErrors.InputError, initialValue)
            return
        }
        
        let headers = ["Authorization": authToken]

        image = image.correctlyOrientedImage()
        let imageBytes = image.height * image.width * 4
        let maxBytes = CGFloat(pow(8.0, 6.0) * 3.0)
        let imageQuality = imageBytes > maxBytes ? maxBytes / imageBytes : 1.0
        guard let imageData = UIImageJPEGRepresentation(image, imageQuality) else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InternalError)
            callback(APIClientErrors.InternalError, initialValue)
            return
        }

        Alamofire.upload(
            multipartFormData: { multipartFormData in

                
                for key in self.keys {
                    if let value = self.value(forKey: key) as? String {
                        multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key)
                    }
                }
        
                let timestamp = APIClient.shared.formatter.string(from: self.timestamp ?? Date())
                multipartFormData.append("\(timestamp)".data(using: String.Encoding.utf8)!, withName: "timestamp")
                multipartFormData.append("\(createdBy)".data(using: String.Encoding.utf8)!, withName: "createdBy")
                
                multipartFormData.append(imageData, withName: "photo", fileName: "image.jpg", mimeType: "image/jpg")
            },
            to: url,
            headers: headers,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in

                        guard let jsonResponse = response.result.value as? [String: Any] else {
                            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                                        _functionDescriptor: function,
                                                        _url: url,
                                                        _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                                        _start: start,
                                                        _error: APIClientErrors.DataError,
                                                        _response: nil,
                                                        _body: response.result.value as JSONObject)
                            callback(APIClientErrors.DataError, initialValue)
                            return
                        }

                        self.id = jsonResponse["id"] as? String
                        self.filename = jsonResponse["filename"] as? String
                        self.nytPhoto = NYTPhotoBox(info: NYTPhotoInfo(photo: self))
                        
                        self.entity = self.createEntity()
        
                        self.image = UIImage(data: imageData)
                        
                        if let placeholderData = UIImageJPEGRepresentation(image, imageQuality * 0.1) {
                            self.placeholder = UIImage(data: placeholderData)
                        }
                        
                        APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                                      _functionDescriptor: function,
                                                      _url: url,
                                                      _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                                      _start: start,
                                                      _body: response.result.value as JSONObject)

                        APIUpdater.shared.post(type: self.modelType, action: .Create, model: self)
                        callback(nil, initialValue)
                        return
                    }
                case let .failure(encodingError):
                    APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                                _functionDescriptor: function,
                                                _url: url,
                                                _params: ["encodingError": encodingError as JSONObject],
                                                _start: start,
                                                _error: APIClientErrors.InternalError)
                    callback(APIClientErrors.InternalError, initialValue)
                    return
                }
            }
        )
    }
    
    override var retrieveUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/photos/%@/info", arguments: [orgId, id])
    }
    
    override func processRetrieve(data: JSON) -> JSON? {
        let photo = Photo(attrs: data)
        
        let container: JSON = [
            "model": photo as JSONObject,
            ]
        
        return container
    }

    override var updateUrl: String? {
         guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/photos/%@", arguments: [orgId, id])
    }
    
   override  var deleteUrl: String? {
        guard let orgId = Auth.shared.orgId, let id = self.id else {
            return nil
        }
        
        return String(format: "/organizations/%@/photos/%@?hard=true", arguments: [orgId, id])
    }
    
    // MARK: - Additional Methods

    func download(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard self.image == nil else {
            callback(nil, nil)
            return
        }
        
        let function: String = "download"

        let start = Date()

        guard let authToken = Auth.shared.authToken, let url = self.url, let nsurl = NSURL(string: url) else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValue": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(nil, initialValue)
            return
        }

        let request = NSMutableURLRequest(url: nsurl as URL)
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let session: URLSession = initialValue as? URLSession ?? APIClient.shared.downloadSession
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            
            guard error == nil else {
                Async.waterfall(session, [self.download], end: { _, _ in })
                return
            }
            
            guard let response = data, let image = UIImage(data: response) else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                            _start: start,
                                            _error: APIClientErrors.DataError)
                callback(APIClientErrors.DataError, initialValue)
                return
            }

            DispatchQueue.main.async {
                self.image = image
                self.nytPhoto?.image = self.image
                
                if let uid = self.uid {
                    let userInfo: [AnyHashable: Any] = [
                        "image": image,
                        "uid": uid,
                        "status": MessageStatus.success,
                        ]
                    
                    Notifications.shared.chat_photo_retrieved.post(userInfo)
                }
            }
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                          _start: start,
                                          _body: nil)

            callback(nil, initialValue)
        }

        task.resume()
    }
    
    
    func downloadPlaceholder(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?) {
        
        guard self.placeholder == nil else {
            callback(nil, nil)
            return
        }
        
        let function: String = "downloadPlaceholder"
        
        let start = Date()
        
        guard let authToken = Auth.shared.authToken, let url = self.placeholderUrl, let nsurl = NSURL(string: url) else {
            APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                        _functionDescriptor: function,
                                        _url: "nil",
                                        _params: ["initialValue": initialValue.debugDescription as JSONObject],
                                        _start: start,
                                        _error: APIClientErrors.InputError)
            callback(nil, initialValue)
            return
        }
        
        let request = NSMutableURLRequest(url: nsurl as URL)
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let session: URLSession = initialValue as? URLSession ?? APIClient.shared.defaultSession
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            
            guard error == nil else {
                Async.waterfall(session, [self.downloadPlaceholder], end: { _, _ in })
                return
            }
            
            guard let response = data, let image = UIImage(data: response) else {
                APIDiagnostics.shared.ERROR(_classDescription: self.descriptor,
                                            _functionDescriptor: function,
                                            _url: url,
                                            _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                            _start: start,
                                            _error: APIClientErrors.DataError)
                callback(APIClientErrors.DataError, initialValue)
                return
            }
            
            DispatchQueue.main.async {
                self.placeholder = image
                
                if self.observePlaceholderUpdates == true {
                    Notifications.shared.image_placeholder_retrieved.post(["photo": self])
                    self.observePlaceholderUpdates = false
                }
            }
            
            APIDiagnostics.shared.SUCCESS(_classDescription: self.descriptor,
                                          _functionDescriptor: function,
                                          _url: url,
                                          _params: ["initialValues": initialValue.debugDescription as JSONObject],
                                          _start: start,
                                          _body: nil)
            
            callback(nil, initialValue)
        }
        
        task.resume()
    }
}


@objcMembers class PhotoAssets: NSObject {
    
    override init() {
        super.init()
    }
    
    static let shared: PhotoAssets = PhotoAssets()
    
    static var descriptor: String = "PhotoAssets"
    typealias Item = PhotoAssets
    
    static var entityName: String = "CorePhotoAssets"
    
    class func setValue(id: String?, key: String?, value: Any?) {
        guard let id = id, let key = key, let context = AppDelegate.managedContext else {
            return
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        
        do {
            let matches = try context.fetch(fetchRequest)
            
            if let match = matches.first {
                
                match.setValue(value, forKey: key)
                match.setValue(Date(), forKey: "timestamp")
                
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Error Setting Value of \(self.entityName). \(error), \(error.userInfo)")
                }
            } else {
                guard let context = AppDelegate.managedContext, let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: context) else {
                    return
                }
                
                let object = NSManagedObject(entity: entity, insertInto: context)
                
                object.setValue(id, forKey: "id")
                object.setValue(Date(), forKey: "timestamp")
                object.setValue(value, forKey: key)
                
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Error Setting Value of \(self.entityName). \(error), \(error.userInfo)")
                }
            }
        } catch let error as NSError {
            print("Error Setting Value of \(self.entityName). \(error), \(error.userInfo)")
        }
    }
    
    class func retrieveValue(id: String?, key: String?) -> Any? {
        guard let id = id, let key = key, let context = AppDelegate.managedContext else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        
        do {
            let matches = try context.fetch(fetchRequest)
            
            if let match = matches.first {
                return match.value(forKey: key)
            } else {
                return nil
            }
        } catch let error as NSError {
            print("Error Retrieving Value of \(self.entityName). \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func deleteAllEntities() {
        
        guard let context = AppDelegate.managedContext else {
            return
        }
        
        let entities = fetchAllEntities()
        for entity in entities {
            context.delete(entity)
        }
        
        AppDelegate.saveContext()
    }
    
    
    func fetchAllEntities() -> [NSManagedObject] {
        
        guard let context = AppDelegate.managedContext else {
            return []
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: PhotoAssets.entityName)
        
        do {
            let entities = try context.fetch(fetchRequest)
            
            print("\(PhotoAssets.entityName) Entity Fetch Success! \(entities.count) items fetched")
            
            return entities
            
        } catch let error as NSError {
            print("\(PhotoAssets.entityName) Entity Fetch Error: \(error), \(error.userInfo)")
            
            return []
        }
    }
}


class PhotoBucket: APIContainer<Photo>, APIContainerSingletonProtocol {
    
    override var entityName: String {
        return "CorePhoto"
    }
    
    override var modelType: ModelType {
        return ModelType.PhotoBucket
    }
    
    override var descriptor: String {
        return "Photo Bucket"
    }
    
    typealias Shared = PhotoBucket
    
    static var shared: Shared = Shared()
    
    override init() {
        super.init()
        
        guard let context = AppDelegate.managedContext else {
            return
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
        
        do {
            entities = try context.fetch(fetchRequest)
            
            for entity in entities {
                let item = Item(object: entity)
                items.append(item)
            }
            
            print("\(self.descriptor) Entity Fetch Success! \(entities.count) items fetched")
        } catch let error as NSError {
            print("\(self.descriptor) Entity Fetch Error: \(error), \(error.userInfo)")
        }
    }
    
    func sharedItem(attrs: JSON?) -> Item? {
        guard let attrs = attrs, let id = attrs["id"] as? String else {
            return nil
        }
        
        if let item = self[id] {
            var updatedItem: Bool = false
            for key in item.keys {
                if let value = attrs[key], item.value(forKey: key) == nil {
                    updatedItem = true
                    item.setValue(value, forKey: key)
                }
            }
            
            if updatedItem == true {
                item.saveEntity()
            }
            
            return item
        } else {
            var item: Item? = Item(attrs: attrs)
            item = add(item: item)
            return item
        }
    }
    
    func sharedEntity(id: String?) -> NSManagedObject? {
        
        guard let id = id, let context = AppDelegate.managedContext else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        
        do {
            let matches = try context.fetch(fetchRequest)
            
            if let match = matches.first {
                print("Successfully fectched \(self.entityName). id: \(id) ")
                return match
            } else {
                print("Fetch found none for \(self.entityName). id: \(id) ")
                return nil
            }
        } catch let error as NSError {
            print("Error Fetching \(self.entityName). \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func add(entity: NSManagedObject?) {
        guard let entity = entity, let id = entity.value(forKey: "id") as? String else {
            return
        }
        
        let matches = self.entities.filter { (seachItem) -> Bool in
            guard let searchId = seachItem.value(forKey: "id") as? String else {
                return false
            }
            
            return id == searchId
        }
        
        guard matches.count == 0 else {
            return
        }
        
        self.entities.append(entity)
    }
    
    func add(item: Item?) -> Item? {
        
        guard let item = item, let id = item.id else {
            return nil
        }
        
        if item.entity == nil, let entity = sharedEntity(id: id) {
            item.entity = entity
        } else {
            item.entity = item.createEntity()
            add(entity: item.entity)
        }
        
        let matches = self.items.filter { (searchItem) -> Bool in
            return id == searchItem.id
        }
        
        guard matches.count == 0 else {
            let match = matches.first
            return match
        }
        
        self.items.append(item)
        return item
    }
}


final class NYTPhotoInfo {
    // This would usually be a URL, but for this demo we load images from the bundle.
    
    var name: String
    var summary: String
    var credit: String
    var photo: Photo!
    
    init(photo: Photo) {
        self.name = photo.title ?? "Untitled"
        self.summary = photo.notes == nil || photo.notes == "" ? APIClient.shared.formatter.string(from: photo.timestamp ?? Date()) : photo.notes!
        self.photo = photo
        
        self.credit = APIClient.shared.formatter.string(from: Date())
        if let user = Users.shared[photo.user] ?? DeviceUser.shared.user {
            self.credit = String(format: "%@ %@", arguments: [user.firstName ?? "", user.lastName ?? ""])
        }
    }
    
    init(name: String, summary: String, credit: String, photo: Photo? = nil) {
        self.name = name
        self.summary = summary
        self.credit = credit
    }
}

final class PhotoViewerCoordinator: NYTPhotoViewerDataSource {
    var slideshow = [NYTPhotoBox]()
    
    lazy var photoViewer: NYTPhotosViewController = {
        NYTPhotosViewController(dataSource: self)
    }()
    
    init(images: [NYTPhotoBox]) {
        for image in images {
            slideshow.append(image)
        }
        fetchPhotos()
    }
    
    func fetchPhotos() {
        for box in slideshow {
            photoViewer.update(box)
        }
    }
    
    // MARK: NYTPhotoViewerDataSource
    
    @objc
    var numberOfPhotos: NSNumber? {
        return NSNumber(integerLiteral: slideshow.count)
    }
    
    @objc
    func index(of photo: NYTPhoto) -> Int {
        guard let box = photo as? NYTPhotoBox else { return NSNotFound }
        return slideshow.index(where: { $0.info.photo.id  == box.info.photo.id   }) ?? NSNotFound
    }
    
    @objc
    func photo(at index: Int) -> NYTPhoto? {
        guard index < slideshow.count else { return nil }
        return slideshow[index]
    }
}

final class NYTPhotoBox: NSObject, NYTPhoto {
    var info: NYTPhotoInfo!
    var image: UIImage?
    var placeholderImage: UIImage?
    
    var imageData: Data? {
        return nil
    }
    
    init(info: NYTPhotoInfo) {
        self.info = info
    }
    
    var attributedCaptionTitle: NSAttributedString? {
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 14.0)!]
        return NSAttributedString(string: info.name, attributes: attributes as [NSAttributedStringKey: Any])
    }
    
    var attributedCaptionSummary: NSAttributedString? {
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 12.0)!]
        return NSAttributedString(string: info.summary, attributes: attributes as [NSAttributedStringKey: Any])
    }
    
    var attributedCaptionCredit: NSAttributedString? {
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.lightGray, NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 12.0)!]
        return NSAttributedString(string: info.credit, attributes: attributes as [NSAttributedStringKey: Any])
    }
}

// MARK: NSObject Equality

extension NYTPhotoBox {
    @objc
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherPhoto = object as? NYTPhotoBox else { return false }
        return info.photo.id == otherPhoto.info.photo.id
    }
}

