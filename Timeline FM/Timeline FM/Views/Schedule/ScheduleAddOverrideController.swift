//
//  ScheduleAddOverrideController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/26/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import PKHUD
import UIKit
import CoreLocation

// MARK: - ScheduleAddOverrideController

class ScheduleAddOverrideController: ViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet var tableView: UITableView!

    let localDateFormatter = DateFormatter()
    let pickerDateFormatter = DateFormatter()
    let timeFormatter = DateFormatter()

    var doNotSchedule: Bool! = false
    var multiDay: Bool! = false

    var titleInput: String?
    var notesInput: String?
    var startDate: Date?
    var endDate: Date?
    var startTime: Date?
    var endTime: Date?

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = true
        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        localDateFormatter.dateFormat = "LLL d, yyyy"
        pickerDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        timeFormatter.dateFormat = "h:mm a"

        hideKeyboardWhenTappedAround()

        let dateString = localDateFormatter.string(from: Date())

        startDate = localDateFormatter.date(from: dateString)

        var comps = DateComponents()
        comps.hour = 8

        startTime = Calendar.current.date(byAdding: comps, to: startDate!)

        comps.hour = 17
        endTime = Calendar.current.date(byAdding: comps, to: startDate!)

        StandardHeaderCell.register(tableView)
        OverrideDateCell.register(tableView)
        OverrideSwitchCell.register(tableView)
        StandardTextFieldCell.register(tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func setupNavBar() {
        navBar?.title = "Add Override"
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
        
        disableAddButton()
    }
    
    // MARK: - UITableView Delegate and DataSource

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else if section == 1 {
            if doNotSchedule == false {
                return 5

            } else {
                if multiDay == true {
                    return 5
                } else {
                    return 4
                }
            }
        }

        return 0
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 60
        } else if indexPath.row < 5 {
            return 50
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Info"

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Title"
                cell.contents.delegate = self
                cell.contents.placeholder = "Title (Required)"
                cell.contents.text = titleInput

                cell.contents.addTarget(self, action: #selector(updateTitleInput(_:)), for: UIControlEvents.editingChanged)

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Notes"
                cell.contents.delegate = self
                cell.contents.placeholder = "Notes (Optional)"
                cell.contents.text = notesInput

                cell.contents.addTarget(self, action: #selector(updateNotesInput(_:)), for: UIControlEvents.editingChanged)

                cell.selectionStyle = .none
                return cell
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Date & Time"

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = OverrideSwitchCell.loadNib(tableView)

                cell.titleLabel.text = "Time Off"

                if doNotSchedule == true {
                    cell.selector.isOn = true

                } else {
                    cell.selector.isOn = false
                }

                cell.selector.addTarget(self, action: #selector(updateOverrideTypeSwitch(_:)), for: UIControlEvents.valueChanged)

                cell.selectionStyle = .none
                return cell
            } else {
                if doNotSchedule == false {
                    if indexPath.row == 2 {
                        let cell = OverrideDateCell.loadNib(tableView)

                        cell.leftLabel.text = "Date"
                        cell.rightLabel.text = localDateFormatter.string(from: startDate!)

                        cell.tag = indexPath.row
                        let tap = UITapGestureRecognizer(target: self, action: #selector(selectDate(_:)))
                        cell.addGestureRecognizer(tap)
                        cell.isUserInteractionEnabled = true

                        cell.selectionStyle = .none
                        return cell
                    } else if indexPath.row == 3 {
                        let cell = OverrideDateCell.loadNib(tableView)

                        cell.leftLabel.text = "Start"
                        cell.rightLabel.text = timeFormatter.string(from: startTime!)

                        let tap = UITapGestureRecognizer(target: self, action: #selector(selectStartTime(_:)))
                        cell.addGestureRecognizer(tap)
                        cell.isUserInteractionEnabled = true

                        cell.selectionStyle = .none
                        return cell
                    } else if indexPath.row == 4 {
                        let cell = OverrideDateCell.loadNib(tableView)

                        cell.leftLabel.text = "End"
                        cell.rightLabel.text = timeFormatter.string(from: endTime!)

                        let tap = UITapGestureRecognizer(target: self, action: #selector(selectEndTime(_:)))
                        cell.addGestureRecognizer(tap)
                        cell.isUserInteractionEnabled = true

                        cell.selectionStyle = .none
                        return cell
                    }
                } else {
                    if indexPath.row == 2 {
                        let cell = OverrideSwitchCell.loadNib(tableView)

                        cell.titleLabel.text = "Multi-Day"
                        if multiDay == true {
                            cell.selector.isOn = true
                        } else {
                            cell.selector.isOn = false
                        }

                        cell.selector.addTarget(self, action: #selector(updateMultiDaySwitch(_:)), for: UIControlEvents.valueChanged)

                        cell.selectionStyle = .none
                        return cell
                    }

                    if multiDay == true {
                        if indexPath.row == 3 {
                            let cell = OverrideDateCell.loadNib(tableView)

                            cell.leftLabel.text = "Start"
                            cell.rightLabel.text = localDateFormatter.string(from: startDate!)

                            cell.tag = indexPath.row
                            let tap = UITapGestureRecognizer(target: self, action: #selector(selectStartDate(_:)))
                            cell.addGestureRecognizer(tap)
                            cell.isUserInteractionEnabled = true

                            cell.selectionStyle = .none
                            return cell
                        } else if indexPath.row == 4 {
                            let cell = OverrideDateCell.loadNib(tableView)

                            cell.leftLabel.text = "End"

                            let calendar = Calendar.current
                            var components = DateComponents()
                            components.day = 1

                            if endDate == nil {
                                endDate = calendar.date(byAdding: components, to: startDate!)
                            }

                            cell.rightLabel.text = localDateFormatter.string(from: endDate!)

                            cell.tag = indexPath.row
                            let tap = UITapGestureRecognizer(target: self, action: #selector(selectEndDate(_:)))
                            cell.addGestureRecognizer(tap)
                            cell.isUserInteractionEnabled = true

                            cell.selectionStyle = .none
                            return cell
                        }
                    } else {
                        if indexPath.row == 3 {
                            let cell = OverrideDateCell.loadNib(tableView)

                            cell.leftLabel.text = "Date"
                            cell.rightLabel.text = localDateFormatter.string(from: startDate!)

                            cell.tag = indexPath.row
                            let tap = UITapGestureRecognizer(target: self, action: #selector(selectStartDate(_:)))
                            cell.addGestureRecognizer(tap)
                            cell.isUserInteractionEnabled = true

                            cell.selectionStyle = .none
                            return cell
                        }
                    }
                }
            }
        }

        return UITableViewCell()
    }
    
    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0.01
    }
    
    // MARK: - UIText Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        view.endEditing(true)
        
        updateAddButton()
        
        return false
    }

    // MARK: - Other Functions
    
    @objc func updateTitleInput(_ sender: UITextField) {
        titleInput = sender.text

        updateAddButton()
    }

    @objc func updateNotesInput(_ sender: UITextField) {
        notesInput = sender.text
    }


    @objc func updateMultiDaySwitch(_ sender: UISwitch) {
        Generator.bump()

        endDate = nil

        if sender.isOn == true {
            multiDay = true

            let array = [1]
            let indexSet = IndexSet(array)
            tableView.reloadSections(indexSet, with: UITableViewRowAnimation.none)
        } else {
            multiDay = false

            let array = [1]
            let indexSet = IndexSet(array)
            tableView.reloadSections(indexSet, with: UITableViewRowAnimation.none)
        }
    }

    @objc func updateOverrideTypeSwitch(_ sender: UISwitch) {
        Generator.bump()

        if sender.isOn == true {
            doNotSchedule = true

            let array = [1]
            let indexSet = IndexSet(array)
            tableView.reloadSections(indexSet, with: UITableViewRowAnimation.none)

        } else {
            doNotSchedule = false
            multiDay = false

            let array = [1]
            let indexSet = IndexSet(array)
            tableView.reloadSections(indexSet, with: UITableViewRowAnimation.none)
        }
    }

    @objc func selectStartTime(_: UITapGestureRecognizer) {
        Generator.bump()

        let time = startTime!

        let picker = ActionSheetDatePicker(title: "Start Time:", datePickerMode: UIDatePickerMode.time, selectedDate: time, target: self, action: #selector(startTimeSelected(_:)), origin: tableView)

        let endTime = self.endTime!
        var components = DateComponents()
        components.minute = -15

        let maxTime = Calendar.current.date(byAdding: components, to: endTime)
        picker!.maximumDate = maxTime
        picker!.minuteInterval = 15

        styleActionSheetDatePicker(picker!)

        picker!.show()
    }

    @objc func startTimeSelected(_ date: Date) {
        Generator.bump()

        startTime = date

        let indexPath = IndexPath(row: 3, section: 1)

        if let cell = self.tableView.cellForRow(at: indexPath) as? OverrideDateCell {
            let timeString = timeFormatter.string(from: startTime!)

            cell.rightLabel.text = timeString
        }

        updateAddButton()
    }

    @objc func selectEndTime(_: UITapGestureRecognizer) {
        Generator.bump()

        let time = endTime
        let startTime = self.startTime

        var components = DateComponents()
        components.minute = 15
        let minTime = Calendar.current.date(byAdding: components, to: startTime!)

        let picker = ActionSheetDatePicker(title: "End Time:", datePickerMode: UIDatePickerMode.time, selectedDate: time, target: self, action: #selector(endTimeSelected(_:)), origin: tableView)

        picker!.minimumDate = minTime
        picker!.minuteInterval = 15

        styleActionSheetDatePicker(picker!)

        picker!.show()
    }

    @objc func endTimeSelected(_ date: Date) {
        Generator.bump()

        endTime = date

        let indexPath = IndexPath(row: 4, section: 1)
        if let cell = self.tableView.cellForRow(at: indexPath) as? OverrideDateCell {
            let timeString = timeFormatter.string(from: date)

            cell.rightLabel.text = timeString
        }

        updateAddButton()
    }

    @objc func selectDate(_: UITapGestureRecognizer) {
        Generator.bump()

        // Determine Maximum Date
        let calendar = Calendar.current
        var maxComponents = DateComponents()
        maxComponents.year = 5

        let maximumDate = calendar.date(byAdding: maxComponents, to: startDate!)
        let minimumDate = startDate!

        let picker = ActionSheetDatePicker(title: "Date:", datePickerMode: UIDatePickerMode.date, selectedDate: minimumDate, doneBlock: {
            _, value, _ in

            Generator.bump()

            self.startDate = value as? Date

            let indexPath = IndexPath(row: 2, section: 1)
            if let cell = self.tableView.cellForRow(at: indexPath) as? OverrideDateCell {
                cell.rightLabel.text = self.localDateFormatter.string(from: self.startDate!)
            }
            self.updateAddButton()

            return
        }, cancel: { _ in return }, origin: tableView)

        picker!.minimumDate = minimumDate
        picker!.maximumDate = maximumDate

        styleActionSheetDatePicker(picker!)

        picker!.show()
    }

    @objc func selectStartDate(_: UITapGestureRecognizer) {
        Generator.bump()

        // Determine Maximum Date
        let calendar = Calendar.current
        var maxComponents = DateComponents()
        maxComponents.year = 5
        let maximumDate = calendar.date(byAdding: maxComponents, to: startDate!)
        let minimumDate = startDate!

        let picker = ActionSheetDatePicker(title: "Date:", datePickerMode: UIDatePickerMode.date, selectedDate: minimumDate, doneBlock: {
            _, value, _ in

            Generator.bump()

            self.startDate = value as? Date

            let indexPath = IndexPath(row: 3, section: 1)
            if let startCell = self.tableView.cellForRow(at: indexPath) as? OverrideDateCell {
                startCell.rightLabel.text = self.localDateFormatter.string(from: self.startDate!)
            }

            if self.doNotSchedule == true && self.multiDay == true {
                var components = DateComponents()
                components.day = 1

                let minEndDayDate = calendar.date(byAdding: components, to: self.startDate!)!

                let endIndexPath = IndexPath(row: 4, section: 1)
                if let endCell = self.tableView.cellForRow(at: endIndexPath) as? OverrideDateCell {
                    endCell.rightLabel.text = self.localDateFormatter.string(from: minEndDayDate)
                }
            }

            self.updateAddButton()

            return
        }, cancel: { _ in return }, origin: tableView)

        picker!.minimumDate = minimumDate
        picker!.maximumDate = maximumDate

        styleActionSheetDatePicker(picker!)

        picker!.show()
    }

    @objc func selectEndDate(_: UITapGestureRecognizer) {
        Generator.bump()

        let startDate = self.startDate

        let calendar = Calendar.current
        var minComponents = DateComponents()
        minComponents.day = 1

        let minimumDate = calendar.date(byAdding: minComponents, to: startDate!)

        var maxComponents = DateComponents()
        maxComponents.year = 5

        let maximumDate = calendar.date(byAdding: maxComponents, to: self.startDate!)

        let picker = ActionSheetDatePicker(title: "Date:", datePickerMode: UIDatePickerMode.date, selectedDate: minimumDate, doneBlock: {
            _, value, _ in

            Generator.bump()

            self.endDate = value as? Date

            let indexPath = IndexPath(row: 4, section: 1)
            if let cell = self.tableView.cellForRow(at: indexPath) as? OverrideDateCell {
                cell.rightLabel.text = self.localDateFormatter.string(from: self.endDate!)
            }

            self.updateAddButton()

            return
        }, cancel: { _ in return }, origin: tableView)

        picker!.minimumDate = minimumDate
        picker!.maximumDate = maximumDate

        styleActionSheetDatePicker(picker!)

        picker!.show()
    }

    @objc func updateAddButton() {
        if titleInput != nil {
            enableAddButton()
        } else {
            disableAddButton()
        }
    }

    func enableAddButton() {
        navBar?.rightImage = AssetManager.shared.add
        navBar?.rightEnclosure = { self.add() }
        navBar?.rightButton.tintColor = UIColor.red
    }

    func disableAddButton() {
        navBar?.rightImage = AssetManager.shared.add
        navBar?.rightEnclosure = nil
        navBar?.rightButton.tintColor = Theme.shared.active.subHeaderFontColor
    }

    @objc func add() {
        PKHUD.loading()

        if let title = self.titleInput {
            let override = Override()
            override.title = title

            if let notes = self.notesInput {
                override.notes = notes
            }

            override.doNotTrack = doNotSchedule

            if override.doNotTrack == false {
                // Grab date and times
                let date = startDate!
                let start = startTime!
                let end = endTime!

                var startComponents = DateComponents()
                startComponents.hour = Calendar.current.component(.hour, from: start)
                startComponents.minute = Calendar.current.component(.minute, from: start)

                var endComponents = DateComponents()
                endComponents.hour = Calendar.current.component(.hour, from: end)
                endComponents.minute = Calendar.current.component(.minute, from: end)

                let startValue = Calendar.current.date(byAdding: startComponents, to: date)
                let endValue = Calendar.current.date(byAdding: endComponents, to: date)

                override.start = startValue
                override.end = endValue
                override.user = Auth.shared.id
                override.multiDay = false

                override.create { success in
                    guard success == true else {
                        PKHUD.failure()
                        return
                    }

                    PKHUD.success()

                    self.goBack()
                }
            } else {
                override.multiDay = multiDay
                override.start = startDate!

                if override.multiDay == true {
                    override.end = endDate
                } else {
                    var dateComponents = DateComponents()
                    dateComponents.day = 1

                    let endValue = Calendar.current.date(byAdding: dateComponents, to: startDate!)
                    override.end = endValue
                }

                override.create { success in
                    guard success == true else {
                        PKHUD.failure()
                        return
                    }

                    PKHUD.success()

                    self.goBack()
                }
            }
        } else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "You must add a title")
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT)
        }
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }

}
