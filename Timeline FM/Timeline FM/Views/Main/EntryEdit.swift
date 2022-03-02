//
//  TimesheetEditEntryViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/2/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import Material
import PKHUD
import UIKit
import CoreLocation

// MARK: - EntryEdit

class EntryEdit: ViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }

    var sheet: Sheet?
    var index: Int?
    
    var entry: Entry? {
        guard let index = index, let sheet = sheet, sheet.entries.items.count > index else {
            return nil
        }
        
        return sheet.entries.items[index]
    }

    var formatter = DateFormatter()

    var originalStartTime: Date?
    var originalActivityId: String?
    var originalLocationId: String?
    var originalPaid: Bool?
    var originalNotes: String?

    var selectedStartTime: Date?
    var selectedActivityId: String?
    var selectedLocationId: String?
    var selectedPaid: Bool?
    var selectedNotes: String?

    var hold: Bool = false
    
    var timer_1000ms: Timer?
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard sheet != nil, index != nil else {
            goBack()
            return
        }

        tableView.separatorStyle = .none
        
        formatter.dateFormat = "EEE, MMM d, h:mm:ss a"

        if index == 0 && sheet?.submitted != true {
            
            timer_1000ms?.invalidate()
            timer_1000ms = nil
            timer_1000ms = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
                
                print("Timer - Entry Controller")
                
                self.update()
            })
            
            timer_1000ms?.fire()
        }

        backupOriginalData()

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(cancel), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        hideKeyboardWhenTappedAround()

        StandardTextFieldCell.register(tableView)
        StandardTextViewCell.register(tableView)
        StandardHeaderCell.register(tableView)
        StandardButtonCell.register(tableView)

        NSNotification.Name.UIKeyboardWillShow.observe(self, selector: #selector(keyboardWillShow))
        NSNotification.Name.UIKeyboardWillHide.observe(self, selector: #selector(keyboardWillHide))
    }
    
    override func setupNavBar() {
        
        navBar?.rightImage = AssetManager.shared.save
        navBar?.rightEnclosure = { self.save() }
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.cancel() }
    }
    
    // MARK: - UITableView Delegate and DataSource

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else if section == 1 {
            return 3
        } else if section == 2 {
            return 2
        } else if section == 3 {
            return 2
        } else if section == 4 {
            return 2
        } else {
            return 0
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        return 4 // 5
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // height of the buttons at the bottome of the table
        if indexPath.section == 4 && indexPath.row == 1 {
            return 60
        } else if indexPath.section == 3 && indexPath.row == 1 {
            return 130
        } else if indexPath.row > 0 {
            return 50
        } else {
            return 70
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Time & Date"

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Start"

                if selectedStartTime == nil {
                    let entry = sheet!.entries[self.index!]
                    cell.contents.text = formatter.string(from: (entry?.start!)!)
                } else {
                    cell.contents.text = formatter.string(from: selectedStartTime!)
                }
                cell.contents.isUserInteractionEnabled = false

                let tap = UITapGestureRecognizer(target: self, action: #selector(updateStartTime(_:)))
                cell.isUserInteractionEnabled = true
                cell.addGestureRecognizer(tap)

                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "End"

                if let _ = self.selectedStartTime {
                    cell.contents.text = "To be determined"
                } else if index! != 0 {
                    let previousEntry = sheet!.entries[self.index! - 1]
                    cell.contents.text = formatter.string(from: (previousEntry?.start!)!)
                } else {
                    if sheet!.submitted == false {
                        cell.contents.text = formatter.string(from: Date())
                    } else {
                        if sheet!.submissionDate != nil {
                            cell.contents.text = formatter.string(from: sheet!.submissionDate!)
                        } else {
                            cell.contents.text = ""
                        }
                    }
                }

                cell.contents.isUserInteractionEnabled = false

                cell.selectionStyle = .none

                cell.carrot.alpha = 0.0
                cell.contents.textColor = Theme.shared.active.primaryFontColor

                return cell
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Activity"

                if let _ = self.selectedStartTime {
                    cell.footer.text = ""
                } else if let seconds = self.sheet!.duration(index: self.index!) {
                    var durationString: String?
                    if clockHours(seconds) == 1 {
                        durationString = String(format: "%.0f hour %0.f minutes %.0f seconds", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                    } else {
                        durationString = String(format: "%.0f hours %0.f minutes %.0f seconds", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                    }

                    cell.footer.text = durationString
                } else {
                    cell.footer.text = ""
                }

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Activity"

                if selectedActivityId == nil {
                    let entry = sheet!.entries[self.index!]
                    cell.contents.text = entry?.activity!.name!

                    if entry?.activity?.traveling == true || entry?.activity?.breaking == true {
                        cell.carrot.alpha = 0
                    } else {
                        let tap = UITapGestureRecognizer(target: self, action: #selector(updateActivity(_:)))
                        cell.isUserInteractionEnabled = true
                        cell.addGestureRecognizer(tap)
                    }

                } else {
                    let tap = UITapGestureRecognizer(target: self, action: #selector(updateActivity(_:)))
                    cell.isUserInteractionEnabled = true
                    cell.addGestureRecognizer(tap)

                    if let activity = Activities.shared[self.selectedActivityId] {
                        cell.contents.text = activity.name
                    }
                }

                cell.contents.isUserInteractionEnabled = false
                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                let entry = sheet!.entries[self.index!]
                cell.label.text = "Paid / Unpaid"

                if selectedPaid == nil {
                    if entry?.paidTime == true {
                        cell.contents.text = "Paid"
                    } else {
                        cell.contents.text = "Unpaid"
                    }
                } else {
                    if selectedPaid == true {
                        cell.contents.text = "Paid"
                    } else {
                        cell.contents.text = "Unpaid"
                    }
                }

                let tap = UITapGestureRecognizer(target: self, action: #selector(updatePaid(_:)))
                cell.isUserInteractionEnabled = true
                cell.addGestureRecognizer(tap)

                cell.contents.isUserInteractionEnabled = false
                cell.selectionStyle = .none
                return cell
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Location"
                cell.footer.text = ""

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Location"

                if selectedLocationId == nil {
                    let entry = sheet!.entries[self.index!]

                    if entry?.activity?.traveling == false && entry?.activity?.breaking == false {
                        cell.contents.text = entry?.location?.name ?? "Unknown"
                    } else {
                        cell.contents.text = "No Location"

                        cell.carrot.alpha = 0.0
                        cell.contents.textColor = UIColor.black
                    }
                } else {
                    if let location = Locations.shared[self.selectedLocationId] {
                        cell.contents.text = location.name
                    }
                }

                if entry?.activity?.traveling == false && entry?.activity?.breaking == false {
                    let tap = UITapGestureRecognizer(target: self, action: #selector(updateLocation(_:)))
                    cell.isUserInteractionEnabled = true
                    cell.addGestureRecognizer(tap)
                }

                cell.contents.isUserInteractionEnabled = false
                cell.selectionStyle = .none
                return cell
            }
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = "Notes"
                cell.footer.text = ""

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextViewCell.loadNib(tableView)

                let entry = sheet!.entries[self.index!]
                if let notes = entry?.notes {
                    cell.contents.text = notes
                } else {
                    cell.contents.text = ""
                }

                cell.contents.delegate = self

                cell.selectionStyle = .none
                return cell
            }
        } else if indexPath.section == 4 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.title.text = ""
                cell.footer.text = ""

                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 1 {
                let cell = StandardButtonCell.loadNib(tableView)

                cell.label.text = "Delete"
                cell.backgroundColor = Color.red.base
                cell.label.textColor = UIColor.white

                let tap = UITapGestureRecognizer(target: self, action: #selector(deleteButtonPressed))
                cell.isUserInteractionEnabled = true
                cell.addGestureRecognizer(tap)

                cell.selectionStyle = .none
                return cell
            }
        }

        return UITableViewCell()
    }
    
    // MARK: - UIText Delegate

    func textViewDidChange(_ textView: UITextView) {
        selectedNotes = textView.text
    }
    
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    // MARK: - Other Functions

    @objc func updateStartTime(_: Any) {
        Generator.bump()

        let maximum = Date()
        let minimum = sheet!.date

        var selected: Date?
        if selectedStartTime != nil {
            selected = selectedStartTime!
        } else {
            selected = originalStartTime!
        }

        let picker = ActionSheetDatePicker(title: NSLocalizedString("ReviewTimeEntryViewController_ActionPicker_ChangeStartTime", comment: ""), datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: selected!, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(EntryEdit.setStartTime(_:)), cancelAction: nil, origin: tableView)

        styleActionSheetDatePicker(picker!)

        picker!.show()
    }

    @objc func updateActivity(_: Any) {
        Generator.bump()

        let indexPath = IndexPath(row: 1, section: 1)
        let cell = tableView.cellForRow(at: indexPath) as! StandardTextFieldCell

        if cell.carrot.alpha != 0 {
            var strings = [String]()
            
            for activity in Activities.shared.items {
                strings.append(activity.name!)
            }
            
            var index = 0
            if let name = cell.contents.text {
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

            let picker = ActionSheetStringPicker(title: NSLocalizedString("ReviewTimeEntryViewController_ActionPicker_ChangeActivity", comment: ""), rows: strings, initialSelection: index, doneBlock: {
                _, _, value in

                Generator.bump()

                self.selectedActivityId = Activities.shared.get(name: value as? String)?.id
                self.tableView.reloadData()

                return
            }, cancel: { _ in return }, origin: tableView)

            styleActionSheetStringPicker(picker!)

            picker!.show()
        }
    }

    @objc func updateLocation(_: Any) {
        let entry = sheet!.entries[self.index!]

        Generator.bump()

        if entry?.activity?.traveling == false && entry?.activity?.breaking == false {
            Locations.shared.sort(location: LocationManager.shared.currentLocation)
            
            var strings = [String]()
            
            for location in Locations.shared.items {
                strings.append(location.name!)
            }
            
            var index = 0
            if let name = Locations.shared[self.selectedLocationId]?.name {
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

            let picker = ActionSheetStringPicker(title: "Edit Location:", rows: strings, initialSelection: index, doneBlock: {
                _, index, _ in

                Generator.bump()

                self.selectedLocationId = Locations.shared.items[index].id!

                self.tableView.reloadData()

                return
            }, cancel: { _ in
                Generator.bump()
                return
            }, origin: tableView)

            styleActionSheetStringPicker(picker!)

            picker!.show()
        }
    }

    @objc func updatePaid(_: Any) {
        Generator.bump()

        var names = [String]()

        names.append("Paid")
        names.append("Unpaid")

        var initialIndex: Int?

        if selectedPaid != nil {
            if selectedPaid == true {
                initialIndex = 0
            } else {
                initialIndex = 1
            }
        } else {
            if originalPaid == true {
                initialIndex = 0
            } else {
                initialIndex = 1
            }
        }

        let picker = ActionSheetStringPicker(title: "Select Paid/Unpaid:", rows: names, initialSelection: initialIndex!, doneBlock: {
            _, index, _ in

            Generator.bump()

            if index == 0 {
                self.selectedPaid = true
            } else if index == 1 {
                self.selectedPaid = false
            }

            self.tableView.reloadData()

            return
        }, cancel: { _ in
            Generator.bump()
            return
        }, origin: tableView)

        styleActionSheetStringPicker(picker!)

        picker!.show()
    }
    
    @objc func setStartTime(_ date: Date) {
        Generator.bump()
        
        selectedStartTime = date
        tableView.reloadData()
    }
    
    
    
    func backupOriginalData() {
        if let index = self.index, let entry = self.sheet?.entries[index] {
            originalStartTime = entry.start
            originalActivityId = entry.activity?.id
            originalLocationId = entry.location?.id
            originalPaid = entry.paidTime
            originalNotes = entry.notes
        }
    }
    
    func restoreBackupData() {
        if let index = self.index, let entry = self.sheet?.entries[index] {
            if let start = self.originalStartTime { entry.start = start }
            if let activityId = self.originalActivityId, let activity = Activities.shared[activityId] { entry.activity = activity }
            if let paidTime = self.originalPaid { entry.paidTime = paidTime }
            if let locationId = self.originalLocationId, let location = Locations.shared[locationId] { entry.location = location }
            if let notes = self.originalNotes { entry.notes = notes }
        }
    }
    
    @objc func update() {
        if hold == false {
            DispatchQueue.main.async {
                
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? StandardHeaderCell {
                    if let _ = self.selectedStartTime {
                        cell.footer.text = ""
                    } else if let seconds = self.sheet!.duration(index: self.index!) {
                        var durationString: String?
                        if clockHours(seconds) == 1 {
                            durationString = String(format: "%.0f hour %0.f minutes %.0f seconds", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                        } else {
                            durationString = String(format: "%.0f hours %0.f minutes %.0f seconds", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                        }
                        
                        cell.footer.text = durationString
                    } else {
                        cell.footer.text = ""
                    }
                }
                
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? StandardTextFieldCell {
                    
                    cell.contents.text = self.formatter.string(from: Date())
                }
            }
        }
    }
    
    
    @objc func cancel() {
        
        restoreBackupData()
        
        goBack()
    }
    
    override func goBack() {
        timer_1000ms?.invalidate()
        timer_1000ms = nil
        
        super.goBack()
    }
    
    @objc func save() {
        if let sheet = self.sheet, let index = self.index {
            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()
            
            if let entry = sheet.entries[index] {
                if let startTime = self.selectedStartTime {
                    entry.start = startTime
                }
                
                if let activityId = self.selectedActivityId {
                    if let activity = Activities.shared[activityId] {
                        entry.activity = activity
                    }
                }
                
                if let locationId = self.selectedLocationId {
                    if let location = Locations.shared[locationId] {
                        entry.location = location
                    }
                }
                
                if let paid = self.selectedPaid {
                    entry.paidTime = paid
                }
                
                if let notes = self.selectedNotes {
                    entry.notes = notes
                }
                
                Async.waterfall(nil, [entry.update, sheet.entries.retrieve]) { (error, value) in
                    guard error == nil else  {
                        Generator.failure()
                        PKHUD.failure()
                        return
                    }
                    
                    Generator.confirm()
                    PKHUD.success()
                    self.goBack()
                }
            } else {
                Generator.failure()
                PKHUD.failure()
            }
        } else {
            Generator.failure()
        }
    }
    
    @objc func deleteButtonPressed() {
        Generator.bump()
        
        let alert = UIAlertController(title: "Timeline", message: "Are you sure you want to delete this entry? This cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) -> Void in
            Generator.bump()
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) -> Void in
            Generator.bump()
            
            if let sheet = self.sheet, let index = self.index {
                PKHUD.loading()
                
                if let entry = sheet.entries[index] {
                    entry.delete({ success in
                        if success == true {
                            PKHUD.success()
                            
                            self.goBack()
                        } else {
                            PKHUD.failure()
                        }
                    })
                }
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }

    
    

    @objc func keyboardWillShow(notification _: NSNotification) {
        hold = true
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        hold = false
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        navBar?.rightButton.tintColor = UIColor.red
        
        let isBreak: Bool = entry?.activity?.breaking ?? false
        let isTraveling: Bool = entry?.activity?.traveling ?? false
        
        if isBreak || isTraveling {
            if isBreak {
                navBar?.background = Color.orange.darken2
                navBar?.title = "Edit Break"
                
            } else if isTraveling {
                navBar?.background = Color.blue.darken2
                navBar?.title = "Edit Traveling"
            }
            
            navBar?.leftButton.tintColor = UIColor.white
            navBar?.rightButton.tintColor = UIColor.white
            navBar?.titleLabel.textColor = UIColor.white
        } else {
            
            navBar?.title = "Edit Entry"
        }
    }
}

