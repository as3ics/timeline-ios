//
//  ChatAddUser.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/11/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UICheckbox_Swift
import UIKit
import CoreLocation

// MARK: - ChatAddUser

class ChatAddUser: ViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!

    weak var addRoomController: ChatAddRoom?

    var originalUserList: [User]?
    
    // MARK: - Search Controller Items
    
    var filteredUsers = [User]()
    var searchController = UISearchController(searchResultsController: nil)
    var filtering: Bool = false
    
    // MARK: - UIViewController Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        originalUserList = addRoomController!.userList

        styleSearchBar(searchController)
        definesPresentationContext = true

        tableView.tableHeaderView = searchController.searchBar
        tableView.tableHeaderView?.height = DEFAULT_SEARCHBAR_HEADER_HEIGHT
        searchController.searchBar.sizeToFit()

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        ChatAddUserCell.register(tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchController.searchBar.setShowsCancelButton(false, animated: true)
    }

    override func setupNavBar() {
        navBar?.title = "Add User"
        
        navBar?.leftImage = AssetManager.shared.cancel
        navBar?.leftEnclosure = { self.cancel() }
        
        navBar?.rightImage = AssetManager.shared.done
        navBar?.rightEnclosure = { self.goBack() }
    }

    @objc func cancel() {
        addRoomController!.userList = originalUserList!

        goBack()
    }
    
    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        let users = filtering ? filteredUsers : Users.shared.items

        return users.count
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let users = filtering ? filteredUsers : Users.shared.items
        let index = indexPath.row

        let user = users[index]

        let cell = ChatAddUserCell.loadNib(tableView)
        cell.populate(user)

        for addedUser in addRoomController?.userList ?? [] {
            if addedUser.id == user.id {
                cell.checkbox.isSelected = true
                break
            }
        }

        if user.id != Auth.shared.id {
            cell.checkbox.tag = index
            cell.checkbox.addTarget(self, action: #selector(updateUserSelection(_:)), for: UIControlEvents.touchUpInside)
        } else {
            cell.checkbox.isUserInteractionEnabled = false
        }

        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return DEFAULT_HEIGHT_FOR_SECTION_HEADER
    }
    
    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0.01
    }
    
    // MARK: - Other Functions
    
    @objc func updateUserSelection(_ sender: Any) {
        let button = sender as! UICheckbox
        let index = button.tag

        let indexPath = IndexPath(row: index, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! ChatAddUserCell

        let user = cell.user!

        if button.isSelected == true {
            addRoomController!.userList.append(user)
        } else {
            var i = 0
            for addedUser in addRoomController!.userList {
                if addedUser.id == user.id {
                    addRoomController!.userList.remove(at: i)
                    break
                }
                i += 1
            }
        }
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        navBar?.leftButton.tintColor = UIColor.red
        navBar?.rightButton.tintColor = UIColor.red
    }
}

extension ChatAddUser: UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    
    // MARK: UISearchResultsUpdating and UISearchControllerDelegate
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchString = searchController.searchBar.text?.uppercased() {
            let searchArray = searchString.components(separatedBy: " ")
            if searchString.characters.count > 0 && Users.shared.items.count > 0 {
                filteredUsers = Users.shared.items.filter({ (user) -> Bool in
                    
                    var found: Int = 0
                    for searchItem in searchArray {
                        if searchItem == " " || searchItem == "" {
                            found += 1
                            continue
                        }
                        
                        if user.firstName!.uppercased().contains(searchItem) || user.lastName!.uppercased().contains(searchItem) || user.fullName!.uppercased().contains(searchItem) {
                            
                            found += 1
                            continue
                        }
                    }
                    
                    return found >= searchArray.count
                })
            } else {
                filteredUsers = Users.shared.items
            }
        }
        
        if filtering {
            tableView.reloadData()
        }
    }
    
    func didPresentSearchController(_: UISearchController) {
        filtering = true
        tableView.reloadData()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        filtering = false
        view.endEditing(true)
        tableView.reloadData()
    }
}
