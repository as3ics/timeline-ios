//
//  Chat.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/7/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Chatto
import ChattoAdditions
import IQKeyboardManagerSwift
import Material
import PKHUD
import SocketIO
import UIKit
import CoreLocation

var _disableZoom: Bool! = false
var disableZoom: Bool! {
    set {
        _disableZoom = newValue
        if newValue == true {
            delay(0.5) {
                _disableZoom = false
            }
        }
    }

    get {
        return _disableZoom
    }
}

class Chat: BaseChatViewController, UIPopoverPresentationControllerDelegate {
    weak var navBar: NavBar?

    var presenter: BasicChatInputBarPresenter!
    var decorator: Decorator!
    var dataSource: DataSource!

    var totalMessages = [ChatItemProtocol]()
    var bottomSafeAreaView: UIView!

    weak var chatroom: Chatroom?

    var cooldownDate: Date = Date()
    var chatNavBar: UserScrollView?
    
    var photoViewerCoordinator: PhotoViewerCoordinator?
    var nytPhotos = [NYTPhotoBox]()
    var presentingPhotos: Bool = false

    override func viewDidLoad() {
        
        super.constants.defaultContentInsets = UIEdgeInsetsMake(84, 0, 10.0, 0)
        super.constants.defaultScrollIndicatorInsets = self.constants.defaultContentInsets
        
        super.viewDidLoad()
        
        navBar = NavBar(self)
        
        initializeChat()
        
        NotificationManager.shared.chat_photo_selected.observe(self, selector: #selector(pictureMessageSelected))
        NotificationManager.shared.chat_new_message.observe(self, selector: #selector(processNewMessage))
        NotificationManager.shared.chat_users_reloaded.observe(self, selector: #selector(chatUsersReloadedNotification))
        
        socketConnect()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        IQKeyboardManager.shared.enable = false
        navigationDrawerController?.isEnabled = false
    }
    
    
    override func goBack() {
        super.goBack()
        
        socketDisonnect()
        
        delay(0.5) {
            self.prepareForDeinit()
        }
    }
    
    func initializeChat() {
        
        decorator = Decorator()
        self.totalMessages.removeAll()
        for message in self.chatroom?.messages.items ?? [] {
            
            let dateString = APIClient.shared.formatter.string(from: message.timestamp!)
            let userId = message.user ?? "unknown"
            let uid = String(format: "%@-%@", arguments: [userId, dateString])
            let incoming = Auth.shared.id == userId ? false : true
            
            if message.messageKind == MessageKind.Text {
                let textModel = TextModel(messageModel: MessageModel(uid: uid, senderId: userId, type: TextModel.chatItemType, isIncoming: incoming, date: message.timestamp!, status: MessageStatus.success), text: message.content!)
                totalMessages.insert(textModel, at: 0)
                
            } else if message.messageKind == MessageKind.Photo {
                if let photo = self.chatroom?.photos.get(filename: message.photo) {
                    let message = MessageModel(uid: uid, senderId: userId, type: PhotoModel.chatItemType, isIncoming: incoming, date: message.timestamp!, status: MessageStatus.success)
                    photo.uid = uid
                    
                    if let image = photo.image {
                        let photoMessage = PhotoModel(messageModel: message, imageSize: image.size, image: image)
                        totalMessages.insert(photoMessage, at: 0)
                    } else {
                        let photoMessage = PhotoModel(messageModel: message, imageSize: CGSize.zero, image: UIImage())
                        totalMessages.insert(photoMessage, at: 0)
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
                    
                    let message = MessageModel(uid: uid, senderId: userId, type: PhotoModel.chatItemType, isIncoming: incoming, date: message.timestamp!, status: MessageStatus.sending)
                    let photoMessage = PhotoModel(messageModel: message, imageSize: CGSize.zero, image: UIImage())
                    totalMessages.insert(photoMessage, at: 0)
                    
                    Async.waterfall(nil, [photo.download], end: { _, _ in
                        self.chatroom?.photos.add(photo)
                    })
                }
            }
        }
        
        dataSource = DataSource(totalMessages: totalMessages)
        dataSource.setChatroom(chatroom)
        chatDataSource = dataSource
        decorator.chatroom = chatroom
        chatItemsDecorator = decorator
        constants.preferredMaxMessageCount = max(50, totalMessages.count)
        setChatDataSource(dataSource, triggeringUpdateType: UpdateType.firstLoad)
        
    }
    
    func prepareForDeinit() {
        
        view.endEditing(true)
        
        totalMessages.removeAll()
        
        dataSource?.relinquish()
        dataSource = nil
        
        presenter?.chatInputBar.purge(complete: true)
        presenter?.chatInputBar.removeFromSuperview()
        presenter = nil
        
        decorator?.chatroom = nil
        decorator = nil
        
        collectionView?.delegate = nil
        collectionView?.dataSource = nil
        
        (collectionView?.collectionViewLayout as? ChatCollectionViewLayout)?.delegate = nil
        
        chatNavBar?.relinquish()
        chatNavBar?.removeFromParentViewController()
        
        navBar?.relinquish()
        navBar?.removeFromSuperview()
    }
    
    func setupNavBar() {
        
        navBar?.style = .Sub
        
        navBar?.title = nil
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.rightImage = AssetManager.shared.info
        
        navBar?.leftButton.tintColor = Theme.shared.active.alternativeFontColor
        navBar?.rightButton.tintColor = Theme.shared.active.alternativeFontColor
        
        navBar?.leftEnclosure = { self.goBack() }
        navBar?.rightEnclosure = { self.infoPressed() }
        
        let seperator = UIView(frame: CGRect(x: 0, y: self.navBar!.frame.maxY - 0.5, width: self.navBar!.frame.width, height: 0.5))
        seperator.backgroundColor = UIColor.lightGray
        seperator.alpha = 1.0
        navBar?.addSubview(seperator)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.dismissKeyboard()
        
        super.viewWillDisappear(animated)
        
        self.navigationDrawerController?.isEnabled = true
        
        NavBar.extraHeight = 0.0
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        self.populateChatNavBar()
    }
    
    @objc func chatUsersReloadedNotification(_ notification: NSNotification) {
        guard let data = notification.userInfo, let chatroomId = data["chatroom"] as? String, self.chatroom?.id == chatroomId else {
            return
        }
        
        for user in self.chatroom?.chatUsers.chatUsers ?? [] {
            if let userViews = self.chatNavBar?.userViews, user.index! < userViews.count  {
                let userView = userViews[user.index!]
                userView.setConnected(user.connected!)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if bottomSafeAreaView == nil {
            
            let safeAreaHeight = view.safeAreaInsets.bottom
            bottomSafeAreaView = UIView(frame: CGRect(x: 0, y: view.frame.height - safeAreaHeight, width: view.frame.width, height: safeAreaHeight))
            bottomSafeAreaView.backgroundColor = view.backgroundColor
            
            if let view = self.view.viewWithTag(NavWrapper.TagNumber) {
                view.addSubview(bottomSafeAreaView)
            } else {
                view.addSubview(bottomSafeAreaView)
            }
            
            self.setupNavBar()
        }
    }
    
    func populateChatNavBar() {
        
        self.chatNavBar?.relinquish()
        
        self.chatNavBar = UserScrollView(self.chatroom, self.navBar!, UserScrollView.navBarConfiguration, self)
        
        var i = 0
        for user in self.chatroom?.chatUsers.chatUsers ?? [] {
            let userView = self.chatNavBar!.userViews[i]
            
            userView.view.tag = i
            userView.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.viewUserProfile)))
            userView.view.isUserInteractionEnabled = true
            userView.setConnected(user.connected!)
            i += 1
        }
        
        self.navBar?.addSubview(self.chatNavBar!.navView)
        self.chatNavBar?.activated = true
        self.chatNavBar?.navView.isUserInteractionEnabled = true
    }

    @objc func processNewMessage(_ notification: NSNotification) {
        guard let data = notification.userInfo as? JSON, let chatroom = data["chatroom"] as? Chatroom, let _message = data["message"] as? Message else {
            return
        }

        if self.chatroom?.id == chatroom.id, let message = self.chatroom?.messages[_message.timestamp] {
            // foo
            // self.chatroom?.messages.insert(message)

            self.chatroom?.resetTypingUsers()
            coolDown()
            updateUserTyping()

            let date = message.timestamp!
            let double = Double(date.timeIntervalSinceReferenceDate)
            let senderId = message.user!
            let uid = String(format: "%f-%@", arguments: [double, senderId])

            if message.messageKind == MessageKind.Photo {
                let photo = Photo()
                photo.id = message.photo!
                photo.filename = message.photo!
                photo.uid = uid
                photo.chatroom = self.chatroom?.id
                photo.user = senderId
                
                let model = MessageModel(uid: uid, senderId: senderId, type: PhotoModel.chatItemType, isIncoming: true, date: message.timestamp!, status: MessageStatus.sending)
                let photoMessage = PhotoModel(messageModel: model, imageSize: CGSize.zero, image: UIImage())

                delay(0.2) {
                    self.dataSource.addMessage(message: photoMessage)
                }

                photo.download({ error, _ in
                    guard error == nil else {
                        return
                    }

                    self.chatroom?.photos.add(photo)
                }, nil)
            } else if message.messageKind == MessageKind.Text {
                let model = MessageModel(uid: uid, senderId: senderId, type: TextModel.chatItemType, isIncoming: true, date: message.timestamp!, status: MessageStatus.success)
                let textMessage = TextModel(messageModel: model, text: message.content ?? "")

                delay(0.2) {
                    self.dataSource.addMessage(message: textMessage)
                }
            }
        }
    }

    @objc func infoPressed() {

        let destination = UIStoryboard.Chat(identifier: "ChatInfo") as! ChatInfo
        destination.chatroom = chatroom

        Presenter.push(destination, animated: true, completion: nil)
    }

    func adaptivePresentationStyle(for _: UIPresentationController, traitCollection _: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    func socketDisonnect() {
        if let start = typingStart, let end = typingStop {
            Socket.shared.socket.off(id: start)
            Socket.shared.socket.off(id: end)
        }

        Chatrooms.connectedChatroom = nil
        let _ = chatroom?.leave(Socket.shared.socket)
        chatroom?.lastMessageRead = Date()
        chatNavBar?.resetAnimation()
        
        NotificationCenter.default.removeObserver(self)
    }

    var typingStart: UUID?
    var typingStop: UUID?
    func socketConnect() {
        
        guard Chatrooms.connectedChatroom !== chatroom, self.typingStart == nil, self.typingStop == nil else {
            return
        }
        
        Chatrooms.connectedChatroom = chatroom
        
        let _ = chatroom?.join(Socket.shared.socket)
        
        self.typingStart = Socket.shared.socket.on("Chatroom-typingStart", callback: { data, _ in

            if Date().timeIntervalSince(self.cooldownDate) < 1.0 { return }

            if let resp = data[0] as? [String: AnyObject], let userData = resp["user"] as? [String: AnyObject] {
                
                guard let userId = userData["id"] as? String, userId != Auth.shared.id else {
                    return
                }
                
                let chatUser = self.chatroom!.chatUsers[userId]

                guard let index = chatUser?.index, let userView = self.chatNavBar?.userViews[index] else {
                    return
                }

                let previousValue = chatUser?.typing
                chatUser?.typing = true

                if previousValue == false {
                    self.updateUserTyping()

                    if userView.view.frame == userView.originalRect, self.chatNavBar?.navView.contentOffset == self.chatNavBar?.originalContentOffset, let targetOffet = self.getTargetOffsetToCenter(userView) {
                        self.chatNavBar?.animateUser(userView)
                        self.chatNavBar?.navView.setContentOffset(CGPoint(x: targetOffet, y: 0.0), animated: true)
                        
                        self.checkReset(user: chatUser!)
                    }
                }
            }
        })

        self.typingStop = Socket.shared.socket.on("Chatroom-typingStop", callback: { data, _ in

            if let resp = data[0] as? [String: AnyObject], let userData = resp["user"] as? [String: AnyObject] {
                
                guard let userId = userData["id"] as? String, userId != Auth.shared.id else {
                    return
                }
            
                self.chatroom!.chatUsers[userId]?.typing = false
                self.updateUserTyping()
            }
        })
    }
    
    func checkReset(user: ChatUser) {
        delay(1.0) {
            if user.typing == false {
                let userView = self.chatNavBar?.userViews[user.index!]
                self.chatNavBar?.unanimateUser(userView!, alpha: 1.0)
                self.chatNavBar?.navView.setContentOffset(CGPoint(x: self.chatNavBar!.originalContentOffset!.x, y: 0.0), animated: true)
            } else {
                self.checkReset(user: user)
            }
        }
    }

    func updateUserTyping() {
        dataSource.delegate?.chatDataSourceDidUpdate(dataSource!)
    }

    func coolDown() {
        cooldownDate = Date()
    }

    func getTargetOffsetToCenter(_ userView: UserView) -> CGFloat? {
        if let view = userView.view {
            let currentOffset = chatNavBar!.navView!.contentOffset.x
            let maxX = view.frame.maxX
            let centerX = maxX - (view.bounds.width / 2.0)
            let navViewMinX = chatNavBar!.navView!.frame.minX
            let boundCenter = (chatNavBar!.navView!.width / 2.0)
            let insets = chatNavBar!.navView!.adjustedContentInset
            let leftInset = insets.left
            let rightInsets = insets.right
            let overflow = max(chatNavBar!.userViews.last!.view.frame.maxX - 250.0, 0.0)
            let affectedInset = leftInset

            let centerOffset = centerX + affectedInset - boundCenter - overflow

            print("scroll: centerX \(centerX) navViewMinX \(navViewMinX) maxX \(maxX) centerOffset \(centerOffset)  navViewWidth \(boundCenter) currentOffset \(currentOffset) leftInset \(leftInset) rightInsets \(rightInsets) affectedInset \(affectedInset) overflow \(overflow)")

            let newTarget = currentOffset + centerOffset + overflow
            print("scroll: newTarget \(newTarget)")

            return newTarget

        } else {
            return nil
        }
    }

    override func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        let textMessageBuilder = TextMessagePresenterBuilder(viewModelBuilder: TextBuilder(), interactionHandler: TextHandler())
        textMessageBuilder.baseMessageStyle = Avatar()

        let photoMessageBuilder = PhotoMessagePresenterBuilder(viewModelBuilder: PhotoBuilder(), interactionHandler: PhotoHandler())
        photoMessageBuilder.baseCellStyle = Avatar()

        return [
            TextModel.chatItemType: [textMessageBuilder],
            PhotoModel.chatItemType: [photoMessageBuilder],
            TimeSeparatorModel.chatItemType: [TimeSeparatorPresenterBuilder()],
            SystemMessageModel.chatItemType: [SystemMessagePresenterBuilder()],
            NameViewModel.chatItemType: [NameViewPresenterBuilder()],
            ReadReceiptModel.chatItemType: [ReadReceiptPresenterBuilder()],
            TypingModel.chatItemType: [TypingPresenterBuilder()],
        ]
    }

    override func createChatInputView() -> UIView {
        let inputBar = ChatInputBar.loadNib()
        inputBar.delegate = self

        var appearance = ChatInputBarAppearance()
        appearance.sendButtonAppearance.title = "Send"
        appearance.textInputAppearance.placeholderText = "Type a message"

        presenter = BasicChatInputBarPresenter(chatInputBar: inputBar, chatInputItems: [handleSend(), handlePhoto()], chatInputBarAppearance: appearance)

        return inputBar
    }

    func handleSend() -> TextChatInputItem {
        let item = TextChatInputItem()
        item.textInputHandler = { text in

            let date = Date()
            let double = Double(date.timeIntervalSinceReferenceDate)
            let senderId = DeviceUser.shared.user!.id!
            let uid = "(\(double, senderId))"

            let serverMessage = Message()
            serverMessage.timestamp = date
            serverMessage.chatroom = self.chatroom?.id
            serverMessage.content = text
            serverMessage.messageKind = MessageKind.Text

            let messageModel = MessageModel(uid: uid, senderId: senderId, type: TextModel.chatItemType, isIncoming: false, date: date, status: MessageStatus.sending)
            let textMessage = TextModel(messageModel: messageModel, text: text)
            self.dataSource.addMessage(message: textMessage)

            serverMessage.create({ success in
                if success == true {
                    self.chatroom?.messages.insert(serverMessage)
                    NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.success])
                    // soundGenerator.playSent()
                } else {
                    NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.failed])
                }
            })
        }

        return item
    }

    func handlePhoto() -> PhotosChatInputItem {
        
        let item = PhotosChatInputItem(presentingController: self)
        item.photoInputHandler = { image in

            let date = Date()
            let double = Double(date.timeIntervalSinceReferenceDate)
            let senderId = Auth.shared.id!
            let uid = String(format: "%f-%@", arguments: [double, senderId])

            let photo = Photo()
            photo.model = ModelType.Chatroom.rawValue
            photo.modelId = self.chatroom!.id!
            photo.uid = uid

            let message = MessageModel(uid: uid, senderId: senderId, type: PhotoModel.chatItemType, isIncoming: false, date: date, status: MessageStatus.sending)
            let photoMessage = PhotoModel(messageModel: message, imageSize: image.size, image: image)
            self.dataSource!.addMessage(message: photoMessage)

            Async.waterfall(image, [photo.create], end: { (error, returnValue) in
                
                guard error == nil else {
                    NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.failed])
                    return
                }
                
                self.chatroom?.photos.add(photo)
                
                let serverMessage = Message()
                serverMessage.timestamp = date
                serverMessage.chatroom = self.chatroom?.id
                serverMessage.messageKind = MessageKind.Photo
                serverMessage.photo = photo.filename
                serverMessage.content = "photo"
                
                serverMessage.create({ success in
                    if success == true {
                        self.chatroom?.messages.insert(serverMessage)
                        NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.success])
                        // soundGenerator.playSent()
                    } else {
                        NotificationManager.shared.chat_item_status_update.post(["uid": uid, "status": MessageStatus.failed])
                    }
                })
            })
        }

        return item
    }

    @objc func chatroomUsersUpdate(notification: NSNotification) {
        guard let chatroomId = notification.userInfo?["chatroomId"] as? String, chatroomId == self.chatroom!.id else {
            return
        }

        var i = 0
        for user in chatroom?.chatUsers.chatUsers ?? [] {
            chatNavBar?.userViews[i].setConnected(user.connected!)
            i += 1
        }
    }

    @objc func viewUserProfile(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view, let user = Users.shared[self.chatroom?.chatUsers[view.tag]?.user?.id] else {
            return
        }
        
        view.touchAnimation()
        
        let destination = UIStoryboard.Main(identifier: "Profile") as! Profile
        destination.user = user
        
        delay(0.2) {
            Presenter.push(destination, animated: true, completion: nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension Chat: ChatInputBarDelegate {
    func inputBarShouldBeginTextEditing(_: ChatInputBar) -> Bool {
        return true
    }

    func inputBarDidBeginEditing(_: ChatInputBar) {
        sendTypingCommand(true)
    }

    func inputBarDidEndEditing(_: ChatInputBar) {
        sendTypingCommand(false)
    }

    func inputBarDidChangeText(_ inputBar: ChatInputBar) {
        if inputBar.inputText != "" {
            sendTypingCommand(true)
        } else {
            sendTypingCommand(false)
        }
    }

    func inputBarSendButtonPressed(_: ChatInputBar) {
        sendTypingCommand(false)
    }

    func inputBar(_: ChatInputBar, shouldFocusOnItem _: ChatInputItemProtocol) -> Bool {
        return true
    }

    func inputBar(_: ChatInputBar, didReceiveFocusOnItem _: ChatInputItemProtocol) {
        collectionView.layoutIfNeeded()
    }

    struct UserData: SocketData {
        let room: String
        let user: [String: AnyObject]

        func socketRepresentation() -> SocketData {
            return ["room": room, "user": user]
        }
    }

    func sendTypingCommand(_ typing: Bool) {
        let room = chatroom!.id!
        let user: [String: AnyObject] = [
            "id": Auth.shared.id! as AnyObject,
            "firstName": DeviceUser.shared.user!.firstName! as AnyObject,
            "lastName": DeviceUser.shared.user!.lastName! as AnyObject,
        ]

        if typing == true {
            Socket.shared.socket.emit("Chatroom-typingStart", UserData(room: room, user: user))
            print("Typing True")
        } else {
            Socket.shared.socket.emit("Chatroom-typingStop", UserData(room: room, user: user))
            print("Typing False")
        }
    }
}


// MARK: - NYTPhotosViewControllerDelegate

extension Chat: NYTPhotosViewControllerDelegate {
    
    @objc func pictureMessageSelected(notification: Notification) {
        
        guard presentingPhotos == false else {
            return
        }
        
        presentingPhotos = true
        Generator.bump()
        
        if let info = notification.userInfo as? [String: Any], let uid = info["uid"] as? String, let photo = chatroom?.photos.get(uid: uid) {
            
            if self.photoViewerCoordinator == nil || self.nytPhotos.count != self.chatroom!.photos.count {
                
                self.nytPhotos.removeAll()
                for photo in self.chatroom?.photos.items ?? [] {
                    self.nytPhotos.append(photo.nytPhoto)
                }
                
                self.photoViewerCoordinator = PhotoViewerCoordinator(images: self.nytPhotos)
            }
            
            if photo.image == nil {
                Async.waterfall(APIClient.shared.downloadSession, [photo.download], end: { _, _ in
                    DispatchQueue.main.async {
                        photo.nytPhoto.image = photo.image
                        
                        PKHUD.success()
                        
                        Presenter.present(NYTPhotosViewController(dataSource: self.photoViewerCoordinator!, initialPhoto: photo.nytPhoto, delegate: self), animated: true, completion: nil)
                    }
                })
            } else if photo.image != nil {
                
                DispatchQueue.main.async {
                    
                    PKHUD.success()
                    
                    if photo.nytPhoto.image == nil {
                        photo.nytPhoto.image = photo.image
                    }
                    
                    
                    Presenter.present(NYTPhotosViewController(dataSource: self.photoViewerCoordinator!, initialPhoto: photo.nytPhoto, delegate: self), animated: true, completion: nil)
                }
            }
        }
    }
    
    
    func photosViewController(_ photosViewController: NYTPhotosViewController, handleActionButtonTappedFor photo: NYTPhoto) -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad, let photoImage = photo.image else {
            return false
        }
        
        let shareActivityViewController = UIActivityViewController(activityItems: [photoImage], applicationActivities: nil)
        shareActivityViewController.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, _: [Any]?, _: Error?) in
            if completed {
                photosViewController.delegate?.photosViewController!(photosViewController, actionCompletedWithActivityType: activityType?.rawValue)
            }
        }
        
        shareActivityViewController.popoverPresentationController?.barButtonItem = photosViewController.rightBarButtonItem
        photosViewController.present(shareActivityViewController, animated: true, completion: nil)
        
        return true
    }
    
    func photosViewController(_ controller: NYTPhotosViewController, didNavigateTo nytPhoto: NYTPhoto, at index: UInt) {
        guard let nytPhotoBox = nytPhoto as? NYTPhotoBox else {
            return
        }
        
        if nytPhotoBox.image == nil {
            
            if let image = nytPhotoBox.info.photo.image {
                DispatchQueue.main.async {
                    nytPhotoBox.image = image
                    controller.display(nytPhotoBox, animated: true)
                }
            } else {
                Async.waterfall(APIClient.shared.downloadSession, [nytPhotoBox.info.photo.download], end: { _, _ in
                    DispatchQueue.main.async {
                        nytPhotoBox.image = nytPhotoBox.info.photo.image
                        controller.display(nytPhotoBox, animated: true)
                    }
                })
            }
        }
    }
    
    func photosViewControllerWillDismiss(_ photosViewController: NYTPhotosViewController) {
        PKHUD.hide(animated: false)
        presentingPhotos = false
        Generator.confirm()
    }
}
