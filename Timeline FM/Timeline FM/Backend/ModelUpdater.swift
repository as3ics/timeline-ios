//
//  ModelUpdater.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Model {
    
    var id: String
    var type: ModelType
    var action: ModelAction
    weak var user: User!

    init(id: String, user: User, type: ModelType, action: ModelAction) {
        self.id = id
        self.type = type
        self.action = action
        self.user = user
    }

    func process() {
        print("Processing Model Updates -> Type: \(type.rawValue) Action: \(action.rawValue)")

        guard type.socketUpdateSupported() && action.socketUpdateSupported() else {
            print("Error: Model Type Not Handled")
            return
        }

        switch action {
        case .Create:
            switch type {
            case ModelType.Activity:
                let item = Activity(attrs: ["id": self.id as JSONObject])
                item.retrieve { _ in }
                break
            case ModelType.Location:
                let item = Location(attrs: ["id": self.id as JSONObject])
                item.retrieve { _ in }
                break
            case ModelType.User:
                let item = User(attrs: ["id": self.id as JSONObject])
                item.retrieve { _ in }
                break
            default:
                break
            }
            break
        case .Delete:
            switch type {
            case ModelType.Activity:
                let item = Activity(attrs: ["id": self.id as JSONObject])
                APIUpdater.shared.post(type: .Activity, action: .Delete, model: item)
                break
            case ModelType.Location:
                let item = Location(attrs: ["id": self.id as JSONObject])
                APIUpdater.shared.post(type: .Location, action: .Delete, model: item)
                break
            case ModelType.User:
                let item = User(attrs: ["id": self.id as JSONObject])
                APIUpdater.shared.post(type: .User, action: .Delete, model: item)
                break
            default:
                break
            }
            break
        case .Update:
            switch type {
            case ModelType.Activity:
                let item = Activity(attrs: ["id": self.id as JSONObject])
                Activities.shared.remove(item)
                item.retrieve { _ in }
                break
            case ModelType.Location:
                let item = Location(attrs: ["id": self.id as JSONObject])
                Locations.shared.remove(item)
                Async.waterfall(nil, [item.retrieve, item.retrievePhotos], end: { _, _ in })
                break
            case ModelType.User:
                let item = User(attrs: ["id": self.id as JSONObject])
                Users.shared.remove(item)
                item.retrieve { _ in }
                break
            default:
                break
            }
            break
        default:
            break
        }
    }
}

class ModelUpdater {
    
    static let shared = ModelUpdater()
    
    func initialize() {
        
    }

    init() {
        Notifications.shared.model_update.observe(self, selector: #selector(updateModel(_:)))
    }

    @objc func updateModel(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate, let model = update.model else {
            Notifications.shared.model_updated.post(notification.userInfo)
            return
        }

        switch update.action {
        case .Create:

            if let entry = model as? Entry, let entries = entry.sheet?.entries {
                if entry.sheet === DeviceUser.shared.sheet {
                    LocationManager.shared.resetBreadcrumbLocation()
                    LocationManager.shared.resetDebounce()
                }
                
                entries.add(model)
            }

            /*
            if let photo = model as? Photo, photo.model == .Entry, let entry = photo.entry  {
                entry.photos.add(model)
            }
            */
            
            if let breadcrumb = model as? Breadcrumb, let entry = DeviceUser.shared.sheet?.entries.latest {
                entry.meters = breadcrumb.distance
                entry.breadcrumbs.append(breadcrumb)
                
                NotificationManager.shared.new_breadcrumb.post()
            }
            
            if let sheet = model as? Sheet {
                if let user = Users.shared[sheet.user] {
                    user.sheet = sheet
                } else {
                    DeviceUser.shared.sheet = sheet
                }
            }

            if let activity = model as? Activity{
                Activities.shared.add(activity)
            }

            if let location = model as? Location {
                Locations.shared.add(location, insert: true)
            }

            if let chatroom = model as? Chatroom {
                chatroom.retrieve { _ in }
            }

            if let override = model as? Override{
                Overrides.shared.add(override)
            }
            
            if let user = model as? User {
                Users.shared.add(user)
            }

            if let message = model as? Message, let chatroom = Chatrooms.shared[message.chatroom] {
                chatroom.messages.add(message)
                chatroom.latestMessage = message
            }

            break
        case .Delete:

            if let entry = model as? Entry, let entries = entry.sheet?.entries {
                entries.remove(model)
            }
            
            if let user = model as? User {
                Users.shared.remove(user)
            }

            if let activity = model as? Activity {
                Activities.shared.remove(activity)
            }

            if let location = model as? Location {
                Locations.shared.remove(location)
                
                if let context = AppDelegate.managedContext, let entity = location.entity {
                    context.delete(entity)
                    location.entity = nil
                    
                    AppDelegate.saveContext()
                }
            }

            if let chatroom = model as? Chatroom {
                Chatrooms.shared.remove(chatroom)
            }

            if let override = model as? Override {
                Overrides.shared.remove(override)
            }
            
            if let sheet = model as? Sheet {
                if sheet.id == DeviceUser.shared.sheet?.id {
                    DeviceUser.shared.sheet = nil
                    
                    LocationManager.shared.resetDebounce()
                } else if let user = Users.shared[sheet.id] {
                    user.sheet = nil
                }
            }

            break
        case .Update:
            break
        case .Retrieve:

            if let activity = model as? Activity{
                Activities.shared.add(activity)
            }

            if let location = model as? Location {
                Locations.shared.add(location, insert: true)
                Locations.shared.entities.append(location.entity!)
            }

            if let activity = model as? User {
                Users.shared.add(activity)
            }
            
            if let chatroom = model as? Chatroom {
                Chatrooms.shared.add(chatroom)
            }

            break
        case .Submit:
            if let sheet = model as? Sheet {
                if sheet.id == DeviceUser.shared.sheet?.id {
                    DeviceUser.shared.sheet?.cleanse()
                    DeviceUser.shared.sheet = nil
                    
                    if let user = DeviceUser.shared.user {
                        Async.waterfall(nil, [user.retrieveStatistics], end: { _, _ in
                            Sidebar.refresh()
                        })
                    }
                    
                    LocationManager.shared.resetDebounce()
                } else if let user = Users.shared[sheet.user] {
                    user.sheet?.cleanse()
                    user.sheet = nil
                }
            }
            break
        }

        Notifications.shared.model_updated.post(data)
    }
    
    func processPayload(payload: JSON?) {
        
        guard let data = payload, let _action = data["action"] as? String, let action = ModelAction(rawValue: _action),  let _type = data["type"] as? String, let type = ModelType(rawValue: _type), let model = data["model"] as? JSON, let createdBy = data["createdBy"] as? JSON else {
            print("Socket - Invalid Data recieved from Server")
            return
        }
        
        let user = User(attrs: createdBy)
        
        guard let userId = user.id, userId != Auth.shared.id else { return }
        
        switch type {
        case .Entry:
            if let subscription = Subscriptions.shared.get(userId: userId) {
                switch action {
                case .Create, .Update:
                    let entry = Entry(attrs: model)
                    subscription.entry = entry
                case .Delete, .Submit:
                    subscription.entry = nil
                default:
                    break
                }
            }
            break
        case .Breadcrumb:
            if let subscription = Subscriptions.shared.get(userId: userId) {
                let breadcrumb = Breadcrumb(attrs: model)
                subscription.breadcrumb = breadcrumb
            }
            break
        case .Sheet:
            if let subscription = Subscriptions.shared.get(userId: userId) {
                switch action {
                case .Create:
                    let sheet = Sheet(attrs: model)
                    subscription.sheet = sheet
                case .Update:
                    let sheet = Sheet(attrs: model)
                    if sheet.submissionDate != nil {
                        subscription.sheet = nil
                        subscription.entry = nil
                        subscription.breadcrumb = nil
                    } else {
                        subscription.sheet = sheet
                    }
                default:
                    break
                }
                
            }
            break
        case .Chatroom:
            let chatroom = Chatroom(attrs: model)
            APIUpdater.shared.post(type: chatroom.modelType, action: action, model: chatroom)
        default:
            break
        }
        
    }
}


extension ModelType {
    func socketUpdateSupported() -> Bool {
        guard self == .Activity || self == .Location || self == .User else {
            return false
        }
        
        return true
    }
}

extension ModelAction {
    func socketUpdateSupported() -> Bool {
        guard self == .Create || self == .Delete || self == .Update else {
            return false
        }
        
        return true
    }
}
