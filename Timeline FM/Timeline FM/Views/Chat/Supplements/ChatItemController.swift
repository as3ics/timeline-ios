//
//  ChatItemController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/7/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Chatto
import ChattoAdditions
import Foundation
import CoreLocation

class ChatItemsController {
    var items: [ChatItemProtocol] = []
    var totalMessages: [ChatItemProtocol] = []
    var chatroom: Chatroom?

    func insertItem(message: ChatItemProtocol) {
        items.append(message)
        totalMessages.append(message)
    }

    func loadIntoItemsArray(messagesNeeded: Int) {
        for index in stride(from: totalMessages.count - items.count, to: totalMessages.count - items.count - messagesNeeded, by: -1) {
            items.insert(totalMessages[index - 1], at: 0)
        }
    }
    
    func unload() {
        self.items.removeAll()
        self.totalMessages.removeAll()
        self.chatroom = nil
    }

    deinit {
        print("foo")
    }

    var isLoadingPrevious: Bool = false
    func loadPrevious(messages: Messages, _ callback: @escaping (_ success: Bool) -> Void) {
        if isLoadingPrevious == false {
            isLoadingPrevious = true
            if let fromDate = messages.items.last?.timestamp {
                messages.retrieveMoreMessages(fromDate: fromDate) { success, messages in
                    if success == true {
                        var messagesAdded: Int = 0
                        for message in messages! {
                            let dateString = APIClient.shared.formatter.string(from: message.timestamp!)
                            let userId = message.user ?? "unknown"
                            let uid = String(format: "%@-%@", arguments: [userId, dateString])
                            let incoming = Auth.shared.id == userId ? false : true

                            if message.messageKind == MessageKind.Text {
                                let textModel = TextModel(messageModel: MessageModel(uid: uid, senderId: userId, type: TextModel.chatItemType, isIncoming: incoming, date: message.timestamp!, status: MessageStatus.success), text: message.content!)
                                self.totalMessages.insert(textModel, at: 0)
                                messagesAdded += 1
                            } else if message.messageKind == MessageKind.Photo {
                                if let photo = self.chatroom?.photos.get(filename: message.photo) {
                                    let message = MessageModel(uid: uid, senderId: userId, type: PhotoModel.chatItemType, isIncoming: incoming, date: message.timestamp!, status: MessageStatus.success)
                                    photo.uid = uid
                                    
                                    if let image = photo.image {
                                        let photoMessage = PhotoModel(messageModel: message, imageSize: image.size, image: image)
                                        self.totalMessages.insert(photoMessage, at: 0)
                                    } else {
                                        let photoMessage = PhotoModel(messageModel: message, imageSize: CGSize.zero, image: UIImage())
                                        self.totalMessages.insert(photoMessage, at: 0)
                                        Async.waterfall(nil, [photo.download], end: { _, _ in
                                            self.chatroom?.photos.add(photo)
                                        })
                                    }
                                } else {
                                    let photo = Photo()
                                    photo.id = message.photo!
                                    photo.filename = message.photo!
                                    photo.uid = uid
                                    photo.chatroom = self.chatroom?.id
                                    photo.user = userId

                                    let model = MessageModel(uid: uid, senderId: userId, type: PhotoModel.chatItemType, isIncoming: incoming, date: message.timestamp!, status: MessageStatus.sending)
                                    let photoMessage = PhotoModel(messageModel: model, imageSize: CGSize.zero, image: UIImage())
                                    self.totalMessages.insert(photoMessage, at: 0)

                                    Async.waterfall(nil, [photo.download], end: { _, _ in
                                        self.chatroom?.photos.add(photo)
                                    })
                                }

                                messagesAdded += 1
                            }
                        }

                        self.loadIntoItemsArray(messagesNeeded: messagesAdded)

                        self.isLoadingPrevious = false
                        callback(true)
                    } else {
                        self.isLoadingPrevious = false
                        callback(false)
                    }
                }
            } else {
                callback(false)
            }
        } else {
            callback(false)
        }
    }

    func adjustWindow() {
        if items.count > 100 {
            items.removeFirst(items.count - 100)
        }
    }
}
