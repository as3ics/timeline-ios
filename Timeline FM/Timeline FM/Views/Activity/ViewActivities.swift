//
//  ActivitiesViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/3/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import Material
import PKHUD
import UIKit

// MARK: - ViewActivities

class ViewActivities: ViewController, UITableViewDelegate, UITableViewDataSource, SidebarSectionProtocol, SearchControllerProtocol {
    
    static var section: String = "Activities"
    
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Search Controller Protocol Items
    
    typealias Item = Activity
    var items: [Item] {
        return Activities.shared.items
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
        definesPresentationContext = true
        
        NSNotification.Name.UIKeyboardDidShow.observe(self, selector: #selector(keyboardDidShow))
        NSNotification.Name.UIKeyboardWillHide.observe(self, selector: #selector(keyboardWillHide))
        
        // MARK: Set KeyPaths for Search Controller
        
        keypaths.append(\Item.name)

        // MARK: End Code For Search Controller
        
        tableView.separatorStyle = .none
        
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.5
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(resetRefreshControl), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 12.5, 0)
        
        ActivityCell.register(tableView)

        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Activities.shared.sort()
        tableView.reloadData()
        tableView.reloadSectionIndexTitles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if searchController.searchBar.text?.isEmpty ?? true {
            searchController.searchBar.setShowsCancelButton(false, animated: true)
        }
    }
    
    override func setupNavBar() {
        navBar?.title = String(format: "Activities (%i)", Activities.shared.count)
        navBar?.titleAction = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        
        navBar?.leftImage = AssetManager.shared.menu
        navBar?.leftEnclosure = {
            self.menuPressed()
        }
        
        navBar?.rightImage = AssetManager.shared.plus
        navBar?.rightEnclosure = {
            Activity().create()
        }
    }
    
    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        if filtering == true {
            return 1
        } else {
            return Activities.shared.sectionTitles.count
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filtering == true {
            let value = filteredItems.count == 0 ? 1 : filteredItems.count
            
            DispatchQueue.main.async {
                self.navBar?.title = String(format: "Activities (%i)", self.filteredItems.count)
                
            }
            
            return value
        } else {
            
            DispatchQueue.main.async {
                self.navBar?.title = String(format: "Activities (%i)", Activities.shared.count)
                
            }
            
            return Activities.shared.sectionValues(Activities.shared.sectionTitles[section]).count
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
        if filtering == true {
            return []
        } else {
            return [UITableViewIndexSearch, "A", "B", "C" , "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        }
        
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: DEFAULT_HEIGHT_FOR_SECTION_HEADER))
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let activities = filtering ? filteredItems : Activities.shared.items

        if activities.count == 0 {
            let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
            let cell = views![0] as! EmptyCell

            cell.tag = -1

            cell.isUserInteractionEnabled = false

            cell.selectionStyle = .none
            return cell
        } else {
            var activity: Activity?
            if filtering == true {
                if indexPath.row < filteredItems.count {
                    activity = activities[indexPath.row]
                }
            } else {
                activity = Activities.shared.sectionValues(Activities.shared.sectionTitles[indexPath.section])[indexPath.row]
            }

            let cell = ActivityCell.loadNib(tableView)

            cell.nameLabel.text = activity?.name
            cell.tag = Activities.shared.index(id: activity?.id) ?? -1

            if activity?.restricted == true {
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .disclosureIndicator
            }

            cell.backgroundColor = UIColor.clear
            cell.alpha = 0.9
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath), let activity = Activities.shared[cell.tag] {
            Generator.bump()
            
            activity.view()
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        let activities = filtering ? filteredItems : Activities.shared.items
        if activities.count == 0 {
            return 200
        } else {
            return ActivityCell.cellHeight
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Activities.shared.sectionTitles[section]
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let cell = tableView.cellForRow(at: indexPath) as? ActivityCell else {
            return false
        }

        if Activities.shared.get(name: cell.nameLabel.text)?.restricted == true {
            return false
        } else {
            return true
        }
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { _, _ in

            Generator.bump()

            if let index = tableView.cellForRow(at: indexPath)?.tag, let activity = Activities.shared[index] {
                self.deleteActivity(activity)
            }
        })

        let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit", handler: { _, _ in

            Generator.bump()

            if let index = tableView.cellForRow(at: indexPath)?.tag, let activity = Activities.shared[index] {
                activity.edit()
            }
        })

        let viewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "View", handler: { _, _ in

            Generator.bump()

            if let index = tableView.cellForRow(at: indexPath)?.tag, let activity = Activities.shared[index] {
                activity.view()
            }
        })

        deleteRowAction.backgroundColor = UIColor.red
        editRowAction.backgroundColor = UIColor.gray
        viewRowAction.backgroundColor = UIColor.blue

        if System.shared.adminAccess == true {
            return [viewRowAction, editRowAction, deleteRowAction]
        } else {
            return [viewRowAction]
        }
    }
    
    // MARK: - Model Updater
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate else {
            return
        }
        
        if update.model is Activity {
            
            updateSearchResults(for: searchController)
            
            tableView.reloadData()
        }
    }

    
    // MARK: - Other Functions
    
    fileprivate func deleteActivity(_ activity: Activity) {
        PKHUD.loading()
        activity.delete { success in
            guard success == true else {
                PKHUD.failure()
                return
            }
            
            PKHUD.success()
            self.tableView.reloadData()
        }
    }
    
    @objc func scrollToTop() {
        DispatchQueue.main.async {
            let activities = self.filtering ? self.filteredItems : Activities.shared.items
            if activities.count > 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
            }
        }
    }
    
    @objc func resetRefreshControl() {
        Async.waterfall(nil, [Activities.shared.retrieve]) { (_, _) in
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.tableHeaderView?.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.tableFooterView?.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }
}


// MARK: - Copy and Paste Code For Search Controller

extension ViewActivities {
    
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
                    for searchItem in searchArray {
                        if searchItem == " " || searchItem == "" {
                            found += 1
                            continue
                        } else {
                            for keypath in keypaths {
                                if (item[keyPath: keypath]?.uppercased().contains(searchItem) ?? false )! {
                                    found += 1
                                    break
                                }
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
