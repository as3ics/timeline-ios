//
//  TextMessage.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/2/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Chatto
import ChattoAdditions
import Foundation
import CoreLocation

class TextModel: TextMessageModel<MessageModel> {
    static let chatItemType = "text"

    override init(messageModel: MessageModel, text: String) {
        super.init(messageModel: messageModel, text: text)
    }
}

class ViewModel: TextMessageViewModel<TextModel> {
    override init(textMessage: TextModel, messageViewModel: MessageViewModelProtocol) {
        super.init(textMessage: textMessage, messageViewModel: messageViewModel)
    }
}

class TextBuilder: ViewModelBuilderProtocol {
    let defaultBuilder = MessageViewModelDefaultBuilder()

    func canCreateViewModel(fromModel decoratedTextMessage: Any) -> Bool {
        return decoratedTextMessage is TextModel
    }

    func createViewModel(_ decoratedTextMessage: TextModel) -> ViewModel {
        let textMessageViewModel = ViewModel(textMessage: decoratedTextMessage, messageViewModel: defaultBuilder.createMessageViewModel(decoratedTextMessage))

        if textMessageViewModel.isIncoming == true {
            if let image = Users.shared[decoratedTextMessage.senderId]?.profilePicture {
                textMessageViewModel.avatarImage = Observable(image)
                textMessageViewModel.showsAvatar = true
            } else {
                textMessageViewModel.avatarImage = Observable(AssetManager.shared.avatar)
                textMessageViewModel.showsAvatar = true
            }
        } else {
            if let image = DeviceUser.shared.user?.profilePicture {
                textMessageViewModel.avatarImage = Observable(image)
            }
        }

        return textMessageViewModel
    }
}

class TextHandler: BaseMessageInteractionHandlerProtocol {
    func userDidTapOnFailIcon(viewModel: ViewModel, failIconView _: UIView) {
        let uid = viewModel.textMessage.uid
        let chatroomId = Chatrooms.connectedChatroom?.id
        let date = viewModel.textMessage.date
        let text = viewModel.textMessage.text

        NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.sending])

        let serverMessage = Message()
        serverMessage.timestamp = date
        serverMessage.chatroom = chatroomId
        serverMessage.content = text
        serverMessage.messageKind = MessageKind.Text

        serverMessage.create({ success in
            if success == true {
                Chatrooms.connectedChatroom?.messages.insert(serverMessage)
                NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.success])
                // soundGenerator.playSent()
            } else {
                NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.failed])
            }
        })
    }

    func userDidTapOnAvatar(viewModel _: ViewModel) {
    }

    func userDidTapOnBubble(viewModel _: ViewModel) {
    }

    func userDidEndLongPressOnBubble(viewModel _: ViewModel) {
    }

    func userDidBeginLongPressOnBubble(viewModel _: ViewModel) {
    }
}
