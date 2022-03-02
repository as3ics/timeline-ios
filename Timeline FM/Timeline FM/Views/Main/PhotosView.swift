//
//  PhotosView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/11/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import PKHUD
import Material

// MARK: - PhotosView

class PhotosView: ViewController, UITableViewDelegate, UITableViewDataSource, SidebarSectionProtocol, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    
    static var section: String {
        return "Photos"
    }
    
    @IBOutlet var tableView: UITableView!
    
    var photos: Photos!
    
    var photoViewerCoordinator: PhotoViewerCoordinator?
    var nytPhotos = [NYTPhotoBox]()
    var previousIndex: UInt?

    @IBOutlet var tabViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var tabAllIcon: UIImageView!
    @IBOutlet var tabAllLabel: UILabel!
    @IBOutlet var tabAllButton: FlatButton!
    @IBOutlet var tabUsersIcon: UIImageView!
    @IBOutlet var tabUsersLabel: UILabel!
    @IBOutlet var tabUsersButton: FlatButton!
    @IBOutlet var tabZonesIcon: UIImageView!
    @IBOutlet var tabZonesLabel: UILabel!
    @IBOutlet var tabZonesButton: FlatButton!
    @IBOutlet var searchBarView: UIView!
    @IBOutlet var searchBarHeightConstraint: NSLayoutConstraint!
    
    enum PhotoTabs: Int {
        case All = 1
        case Users = 2
        case Zones = 3
    }
    
    var currentTab: PhotoTabs = .All
    
    var sectionTitles: [String] = [String]()
    
    
    var filteredItems: [Photo] = [Photo]()
    var searchController = UISearchController(searchResultsController: nil)
    var filtering: Bool = false
    var keypaths: [KeyPath<Photo, String?>] = [KeyPath<Photo, String?>]()
    
    var loaded: Bool = false
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor.clear
        
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: photos === Organization.shared.photos ? #selector(resetRefreshControl) : #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
        
        var i: Int = 0
        for photo in photos.items {
            photo.index = i
            i += 1
        }
        
        PhotosCell.register(tableView)
        PhotoFooterCell.register(tableView)
        
        tabViewHeightConstraint.constant = Device.hasNotch == true ? tabViewHeightConstraint.constant : tabViewHeightConstraint.constant - TIMELINE_STATUS_VIEW_HEIGHT_DIFFERENCE
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, tabViewHeightConstraint.constant, 0)
        
        tabAllIcon.image = AssetManager.shared.photoStack
        tabUsersIcon.image = AssetManager.shared.userPhoto
        tabZonesIcon.image = AssetManager.shared.zone
        
        tabAllButton.tag = PhotoTabs.All.rawValue
        tabUsersButton.tag = PhotoTabs.Users.rawValue
        tabZonesButton.tag = PhotoTabs.Zones.rawValue
        
        //tabAllButton.animateTouch()
        //tabUsersButton.animateTouch()
        //tabZonesButton.animateTouch()
        
        
        keypaths.append(\Photo.location_zone)
        keypaths.append(\Photo.name)
        keypaths.append(\Photo.notes)
        
        tabAllButton.addTarget(self, action: #selector(setTabs), for: .touchUpInside)
        tabUsersButton.addTarget(self, action: #selector(setTabs), for: .touchUpInside)
        tabZonesButton.addTarget(self, action: #selector(setTabs), for: .touchUpInside)
        
        
        tabAllButton.addTarget(tabAllButton, action: #selector(tabAllButton.touchAnimation), for: .touchUpInside)
        tabUsersButton.addTarget(tabUsersButton, action: #selector(tabUsersButton.touchAnimation), for: .touchUpInside)
        tabZonesButton.addTarget(tabZonesButton, action: #selector(tabZonesButton.touchAnimation), for: .touchUpInside)
        
        searchBarHeightConstraint.constant = 0.0
        styleSearchBar(searchController)
        definesPresentationContext = true
        
        searchBarView.addSubview(searchController.searchBar)
        searchController.searchBar.sizeToFit()
        
        applyTheme()
        
        NSNotification.Name.UIKeyboardDidShow.observe(self, selector: #selector(keyboardDidShow))
        NSNotification.Name.UIKeyboardWillHide.observe(self, selector: #selector(keyboardWillHide))
        
        self.setTabs(self.tabAllButton)
    }
    
    @objc func scrollToBottom(_ sender: Any?) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: self.sectionTitles.count)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    @objc func scrollToTop(_ sender: Any?) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.sizeThatFits(UIScreen.main.bounds.size)
        
        if searchController.searchBar.text?.isEmpty ?? true {
            searchController.searchBar.setShowsCancelButton(false, animated: true)
        }
        
        if loaded == false {
            self.scrollToBottom(nil)
            loaded = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        searchController.dismiss(animated: true, completion: nil)
        view.endEditing(true)
    }
    
    override func setupNavBar() {
        navBar?.title = title ?? "Photos"
        
        navBar?.rightImage = AssetManager.shared.search
        navBar?.rightEnclosure = {
            if self.searchBarHeightConstraint.constant == CGFloat(0.0) {
                self.searchBarHeightConstraint.constant = CGFloat(50.0)
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.layoutSubviews], animations: {
                    self.view.layoutIfNeeded()
                }, completion: { (done) in
                    self.searchController.searchBar.becomeFirstResponder()
                })
            } else {
                self.searchBarHeightConstraint.constant = CGFloat(0.0)
                self.searchController.dismiss(animated: true, completion: nil)
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.layoutSubviews], animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
        
        if photos === Organization.shared.photos {
            navBar?.leftImage = AssetManager.shared.menu
            navBar?.leftEnclosure = { self.menuPressed() }
        } else {
            navBar?.leftImage = AssetManager.shared.arrowLeft
            navBar?.leftEnclosure = { self.goBack() }
        }
    }
    
    override func prepareForDeinit() {
        super.prepareForDeinit()
        
        self.photos.unload()
        self.nytPhotos.removeAll()
        self.photoViewerCoordinator = nil
    }

    // MARK: - UITableView Delegate and DataSource
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return PhotosCell.cellHeight
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.filtering {
            return 2
        } else {
            return sectionTitles.count + 1
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.filtering {
            if section == 0 {
                return max(Int(ceil(Double(self.filteredItems.count) / 3.0)), 1)
            } else {
                return 1
            }
        }
        
        guard section < sectionTitles.count else {
            return 1
        }
        
        var photos: [Photo]!
        
        switch currentTab {
        case .All:
            photos = self.photos.sectionValues(mode: .Date, value: sectionTitles[section])
            break
        case .Users:
            photos = self.photos.sectionValues(mode: .User, value: sectionTitles[section])
            break
        case .Zones:
            photos = self.photos.sectionValues(mode: .Zone, value: sectionTitles[section])
        }
    
        return Int(ceil(Double(photos.count) / 3.0))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.filtering {
            if indexPath.section == 0 {
                if self.filteredItems.count > 0 {
                    let cell = PhotosCell.loadNib(tableView)
                    cell.backgroundColor = UIColor.clear
                    cell.selectionStyle = .none
                    return cell
                } else {
                    return UITableViewCell.defaultCell()
                }
            } else {
                let cell = PhotoFooterCell.loadNib(tableView)
                cell.populate(count: self.filteredItems.count)
                cell.selectionStyle = .none
                return cell
            }
        }
        
        
        let section = indexPath.section
        
        guard section < sectionTitles.count else {
            let cell = PhotoFooterCell.loadNib(tableView)
            
            cell.populate(count: self.photos.count)
            cell.selectionStyle = .none
            return cell
        }
        
        let cell = PhotosCell.loadNib(tableView)
        
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < sectionTitles.count, self.filtering == false else {
            return 0
        }
        
        return PhotosHeaderView.cellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = PhotosHeaderView.loadNib()
        
        guard section < sectionTitles.count, self.filtering == false else {
            return nil
        }
        
        switch currentTab {
        case .All:
            view?.titleLabel.text = sectionTitles[section]
            view?.subLabel.text = nil
            return view
        case .Users:
            let userId = sectionTitles[section]
            if let user = userId == Auth.shared.id ? DeviceUser.shared.user : Users.shared[userId] {
                view?.titleLabel.text = user.fullName
                view?.subLabel.text = nil
                return view
            } else {
                return nil
            }
        case .Zones:
            let zoneString = sectionTitles[section]
            guard zoneString != "Unassigned" else {
                view?.titleLabel.text = "No Location"
                view?.subLabel.text = nil
                return view
            }
            
            let components = zoneString.components(separatedBy: "~")
            guard components.count == 2 else {
                return nil
            }
            
            let locationId = components[0]
            let zone = components[1]
            
            if let locationName = Locations.shared[locationId]?.name {
                if zone != "Unassigned" {
                    view?.titleLabel.text =  locationName
                    view?.subLabel.text =  zone
                    view?.titleCenterConstraint.constant = -5.0
                    return view
                } else {
                    view?.titleLabel.text =  locationName
                    view?.subLabel.text = nil
                    return view
                }
            } else {
                view?.titleLabel.text = zone
                view?.subLabel.text = nil
                return view
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let photoCell = cell as? PhotosCell else {
            return
        }
        
        photoCell.prepareForReuse()
        
        var photos: [Photo]!
        
        if self.filtering == false {
            switch currentTab {
            case .All:
                photos = self.photos.sectionValues(mode: .Date, value: sectionTitles[indexPath.section])
                break
            case .Users:
                photos = self.photos.sectionValues(mode: .User, value: sectionTitles[indexPath.section])
                break
            case .Zones:
                photos = self.photos.sectionValues(mode: .Zone, value: sectionTitles[indexPath.section])
            }
        } else {
            photos = self.filteredItems
        }
        
        
        let base = indexPath.row * 3
        
        var _photos = [Photo]()
        for i in base ... base + 2 {
            guard i < photos.count else {
                break
            }
            
            let photo = photos[i]
            
            _photos.append(photo)
        }
        
        photoCell.populate(photos: _photos)
        
        for image in photoCell.images {
            image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewPhoto)))
            image.isUserInteractionEnabled = true
        }
    }
    
    @objc func resetRefreshControl() {
        tableView.refreshControl?.endRefreshing()
    }
    
    // MARK: - Other Functions
    
    @objc func setTabs(_ sender: FlatButton) {
        
        currentTab = PhotoTabs(rawValue: sender.tag) ?? .All
        
        tabAllIcon.tintColor = currentTab == .All ? Theme.shared.active.alternateIconColor : Theme.shared.active.placeholderColor
        tabAllLabel.textColor = currentTab == .All ? Theme.shared.active.alternateIconColor : Theme.shared.active.placeholderColor
        
        tabUsersIcon.tintColor = currentTab == .Users ? Theme.shared.active.alternateIconColor : Theme.shared.active.placeholderColor
        tabUsersLabel.textColor = currentTab == .Users ? Theme.shared.active.alternateIconColor : Theme.shared.active.placeholderColor
        
        tabZonesIcon.tintColor = currentTab == .Zones ? Theme.shared.active.alternateIconColor : Theme.shared.active.placeholderColor
        tabZonesLabel.textColor = currentTab == .Zones ? Theme.shared.active.alternateIconColor : Theme.shared.active.placeholderColor
        
        switch currentTab {
        case .All:
            sectionTitles = self.photos.sectionTitles(mode: .Date)
            break
        case .Users:
            sectionTitles = self.photos.sectionTitles(mode: .User)
            break
        case .Zones:
            sectionTitles = self.photos.sectionTitles(mode: .Zone)
            break
        }
        
        tableView.reloadData()
        if currentTab == .All {
            self.scrollToBottom(sender)
        } else {
            self.scrollToTop(sender)
        }
    }
    
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        self.view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        searchBarView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        searchBarView.clipsToBounds = true
    }
    
}


// MARK: - NYTPhotosViewControllerDelegate

extension PhotosView: NYTPhotosViewControllerDelegate {
    
    @objc func viewPhoto(_ sender: UITapGestureRecognizer) {
        
        guard let imageView = sender.view as? UIImageView else {
            return
        }
        
        imageView.touchAnimation()
        PKHUD.loading()
        
        if self.photoViewerCoordinator == nil {
            
            self.nytPhotos.removeAll()
            for photo in self.photos.items {
                self.nytPhotos.append(photo.nytPhoto)
            }
            
            self.photoViewerCoordinator = PhotoViewerCoordinator(images: self.nytPhotos)
        }
        
        if imageView.tag >= 0, imageView.tag < self.photos.count {
            
            previousIndex = UInt(imageView.tag)
            
            if self.photos.items[imageView.tag].image == nil {
                Async.waterfall(APIClient.shared.downloadSession, [self.photos.items[imageView.tag].download], end: { _, _ in
                    DispatchQueue.main.async {
                        self.photos.items[imageView.tag].nytPhoto.image = self.photos.items[imageView.tag].image
                        
                        PKHUD.success()
                        
                        Presenter.present(NYTPhotosViewController(dataSource: self.photoViewerCoordinator!, initialPhoto: self.photos.items[imageView.tag].nytPhoto, delegate: self), animated: true, completion: {
                            // foo
                        })
                    }
                })
            } else {
                DispatchQueue.main.async {
                    
                    PKHUD.success()
                    
                    if self.photos.items[imageView.tag].nytPhoto.image == nil {
                        self.photos.items[imageView.tag].nytPhoto.image = self.photos.items[imageView.tag].image
                    }
                    
                    Presenter.present(NYTPhotosViewController(dataSource: self.photoViewerCoordinator!, initialPhoto: self.photos.items[imageView.tag].nytPhoto, delegate: self), animated: true, completion: {
                        // foo
                    })
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
        
        // Get rid of previous photo for memory consumption reduction
        
        if let previous = self.previousIndex, previous < self.nytPhotos.count {
            let prevPhoto = self.nytPhotos[Int(previous)]
            prevPhoto.image = nil            
        }
        
        previousIndex = index
        
        // Fetch photo if not set
        
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
    }
    
    func photosViewControllerDidDismiss(_ photosViewController: NYTPhotosViewController) {
        if let previous = self.previousIndex, previous < self.nytPhotos.count {
            let prevPhoto = self.nytPhotos[Int(previous)]
            prevPhoto.image = nil
        }
        
        previousIndex = nil
    }
}


extension PhotosView {
    
    func didPresentSearchController(_: UISearchController) {
        filtering = true
        tableView.reloadData()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        filtering = false
        view.endEditing(true)
        tableView.reloadData()
        
        self.searchBarHeightConstraint.constant = CGFloat(0.0)
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.layoutSubviews], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchString = searchController.searchBar.text?.uppercased() {
            if searchString.characters.count > 0 {
                let searchArray = searchString.components(separatedBy: " ")
                filteredItems = self.photos.items.filter({ (item) -> Bool in
                    var found: Int = 0
                    var compares: [String] = [String]()
                    
                    if let location = Locations.shared[item.location] {
                        if let name = location.name {
                            compares.append(name)
                        }
                        
                        if let address = location.addressStringZip {
                            compares.append(address)
                        }
                        
                        if let street = location.address {
                            compares.append(street)
                        }
                    }
                    
                    if let user = Users.shared[item.user] ?? DeviceUser.shared.user {
                        if let name = user.fullName {
                            compares.append(name)
                        }
                    }
                    
                    if let activity = Activities.shared[item.activity] {
                        if let name = activity.name {
                            compares.append(name)
                        }
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
                filteredItems = self.photos.items
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
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.tabViewHeightConstraint.constant, 0)
        }
    }
}
