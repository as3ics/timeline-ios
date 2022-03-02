//
//  SheetReview.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 11/23/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//


import Material
import PKHUD
import UIKit
import CoreLocation
import ActionSheetPicker_3_0

// MARK: - EntryReview

class SheetReview: ViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }
    
    var sheet: Sheet!
    
    var originalStartDate: Date?
    var startDate: Date?
    var originalEndDate: Date?
    var endDate: Date?
    
    var photos: Photos = Photos()
    
    var timer_1000ms: Timer?
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard sheet != nil else {
            goBack()
            return
        }
        
        originalStartDate = sheet.date
        startDate = originalStartDate
        
        originalEndDate = sheet.submissionDate
        endDate = originalEndDate
        
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
        
        var array: [Photo] = [Photo]()
        for entry in sheet.entries.items {
            array.append(contentsOf: entry.photos.items)
        }
        
        photos.items = array
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        updates = false
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard sheet != nil else {
            self.updates = false
            self.goBack()
            return
        }
        
        if sheet.submitted == false {
            self.updates = true
        }
        
        tableView.reloadData()
    }
    
    override func setupNavBar() {
        
        if let start = sheet.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE LLL d"
            
            navBar?.title = String(format: "Timesheet - %@", formatter.string(from: start))
        } else {
            
            navBar?.title = "Timesheet"
        }
        
        navBar?.rightImage = AssetManager.shared.save
        navBar?.rightEnclosure = {
            self.save()
        }
        navBar?.rightButton.alpha = 0.0
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
    }
    
    override func goBack() {
        if let date = originalStartDate {
            sheet.date = date
        }
        
        if let date = originalEndDate {
            sheet.submissionDate = date
        }
        
        updates = false
        super.goBack()
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
                    
                    print("Timer - Sheet Review")
                    
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
            return 2
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
        
        switch indexPath.section {
            
        case 0:
            let cell = StandardMapCell.loadNib(tableView)
            cell.populateMap(sheet: sheet)
            cell.selectionStyle = .none
            return cell
        case 1:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                cell.title.text = "Summary"
                cell.footer.text = ""
                cell.selectionStyle = .none
                return cell
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)
                cell.label.text = "User"
                cell.contents.text = self.sheet.user?.user()?.fullName ?? "John Doe"
                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0
                cell.selectionStyle = .none
                return cell
            case 2:
                let cell = StandardTextFieldCell.loadNib(tableView)
                cell.label.text = "Start"
                if let date = startDate {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "LLL d, h:mm:ss a"
                    cell.contents.text =  String(format: "%@", formatter.string(from: date))
                    cell.carrot.alpha = 1.0
                    cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(udpateStart)))
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.contents.text = ""
                    cell.carrot.alpha = 0.0
                    cell.isUserInteractionEnabled = false
                }
                cell.contents.isUserInteractionEnabled = false
                cell.selectionStyle = .none
                return cell
            case 3:
                let cell = StandardTextFieldCell.loadNib(tableView)
                cell.label.text = "End Date"
                if let date = endDate {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "LLL d, h:mm:ss a"
                    cell.contents.text =  String(format: "%@", formatter.string(from: date))
                    cell.carrot.alpha = 1.0
                    cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(udpateEnd)))
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.contents.text = ""
                    cell.carrot.alpha = 0.0
                    cell.isUserInteractionEnabled = false
                }
                cell.contents.isUserInteractionEnabled = false
                cell.selectionStyle = .none
                return cell
            case 4:
                let cell = StandardTextFieldCell.loadNib(tableView)
                cell.label.text = "Submmitted"
                cell.contents.text =  sheet.submitted ? "True" : "False"
                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0
                cell.selectionStyle = .none
                return cell
            default:
                return UITableViewCell.defaultCell()
            }
            
        case 2:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                cell.title.text = "Info"
                cell.footer.text = ""
                cell.selectionStyle = .none
                return cell
            case 1:
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Photos"
                cell.contents.text = String(format: "%i", photos.items.count)
                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 1.0
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewPhotos)))
                cell.isUserInteractionEnabled = true
                cell.selectionStyle = .none
                return cell
            default:
                return UITableViewCell.defaultCell()
            }
        default:
            return UITableViewCell.defaultCell()
        }
        
        
        /*
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.title.text = "Time Breakdown"
                cell.footer.text = ""
                
                cell.selectionStyle = .none
                
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Paid Time"
                
                let seconds = sheet.paidSeconds
                cell.contents.text = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                
                cell.contents.isUserInteractionEnabled = false
                cell.carrot.alpha = 0.0
                cell.selectionStyle = .none
                
                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Break Time"
                
                let seconds = sheet.unpaidSeconds
                cell.contents.text = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                
                cell.carrot.alpha = 0.0
                cell.contents.isUserInteractionEnabled = false
                cell.selectionStyle = .none
                
                return cell
            } else if indexPath.row == 3 {
                let cell = StandardTextFieldCell.loadNib(tableView)
                
                cell.label.text = "Traveling Time"
                
                let seconds = sheet.travelingSeconds
                cell.contents.text = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                
                cell.carrot.alpha = 0.0
                cell.contents.isUserInteractionEnabled = false
                cell.selectionStyle = .none
                
                return cell
            }
        }
        */
    }
    
    // MARK: - Other Functions
    
    @objc func update() {
        DispatchQueue.main.async {
            print("Timer - Sheet Review")
        }
    }
    
    @objc func udpateStart(_ sender: UIGestureRecognizer) {
        Generator.bump()
        
        guard let view = sender.view, let start = startDate else {
            return
        }
        
        let minimum = Date(timeIntervalSince1970: 0)
        let maximum = Date()
        
        let picker = ActionSheetDatePicker(title: "Start Time", datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: start, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(self.commitStart), cancelAction: nil, origin: view)
        
        picker?.maximumDate = maximum
        picker?.minimumDate = minimum
        
        UIViewController().styleActionSheetDatePicker(picker)
        
        picker?.show()
    }
    
    @objc func commitStart(_ date: Date) {
        Generator.bump()
        
        startDate = date
        tableView.reloadData()
        
        UIView.animate(withDuration: 0.3) {
            self.navBar?.rightButton.alpha = 1.0
        }
    }
    
    
    @objc func udpateEnd(_ sender: UIGestureRecognizer) {
        Generator.bump()
        
        guard let view = sender.view, let end = endDate else {
            return
        }
        
        let minimum = Date(timeIntervalSince1970: 0)
        let maximum = Date()
        
        let picker = ActionSheetDatePicker(title: "End Time", datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: end, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(self.commitEnd), cancelAction: nil, origin: view)
        
        picker?.maximumDate = maximum
        picker?.minimumDate = minimum
        
        UIViewController().styleActionSheetDatePicker(picker)
        
        picker?.show()
    }
    
    @objc func commitEnd(_ date: Date) {
        Generator.bump()
        
        endDate = date
        tableView.reloadData()
        
        UIView.animate(withDuration: 0.3) {
            self.navBar?.rightButton.alpha = 1.0
        }
    }
    
    @objc func viewPhotos(_ sender: UIGestureRecognizer) {
        Generator.bump()
        
        photos.view(title: navBar?.title)
    }
    
    @objc func save() {
        
        sheet.date = startDate
        sheet.submissionDate = endDate
        
        PKHUD.loading()
        Async.waterfall(nil, [sheet.update]) { (error, response) in
            guard error == nil else {
                PKHUD.failure()
                return
            }
            
            PKHUD.success()
            
            self.originalStartDate = nil
            self.originalEndDate = nil
            self.goBack()
        }
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        
        self.navBar?.rightButton.tintColor = Color.red.base
    }
}
