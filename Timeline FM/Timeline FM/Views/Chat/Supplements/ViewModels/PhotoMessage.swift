//
//  PhotoMessage.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/2/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation

import Chatto
import ChattoAdditions
import CoreLocation

class PhotoModel: PhotoMessageModel<MessageModel> {
    static let chatItemType = "photo"

    override init(messageModel: MessageModel, imageSize: CGSize, image: UIImage) {
        super.init(messageModel: messageModel, imageSize: imageSize, image: image)
    }

    var status: MessageStatus {
        get {
            return _messageModel.status
        } set {
            _messageModel.status = newValue
        }
    }
}

class PhotoViewModel: PhotoMessageViewModel<PhotoModel> {
    override init(photoMessage: PhotoModel, messageViewModel: MessageViewModelProtocol) {
        super.init(photoMessage: photoMessage, messageViewModel: messageViewModel)
    }
}

class PhotoBuilder: ViewModelBuilderProtocol {
    let defaultBuilder = MessageViewModelDefaultBuilder()

    func canCreateViewModel(fromModel decoratedPhotoMessage: Any) -> Bool {
        return decoratedPhotoMessage is PhotoModel
    }

    func createViewModel(_ decoratedPhotoMessage: PhotoModel) -> PhotoViewModel {
        let photoMessageViewModel = PhotoViewModel(photoMessage: decoratedPhotoMessage, messageViewModel: defaultBuilder.createMessageViewModel(decoratedPhotoMessage))

        if photoMessageViewModel.isIncoming == true {
            if let image = Users.shared[decoratedPhotoMessage.senderId]?.profilePicture {
                photoMessageViewModel.avatarImage = Observable(image)
                photoMessageViewModel.showsAvatar = true
            } else {
                photoMessageViewModel.avatarImage = Observable(AssetManager.shared.avatar)
                photoMessageViewModel.showsAvatar = true
            }
        } else {
            if let image = DeviceUser.shared.user?.profilePicture {
                photoMessageViewModel.avatarImage = Observable(image)
            }
        }

        return photoMessageViewModel
    }
}

class PhotoHandler: BaseMessageInteractionHandlerProtocol {
    func userDidTapOnFailIcon(viewModel: PhotoViewModel, failIconView _: UIView) {
        let uid = viewModel._photoMessage.uid
        let chatroomId = Chatrooms.connectedChatroom?.id
        let date = viewModel._photoMessage.date
        let image = viewModel._photoMessage.image

        let photo = Photo()
        photo.model = ModelType.Chatroom.rawValue
        photo.modelId = chatroomId
        photo.uid = uid

        NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.sending])

        Async.waterfall(image, [photo.create]) { (error, returnValue) in
            guard error == nil else {
                NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.failed])
                return
            }
            
            Chatrooms.connectedChatroom?.photos.add(photo)
            
            let serverMessage = Message()
            serverMessage.timestamp = date
            serverMessage.chatroom = chatroomId
            serverMessage.messageKind = MessageKind.Photo
            serverMessage.photo = photo.filename
            serverMessage.content = "photo"
            
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
    }

    func userDidTapOnAvatar(viewModel _: PhotoViewModel) {
        
    }

    
    var debounce: Date = Date()
    
    func userDidTapOnBubble(viewModel: PhotoViewModel) {
        
        guard debounce.timeIntervalSinceNow < -1.0 else {
            return
        }
        
        debounce = Date()
        
        if let image = viewModel.image.value {
            NotificationManager.shared.chat_photo_selected.post(["image": image, "uid": viewModel.photoMessage.uid])
        }
    }

    func userDidEndLongPressOnBubble(viewModel _: PhotoViewModel) {
        
    }

    func userDidBeginLongPressOnBubble(viewModel _: PhotoViewModel) {
        
    }
}
