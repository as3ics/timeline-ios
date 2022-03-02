//
//  ViewChats.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/6/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Material
import PKHUD
import UIKit

// MARK: - ViewChats

class ViewChats: ViewController, UITableViewDelegate, UITableViewDataSource, SidebarSectionProtocol {
    static var section: String = "Chat"

    @IBOutlet var tableView: UITableView!

    var headerView: UIView?
    var chatNavBar: UserScrollView?
    var quickAccessed: Bool = false

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ChatRoomCell.register(tableView)

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.5
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: quickAccessed == true ? #selector(goBack) : #selector(resetRefreshControl), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
        NotificationManager.shared.chat_new_message.observe(self, selector: #selector(reloadTableView))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationDrawerController?.isEnabled = true
        updateFavorites()
        reloadTableView()
        
        Notifications.shared.updateBadge()
    }
    
    override func setupNavBar() {
        
        navBar?.title = "Chat"
        
        if quickAccessed == true {
            navBar?.leftImage = AssetManager.shared.arrowLeft
            navBar?.leftEnclosure = { self.goBack() }
        } else {
            navBar?.leftImage = AssetManager.shared.menu
            navBar?.leftEnclosure = { self.menuPressed() }
        }
        
        navBar?.rightImage = AssetManager.shared.composeMessage
        navBar?.rightEnclosure = { self.add() }
        
        if let navBar = self.navBar {
            let seperator = UIView(frame: CGRect(x: 0, y: navBar.frame.maxY - 0.5, width: navBar.frame.width, height: 0.5))
            seperator.backgroundColor = tableView.separatorColor
            seperator.alpha = 1.0
            navBar.addSubview(seperator)
        }
    }
    
    override func prepareForDeinit() {
        super.prepareForDeinit()
        
        self.chatNavBar?.relinquish()
    }

    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        let count = Chatrooms.shared.count
        return count + 1
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        if Chatrooms.shared.count != 0 {
            return 0 // DEFAULT_HEIGHT_FOR_SECTION_HEADER
        } else {
            return 0
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = Chatrooms.shared.count

        if count == 0 {
            return 1
        } else if section < count {
            return 1
        } else {
            return 0
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        let count = Chatrooms.shared.count

        if count == 0 {
            return 200
        } else {
            return 70
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let count = Chatrooms.shared.count

        if count == 0 {
            let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
            let cell = views![0] as! EmptyCell

            let tap = UITapGestureRecognizer(target: self, action: #selector(add))
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
            cell.backgroundColor = UIColor.clear

            cell.selectionStyle = .none
            return cell

        } else if indexPath.section < count {
            let chatroom = Chatrooms.shared.items[indexPath.section]
            let cell = chatroom.dequeCell()!
            
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_: UITableView, didEndEditingRowAt _: IndexPath?) {
        reloadTableView()
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        Generator.bump()

        if let cell = self.tableView.cellForRow(at: indexPath) as? ChatRoomCell, let chatroom = cell.chatroom {
            
            chatroom.view()
            
            delay(0.5) {
                self.reloadTableView()
            }
        }
    }

    func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section < Chatrooms.shared.count {
            return 0
        } else {
            return 0.01
        }
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        return true
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { _, _ in

            Generator.bump()

            guard let chatroom = (self.tableView.cellForRow(at: indexPath) as? ChatRoomCell)?.chatroom else {
                return
            }

            PKHUD.loading()
            chatroom.delete({ success in
                guard success == true else {
                    PKHUD.failure()
                    return
                }

                PKHUD.success()
            })
        })

        /*
        let leaveRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Leave", handler: { _, _ in

            Generator.bump()
        })
        */
        
        let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit", handler: { _, _ in

            Generator.bump()
            
            guard let chatroom = (self.tableView.cellForRow(at: indexPath) as? ChatRoomCell)?.chatroom else {
                return
            }
            
            chatroom.edit()
        })

        deleteRowAction.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        //leaveRowAction.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
        editRowAction.backgroundColor = UIColor.gray.withAlphaComponent(0.8)

        return [editRowAction, deleteRowAction]
    }
    
    // MARK: - Model Updater
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate else {
            return
        }
        
        if update.model is Chatroom, update.action != .Create {
            tableView.reloadData()
        }
    }
    
    // MARK: - Other Functions
    
    
    func updateFavorites() {
        headerView?.removeFromSuperview()
        headerView = nil
        
        let phantomChatroom = Chatroom()
        for user in Users.shared.favorites {
            phantomChatroom.chatUsers.append(user.chatUser)
        }
        
        guard phantomChatroom.chatUsers.count > 0 else {
            tableView.tableHeaderView?.height = 0
            tableView.tableHeaderView = nil
            return
        }
        
        headerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100.0))
        chatNavBar = UserScrollView(phantomChatroom, headerView!, UserScrollView.headerViewConfiguration, self)
        
        let seperator = UIView(frame: CGRect(x: tableView.separatorInset.left, y: 99.5, width: UIScreen.main.bounds.width - tableView.separatorInset.left, height: 0.5))
        seperator.backgroundColor = tableView.separatorColor
        seperator.alpha = 0.5
        self.headerView!.addSubview(seperator)
        
        var i: Int = 0
        for user in chatNavBar?.userViews ?? [] {
            user.view?.tag = i
            let tap = UITapGestureRecognizer(target: self, action: #selector(quickMessageShortcut))
            user.view?.addGestureRecognizer(tap)
            user.view?.isUserInteractionEnabled = true
            user.setConnected(false)
            user.setCircle(false)
            i += 1
        }
        
        let label = UILabel(frame: CGRect(x: 12.5, y: 7.5, width: UIScreen.main.bounds.width, height: 10.0))
        label.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 12.0)
        label.textColor = Theme.shared.lightTheme.secondaryFontColor
        label.text = "Favorites"
        
        headerView?.addSubview(chatNavBar!.navView)
        headerView?.addSubview(label)
        
        tableView.tableHeaderView = headerView
        tableView.tableHeaderView?.height = 100.0
        
        phantomChatroom.users.removeAll()
        phantomChatroom.chatUsers.chatUsers.removeAll()
        phantomChatroom.messages = nil
    }
    
    @objc func reloadTableView() {
        tableView.refreshControl?.endRefreshing()
        
        Chatrooms.shared.sort()
        
        tableView.reloadData()
    }
    
    @objc func resetRefreshControl() {
        Async.waterfall(nil, [Chatrooms.shared.retrieve]) { (_, _) in
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    @objc func quickMessageShortcut(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag, let user = self.chatNavBar?.userViews[tag].user.user else {
            return
        }
        
        sender.view?.touchAnimation()
        
        delay(0.2) {
            let previousChat = Chatrooms.shared.chats.filter({ (chatroom) -> Bool in
                chatroom.chatUsers[0]?.user?.id == user.id!
            })
            
            if previousChat.count == 0 {
                let chatroom = Chatroom()
                
                chatroom.name = "Chat"
                chatroom.purpose = "Chat"
                
                chatroom.users.append(DeviceUser.shared.user!)
                chatroom.users.append(user)
                
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
                        
                        delay(0.5) {
                            self.reloadTableView()
                        }
                    }
                }
            } else {
                
                previousChat[0].view()
                
                delay(0.5) {
                    self.reloadTableView()
                }
            }
        }
    }
    
    @objc func add() {
        Chatroom().create()
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.secondaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.secondaryBackgroundColor
        
        navBar?.leftButton.tintColor = Theme.shared.active.alternateIconColor
        navBar?.rightButton.tintColor = Theme.shared.active.alternativeFontColor
    }
}
