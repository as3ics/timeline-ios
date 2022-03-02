//
//  ViewUsers.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/28/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import UIKit
import CoreLocation
import PKHUD


// MARK: - ViewUsers

class ViewUsers: ViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, SidebarSectionProtocol, SearchControllerProtocol {
    
    static var section: String = "Users"

    @IBOutlet var tableView: UITableView!
    
    // MARK: - Search Controller Protocol Items
    
    typealias Item = User
    var items: [Item] {
        return Users.shared.items
    }
    
    var filteredItems: [Item] = [Item]()
    var searchController = UISearchController(searchResultsController: nil)
    var filtering: Bool = false
    var keypaths: [KeyPath<Item, String?>] = [KeyPath<Item, String?>]()

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: Copy and Paste Code For Search Controller
        
        styleSearchBar(searchController)
        tableView.tableHeaderView = searchController.searchBar
        tableView.tableHeaderView?.height = DEFAULT_SEARCHBAR_HEADER_HEIGHT
        searchController.searchBar.sizeToFit()
        definesPresentationContext = false
        
        NSNotification.Name.UIKeyboardDidShow.observe(self, selector: #selector(keyboardDidShow))
        NSNotification.Name.UIKeyboardWillHide.observe(self, selector: #selector(keyboardWillHide))
        
        // MARK: Set KeyPaths for Search Controller
        
        keypaths.append(\Item.firstName)
        keypaths.append(\Item.lastName)
        keypaths.append(\Item.fullName)
        
        // MARK: End Code For Search Controller
        
        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.alpha = 0.5
        refreshControl.addTarget(self, action: #selector(resetRefreshControl), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        UserCell.register(tableView)
        
        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Users.shared.sort()
        
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if searchController.searchBar.text?.isEmpty ?? true {
            searchController.searchBar.setShowsCancelButton(false, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        searchController.dismiss(animated: true, completion: nil)
    }
    
    override func setupNavBar() {
        navBar?.title = String(format: "Users (%i)", Users.shared.count)
        navBar?.titleAction = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        
        navBar?.leftImage = AssetManager.shared.menu
        navBar?.leftEnclosure = { self.menuPressed() }
        
        navBar?.rightImage = AssetManager.shared.plus
        navBar?.rightEnclosure = { self.add() }
    }

    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        if filtering == true {
            return 1
        } else {
            return Users.shared.sectionTitles.count
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filtering == true {
            
            DispatchQueue.main.async {
                self.navBar?.title = String(format: "Users (%i)", self.filteredItems.count)
            }
            
            return max(filteredItems.count, 1)
        } else {
            
            DispatchQueue.main.async {
                self.navBar?.title = String(format: "Users (%i)", Users.shared.count)
            }
            
            return Users.shared.sectionValues(Users.shared.sectionTitles[section]).count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let users = self.filtering == true ? filteredItems : Users.shared.sectionValues(Users.shared.sectionTitles[indexPath.section])
        if users.count == 0 {
            let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
            let cell = views![0] as! EmptyCell

            cell.tag = -1
            cell.isUserInteractionEnabled = false

            cell.selectionStyle = .none
            return cell

        } else {
            let user: User = users[indexPath.row]
        
            let cell = UserCell.loadNib(tableView)
            cell.populate(user)
            cell.tag = Users.shared.index(id: user.id) ?? -1

            cell.gestureRecognizers?.removeAll()
            let tap = UITapGestureRecognizer(target: self, action: #selector(goViewUser))
            cell.addGestureRecognizer(tap)

            return cell
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         let users = self.filtering == true ? filteredItems : Users.shared.sectionValues(Users.shared.sectionTitles[indexPath.section])
        if users.count == 0 {
            return 200
        } else {
            return UserCell.cellHeight
        }
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        if filtering == true {
            return 0.01
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle _: String, at index: Int) -> Int {
        if index == 0 {
            let frame = tableView.tableHeaderView?.frame ?? CGRect(x: 0, y: 0, width: 1, height: 1)
            tableView.scrollRectToVisible(frame, animated: true)
            return -1
        }

        return index
    }

    func sectionIndexTitles(for _: UITableView) -> [String]? {
        if self.filtering == true {
            return []
        } else {
            return [UITableViewIndexSearch, "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        }
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: DEFAULT_HEIGHT_FOR_SECTION_HEADER))
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        return view
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit", handler: { _, _ in
            
            Generator.bump()
        })
        
        let viewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "View", handler: { _, _ in
            
            Generator.bump()
            
            if let tag = tableView.cellForRow(at: indexPath)?.tag, let user = Users.shared[tag] {
                user.view()
            }
        })
        
        editRowAction.backgroundColor = UIColor.gray
        viewRowAction.backgroundColor = UIColor.blue
        
        return [viewRowAction, editRowAction]
    }
    
    // MARK: - Model Updater
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate else {
            return
        }
        
        if update.type == .Users || update.type == .User {
            
            if filtering == true {
                updateSearchResults(for: searchController)
            }
            
            tableView.reloadData()
        }
    }
    
    // MARK: - Other Functions
    
    @objc func add() {
        Shortcuts.goCreateEmployee()
    }

    @objc func goViewUser(_ sender: UITapGestureRecognizer) {
        Generator.bump()

        guard let tag = sender.view?.tag, tag >= 0 else {
            return
        }
        
        if let cell = sender.view as? UITableViewCell {
            cell.setSelected(true, animated: true)
        }

        let user = Users.shared.items[tag]
        
        user.view()
    }

    func reloadTableView() {
        self.tableView.reloadData()
        
         let users = self.filtering == true ? filteredItems : Users.shared.items
        
        self.tableView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: DEFAULT_HEIGHT_FOR_SECTION_HEADER + CGFloat(users.count) * UserCell.cellHeight)
    }
    
    @objc func resetRefreshControl() {
        Async.waterfall(nil, [Users.shared.retrieve, Stream.shared.retrieve], end: { _, _ in
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        })
    }
    
    @objc func scrollToTop() {
        DispatchQueue.main.async {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
        }
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        searchController.searchBar.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Copy and Paste Code For Search Controller

extension ViewUsers {
    func didPresentSearchController(_: UISearchController) {
        filtering = true
        tableView.reloadData()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        filtering = false
        view.endEditing(true)
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchString = searchController.searchBar.text?.uppercased() {
            if searchString.characters.count > 0 {
                let searchArray = searchString.components(separatedBy: " ")
                filteredItems = items.filter({ (item) -> Bool in
                    var found: Int = 0
                    var compares: [String] = [String]()
                    
                    compares.append(item.userRole.rawValue.uppercased())
                    
                    if let stream = Stream.shared[item.id] {
                        compares.append("-ACTIVE")
                        
                        if let activity = stream.entry?.activity?.name {
                            compares.append(activity)
                        }
                        if let location = stream.entry?.location?.name {
                            compares.append(location)
                        }
                    } else {
                        compares.append("-FREE")
                    }
                    
                    for searchItem in searchArray {
                        
                        if searchItem == " " || searchItem == "" {
                            found += 1
                            continue
                        }
                        
                        for compare in compares {
                            if(compare.uppercased().contains(searchItem)) {
                                found += 1
                            }
                        }
                        
                        for keypath in keypaths {
                            if (item[keyPath: keypath]?.uppercased().contains(searchItem) ?? false )! {
                                found += 1
                            }
                        }
                    }
                    
                    return found >= searchArray.count
                })
            } else {
                filteredItems = items
            }
        }
        
        if filtering == true {
            tableView.reloadData()
        }
    }
    
    @objc func keyboardDidShow(_ notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
            }
        }
    }
    
    @objc func keyboardWillHide(notification _: NSNotification) {
        UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
            self.tableView.contentInset = UIEdgeInsets.zero
        }
    }
}
