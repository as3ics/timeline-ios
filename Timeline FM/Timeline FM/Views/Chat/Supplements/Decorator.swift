//
//  Decorator.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/7/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Chatto
import ChattoAdditions
import Foundation
import CoreLocation

class Avatar: BaseMessageCollectionViewCellDefaultStyle {
    override func avatarSize(viewModel: MessageViewModelProtocol) -> CGSize {
        if viewModel.showsAvatar == true {
            return CGSize(width: 30, height: 30)
        } else {
            return CGSize.zero
        }
    }
}

class Decorator: ChatItemsDecoratorProtocol {
    var chatroom: Chatroom?
    func decorateItems(_ chatItems: [ChatItemProtocol]) -> [DecoratedChatItem] {
        var decoratedItems = [DecoratedChatItem]()
        let calendar = Calendar.current
        for (index, item) in chatItems.enumerated() {
            var addTimestamp: Bool = false
            var addTail: Bool = false
            var addName: Bool = false
            var addAvatar: Bool = false
            var addReceipt: Bool = false
            var addTyping: Bool = false

            let nextMessage: ChatItemProtocol? = (index + 1 < chatItems.count) ? chatItems[index + 1] : nil
            let previousMessage: ChatItemProtocol? = (index > 0) ? chatItems[index - 1] : nil

            // Should add timestamp?
            if previousMessage == nil {
                if item is MessageModelProtocol {
                    addTimestamp = true
                }
            } else if let previousMessage = previousMessage as? MessageModelProtocol {
                if item is SystemMessageModel {
                    addTimestamp = !calendar.isDate((item as! SystemMessageModel).date, inSameDayAs: previousMessage.date)
                } else if item is MessageModelProtocol {
                    addTimestamp = !calendar.isDate((item as! MessageModelProtocol).date, inSameDayAs: previousMessage.date)
                }
            }

            // should add tail?
            addTail = true
            if item is MessageModelProtocol, nextMessage is MessageModelProtocol, (nextMessage as! MessageModelProtocol).senderId == (item as! MessageModelProtocol).senderId {
                addTail = false
            }

            // should add name?
            if previousMessage == nil {
                if let thisMessage = item as? MessageModelProtocol {
                    if thisMessage.isIncoming == false {
                        addName = false
                    } else {
                        addName = true
                    }
                }
            } else if let thisMessage = item as? MessageModelProtocol {
                if thisMessage.isIncoming == false {
                    addName = false
                } else if let previousMessage = previousMessage as? MessageModelProtocol {
                    if previousMessage.isIncoming == false {
                        addName = true
                    } else if previousMessage.senderId != thisMessage.senderId {
                        addName = true
                    }
                } else {
                    addName = true
                }
            }

            // should add avatar?
            if let thisMessage = item as? MessageModelProtocol {
                if thisMessage.senderId != Auth.shared.id {
                    addAvatar = true
                }
            }

            // should add read receipt?
            if let thisItem = item as? MessageModelProtocol, thisItem.isIncoming == false {
                addReceipt = true
            }

            if addReceipt == true, index + 1 < chatItems.count {
                for i in index + 1 ... chatItems.count - 1 {
                    if let item = chatItems[i] as? MessageModelProtocol {
                        if item is TextModel || item is PhotoModel {
                            addReceipt = false
                            break
                        }
                    }
                }
            }

            // add timestamp
            if addTimestamp == true {
                var date: Date?
                if item is SystemMessageModel {
                    date = (item as! SystemMessageModel).date
                } else if item is MessageModelProtocol {
                    date = (item as! MessageModelProtocol).date
                }

                if date != nil {
                    let timeSeperatorModel = TimeSeparatorModel(uid: UUID().uuidString, date: date!.toWeekDayAndDateString())
                    decoratedItems.append(DecoratedChatItem(chatItem: timeSeperatorModel, decorationAttributes: ChatItemDecorationAttributes(bottomMargin: 3.0, canShowTail: false, canShowAvatar: false, canShowFailedIcon: false)))
                }
            }

            // add name
            if item is MessageModelProtocol {
                if addName == true {
                    if let userIndex = Users.shared.index(id: (item as! MessageModelProtocol).senderId) {
                        let user = Users.shared.items[userIndex]
                        let nameString = String(format: "%@ %@", arguments: [user.firstName!, user.lastName!])
                        let nameViewModel = NameViewModel(uid: UUID().uuidString, name: nameString, date: Date())
                        let decoratedItem = DecoratedChatItem(chatItem: nameViewModel, decorationAttributes: ChatItemDecorationAttributes(bottomMargin: 3.0, canShowTail: false, canShowAvatar: false, canShowFailedIcon: false))
                        decoratedItems.append(decoratedItem)
                    }
                }
            }

            // add typing

            if chatroom?.getTypingUsers().count ?? 0 > 0, nextMessage == nil {
                addTyping = true
            }

            let bottomMargin = separationAfterItem(current: item, next: nextMessage, addReceipt: addReceipt)
            let decoratedItem = DecoratedChatItem(chatItem: item, decorationAttributes: ChatItemDecorationAttributes(bottomMargin: bottomMargin, canShowTail: addTail, canShowAvatar: addAvatar, canShowFailedIcon: true))

            decoratedItems.append(decoratedItem)

            if addReceipt == true {
                var date: Date?
                var status: MessageStatus?
                if item is SystemMessageModel {
                    date = (item as! SystemMessageModel).date
                } else if item is MessageModelProtocol {
                    date = (item as! MessageModelProtocol).date
                    status = (item as! MessageModelProtocol).status
                }

                var count: Int = 0
                for user in chatroom!.chatUsers.chatUsers {
                    if let lastMessageRead = user.lastMessageRead {
                        if user.connected! == true || lastMessageRead > date! {
                            count = count + 1
                        }
                    }
                }

                var message: String = "Delivered"
                if status == MessageStatus.sending {
                    message = "Sending"
                } else if status == MessageStatus.failed {
                    message = "Failed"
                }

                if count > 0 {
                    if chatroom!.users.count == 1 {
                        message = "Read"
                    } else if count == chatroom!.users.count {
                        message = "Read"
                    } else {
                        message = String(format: "Read by %i", arguments: [count])
                    }
                }

                let receiptModel = ReadReceiptModel(uid: UUID().uuidString, message: message, date: Date())
                let decoratedItem = DecoratedChatItem(chatItem: receiptModel, decorationAttributes: ChatItemDecorationAttributes(bottomMargin: 3, canShowTail: false, canShowAvatar: false, canShowFailedIcon: false))
                decoratedItems.append(decoratedItem)
            }

            if addTyping == true {
                let typingModel = TypingModel(uid: UUID().uuidString, users: chatroom!.getTypingUsers(), date: Date())
                let decoratedTypingMessage = DecoratedChatItem(chatItem: typingModel, decorationAttributes: ChatItemDecorationAttributes(bottomMargin: 3.0, canShowTail: false, canShowAvatar: false, canShowFailedIcon: false))
                decoratedItems.append(decoratedTypingMessage)
            }
        }

        return decoratedItems
    }

    func separationAfterItem(current: ChatItemProtocol?, next: ChatItemProtocol?, addReceipt: Bool) -> CGFloat {
        if addReceipt == true {
            return 3
        }

        guard let next = next else { return 10 }

        let currentMessage = current as? MessageModelProtocol
        let nextMessage = next as? MessageModelProtocol

        if currentMessage?.senderId != nextMessage?.senderId {
            return 10
        } else {
            return 3
        }
    }
}
