//
//  NewEntryViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/4/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import UIKit
import CoreLocation
import Material
import PKHUD
import ActionSheetPicker_3_0

// MARK: - EntryCreate

class EntryCreate: ViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }
    
    var date: Date?
    weak var sheet: Sheet?
    weak var activity: Activity?
    weak var location: Location?
    var selectedPaid: String = "Paid"

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard sheet != nil else {
            goBack()
            return
        }

        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        date = self.sheet?.entries.count == 0 ? self.sheet?.date ?? Date() : Date()

        StandardMapCell.register(tableView)
        StandardHeaderCell.register(tableView)
        StandardButtonCell.register(tableView)
        StandardTextFieldCell.register(tableView)
        StandardTwoButtonCell.register(tableView)

        if sheet === DeviceUser.shared.sheet {
            LocationManager.shared.updateHold(true)
        }
    }

    override func goBack() {
        prepareForDeinit()
        
        if sheet === DeviceUser.shared.sheet {
            LocationManager.shared.updateHold(false)
        }
        
        navigationController?.dismiss(animated: true, completion: nil)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        
        if activity == nil || activity?.id == nil {
            activity = Activities.shared.defaultActivity
        }
        

        if location == nil || location?.id == nil {
            guard let location = LocationManager.shared.currentLocation else {
                PKHUD.loading()
                DispatchQueue.main.async {
                    LocationManager.shared.fetchLocation { (location) in
                        PKHUD.success()
                        if let closest = Locations.shared.closest(location) {
                            self.location = closest
                            self.tableView.reloadSections([0,2], with: .automatic)
                        }
                    }
                }
                
                return
            }
            
            if let closest = Locations.shared.closest(location) {
                self.location = closest
                self.tableView.reloadSections([0,2], with: .automatic)
            }
        }
    }
    
    override func setupNavBar() {
        navBar?.title = "Create Entry"
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.rightImage = AssetManager.shared.add
        
        navBar?.leftEnclosure = { self.goBack() }
        navBar?.rightEnclosure = { self.create() }
    }

    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        return 5
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 4
        case 2:
            return 2
        case 3:
            return 2
        case 4:
            return 2
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
        case 2, 3, 4:
            switch indexPath.row {
            case 1:
                return 50
            case 2:
                return 55
            default:
                return 60
            }
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = StandardMapCell.loadNib(tableView)

            if let location = self.location {
                cell.populateMap(location: location)
            } else if let coordinate = LocationManager.shared.currentLocation?.coordinate {
                cell.mapView.setCenter(coordinate, animated: false)
            }

            cell.selectionStyle = .none
            return cell
        case 1:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Info"
                cell.footer.text = ""

                cell.selectionStyle = .none
                return cell
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "User"
                cell.contents.isUserInteractionEnabled = false
                
                let user = Users.shared[self.sheet?.user] ?? DeviceUser.shared.user
                cell.contents.text = user?.fullName ?? "John Doe"
                
                cell.carrot.alpha = 0.0
                
                cell.selectionStyle = .none
                return cell
            case 2:
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Start Time"
                cell.contents.isUserInteractionEnabled = false

                let formatter = DateFormatter()
                formatter.dateFormat = "EEE LLL d, h:mm:ss a"
                cell.contents.text = formatter.string(from: date!)

                cell.carrot.alpha = 1.0

                cell.selectionStyle = .none
                return cell
            default:
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Paid/Unpaid"
                cell.contents.isUserInteractionEnabled = false
                cell.contents.text = selectedPaid
                cell.carrot.alpha = 1.0

                cell.selectionStyle = .none
                return cell
            }
        case 2:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Location"
                cell.footer.text = ""

                cell.selectionStyle = .none
                return cell
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Location"
                cell.contents.isUserInteractionEnabled = false

                if let location = self.location {
                    cell.contents.text = location.name!
                    cell.carrot.alpha = 1.0
                } else {
                    if self.activity?.breaking == true || self.activity?.traveling == true {
                        cell.contents.text = "Empty"
                        cell.isUserInteractionEnabled = false
                        cell.carrot.alpha = 0.0
                    } else {
                        cell.contents.text = "Choose"
                        cell.isUserInteractionEnabled = true
                        cell.carrot.alpha = 1.0
                    }
                }

                cell.selectionStyle = .none
                return cell
            default:
                let cell = StandardButtonCell.loadNib(tableView)

                cell.label.text = "Create New Location"

                cell.selectionStyle = .none
                return cell
            }
        case 3:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Activity"
                cell.footer.text = ""

                cell.selectionStyle = .none
                return cell
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Activity"
                cell.contents.isUserInteractionEnabled = false

                if let activity = self.activity { cell.contents.text = activity.name }
                else { cell.contents.text = nil }

                cell.carrot.alpha = 1.0

                cell.selectionStyle = .none
                return cell
            default:
                let cell = StandardButtonCell.loadNib(tableView)

                cell.label.text = "Create New Activity"

                cell.selectionStyle = .none
                return cell
            }
        default:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.title.text = "Actions"
                cell.footer.text = ""
                
                cell.selectionStyle = .none
                return cell
            default:
                let cell = StandardTwoButtonCell.loadNib(tableView)
                
                cell.leftButton.style(Color.blue.base, image: nil, title: "New Location")
                cell.rightButton.style(Color.green.base, image: nil, title: "New Activity")
                
                cell.leftButton.addTarget(self, action: #selector(goCreateLocation), for: .touchUpInside)
                cell.rightButton.addTarget(self, action: #selector(goCreateActivity), for: .touchUpInside)
                
                cell.selectionStyle = .none
                return cell
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            break
        case 1:
            switch indexPath.row {
            case 0:
                break
            case 2:
                Generator.bump()

                let minimum = sheet!.date!
                let maximum = Date()

                let picker = ActionSheetDatePicker(title: "Start Time", datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: minimum, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(updateTime(_:)), cancelAction: nil, origin: self.tableView)

                styleActionSheetDatePicker(picker!)
                picker!.show()
                break
            case 3:
                Generator.bump()

                var names = [String]()

                names.append("Paid")
                names.append("Unpaid")

                var index: Int = 1

                if selectedPaid == "Paid" {
                    index = 0
                }

                let picker = ActionSheetStringPicker(title: "Select Paid/Unpaid:", rows: names, initialSelection: index, doneBlock: {
                    _, index, _ in
                    Generator.bump()
                    
                    guard index < names.count else {
                        return
                    }
                    
                    self.selectedPaid = names[index]
                    self.tableView.reloadRows(at: [indexPath], with: .none)

                    return
                }, cancel: { _ in
                    Generator.bump()
                    return
                }, origin: tableView)

                styleActionSheetStringPicker(picker!)
                picker!.show()
                break
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                break
            case 1:
                Generator.bump()

                if Locations.shared.items.count > 0 {
                    var strings = [String]()

                    for location in Locations.shared.items {
                        strings.append(location.name!)
                    }

                    var index = 0
                    if let name = location?.name {
                        for string in strings {
                            if string == name {
                                break
                            } else if index < strings.count {
                                index += 1
                            } else {
                                index = 0
                            }
                        }
                    }
                    

                    let picker = ActionSheetStringPicker(title: NSLocalizedString("NewEntryViewController_PickLocation", comment: ""), rows: strings, initialSelection: index, doneBlock: {
                        _, index, _ in
                        Generator.bump()
                        
                        guard index < strings.count else {
                            return
                        }

                        self.location = Locations.shared.get(name: strings[index])
                        self.tableView.reloadData()
                        
                        return
                    }, cancel: { _ in
                        Generator.bump()
                        return
                    }, origin: tableView)

                    styleActionSheetStringPicker(picker!)
                    picker!.show()
                }
                break
            default:
                break
            }
        default:
            switch indexPath.row {
            case 0:
                break
            case 1:
                Generator.bump()
                var strings = [String]()

                for activity in Activities.shared.items {
                    strings.append(activity.name!)
                }

                var index = 0
                if let name = activity?.name {
                    for string in strings {
                        if string == name {
                            break
                        } else if index < strings.count {
                            index += 1
                        } else {
                            index = 0
                        }
                    }
                }

                let picker = ActionSheetStringPicker(title: NSLocalizedString("NewEntryViewController_PickActivity", comment: ""), rows: strings, initialSelection: index, doneBlock: {
                    _, index, _ in
                    Generator.bump()
                    
                    guard index < strings.count else {
                        return
                    }

                    let name = strings[index]
                    if name == "Break" || name == "Traveling" {
                        self.location = nil
                    }
                    
                    if name == "Break" {
                        self.selectedPaid = "Unpaid"
                    }
                    
                    self.activity = Activities.shared.get(name: name)
                    self.tableView.reloadData()
                    
                    return
                }, cancel: { _ in
                    Generator.bump()
                    return
                }, origin: tableView)

                styleActionSheetStringPicker(picker!)
                picker!.show()
                break
            default:
                break
            }
        }
    }
    
    // MARK: - Other Functions

    @objc func create() {
        Generator.bump()

        guard let activity = self.activity else {
            PKHUD.message(text: "You must add an activity")
            PKHUD.hide(delay: 1.0)
            return
        }
        
        if activity.breaking == false && activity.traveling == false {
            if location == nil {
                PKHUD.message(text: "You must add a location for this activity")
                PKHUD.hide(delay: 1.0)
                return
            }
        }

        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()

        let entry: Entry = Entry()
        entry.sheet = sheet
        entry.user = Users.shared[entry.sheet?.user] ?? DeviceUser.shared.user
        entry.activity = activity
        entry.location = location
        entry.start = date ?? Date()
        entry.paidTime = selectedPaid == "Paid" ? true : false
        entry.autoGenerated = false

        entry.create { success in
            guard success == true else {
                PKHUD.failure()
                return
            }

            PKHUD.success()
            self.goBack()
        }
    }

    @objc func updateTime(_ date: Date) {
        Generator.bump()

        self.date = date
        self.tableView.reloadData()
    }

    @objc func goCreateLocation() {
        Generator.bump()

        delay(0.2) {
            let destination = UIStoryboard.Location(identifier: "CreateLocation") as! CreateLocation

            destination.location = Location()
            self.location = destination.location

            self.navigationController?.pushViewController(destination, animated: true)
        }
    }

    @objc func goCreateActivity() {
        Generator.bump()

        delay(0.2) {
            let destination = UIStoryboard.Activity(identifier: "ViewActivity") as! ViewActivity

            destination.mode = ViewingMode.Creating
            destination.activity = Activity()
            self.activity = destination.activity

            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        navBar?.rightButton.tintColor = UIColor.red
    }
}
