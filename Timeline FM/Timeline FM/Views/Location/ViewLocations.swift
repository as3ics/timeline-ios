//
//  LocationsViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/3/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import MapKit
import Material
import PKHUD
import UIKit
import CoreLocation

// MARK: - ViewLocations

class ViewLocations: ViewController, UITableViewDelegate, UITableViewDataSource, SidebarSectionProtocol, SearchControllerProtocol {
    
    static var section: String = "Locations"
    
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Search Controller Protocol Items
    
    typealias Item = Location
    var items: [Item] {
        return Locations.shared.items
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
        
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.5
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(resetRefreshControl), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.contentInset = UIEdgeInsets.zero
        
        NSNotification.Name.UIKeyboardDidShow.observe(self, selector: #selector(keyboardDidShow))
        NSNotification.Name.UIKeyboardWillHide.observe(self, selector: #selector(keyboardWillHide))
        
        // MARK: Set KeyPaths for Search Controller
        
        keypaths.append(\Item.name)
        keypaths.append(\Item.city)
        keypaths.append(\Item.address)
        
        // MARK: End Code For Search Controller
        
        tableView.separatorStyle = .none

        LocationCell.register(tableView)
        
        Locations.shared.sortByDistance()

        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if searchController.searchBar.text?.isEmpty ?? true {
            searchController.searchBar.setShowsCancelButton(false, animated: true)
        }
        
        tableView.sizeThatFits(tableView.contentSize)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        searchController.dismiss(animated: true, completion: nil)
    }
    
    override func setupNavBar() {
        navBar?.title = String(format: "Locations (%i)", Locations.shared.count)
        navBar?.titleAction = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        
        navBar?.leftImage = AssetManager.shared.menu
        navBar?.leftEnclosure = { self.menuPressed() }
        
        navBar?.rightImage = AssetManager.shared.plus
        navBar?.rightEnclosure = { self.add() }
    }
    
    // MARK: - UITableView Delegate and DataSource
    
    func numberOfSections(in _: UITableView) -> Int {
        let locations = filtering ? filteredItems : items
        DispatchQueue.main.async {
            self.navBar?.title = String(format: "Locations (%i)", locations.count)
        }
        return locations.count + 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func tableView(_: UITableView, shouldHighlightRowAt _: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let locations = filtering ? filteredItems : items

        if locations.count == 0 {
            let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
            let cell = views![0] as! EmptyCell

            if filtering == false {
                let tap = UITapGestureRecognizer(target: self, action: #selector(add))
                cell.addGestureRecognizer(tap)
                cell.isUserInteractionEnabled = true
            }

            cell.selectionStyle = .none
            return cell
        } else {
            let index = indexPath.section
            if index < locations.count {
                let location = locations[index]
                let cell = location.dequeCell()!
                return cell
            } else {
                return UITableViewCell()
            }
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let locations = filtering ? filteredItems : items

        Generator.bump()
        
        let location = locations[indexPath.section]
        location.view()
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let locations = filtering ? filteredItems : items

        if locations.count == 0 {
            return 200
        } else if indexPath.section < locations.count {
            return 70
        } else {
            return 0
        }
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        let locations = filtering ? filteredItems : items
        return (locations.count != 0)
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { _, _ in

            Generator.bump()

            let location = self.filtering ? self.filteredItems[indexPath.section] : self.items[indexPath.section]

            self.deleteLocation(location)

        })

        let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit", handler: { _, _ in

            Generator.bump()

            let location = self.filtering ? self.filteredItems[indexPath.section] : self.items[indexPath.section]

            location.edit()
        })

        let viewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "View", handler: { _, _ in

            Generator.bump()

            let location = self.filtering ? self.filteredItems[indexPath.section] : self.items[indexPath.section]

            location.view()
        })

        viewRowAction.backgroundColor = UIColor.blue
        editRowAction.backgroundColor = UIColor.gray
        deleteRowAction.backgroundColor = UIColor.red

        if System.shared.adminAccess == true {
            return [viewRowAction, editRowAction, deleteRowAction]
        } else {
            return [viewRowAction]
        }
    }
    
    @objc func resetRefreshControl() {
        Async.waterfall(nil, [Locations.shared.retrieve, Stream.shared.retrieve]) { (_, _) in
            
            Locations.shared.sortByDistance()
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - Model Updater
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate else {
            return
        }
        
        if update.model is Location {
            
            
            if filtering == true {
                updateSearchResults(for: searchController)
            }
            
            tableView.reloadData()
        }
    }

    // MARK: - Other Functions
    
    fileprivate func deleteLocation(_ location: Location?) {
        guard let location = location else {
            return
        }

        PKHUD.loading()

        location.delete { success in
            guard success == true else {
                PKHUD.failure()
                return
            }

            PKHUD.success()
            self.tableView.reloadData()
        }
    }

    @objc func add() {
        filtering = false
        tableView.reloadData()

        searchController.searchBar.endEditing(true)

        let destination = UIStoryboard.Location(identifier: "CreateLocation") as! CreateLocation

        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc func scrollToTop() {
        DispatchQueue.main.async {
            let locations = self.filtering ? self.filteredItems : self.items
            if locations.count > 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
            }
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

extension ViewLocations {
    
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

