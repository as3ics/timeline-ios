//
//  ReviewLocationViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/7/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import MapKit
import PKHUD
import UIKit
import Material
import CoreLocation

// MARK: - ViewLocation

class ViewLocation: ViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }

    var tempLat: Double?
    var tempLon: Double?
    var tempBoundaries = [CLLocationCoordinate2D]()
    
    var location: Location?
    
    var name: String?
    var address: String?
    var city: String?
    var state: String?
    var zip: String?
    var notes: String?

    var photoViewerCoordinator: PhotoViewerCoordinator?
    var nytPhotos = [NYTPhotoBox]()
    
    var users: Users = Users(lean: true)
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard location != nil else {
            goBack()
            return
        }
        
        if mode == nil {
            mode = .Viewing
        }

        // Style the Table View
        tableView.separatorStyle = .none

        hideKeyboardWhenTappedAround()

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        StandardMapCell.register(tableView)
        StandardTwoButtonCell.register(tableView)
        StandardHeaderCell.register(tableView)
        StandardTextFieldCell.register(tableView)
        StandardTextViewCell.register(tableView)
        StandardDescriptionCell.register(tableView)
        StandardSliderCell.register(tableView)
    
        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        users.items = self.location?.presentUsers() ?? []
        tableView.reloadData()
    }
    
    override func setupNavBar() {
        navBar?.title = "Review Location"
        
        if System.shared.adminAccess == true {
            navBar?.rightImage = AssetManager.shared.edit
            navBar?.rightEnclosure = { self.edit() }
        } else {
            navBar?.rightImage = nil
        }
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
        
        updateNavItems()
    }
    
    override func goBack() {
        if mode == .Editing {
            mode = ViewingMode.Viewing
            tableView.refreshControl?.endRefreshing()
            updateNavItems()
        } else {
            super.goBack()
        }
    }
    
    @objc func updateNavItems() {
        setRightNavButton()
        
        navBar?.title = mode == ViewingMode.Editing ? "Edit Location" : location?.name ?? "Location"
        
        tableView.reloadData()
    }
    
    
    func setRightNavButton() {
        if mode == .Editing {
            navBar?.rightImage = AssetManager.shared.save
            navBar?.rightEnclosure = { self.save() }
            navBar?.rightButton.tintColor = UIColor.red
        } else {
            navBar?.rightImage = AssetManager.shared.edit
            navBar?.rightEnclosure = { self.edit() }
            navBar?.rightButton.tintColor = Theme.shared.active.subHeaderFontColor
        }
    }
    
    // MARK: - Model Updater
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate else {
            return
        }
        
        if update.type == .Location {
            tableView.reloadData()
        }
    }

    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        let value = mode == .Editing ? 8 : 7
        return value
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 5:
            return 2
        case 2:
            let value = mode == .Editing ? 0 : 3
            return value
        case 3:
            let value = mode == .Editing ? 0 : users.count == 0 ? 0 : users.count + 1
            return value
        case 4:
            let value = mode == .Editing ? 0 : 5
            return value
        case 6:
            let value = mode == .Editing ? 0 : 2
            return value
        case 7:
            return 2
        case 1:
            let value = mode == .Editing ? 2 : 0
            return value
        default:
            return 0
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 200
        case 1:
            switch indexPath.row {
            case 0:
                return 60
            default:
                return 50
            }
        case 4:
            switch indexPath.row {
            case 0:
                return 60
            default:
                return 40
            }
        case 5:
            switch indexPath.row {
            case 0:
                return 60
            default:
                return 130
            }
        case 2, 3:
            switch indexPath.row {
            case 0:
                return 60
            default:
                return 50
            }
        case 6, 7:
            switch indexPath.row {
            case 0:
                return 60
            default:
                return 60
            }
        default:
            return 0
        }
    }

    func tableView(_: UITableView, shouldHighlightRowAt _: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            default:
                let cell = StandardMapCell.loadNib(tableView)
                
                if let location = location {
                    cell.populateMap(location: location)
                    
                    cell.mapView.mapType = .hybrid
                }
                
                cell.isUserInteractionEnabled = false
                cell.selectionStyle = .none
                
                return cell
            }
        case 1:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = ""
                cell.title.text = "Location Name"
                
                cell.selectionStyle = .none
                
                return cell
            default:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Name"
                cell.contents.placeholder = "Enter Name"
                cell.contents.tag = 1
                cell.contents.delegate = self
                
                if let location = location {
                    cell.contents.text = name ?? location.name
                }
                
                if mode == .Editing {
                    cell.isUserInteractionEnabled = true
                    cell.carrot.alpha = 1.0
                } else {
                    cell.isUserInteractionEnabled = false
                    cell.carrot.alpha = 0.0
                }
                
                cell.selectionStyle = .none
                return cell
            }
        case 4:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = ""
                cell.title.text = "Address"
                
                cell.selectionStyle = .none
                return cell
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Address"
                cell.contents.text = ""
                cell.contents.placeholder = "Enter Address"
                cell.contents.delegate = self
                cell.contents.tag = 2
                
                if let location = location {
                    cell.contents.text = address ?? location.address
                }
                
                if mode == .Editing {
                    cell.isUserInteractionEnabled = true
                    cell.carrot.alpha = 1.0
                } else {
                    cell.isUserInteractionEnabled = false
                    cell.carrot.alpha = 0.0
                }
                
                cell.selectionStyle = .none
                return cell
            case 2:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "City"
                cell.contents.text = ""
                cell.contents.placeholder = "Enter City"
                cell.contents.delegate = self
                cell.contents.tag = 3
                
                if let location = location {
                    cell.contents.text = city ?? location.city
                }
                
                if mode == .Editing {
                    cell.isUserInteractionEnabled = true
                    cell.carrot.alpha = 1.0
                } else {
                    cell.isUserInteractionEnabled = false
                    cell.carrot.alpha = 0.0
                }
                
                cell.selectionStyle = .none
                return cell
            case 3:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "State"
                cell.contents.text = ""
                cell.contents.placeholder = "Enter State"
                cell.contents.delegate = self
                cell.contents.tag = 4
                
                if let location = location {
                    cell.contents.text = state ?? location.state
                }
                
                if mode == .Editing {
                    cell.isUserInteractionEnabled = true
                    cell.carrot.alpha = 1.0
                } else {
                    cell.isUserInteractionEnabled = false
                    cell.carrot.alpha = 0.0
                }
                
                cell.selectionStyle = .none
                return cell
            default:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Zip"
                cell.contents.text = ""
                cell.contents.placeholder = "Enter Zip"
                cell.contents.delegate = self
                cell.contents.tag = 5
                
                if let location = location {
                    cell.contents.text = zip ?? location.zip
                }
                
                if mode == .Editing {
                    cell.isUserInteractionEnabled = true
                    cell.carrot.alpha = 1.0
                } else {
                    cell.isUserInteractionEnabled = false
                    cell.carrot.alpha = 0.0
                }
                
                cell.selectionStyle = .none
                return cell
            }
        case 3:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = ""
                cell.title.text = String(format: "People (%i)", users.count)
                
                cell.selectionStyle = .none
                return cell
            default:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = users.items[indexPath.row - 1].fullName
                cell.contents.text = users.items[indexPath.row - 1].userRole.rawValue.lowercased()
                cell.carrot.alpha = 1.0
                cell.contents.placeholder = ""
                cell.tag = indexPath.row - 1
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewUser)))
                cell.contents.isUserInteractionEnabled = false
                cell.isUserInteractionEnabled = true
                
                cell.selectionStyle = .none
                return cell
            }
        case 5:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = ""
                cell.title.text = "Location Notes"
                
                cell.selectionStyle = .none
                
                return cell
            default:
                let cell = StandardTextViewCell.loadNib(tableView)
                
                cell.contents.delegate = self
                
                if let location = location {
                    cell.contents.text = notes ?? location.notes
                }
                
                if mode == .Editing {
                    cell.contents.isEditable = true
                } else {
                    cell.contents.isEditable = false
                }
                
                cell.selectionStyle = .none
                
                return cell
            }
        case 2:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = ""
                cell.title.text = "Data"
                
                cell.selectionStyle = .none
                
                return cell
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                let count: Int = location?.photos.count ?? 0
                
                cell.label.text = "Photos"
                cell.contents.text = String(format: "%i", arguments: [count])
                cell.contents.isUserInteractionEnabled = false
                
                cell.isUserInteractionEnabled = false
                
                if count > 0 {
                    cell.carrot.alpha = 1.0
                    cell.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(goToPhotos)))
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.carrot.alpha = 0.0
                }
                
                cell.selectionStyle = .none
                return cell
            default:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                let count: Int = location?.zones.count ?? 0
                
                cell.label.text = "Zones"
                cell.contents.text = String(format: "%i", arguments: [count])
                cell.contents.isUserInteractionEnabled = false
                
                cell.carrot.alpha = 1.0
                cell.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(goToZones)))
                cell.isUserInteractionEnabled = true
                
                cell.selectionStyle = .none
                return cell
            }
        case 6:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = ""
                cell.title.text = "Directions"
                
                cell.selectionStyle = .none
                
                return cell
            default:
                let cell = StandardTwoButtonCell.loadNib(tableView)
                
                cell.leftButton.style(Color.blue.base, image: nil, title: "Apple")
                cell.rightButton.style(Color.green.base, image: nil, title: "Google")
                
                cell.leftButton.addTarget(self, action: #selector(openAppleMaps), for: .touchUpInside)
                cell.rightButton.addTarget(self, action: #selector(openGoogleMaps), for: .touchUpInside)
                
                cell.rightButton.alpha = 1.0
                cell.leftButton.alpha = 1.0
                
                cell.selectionStyle = .none
                return cell
            }
        case 7:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = ""
                cell.title.text = "Actions"
                
                cell.selectionStyle = .none
                
                return cell
            default:
                let cell = StandardTwoButtonCell.loadNib(tableView)
                
                // TODO: Fix or remove update images button
                cell.rightButton.isUserInteractionEnabled = false
                cell.rightButton.alpha = 0.0
                
                /*
                 cell.rightButton.style(Color.green.darken3, image: nil, title: "Update Images")
                 cell.rightButton.addTarget(self, action: #selector(updateLocationAssets), for: .touchUpInside)
                */
                
                cell.leftButton.style(Color.blue.darken3, image: nil, title: "Update Boundary")
                cell.leftButton.addTarget(self, action: #selector(goToUpdateBoundary), for: .touchUpInside)
                
                cell.selectionStyle = .none
                return cell
            }
        default:
            return UITableViewCell.defaultCell()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField.tag {
        case 1:
            name = textField.text
            break
        case 2:
            address = textField.text
            break
        case 3:
            city = textField.text
            break
        case 4:
            state = textField.text
            break
        case 5:
            zip = textField.text
            break
        default:
            break
        }
    }
    
    // MARK: - UIText Delegate
    
    func textViewDidEndEditing(_ textView: UITextView) {
        notes = textView.text
    }

    
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    
    // MARK: - Other Functions
    
    @objc func viewUser(_ sender: UIGestureRecognizer?) {
        guard let tag = sender?.view?.tag else {
            return
        }
        
        Generator.bump()
        users.items[tag].view()
        
    }
    
    @objc func updateLocationAssets() {
        delay(0.2) {
            guard let location = self.location else {
                PKHUD.failure()
                return
            }
            
            PKHUD.loading()
            
            location.reprocessAssets({ (success) in
                guard success == true else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
            })
        }
        
    }
    
    @objc func openGoogleMaps() {
        delay(0.2) {
            if let coordinate = self.location?.coordinate {
                coordinate.googleMaps()
            }
        }
    }
    
    @objc func openAppleMaps() {
        delay(0.2) {
            if let coordinate = self.location?.coordinate {
                coordinate.appleMaps(name: self.location?.name)
            }
        }
    }

    @objc func goToUpdateBoundary() {
        delay(0.2) {
            let destination = UIStoryboard.Location(identifier: "CreateBoundary") as! CreateBoundary
            
            destination.location = nil
            destination.updateId = self.location?.id
            destination.mode = .Editing
            
            Presenter.push(destination, animated: true, completion: nil)
        }
    }

    @objc func edit() {

        mode = .Editing
        updateNavItems()
    }

    @objc func save() {
        
        view.endEditing(true)

        location?.name = name != nil ?  name : location?.name
        location?.notes = notes != nil ?  notes : location?.notes
        
        PKHUD.loading()

        location?.update({ (success) in
            guard success == true else {
                PKHUD.failure()
                return
            }
            
            self.name = nil
            self.address = nil
            self.city = nil
            self.state = nil
            self.zip = nil
            self.notes = nil
            
            PKHUD.success()
            self.tableView.reloadData()
            self.mode = .Viewing
            self.updateNavItems()
        })
    }

    @objc func goToPhotos() {
        
        Generator.confirm()
        
        location?.photos.view(title: location?.name)
    }
    
    @objc func goToZones() {
        Generator.confirm()
        
        let destination = UIStoryboard.Location(identifier: "LocationZones") as! LocationZones
        destination.location = self.location!
        
        Presenter.push(destination)
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        if mode == .Editing {
            navBar?.rightButton.tintColor = UIColor.red
        }
    }
}
