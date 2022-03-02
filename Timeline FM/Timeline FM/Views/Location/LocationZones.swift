//
//  LocationZones.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/28/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Material
import PKHUD
import UIKit

// MARK: - LocationZones

class LocationZones: ViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    var location: Location!
    
    // MARK: - Search Controller Protocol Items
    
    typealias Item = String
    var items: [Item]!
    
    var filteredItems: [Item] = [Item]()
    var searchController = UISearchController(searchResultsController: nil)
    var filtering: Bool = false
    var keypaths: [KeyPath<Item, String?>] = [KeyPath<Item, String?>]()
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        items = location.zones
        
        // MARK: Copy and Paste Code For Search Controller
        
        styleSearchBar(searchController)
        tableView.tableHeaderView = searchController.searchBar
        tableView.tableHeaderView?.height = DEFAULT_SEARCHBAR_HEADER_HEIGHT
        searchController.searchBar.sizeToFit()
        definesPresentationContext = true
        
        NSNotification.Name.UIKeyboardDidShow.observe(self, selector: #selector(keyboardDidShow))
        NSNotification.Name.UIKeyboardWillHide.observe(self, selector: #selector(keyboardWillHide))
        
        // MARK: Set KeyPaths for Search Controller
        
        
        // MARK: End Code For Search Controller
        
        tableView.separatorStyle = .none
        
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        ActivityCell.register(tableView)
        
        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        tableView.reloadSectionIndexTitles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if searchController.searchBar.text?.isEmpty ?? true {
            searchController.searchBar.setShowsCancelButton(false, animated: false)
        }
    }
    
    override func setupNavBar() {
        navBar?.title = "Location Zones"
        navBar?.titleAction = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = {
            self.goBack()
        }
        
        navBar?.rightImage = AssetManager.shared.plus
        navBar?.rightEnclosure = {
            let destination = UIStoryboard.Location(identifier: "LocationAddZone") as! LocationAddZone
            destination.location = self.location
            
            Presenter.push(destination)
        }
    }
    
    // MARK: - UITableView Delegate and DataSource
    
    func numberOfSections(in _: UITableView) -> Int {
        if filtering == true {
            return 1
        } else {
            return max(location.sectionTitles.count, 1)
        }
    }
    
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let items = filtering ? filteredItems : location.zones
        
        if filtering == true {
            if filteredItems.count == 0 {
                return 1
            } else {
                return filteredItems.count
            }
        } else {
            if items.count == 0 {
                return 1
            } else {
                return location.sectionValues(location.sectionTitles[section]).count
            }
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
        let items = filtering ? filteredItems : location.zones
        
        if items.count == 0 {
            let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
            let cell = views![0] as! EmptyCell
            
            cell.tag = -1
            
            cell.isUserInteractionEnabled = false
            
            cell.selectionStyle = .none
            return cell
        } else {
            var item: String?
            if filtering == true {
                if indexPath.row < filteredItems.count {
                    item = items[indexPath.row]
                }
            } else {
                item = location.sectionValues(location.sectionTitles[indexPath.section])[indexPath.row]
            }
            
            let cell = ActivityCell.loadNib(tableView)
            
            cell.nameLabel.text = item
            cell.accessoryType = .none
            
            cell.backgroundColor = UIColor.clear
            cell.selectionStyle = .none
            cell.alpha = 0.9
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ActivityCell, let zone = cell.nameLabel.text {
            
            if mode == .Selecting {
                Generator.bump()
                
                NotificationManager.shared.location_zone_selected.post(["zone": zone as AnyHashable])
                
                goBack()
            }
        }
    }
    
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        let items = filtering ? filteredItems : location.zones
        if items.count == 0 {
            return 200
        } else {
            return 40
        }
    }
    
    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        return location.sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let _ = tableView.cellForRow(at: indexPath) as? ActivityCell else {
            return false
        }
        
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { _, _ in
            
            Generator.bump()
            
            guard let cell = tableView.cellForRow(at: indexPath) as? ActivityCell else {
                return
            }
            
            PKHUD.loading()
            
            let zone = cell.nameLabel.text
            
            Async.waterfall(zone, [self.location.removeZone], end: { (error, response) in
                guard error == nil else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
            })
        })
        
        deleteRowAction.backgroundColor = UIColor.red
        
        return [deleteRowAction]
    }
    
    // MARK: - Model Updater
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate else {
            return
        }
        
        if update.model is Location {
            
            updateSearchResults(for: searchController)
            
            items = location.zones
            tableView.reloadData()
        }
    }
    
    
    // MARK: - Other Functions
    
    @objc func scrollToTop() {
        DispatchQueue.main.async {
            let activities = self.filtering ? self.filteredItems : self.location.zones
            if activities.count > 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
            }
        }
    }
    
    @objc func resetRefreshControl() {
        tableView.refreshControl?.endRefreshing()
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

extension LocationZones {
    
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
                filteredItems = items.filter({ (item) -> Bool in
                    return item.uppercased().contains(searchString)
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

