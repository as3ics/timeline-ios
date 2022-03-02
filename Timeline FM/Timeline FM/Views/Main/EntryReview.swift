//
//  EntryReview.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/25/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Material
import PKHUD
import UIKit
import CoreLocation

// MARK: - EntryReview

class EntryReview: ViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }
    
    var entry: Entry?
    var sheet: Sheet?
    var index: Int?
    
    var photoViewerCoordinator: PhotoViewerCoordinator?
    var nytPhotos = [NYTPhotoBox]()
    
    var timer_1000ms: Timer?

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        StandardMapCell.register(tableView)
        StandardTextFieldCell.register(tableView)
        StandardHeaderCell.register(tableView)
        StandardButtonCell.register(tableView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        updates = false
        NotificationCenter.default.removeObserver(self)
    }
    
    var updates: Bool = false {
        willSet {
            guard newValue != updates else {
                return
            }
            
            switch newValue {
            case true:
                timer_1000ms?.invalidate()
                timer_1000ms = nil
                timer_1000ms = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
                    
                    print("Timer - Entry Review")
                    
                    self.update()
                })
                
                timer_1000ms?.fire()
                break
            case false:
                timer_1000ms?.invalidate()
                timer_1000ms = nil
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if index == 0 && sheet == DeviceUser.shared.sheet {
            self.updates = true
            
            if entry?.activity?.traveling == true {
                NotificationManager.shared.new_breadcrumb.observe(self, selector: #selector(crumbsUpdated))
            }
        }
        
        tableView.reloadData()
    }
    
    override func setupNavBar() {
        
        if System.shared.adminAccess {
            navBar?.rightImage = AssetManager.shared.edit
            navBar?.rightEnclosure = { self.edit() }
        } else if let userId = self.sheet?.user ?? self.entry?.user?.id, userId == Auth.shared.id {
            navBar?.rightImage = AssetManager.shared.edit
            navBar?.rightEnclosure = { self.edit() }
        }
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
    }
    
    // MARK: - UITableView Delegate and DataSource
    
    func numberOfSections(in _: UITableView) -> Int {
        return 3
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 5
        case 2:
            return 5
        default:
            return 0
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 200
        default:
            switch indexPath.row {
            case 0:
                return 55
            default:
                return 50
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = StandardMapCell.loadNib(tableView)

                cell.populateMap(entry: entry, sheet: sheet)

                cell.selectionStyle = .none

                return cell
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Summary"

                cell.footer.text = ""

                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "User"
                
                if let user = Users.shared[self.sheet?.user] {
                    cell.contents.text = user.fullName
                } else {
                    cell.contents.text = DeviceUser.shared.user?.fullName
                }
                
                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0
                cell.selectionStyle = .none
                
                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Timespan"

                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"

                // Set timespan string
                var timespanText: String?
                if index == 0, sheet?.submissionDate == nil, let startString = self.entry?.startString {
                    timespanText = String(format: "%@ - Present", arguments: [startString])
                } else if index == 0, sheet?.submissionDate != nil, let startString = self.entry?.startString, let endDate = self.sheet?.submissionDate {
                    let endString = formatter.string(from: endDate)
                    timespanText = String(format: "%@ - %@", arguments: [startString, endString])
                } else if let index = self.index, let previousEntry = self.sheet?.entries[index - 1], let startString = self.entry?.startString, let endString = previousEntry.startString {
                    timespanText = String(format: "%@ - %@", arguments: [startString, endString])
                }

                cell.contents.text = timespanText

                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0
                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 3 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Duration"

                if let index = self.index, let seconds = self.sheet?.duration(index: index) {
                    cell.contents.text = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                } else {
                    cell.contents.text = nil
                }

                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0
                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 4 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Paid / Unpaid"

                if entry?.paidTime == true {
                    cell.contents.text = "Paid"
                } else if entry?.paidTime == false {
                    cell.contents.text = "Unpaid"
                } else {
                    cell.contents.text = nil
                }

                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0
                cell.selectionStyle = .none

                return cell
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Information"
                cell.footer.text = ""

                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Activity"
                cell.contents.text = entry?.activity?.name

                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0
                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)
                cell.carrot.alpha = 0.0
                cell.contents.isUserInteractionEnabled = false
                
                if entry!.activity?.traveling == false , entry!.activity?.breaking == false {
                    cell.label.text = "Location"

                    if let location = self.entry?.location {
                        cell.contents.text = location.name
                        cell.carrot.alpha = 1.0
                        
                        if self.mode != .Editing {
                            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewLocation)))
                            cell.isUserInteractionEnabled = true
                        }
                    } else {
                        cell.contents.text = "Unknown"
                    }
                } else if entry?.activity?.traveling == true {
                    cell.label.text = "Distance"
                    cell.contents.text = String(format: "%0.1f miles", arguments: [self.entry!.meters * CONVERSION_METERS_TO_MILES_MULTIPLIER])
                } else {
                    cell.label.text = "Location"
                    cell.contents.text = "No Location"
                }

                cell.contents.isUserInteractionEnabled = false
                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 3 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                let count = entry!.breadcrumbs.count

                cell.label.text = "Breadcrumbs"
                cell.contents.text = String(format: "%i", arguments: [count])
                
                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0
                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 4 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Photos"
                cell.contents.text = String(format: "%i", arguments: [self.entry!.photos.items.count])
                
                cell.contents.isUserInteractionEnabled = false

                if entry!.photos.items.count > 0 {
                    cell.carrot.alpha = 1.0

                    let tap = UITapGestureRecognizer(target: self, action: #selector(goToPhotos))
                    cell.addGestureRecognizer(tap)
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.carrot.alpha = 0.0
                }

                cell.selectionStyle = .none
                return cell
            }
        }

        return UITableViewCell()
    }
    
    // MARK: - Other Functions
    
    @objc func viewLocation() {
        Generator.bump()
        
        if let location = self.entry?.location {
            location.view()
        }
    }
    
    @objc func update() {
        DispatchQueue.main.async {
            
            guard let sheet = self.sheet, let entry = self.entry, let index = self.index else {
                return
            }
            
            sheet.updateTimes()
            
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 3, section: 1)) as? StandardTextFieldCell, let seconds = sheet.duration(index: index) {
                let durationString = String(format: "%.0fh %0.fm %.0fs", arguments:[clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                cell.contents.text = durationString
            }
            
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 3, section: 2)) as? StandardTextFieldCell {
                let count = entry.breadcrumbs.count
                cell.contents.text = String(format: "%i", arguments: [count])
            }
            
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 2)) as? StandardTextFieldCell, cell.label.text == "Distance" {
                
                cell.contents.text = String(format: "%0.1f miles", arguments: [self.entry!.meters * CONVERSION_METERS_TO_MILES_MULTIPLIER])
            }
        }
    }
    
    @objc func crumbsUpdated(_: NSNotification) {
        tableView.reloadData()
    }

    @objc func edit() {

        let destination = UIStoryboard.Main(identifier: "EntryEdit") as! EntryEdit

        destination.sheet = sheet
        destination.index = index

        Presenter.push(destination, animated: true, completion: nil)
    }
    
    @objc func goToPhotos() {
        
        Generator.confirm()
        
        var title: String!
        
        let activity = entry!.activity!.name!
        if let location = entry?.location?.name {
            title = String(format: "%@ - %@", activity, location)
        } else {
            title = activity
        }
        
        entry!.photos.view(title: title)
    }

    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        
        let isBreak: Bool = entry?.activity?.breaking ?? false
        let isTraveling: Bool = entry?.activity?.traveling ?? false
        
        if isBreak || isTraveling {
            if isBreak {
                navBar?.background = Color.orange.darken2
                navBar?.title = "Break"
                
            } else if isTraveling {
                navBar?.background = Color.blue.darken2
                navBar?.title = "Traveling"
            }
            
            navBar?.leftButton.tintColor = UIColor.white
            navBar?.rightButton.tintColor = UIColor.white
            navBar?.titleLabel.textColor = UIColor.white
        } else {
            
            if let start = sheet?.date {
                
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE LLL d"
                
                navBar?.title = formatter.string(from: start)
            } else {
                
                navBar?.title = "Entry"
            }

        }
    }
}
