//
//  DataSource.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/7/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Chatto
import ChattoAdditions
import Foundation
import CoreLocation

class DataSource: ChatDataSourceProtocol {
    var chatroom: Chatroom?
    var messages: Messages?

    var delegate: ChatDataSourceDelegateProtocol?

    var controller: ChatItemsController!

    var chatItems: [ChatItemProtocol] {
        return controller?.items ?? []
    }
    
    func relinquish() {
        self.controller.unload()
        self.chatroom = nil
        self.messages = nil
        self.controller = nil
        self.delegate = nil
    }


    init(totalMessages: [ChatItemProtocol]) {
        
        self.controller = ChatItemsController()
        
        controller.totalMessages = totalMessages
        controller.loadIntoItemsArray(messagesNeeded: totalMessages.count)

        Notifications.shared.chat_photo_retrieved.observe(self, selector: #selector(updateLoadingPhoto))
        NotificationManager.shared.chat_item_status_update.observe(self, selector: #selector(updateMessageStatus))
    }

    func setChatroom(_ chatroom: Chatroom?) {
        self.chatroom = chatroom
        controller.chatroom = chatroom
        self.messages = chatroom?.messages
    }

    var hasMoreNext: Bool {
        return false
    }

    var hasMorePrevious: Bool {
        return true
    }

    func loadNext() {
    }

    func loadPrevious() {
        guard let messages = messages else {
            return
        }
        
        controller.loadPrevious(messages: messages) { success in
            if success == true {
                self.delegate?.chatDataSourceDidUpdate(self, updateType: .pagination)
            }
        }
    }

    func addMessage(message: ChatItemProtocol) {
        controller.insertItem(message: message)
        delegate?.chatDataSourceDidUpdate(self)
    }

    func updatePhotoMessage(uid: String, status: MessageStatus) {
        if let index = self.controller.items.index(where: { (message) -> Bool in
            message.uid == uid
        }) {
            let message = controller.items[index] as! PhotoModel
            message.status = status
            delegate?.chatDataSourceDidUpdate(self)
        }
    }

    @objc func updateMessageStatus(_ notification: NSNotification) {
        let info = notification.userInfo as! [String: Any]
        let uid = info["uid"] as! String
        let status = info["status"] as! MessageStatus

        if let index = self.controller.items.index(where: { (message) -> Bool in
            message.uid == uid
        }) {
            let item = controller.items[index] as! MessageModelProtocol
            let model = MessageModel(uid: item.uid, senderId: item.senderId, type: item.type, isIncoming: item.isIncoming, date: item.date, status: status)

            switch item.type {
            case TextModel.chatItemType:
                let text = (controller.items[index] as! TextModel).text
                let textModel = TextModel(messageModel: MessageModel(uid: item.uid, senderId: item.senderId, type: TextModel.chatItemType, isIncoming: item.isIncoming, date: item.date, status: status), text: text)

                controller.items[index] = textModel
                delegate?.chatDataSourceDidUpdate(self)
            case PhotoModel.chatItemType:
                let photo = (controller.items[index] as! PhotoModel).image
                let photoModel = PhotoModel(messageModel: model, imageSize: photo.size, image: photo)
                controller.items[index] = photoModel
                delegate?.chatDataSourceDidUpdate(self)
            default:
                break
            }
        }
    }

    @objc func updateLoadingPhoto(_ notification: Notification) {
        let info = notification.userInfo as! [String: Any]
        let image = info["image"] as! UIImage
        let uid = info["uid"] as! String
        let status = info["status"] as! MessageStatus
        if let index = self.controller?.items.index(where: { (message) -> Bool in
            message.uid == uid
        }) {
            let item = controller.items[index] as! PhotoModel
            let model = MessageModel(uid: item.uid, senderId: item.senderId, type: item.type, isIncoming: item.isIncoming, date: item.date, status: status)
            let photoMessage = PhotoModel(messageModel: model, imageSize: image.size, image: image)
            controller.items[index] = photoMessage
            delegate?.chatDataSourceDidUpdate(self)
        }
    }

    @objc func updateReadReceipt(notification: Notification) {
        let info = notification.userInfo as! [String: Any]
        let chatroomId = info["chatroomId"] as! String

        guard chatroomId == chatroom?.id else {
            return
        }

        delegate?.chatDataSourceDidUpdate(self)
    }

    func adjustNumberOfMessages(preferredMaxCount _: Int?, focusPosition: Double, completion: (Bool) -> Void) {
        if focusPosition > 0.9 {
            controller.adjustWindow()
            completion(true)
        } else {
            completion(false)
        }
    }
}
