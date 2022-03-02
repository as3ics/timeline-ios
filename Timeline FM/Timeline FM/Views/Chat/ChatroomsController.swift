//
//  ChatroomsController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 6/17/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Material
import PKHUD
import UIKit

class ChatroomsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    weak var navBar: TSWNavigationBar?
    @IBOutlet var tableView: UITableView!

    var filteredChatrooms = [Chatroom]()
    var searchController = UISearchController(searchResultsController: nil)
    var filtering: Bool = false

    var headerView: UIView?
    var chatNavBar: TSWChatNavBar?

    override func viewDidLoad() {
        super.viewDidLoad()

        navBar = TSWNavigationBar(self)

        // Style the Table View
        tableView.delegate = self
        tableView.dataSource = self

        styleSearchBar(searchController)
        definesPresentationContext = true

        tableView.register(UINib(nibName: "ChatRoomCell", bundle: nil), forCellReuseIdentifier: ChatRoomCell.reuseIdentifier)

        // self.tableView.tableHeaderView = self.searchController.searchBar
        // self.tableView.tableHeaderView?.height = 55

        /*
         let seperator = UIView(frame: CGRect(x: self.tableView.separatorInset.left, y: self.tableView.tableHeaderView!.bounds.maxY - 1, width: self.tableView.tableHeaderView!.bounds.width, height: 0.5))
         seperator.backgroundColor = self.tableView.separatorColor
         seperator.alpha = 1.0
         self.tableView.tableHeaderView?.addSubview(seperator)
         */

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.5
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(reloadChatrooms), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        /*

         var filteresUsers: [User]?
         filteresUsers = deviceUser.users?.users.filter({ (user) -> Bool in
         user.clockedIn == true
         })

         let phantomChatroom = Chatroom()
         for user in filteresUsers ?? [] {
         phantomChatroom.users.append(user.chatroomUser)
         }

         self.headerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100.0))
         self.chatNavBar = TSWChatNavBar(phantomChatroom, self.headerView!, TSWChatNavBar.headerViewConfiguration)

         for user in self.chatNavBar?.userViews ?? [] {
         user.setConnected(false)
         user.setCircle(true)
         }

         let label = UILabel(frame: CGRect(x: 20.0, y: 7.5, width: UIScreen.main.bounds.width, height: 10.0))
         label.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 14.0)
         label.textColor = LightTheme.secondaryFontColor
         label.text = "Active Users"

         self.headerView?.addSubview(self.chatNavBar!.navView)
         self.headerView?.addSubview(label)

         self.tableView.tableHeaderView = headerView
         self.tableView.tableHeaderView?.height = 100.0

         let seperator = UIView(frame: CGRect(x: self.tableView.separatorInset.left, y: self.tableView.tableHeaderView!.bounds.maxY - 1, width: self.tableView.tableHeaderView!.bounds.width - self.tableView.separatorInset.left, height: 1))
         seperator.backgroundColor = self.tableView.separatorColor
         seperator.alpha = 0.35
         self.tableView.tableHeaderView?.addSubview(seperator)

         */

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(editTableview(_:)))
        tableView.addGestureRecognizer(longPress)

        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: Notification.Name(rawValue: notificationManager.darkThemeUpdatedNotificationName), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView), name: Notification.Name(rawValue: notificationManager.chatroomsRetrievedNotificationName), object: nil)

        // Do any additional setup after loading the view.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        navBar?.title = "Groups"

        navBar?.leftImage = UIImage(named: "menu-white")
        navBar?.rightImage = UIImage(named: "compose-white")

        navBar?.leftAction = UITapGestureRecognizer(target: self, action: #selector(menuTapped))
        navBar?.rightAction = UITapGestureRecognizer(target: self, action: #selector(add))

        updateTheme()
    }

    override func viewWillAppear(_: Bool) {
        // Initialize the side bar controller

        navigationDrawerController?.isEnabled = true
    }

    override func viewDidAppear(_: Bool) {
        reloadTableView()
    }

    var longPressStart: Date?
    var timer: Timer?
    @objc func editTableview(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            longPressStart = Date()
            let longPressTime = Date().timeIntervalSince(longPressStart!)
            let longPressMax = sender.minimumPressDuration
            let delta: CGFloat = CGFloat(longPressTime / longPressMax)
            let direction: Bool = tableView.isEditing == true ? false : true
            let startAngle: CGFloat = direction == false ? (-CGFloat(Double.pi / 2) + CGFloat(Double.pi * 2)) : -CGFloat(Double.pi / 2)
            let endAngle: CGFloat = direction == false ? startAngle - min((delta * CGFloat(Double.pi * 2)), CGFloat(Double.pi * 2) - 0.001) : startAngle + (CGFloat(Double.pi * 2) * delta)
            let circlePath = UIBezierPath(arcCenter: sender.location(in: view), radius: 25.0, startAngle: startAngle, endAngle: endAngle, clockwise: true)

            let shapeLayer = CAShapeLayer()
            shapeLayer.path = circlePath.cgPath

            // change the fill color
            shapeLayer.fillColor = UIColor.clear.cgColor
            // you can change the stroke color
            shapeLayer.strokeColor = direction == false ? Color.red.darken1.withAlphaComponent(0.33).cgColor : Color.blue.darken1.withAlphaComponent(0.33).cgColor
            // you can change the line width
            shapeLayer.lineWidth = 50.0

            view.layer.addSublayer(shapeLayer)

            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                if let circle = self.view.layer.sublayers?.last as? CAShapeLayer, let pressStart = self.longPressStart {
                    let longPressTime = Date().timeIntervalSince(pressStart)
                    let longPressMax = sender.minimumPressDuration
                    let delta: CGFloat = CGFloat(longPressTime / longPressMax)
                    let direction: Bool = self.tableView.isEditing == true ? false : true
                    let startAngle: CGFloat = direction == false ? (-CGFloat(Double.pi / 2) + CGFloat(Double.pi * 2)) : -CGFloat(Double.pi / 2)
                    let endAngle: CGFloat = direction == false ? startAngle - min((delta * CGFloat(Double.pi * 2)), CGFloat(Double.pi * 2) - 0.001) : startAngle + (CGFloat(Double.pi * 2) * delta)
                    let circlePath = UIBezierPath(arcCenter: sender.location(in: self.view), radius: 25.0, startAngle: startAngle, endAngle: endAngle, clockwise: true)

                    UIView.animate(withDuration: 0.02, animations: {
                        if delta > 1.0 {
                            circle.strokeColor = direction == false ? Color.red.darken1.withAlphaComponent(0.33).cgColor : Color.green.darken1.withAlphaComponent(0.33).cgColor
                        } else {
                            circle.strokeColor = direction == false ? Color.red.darken1.withAlphaComponent(0.33).cgColor : Color.blue.darken1.withAlphaComponent(0.33).cgColor
                        }
                        circle.path = circlePath.cgPath
                        circle.layoutIfNeeded()
                    })

                    if delta > 1.0 {
                        if self.view.layer.sublayers?.last is CAShapeLayer {
                            _ = self.view.layer.sublayers?.popLast()
                        }

                        self.timer?.invalidate()
                        self.timer = nil
                        self.longPressStart = nil

                        if self.tableView.isEditing == false {
                            self.tableView.setEditing(true, animated: false)
                        } else {
                            self.tableView.setEditing(false, animated: false)
                        }
                    }

                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                }
            }

            timer?.fire()
        }

        if sender.state == .ended {
            if view.layer.sublayers?.last is CAShapeLayer {
                _ = view.layer.sublayers?.popLast()
            }

            timer?.invalidate()
            timer = nil
            longPressStart = nil
        }
    }

    @objc func reloadChatrooms() {
        if deviceUser.chatrooms == nil {
            deviceUser.chatrooms = Chatrooms()
        }

        deviceUser.chatrooms?.initialRetrieve({ success in

            self.reloadTableView()

            if success != true {
                deviceUser.chatrooms = nil
            }
        })
    }

    @objc func reloadTableView() {
        deviceUser.updateBadgeNotification()

        tableView.refreshControl?.endRefreshing()

        if tableView.safeToUpdate() == true {
            tableView.reloadData()
        }
    }

    @objc func add() {
        bump()

        let destination = UIStoryboard.chatViewController(identifier: "ChatAddRoomController") as! ChatAddRoomController
        destination.mode = EditingMode.Creating

        present(destination, animated: true, completion: nil)
    }

    func numberOfSections(in _: UITableView) -> Int {
        let count = deviceUser.chatrooms?.groups.count ?? 0
        return count + 1
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        if deviceUser.chatrooms?.groups.count != 0 {
            return 0 // DEFAULT_HEIGHT_FOR_SECTION_HEADER
        } else {
            return 0
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = deviceUser.chatrooms?.groups.count ?? 0

        if count == 0 {
            return 1
        } else if section < count {
            return 1
        } else {
            return 0
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        let count = deviceUser.chatrooms?.groups.count ?? 0

        if count == 0 {
            return 200
        } else {
            return 70
        }
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let count = deviceUser.chatrooms?.groups.count ?? 0

        if count == 0 {
            if deviceUser.chatrooms == nil {
                let views = Bundle.main.loadNibNamed("ErrorCell", owner: self, options: nil)
                let cell = views![0] as! ErrorCell

                let tap = UITapGestureRecognizer(target: self, action: #selector(reloadChatrooms))
                cell.addGestureRecognizer(tap)
                cell.isUserInteractionEnabled = true
                cell.backgroundColor = UIColor.clear

                cell.selectionStyle = .none
                return cell
            } else {
                let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
                let cell = views![0] as! EmptyCell

                let tap = UITapGestureRecognizer(target: self, action: #selector(add))
                cell.addGestureRecognizer(tap)
                cell.isUserInteractionEnabled = true
                cell.backgroundColor = UIColor.clear

                cell.selectionStyle = .none
                return cell
            }
        } else if indexPath.section < count {
            if let chatroom = deviceUser.chatrooms?.groups[indexPath.section] {
                let cell = tableView.dequeueReusableCell(withIdentifier: ChatRoomCell.reuseIdentifier, for: indexPath) as! ChatRoomCell

                cell.populate(chatroom)

                cell.selectionStyle = .none
                return cell
            }
        }

        return UITableViewCell()
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        bump()

        if let cell = self.tableView.cellForRow(at: indexPath) as? ChatRoomCell, let chatroomId = cell.chatroom?.id, let chatroom = deviceUser.chatrooms?[chatroomId] {
            let destination = UIStoryboard.chatViewController(identifier: "ChatRoomController") as! ChatRoomController

            chatroom.lastMessageSeen = Date()
            chatroom.unreadMessages = 0
            destination.chatroom = chatroom

            deviceUser.updateBadgeNotification()

            present(destination, animated: true, completion: {
                self.reloadTableView()
            })
        }
    }

    func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section < deviceUser.chatrooms?.groups.count ?? 0 {
            return 0
        } else {
            return 0.01
        }
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        if deviceUser.chatrooms?.chatrooms.count ?? 0 > 0 {
            return true
        } else {
            return false
        }
    }

    func tableView(_: UITableView, didEndEditingRowAt _: IndexPath?) {
        reloadTableView()
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { _, _ in

            self.bump()

            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()

            if let chatroom = (self.tableView.cellForRow(at: indexPath) as? ChatRoomCell)?.chatroom {
                chatroom.delete({ success in
                    if success == true {
                        var count: Int = 0
                        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { timer in

                            count += 1

                            if count > 15 {
                                timer.invalidate()

                                PKHUD.sharedHUD.contentView = PKHUDErrorView()
                                PKHUD.sharedHUD.hide(true)
                                return
                            }

                            if let _ = deviceUser.chatrooms?[chatroom.id] {
                                // do nothing
                            } else {
                                timer.invalidate()

                                deviceUser.updateBadgeNotification()

                                PKHUD.sharedHUD.contentView = PKHUDSuccessView()
                                PKHUD.sharedHUD.hide(true)
                            }
                        })

                        timer.fire()
                    } else {
                        PKHUD.sharedHUD.contentView = PKHUDErrorView()
                        PKHUD.sharedHUD.hide(true)
                    }
                })
            }
        })

        let leaveRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Leave", handler: { _, _ in

            self.bump()

            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()

            if let chatroom = (self.tableView.cellForRow(at: indexPath) as? ChatRoomCell)?.chatroom {
                chatroom.removeUser(deviceUser.user, { success in
                    if success == true {
                        var count: Int = 0
                        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { timer in

                            count += 1

                            if count > 15 {
                                timer.invalidate()

                                PKHUD.sharedHUD.contentView = PKHUDErrorView()
                                PKHUD.sharedHUD.hide(true)
                                return
                            }

                            if let _ = deviceUser.chatrooms?[chatroom.id] {
                                // do nothing
                            } else {
                                timer.invalidate()

                                deviceUser.updateBadgeNotification()

                                PKHUD.sharedHUD.contentView = PKHUDSuccessView()
                                PKHUD.sharedHUD.hide(true)
                            }
                        })

                        timer.fire()
                    } else {
                        PKHUD.sharedHUD.contentView = PKHUDErrorView()
                        PKHUD.sharedHUD.hide(true)
                    }
                })
            }
        })

        let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit", handler: { _, _ in

            if let chatroom = (self.tableView.cellForRow(at: indexPath) as? ChatRoomCell)?.chatroom {
                self.bump()

                let destination = UIStoryboard.chatViewController(identifier: "ChatAddRoomController") as! ChatAddRoomController

                destination.mode = EditingMode.Editing
                destination.chatroom = chatroom

                self.present(destination, animated: true, completion: nil)
            }
        })

        deleteRowAction.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        leaveRowAction.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
        editRowAction.backgroundColor = UIColor.gray.withAlphaComponent(0.8)

        return [editRowAction, leaveRowAction, deleteRowAction]
    }

    // MARK: UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        if let searchString = searchController.searchBar.text {
            if searchString.characters.count > 0 && deviceUser.chatrooms != nil {
                filteredChatrooms = deviceUser.chatrooms!.groups.filter({ (_) -> Bool in
                    false // activity.name!.contains(searchString)
                })
            } else {
                filteredChatrooms = deviceUser.chatrooms?.groups ?? []
            }
        }

        if filtering {
            tableView.reloadData()
        }
    }

    // MARK: UISearchBarDelegate

    // MARK: UISearchControllerDelegate

    func willPresentSearchController(_: UISearchController) {
        filtering = true
    }

    func willDismissSearchController(_: UISearchController) {
        filtering = false

        tableView.reloadData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ChatroomsController: TSWThemeSupportedProtocol {
    @objc func updateTheme() {
        navBar?.style = .Root

        tableView.backgroundColor = themeManager.theme.primaryBackgroundColor
        view.backgroundColor = themeManager.theme.primaryBackgroundColor
    }
}
