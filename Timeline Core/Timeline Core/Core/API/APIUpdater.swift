//
//  APIUpdater.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation

enum ModelAction: String {
    case Create = "CREATE"
    case Update = "UPDATE"
    case Delete = "DELETE"
    case Submit = "SUBMIT"
    case Retrieve = "RETRIEVE"
}

class ModelUpdate {
    
    let type: ModelType
    let action: ModelAction
    var model: APIModelProtocol?
    var parent: Any?
    
    init(type: ModelType,
         action: ModelAction,
         model: APIModelProtocol? = nil,
         parent _: Any? = nil) {
        self.type = type
        self.action = action
        self.model = model
    }
}

class APIUpdater {
    
    static let shared: APIUpdater = APIUpdater()
    
    func post(type: ModelType, action: ModelAction, model: APIModelProtocol) {
        let update = ModelUpdate(type: type, action: action, model: model)
        
        Notifications.shared.model_update.post(["update": update])
    }
    
    func post(type: ModelType, action: ModelAction) {
        let update = ModelUpdate(type: type, action: action)
        
        Notifications.shared.model_update.post(["update": update])
    }
    
}
