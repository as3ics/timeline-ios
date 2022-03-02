//
//  ChatAddRoom.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/11/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import PKHUD
import UIKit
import CoreLocation

// MARK: - ChatAddRoom

class ChatAddRoom: ViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }

    var userList: [User] = []
    var chatroom: Chatroom?

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if mode == nil {
            mode = .Creating
        }

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        userList.append(DeviceUser.shared.user!)

        hideKeyboardWhenTappedAround()

        if mode == ViewingMode.Editing {
            for chatUser in chatroom?.chatUsers.chatUsers ?? [] {
                if let user = chatUser.user {
                    userList.append(user)
                }
            }
        } else { // mode == ViewingMode.Creating
            chatroom = Chatroom()
            chatroom?.name = nil
            chatroom?.purpose = nil
        }

        StandardTextFieldCell.register(tableView)
        StandardHeaderCell.register(tableView)
        ChatUserCell.register(tableView)
        StandardButtonCell.register(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        updateRightButton()
    }
    
    override func setupNavBar() {
        navBar?.title = mode == ViewingMode.Editing ? "Edit Chat" : "New Chat"
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
    }
    
    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else {
            return userList.count + 2
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0, indexPath.section == 0 {
            return 35
        } else if indexPath.row == 0 {
            return 70
        } else {
            return 60
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Info"

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Name"
                cell.contents.placeholder = "Required"

                cell.contents.text = chatroom?.name
                cell.contents.delegate = self
                cell.contents.tag = indexPath.row

                cell.contents.delegate = self
                cell.contents.addTarget(self, action: #selector(updateRightButton), for: UIControlEvents.allEditingEvents)

                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Description"
                cell.contents.placeholder = "Optional"

                cell.contents.text = chatroom?.purpose
                cell.contents.delegate = self
                cell.contents.tag = indexPath.row

                cell.contents.delegate = self
                cell.selectionStyle = .none

                return cell
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Users"

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == userList.count + 1 {
                let cell = StandardButtonCell.loadNib(tableView)

                cell.label.text = "Add User"

                let tap = UITapGestureRecognizer(target: self, action: #selector(goAddUsers))
                cell.addGestureRecognizer(tap)
                cell.isUserInteractionEnabled = true

                cell.selectionStyle = .none
                return cell
            } else {
                let userIndex = indexPath.row - 1
                if userIndex >= 0 && userIndex < userList.count {
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: ChatUserCell.reuseIdentifier, for: indexPath) as! ChatUserCell

                    if let user = userIndex == 0 ? DeviceUser.shared.user : Users.shared[self.userList[userIndex].id] {
                        cell.populate(user)

                        cell.removeButton.tag = userIndex
                        let tap = UITapGestureRecognizer(target: self, action: #selector(removeUser(_:)))
                        cell.removeButton.addGestureRecognizer(tap)
                        cell.removeButton.isUserInteractionEnabled = true
                        cell.removeButton.alpha = 1.0

                        if user.id == Auth.shared.id! {  cell.removeButton.alpha = 0 }
                    }

                    cell.selectionStyle = .none
                    return cell
                }
            }
        }

        return UITableViewCell()
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0.01
    }
    
    // MARK: - Other Functions
    
    @objc func updateRightButton() {
        let indexPath = IndexPath(row: 1, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! StandardTextFieldCell
        
        if cell.contents.text != "", userList.count >= 2 {
            if mode == ViewingMode.Creating {
                navBar?.rightImage = AssetManager.shared.add
                navBar?.rightEnclosure = { self.add() }
                navBar?.rightButton.tintColor = UIColor.red
            } else if mode == ViewingMode.Editing {
                navBar?.rightImage = AssetManager.shared.save
                navBar?.rightEnclosure = { self.save() }
                navBar?.rightButton.tintColor = UIColor.red
            }
        } else {
            if mode == ViewingMode.Creating {
                navBar?.rightImage = AssetManager.shared.add
                navBar?.rightButton.tintColor = Theme.shared.active.placeholderColor
                navBar?.rightEnclosure = nil
            } else {
                navBar?.rightImage = AssetManager.shared.save
                navBar?.rightButton.tintColor = Theme.shared.active.placeholderColor
                navBar?.rightEnclosure = nil
            }
        }
    }

    @objc func save() {

        PKHUD.loading()

        guard let chatroom = self.chatroom, chatroom.name != "" else {
            PKHUD.failure()
            return
        }

        chatroom.users.removeAll()
        chatroom.users = userList
        
        chatroom.update { success in
            guard success == true else {
                PKHUD.failure()
                return
            }
            
            PKHUD.success()
            
            self.goBack()
        }
    }

    @objc func add() {

        PKHUD.loading()

        guard let chatroom = self.chatroom, chatroom.name != "" else {
            PKHUD.failure()
            return
        }

        chatroom.users = userList

        chatroom.create { success in
            guard success == true else {
                PKHUD.failure()
                return
            }

            PKHUD.success()
            self.goBack()
        }
    }

    @objc func goAddUsers() {
        Generator.bump()

        let destination = UIStoryboard.Chat(identifier: "ChatAddUser") as! ChatAddUser
        destination.addRoomController = self

        Presenter.push(destination, animated: true, completion: nil)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            chatroom?.name = textField.text
        } else if textField.tag == 2 {
            chatroom?.purpose = textField.text
        }
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    @objc func removeUser(_ sender: UITapGestureRecognizer) {
        if let index = sender.view?.tag {
            Generator.bump()

            userList.remove(at: index)

            tableView.reloadData()
            updateRightButton()
        }
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        navBar?.leftButton.tintColor = Theme.shared.active.alternativeFontColor
        navBar?.rightButton.tintColor = UIColor.red
    }
}
