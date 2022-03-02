//
//  PhotoViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/23/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import MapKit
import PKHUD
import UIKit
import IQKeyboardManagerSwift
import CoreLocation


// MARK: - PhotoCreate

class PhotoCreate: ViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }

    var image: UIImage?
    var photo: Photo?
    var source: String?

    var titleInput: String = ""
    var notesInput: String = ""

    var timestamp: Date?
    var latitude: Double?
    var longitude: Double?
    var zone: String?

    var sheet: Sheet?
    var entry: Entry?
    var location: Location?

    var editingMode: ViewingMode?

    fileprivate let NOTES_TEXTVIEW_TAG: Int = 2

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none

        if image == nil {
            goBack()
        }

        if editingMode == ViewingMode.Creating {
            timestamp = Date()

            self.photo = Photo()
            
            var model: String!
            var modelId: String!
            
            if let entry = self.entry {
                model = ModelType.Entry.rawValue
                modelId = entry.id
            } else if let location = self.location {
                model = ModelType.Location.rawValue
                modelId = location.id
            } else if let user = DeviceUser.shared.user {
                model = ModelType.User.rawValue
                modelId = user.id
            } else {
                model = ModelType.User.rawValue
                modelId = Auth.shared.id
            }
            
            guard model != nil && modelId != nil else {
                goBack()
                return
            }
            
            photo?.model = model
            photo?.modelId = modelId
            photo?.timestamp = timestamp
            photo?.lat = latitude
            photo?.lon = longitude
            photo?.user = DeviceUser.shared.user?.id
            photo?.sheet = sheet?.id
            photo?.entry = entry?.id
            photo?.location = entry?.location?.id
            photo?.location_zone = ""
            photo?.source = source
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE LLL d, h:mm:ss a"
            
            let date = formatter.string(from: timestamp!)
            let name = DeviceUser.shared.user?.fullName ?? ""
            let loc = DeviceUser.shared.sheet?.location?.name ?? ""
            let activity = DeviceUser.shared.sheet?.entries.latest?.activity?.name ?? ""
            let count: Int = (DeviceUser.shared.sheet?.entries.latest?.photos.items.count ?? 0) + 1
            
            let photoName: String = String(format: "%@ %@ %@ %@ %i", date, name, loc, activity, count)
            
            titleInput = photoName
            
            location = Locations.shared[photo?.location]
            
        } else if editingMode == ViewingMode.Editing {
            if let photo = self.photo {
                titleInput = photo.title ?? ""
                notesInput = photo.notes ?? ""
                latitude = photo.lat
                longitude = photo.lon
                timestamp = photo.timestamp
                image = photo.image
                zone = photo.location_zone ?? ""
                
                location = Locations.shared[photo.location]
            }
        }

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        hideKeyboardWhenTappedAround()

        StandardPhotoCell.register(tableView)
        StandardHeaderCell.register(tableView)
        StandardTextFieldCell.register(tableView)
        StandardMapCell.register(tableView)
        StandardTextViewCell.register(tableView)
        
        NotificationManager.shared.location_zone_selected.observe(self, selector: #selector(zoneSelectedNotification))
    }
    
    override func setupNavBar() {
        if editingMode == ViewingMode.Creating {
            navBar?.title = "Save Photo"
        } else if editingMode == ViewingMode.Editing {
            navBar?.title = "Edit Photo"
        }
        
        navBar?.rightImage = AssetManager.shared.save
        navBar?.rightEnclosure = { self.save() }
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
    }
    
    // MARK: - UITableView Delegate and DataSource

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Photo Image
            return 1
        case 1: // Information
            return location == nil ? 4 : 5
        case 2: // Notes
            return 2
        case 3: // Location
            return 2
        default:
            return 2
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        switch editingMode! {
        case ViewingMode.Creating:
            return 4
        default:
            return 5
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 300
        case 1:
            switch indexPath.row {
            case 0:
                return 70
            default:
                return 50
            }
        case 2:
            switch indexPath.row {
            case 0:
                return 70
            default:
                return 130
            }
        case 3:
            switch indexPath.row {
            case 0:
                return 70
            case 1 /*3*/:
                return 300
            default:
                return 50
            }
        default:
            switch indexPath.row {
            case 0:
                return 70
            default:
                return 50
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = StandardPhotoCell.loadNib(tableView)

            cell.populate(image)

            cell.selectionStyle = .none
            return cell
        case 1:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Information"
                cell.footer.text = ""

                cell.selectionStyle = .none
                return cell
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = ""
                cell.contents.placeholder = "Enter Title"
                cell.contents.delegate = self
                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0

                cell.contents.text = titleInput
                cell.contents.autoResize()

                //cell.contents.addTarget(self, action: #selector(updateTitleInput), for: UIControlEvents.allEditingEvents)

                cell.selectionStyle = .none
                return cell
            case 2:
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Date"

                let formatter = DateFormatter()
                formatter.dateFormat = "EEE LLL d, h:mm:ss a"

                if let date = self.timestamp {
                    cell.contents.text = formatter.string(from: date)
                } else {
                    cell.contents.text = "Unknown"
                }

                cell.contents.isEnabled = false
                cell.contents.textColor = UIColor.black
                cell.carrot.alpha = 0
                cell.selectionStyle = .none

                return cell
            case 3:
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Location"

                if let entry = self.entry {
                    if entry.activity?.traveling == false && entry.activity?.breaking == false {
                        cell.contents.text = entry.location?.name
                    } else if entry.activity?.traveling == true {
                        cell.contents.text = "Traveling"
                    } else {
                        cell.contents.text = "Unknown"
                    }
                } else {
                    cell.contents.text = "Unknown"
                }

                cell.contents.isEnabled = false
                cell.contents.textColor = UIColor.black

                cell.carrot.alpha = 0
                cell.selectionStyle = .none

                return cell
            default:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Zone"
                cell.contents.placeholder = "Add Zone"
                cell.contents.text = zone
                cell.contents.isUserInteractionEnabled = false
                
                cell.isUserInteractionEnabled = true
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goSelectZone)))
                cell.carrot.alpha = 1.0
                cell.selectionStyle = .none
                
                return cell
                
            }
        case 2:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Notes"
                cell.footer.text = ""

                cell.selectionStyle = .none
                return cell
            default:
                let cell = StandardTextViewCell.loadNib(tableView)

                cell.contents.text = notesInput
                cell.contents.textColor = UIColor(hex: "929292")

                cell.contents.tag = NOTES_TEXTVIEW_TAG
                cell.contents.delegate = self

                cell.selectionStyle = .none
                return cell
            }
        case 3:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Location"
                cell.footer.text = ""

                cell.selectionStyle = .none
                return cell
                /*
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Latitude"

                cell.contents.text = photo?.latitude ?? "Unknown"

                cell.contents.isEnabled = false
                cell.contents.textColor = UIColor.black
                cell.carrot.alpha = 0
                cell.selectionStyle = .none

                return cell
            case 2:
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Longitude"

                cell.contents.text = photo?.longitude ?? "Unknown"

                cell.contents.isEnabled = false
                cell.contents.textColor = UIColor.black
                cell.carrot.alpha = 0
                cell.selectionStyle = .none

                return cell
                */
            default:
                let cell = StandardMapCell.loadNib(tableView)

                cell.clearMap(all: false)
                cell.populate(photo: photo)

                cell.selectionStyle = .none
                return cell
            }
        default:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Options"
                cell.footer.text = ""

                cell.selectionStyle = .none

                return cell
            default:
                let cell = StandardButtonCell.loadNib(tableView)

                cell.backgroundColor = UIColor.red
                cell.label.text = "Delete"

                let tap = UITapGestureRecognizer(target: self, action: #selector(deletePicture))
                cell.isUserInteractionEnabled = true
                cell.addGestureRecognizer(tap)

                cell.selectionStyle = .none
                return cell
            }
        }
    }
    
    // MARK: - UIText Delegate

    func textViewDidChange(_ textView: UITextView) {
        if textView.tag == NOTES_TEXTVIEW_TAG {
            notesInput = textView.text
        }
    }
    
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    
    // MARK: - Other Functions
    
    @objc func deletePicture(_ sender: UITapGestureRecognizer) {
        
    }

    @objc func updateTitleInput(_ sender: UITextField) {
        titleInput = sender.text ?? self.titleInput
    }

    @objc func save() {
        view.endEditing(true)

        PKHUD.loading()

        if editingMode == ViewingMode.Creating {

            guard let photo = photo else {
                PKHUD.failure()
                return
            }
            
            if let loc_zone = zone {
                photo.title = String(format: "%@ %@", titleInput, loc_zone)
                photo.notes = notesInput
                photo.location_zone = loc_zone
            } else {
                photo.title = titleInput
                photo.notes = notesInput
            }
            
            Async.waterfall(image, [photo.create]) { (error, endValue) in
                guard error == nil else {
                    PKHUD.failure()
                    return
                }
                
                self.entry?.photos.add(photo)
                DeviceUser.shared.user?.photos.add(photo)
                
                PKHUD.success()
                self.goBack()
            }
        } else {
            photo?.title = titleInput
            photo?.notes = notesInput
            photo?.location_zone = zone

            photo?.update({ success in
                guard success == true else {
                    PKHUD.failure()
                    return
                }

                PKHUD.success()
                self.goBack()
            })
        }
    }
    
    @objc func goSelectZone(_ sender: UITapGestureRecognizer) {
        guard let location = location else {
            return
        }
        
        Generator.bump()
        
        let destination = UIStoryboard.Location(identifier: "LocationZones") as! LocationZones
        destination.location = location
        destination.mode = .Selecting
        
        Presenter.push(destination)
    }
    
    @objc func zoneSelectedNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let zone = info["zone"] as? String else {
            return
        }
        
        self.zone = zone
        
        tableView.reloadData()
    }

    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        navBar?.rightButton.tintColor = UIColor.red
    }
}

