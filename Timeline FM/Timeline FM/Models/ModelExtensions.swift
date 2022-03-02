//
//  ModelExtensions.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import IQKeyboardManagerSwift
import PKHUD
import ActionSheetPicker_3_0

// MARK: - Activity

extension Activity {
    
    // MARK: - Navigation Shortcuts
    
    func view() {
        let destination = UIStoryboard.Activity(identifier: "ViewActivity") as! ViewActivity
        
        destination.index = Activities.shared.index(id: self.id)
        destination.mode = ViewingMode.Viewing
        
        Presenter.push(destination)
    }
    
    func edit() {
        let destination = UIStoryboard.Activity(identifier: "ViewActivity") as! ViewActivity
        
        destination.index = Activities.shared.index(id: self.id)
        destination.mode = ViewingMode.Editing
        
        Presenter.push(destination)
    }
    
    func create() {
        let destination = UIStoryboard.Activity(identifier: "ViewActivity") as! ViewActivity
        
        destination.mode = ViewingMode.Creating
        
        Presenter.push(destination)
    }
}

// MARK: - Chatroom

extension Chatroom {
    
    // MARK: - Asset Methods
    
    func dequeCell() -> ChatRoomCell? {
        
        let cell = ChatRoomCell.loadNib()!
        cell.populate(self)
        cell.refresh()
        return cell
        
        /*
        guard let cell = asset(named: "Cell") as? ChatRoomCell else {
            let cell = ChatRoomCell.loadNib()!
            cell.populate(self)
            cell.refresh()
            addAsset(named: "Cell", cell)
            return cell
        }
        
        cell.refresh()
        return cell
        */
    }
    
    // MARK: - Navigation Shortcuts
    
    func view() {
        
        IQKeyboardManager.shared.enable = false
        NavBar.extraHeight = 20.0
        
        Async.waterfall(nil, [self.messages.retrieveNew], end: { _, _ in
            let destination = UIStoryboard.Chat(identifier: "Chat") as! Chat
            destination.chatroom = self
            self.lastMessageRead = Date()
            
            Presenter.push(destination)
        })
    }
    
    func edit() {
        
        let destination = UIStoryboard.Chat(identifier: "ChatAddRoom") as! ChatAddRoom
        
        destination.mode = ViewingMode.Editing
        destination.chatroom = self
        
        Presenter.push(destination)
    }
    
    func create() {
        
        let destination = UIStoryboard.Chat(identifier: "ChatAddRoom") as! ChatAddRoom
        destination.mode = ViewingMode.Creating
        
        Presenter.push(destination)
    }
    
}

// MARK: - Location

extension Location {
    
    // MARK: - Assets Protocol
    
    
    func dequeCell() -> LocationCell? {
        
        let cell = LocationCell.loadNib()!
        cell.populate(self)
        cell.refresh()
        return cell
        
        /*
        guard let cell = asset(named: "Cell") as? LocationCell else {
            let cell = LocationCell.loadNib()!
            cell.populate(self)
            cell.refresh()
            addAsset(named: "Cell", cell)
            return cell
        }
        
        cell.refresh()
        return cell
        */
    }
    
    func dequeCard() -> LocationObject? {
        
        let card = LocationObject.loadNib()!
        card.populate(self)
        card.refresh()
        return card
        
        /*
        guard let card = asset(named: "Card") as? LocationObject else {
            let card = LocationObject.loadNib()!
            card.populate(self)
            card.refresh()
            addAsset(named: "Card", card)
            return card
        }
        
        card.refresh()
        return card
        */
    }
    
    // MARK: - Navigation Shortcuts
    
    func view() {
        let destination = UIStoryboard.Location(identifier: "ViewLocation") as! ViewLocation
        
        destination.location = self
        destination.mode = ViewingMode.Viewing
        
        Async.waterfall(nil, [self.retrievePhotos, Stream.shared.retrieve], end: {_, _ in
            Presenter.push(destination)
        })
    }
    
    func edit() {
        let destination = UIStoryboard.Location(identifier: "ViewLocation") as! ViewLocation
        
        destination.location = self
        destination.mode = ViewingMode.Editing
        
        Presenter.push(destination)
    }
    
    func create() {
        let destination = UIStoryboard.Location(identifier: "CreateLocation") as! CreateLocation
        
        Presenter.push(destination)
    }
}


// MARK: - User

extension User {
    
    // MARK: - Asset Methods
    
    func dequeCard() -> PeopleObject? {
        
        PeopleObject.controlEvent = .touchUpInside
        let card = PeopleObject.loadNib()!
        card.populate(self)
        card.index = -1
        card.refresh()
        return card
        
        /*
        guard let card = asset(named: "Card") as? PeopleObject else {
            PeopleObject.controlEvent = .touchUpInside
            let card = PeopleObject.loadNib()!
            card.populate(self)
            card.index = -1
            card.refresh()
            addAsset(named: "Card", card)
            return card
        }
        
        card.refresh()
        return card
        */
    }
    
    // MARK: - Navigation Shortcuts
    
    func view() {
        
        var queries = [(@escaping (Error?, Any?) -> Void, Any?) -> Void]()
        
        queries.append(retrievePhotos)
        queries.append(retrieveStatistics)
        
        if let sheet = self.sheet {
            queries.append(sheet.entries.retrieve)
        }
        
        Async.waterfall(nil, queries, end: {_, _ in
            let destination = UIStoryboard.Main(identifier: "Profile") as! Profile
            
            destination.user = self
            
            Presenter.push(destination)
        })
    }
    
   func message() {
        
        delay(0.2) {
            let previousChat = Chatrooms.shared.chats.filter({ (chatroom) -> Bool in
                chatroom.chatUsers.chatUsers.first?.user?.id == self.id! && chatroom.chatUsers.count == 1
            })
            
            if previousChat.count == 0 {
                let chatroom = Chatroom()
                
                chatroom.name = "Chat"
                chatroom.purpose = "Quick Chat"
                
                chatroom.users.append(DeviceUser.shared.user!)
                chatroom.users.append(self)
                
                PKHUD.loading()
                
                chatroom.create { success in
                    guard success == true else {
                        PKHUD.failure()
                        return
                    }
                    
                    PKHUD.success()
                    
                    delay(0.5) {
                        
                        let room = Chatrooms.shared[chatroom.id]
                        
                        room?.view()
                    }
                }
            } else {
                
                previousChat.first?.view()
                
            }
        }
    }
    
    func history() {
        let destination = UIStoryboard.History(identifier: "ViewHistory") as! ViewHistory
        
        destination.user = self
        
        Presenter.push(destination)
        
    }
    
    func create() {
        Shortcuts.goCreateEmployee()
    }
    
}

// MARK: - Photos

extension Photos {
    
    // MARK: - Navigation Shortcuts
    
    func view(title: String? = "Photos") {
        
        let destination = UIStoryboard.Main(identifier: "PhotosView") as! PhotosView
        
        destination.photos = self
        destination.title = title
        
        Presenter.push(destination, animated: true)
    }
}

extension Sheet {
    
    func edit(_ sender: UIView? = nil) {
        
        guard self.entries.loaded == false else {
            let destination = UIStoryboard.Main(identifier: "SheetReview") as! SheetReview
            
            destination.sheet = self
            Presenter.push(destination, animated: true)
            return
        }
        
        PKHUD.loading()
        Async.waterfall(nil, [self.entries.retrieve]) { (error, response) in
            guard error == nil else {
                PKHUD.failure()
                return
            }
            
            PKHUD.success()
            let destination = UIStoryboard.Main(identifier: "SheetReview") as! SheetReview
            
            destination.sheet = self
            Presenter.push(destination, animated: true)
        }
        
        
        /*
        let alert = UIAlertController(title: "Timeline", message: "What would you like to do?", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alert.addAction(UIAlertAction(title: "Edit Timesheet", style: .default, handler: { (action) in
            let destination = UIStoryboard.Main(identifier: "SheetReview") as! SheetReview
            
            destination.sheet = self
            Presenter.push(destination, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            
        }))
        
        Presenter.present(alert)
        */
        
    }
    
    func commitStart(_ date: Date) {
        
    }
    
}
