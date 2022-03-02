//
//  ScheduleViewOverrideController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/29/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import PKHUD
import UIKit
import CoreLocation

// MARK: - ScheduleViewOverrideController

class ScheduleViewOverrideController: ViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet var tableView: UITableView!

    var override: Override?

    let localDateFormatter = DateFormatter()
    let pickerDateFormatter = DateFormatter()
    let timeFormatter = DateFormatter()

    var titleInput: String?
    var notesInput: String?

    var doNotSchedule: Bool = false
    var multiDay: Bool = false

    var date: Date?
    var start: Date?
    var end: Date?
    
    // MARK: - UIViewController Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        if override == nil {
            goBack()
        } else {
            titleInput = override!.title
            notesInput = override!.notes
            doNotSchedule = override!.doNotTrack
            multiDay = override!.multiDay
        }

        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        localDateFormatter.dateFormat = "LLL d, yyyy"
        pickerDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        timeFormatter.dateFormat = "h:mm a"

        let dateStr = localDateFormatter.string(from: override!.start!)

        date = localDateFormatter.date(from: dateStr)
        start = override?.start
        end = override?.end

        hideKeyboardWhenTappedAround()

        StandardHeaderCell.register(tableView)
        OverrideDateCell.register(tableView)
        OverrideSwitchCell.register(tableView)
        StandardTextFieldCell.register(tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func setupNavBar() {
        navBar?.title = "Edit Override"
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
        
        updateSaveButton()
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
            return 30
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
                cell.title.text = ""

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
                cell.title.text = ""

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

                        cell.rightLabel.text = localDateFormatter.string(from: date!)

                        cell.tag = indexPath.row
                        let tap = UITapGestureRecognizer(target: self, action: #selector(selectDate(_:)))
                        cell.addGestureRecognizer(tap)
                        cell.isUserInteractionEnabled = true

                        cell.selectionStyle = .none
                        return cell
                    } else if indexPath.row == 3 {
                        let cell = OverrideDateCell.loadNib(tableView)

                        cell.leftLabel.text = "Start"

                        cell.rightLabel.text = timeFormatter.string(from: start!)

                        let tap = UITapGestureRecognizer(target: self, action: #selector(selectStartTime(_:)))
                        cell.addGestureRecognizer(tap)
                        cell.isUserInteractionEnabled = true

                        cell.selectionStyle = .none
                        return cell
                    } else if indexPath.row == 4 {
                        let cell = OverrideDateCell.loadNib(tableView)

                        cell.leftLabel.text = "End"

                        cell.rightLabel.text = timeFormatter.string(from: end!)

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

                            cell.rightLabel.text = localDateFormatter.string(from: start!)

                            cell.tag = indexPath.row
                            let tap = UITapGestureRecognizer(target: self, action: #selector(selectStartDate(_:)))
                            cell.addGestureRecognizer(tap)
                            cell.isUserInteractionEnabled = true

                            cell.selectionStyle = .none
                            return cell
                        } else if indexPath.row == 4 {
                            let cell = OverrideDateCell.loadNib(tableView)

                            cell.leftLabel.text = "End"

                            cell.rightLabel.text = localDateFormatter.string(from: end!)

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

                            cell.rightLabel.text = localDateFormatter.string(from: start!)

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
        
        updateSaveButton()
        
        return false
    }
    
    
    // MARK: - Other Functions

    @objc func updateMultiDaySwitch(_ sender: UISwitch) {
        Generator.bump()

        if sender.isOn {
            multiDay = true

            tableView.reloadSections([1], with: UITableViewRowAnimation.none)
        } else {
            multiDay = false

            tableView.reloadSections([1], with: UITableViewRowAnimation.none)
        }

        updateSaveButton()
    }

    @objc func updateOverrideTypeSwitch(_ sender: UISwitch) {
        Generator.bump()

        if sender.isOn == true {
            doNotSchedule = true

            start = date

            var comps = DateComponents()
            comps.day = 1

            end = Calendar.current.date(byAdding: comps, to: date!)

            tableView.reloadSections([1], with: UITableViewRowAnimation.none)

        } else {
            doNotSchedule = false
            multiDay = false

            var comps = DateComponents()
            comps.hour = 8

            start = Calendar.current.date(byAdding: comps, to: date!)

            comps.hour = 17
            end = Calendar.current.date(byAdding: comps, to: date!)

            tableView.reloadSections([1], with: UITableViewRowAnimation.none)
        }

        updateSaveButton()
    }

    @objc func selectStartTime(_: UITapGestureRecognizer) {
        Generator.bump()

        let time = start!

        let picker = ActionSheetDatePicker(title: "Start Time:", datePickerMode: UIDatePickerMode.time, selectedDate: time, target: self, action: #selector(startTimeSelected(_:)), origin: tableView)

        let endTime = end!
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

        start = date

        updateSaveButton()

        tableView.reloadSections([1], with: UITableViewRowAnimation.none)
    }

    @objc func selectEndTime(_: UITapGestureRecognizer) {
        Generator.bump()

        let startTime = start!

        var components = DateComponents()
        components.minute = 15
        let minTime = Calendar.current.date(byAdding: components, to: startTime)

        let picker = ActionSheetDatePicker(title: "End Time:", datePickerMode: UIDatePickerMode.time, selectedDate: end!, target: self, action: #selector(endTimeSelected(_:)), origin: tableView)

        picker!.minimumDate = minTime
        picker!.minuteInterval = 15

        styleActionSheetDatePicker(picker!)

        picker!.show()
    }

    @objc func endTimeSelected(_ date: Date) {
        Generator.bump()

        end = date

        updateSaveButton()

        tableView.reloadSections([1], with: UITableViewRowAnimation.none)
    }

    @objc func selectDate(_: UITapGestureRecognizer) {
        Generator.bump()

        // Determine Maximum Date
        let calendar = Calendar.current
        var maxComponents = DateComponents()
        maxComponents.year = 2

        let maximumDate = calendar.date(byAdding: maxComponents, to: Date())
        let minimumDate = Date()

        let picker = ActionSheetDatePicker(title: "Date:", datePickerMode: UIDatePickerMode.date, selectedDate: date, doneBlock: {
            _, value, _ in

            Generator.bump()

            let date = value as! Date

            var comps = DateComponents()
            comps.day = Calendar.current.component(.day, from: date)
            comps.month = Calendar.current.component(.month, from: date)
            comps.year = Calendar.current.component(.year, from: date)

            self.date = Calendar.current.date(from: comps)

            self.tableView.reloadRows(at: [IndexPath(row: 2, section: 1)], with: .automatic)

            self.updateSaveButton()

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
        maxComponents.year = 2
        let maximumDate = calendar.date(byAdding: maxComponents, to: Date())
        let minimumDate = Date()

        let picker = ActionSheetDatePicker(title: "Date:", datePickerMode: UIDatePickerMode.date, selectedDate: start, doneBlock: {
            _, value, _ in

            Generator.bump()

            let date = value as! Date

            if self.doNotSchedule == false {
                var comps = DateComponents()
                comps.hour = Calendar.current.component(.hour, from: date)
                comps.minute = Calendar.current.component(.minute, from: date)
                self.start = Calendar.current.date(byAdding: comps, to: self.start!)
            } else {
                self.start = date
            }

            self.tableView.reloadRows(at: [IndexPath(row: 3, section: 1)], with: .automatic)

            if self.doNotSchedule == true && self.multiDay == true {
                var components = DateComponents()
                components.day = 1

                let minEndDayDate = calendar.date(byAdding: components, to: self.start!)!
                self.end = minEndDayDate

                self.tableView.reloadRows(at: [IndexPath(row: 4, section: 1)], with: .automatic)
            }

            self.updateSaveButton()

            return
        }, cancel: { _ in return }, origin: tableView)

        picker!.minimumDate = minimumDate
        picker!.maximumDate = maximumDate

        styleActionSheetDatePicker(picker!)

        picker!.show()
    }

    @objc func selectEndDate(_: UITapGestureRecognizer) {
        Generator.bump()

        let startDate = start!

        let calendar = Calendar.current
        var minComponents = DateComponents()
        minComponents.day = 1

        let minimumDate = calendar.date(byAdding: minComponents, to: startDate)

        var maxComponents = DateComponents()
        maxComponents.year = 2

        let maximumDate = calendar.date(byAdding: maxComponents, to: Date())

        let picker = ActionSheetDatePicker(title: "Date:", datePickerMode: UIDatePickerMode.date, selectedDate: end, doneBlock: {
            _, value, _ in

            Generator.bump()

            let date = value as! Date

            if self.doNotSchedule == false {
                var comps = DateComponents()
                comps.hour = Calendar.current.component(.hour, from: date)
                comps.minute = Calendar.current.component(.minute, from: date)
                self.end = Calendar.current.date(byAdding: comps, to: self.start!)
            } else {
                self.end = date
            }
            self.tableView.reloadRows(at: [IndexPath(row: 4, section: 1)], with: .automatic)

            self.updateSaveButton()

            return
        }, cancel: { _ in return }, origin: tableView)

        picker!.minimumDate = minimumDate
        picker!.maximumDate = maximumDate

        styleActionSheetDatePicker(picker!)

        picker!.show()
    }

    @objc func updateTitleInput(_ sender: UITextField) {
        titleInput = sender.text

        updateSaveButton()
    }

    @objc func updateNotesInput(_ sender: UITextField) {
        notesInput = sender.text
    }

    @objc func updateSaveButton() {
        if titleInput != "" {
            enableSaveButton()
        } else {
            disableSaveButton()
        }
    }

    func enableSaveButton() {
        navBar?.rightEnclosure = { self.save() }
        navBar?.rightImage = AssetManager.shared.save
        navBar?.rightButton.tintColor = UIColor.red
    }

    func disableSaveButton() {
        navBar?.rightEnclosure = nil
        navBar?.rightImage = AssetManager.shared.save
        navBar?.rightButton.tintColor = Theme.shared.active.subHeaderFontColor
    }

    @objc func save() {

        PKHUD.loading()

        if titleInput != "" {
            override!.title = titleInput
            override!.notes = notesInput
            override!.multiDay = multiDay
            override!.doNotTrack = doNotSchedule

            if override!.doNotTrack == false {
                let dateStr = localDateFormatter.string(from: self.start!)
                let startStr = timeFormatter.string(from: self.start!)
                let endStr = timeFormatter.string(from: self.end!)

                let date = localDateFormatter.date(from: dateStr)
                let start = timeFormatter.date(from: startStr)
                let end = timeFormatter.date(from: endStr)

                var startComponents = DateComponents()
                startComponents.hour = Calendar.current.component(.hour, from: start!)
                startComponents.minute = Calendar.current.component(.minute, from: start!)

                var endComponents = DateComponents()
                endComponents.hour = Calendar.current.component(.hour, from: end!)
                endComponents.minute = Calendar.current.component(.minute, from: end!)

                let startDate = Calendar.current.date(byAdding: startComponents, to: date!)
                let endDate = Calendar.current.date(byAdding: endComponents, to: date!)

                override!.start = startDate
                override!.end = endDate
                override!.user = Auth.shared.id
                override!.multiDay = false

                override!.update { success in
                    guard success == true else {
                        PKHUD.failure()
                        return
                    }

                    PKHUD.success()
                    self.goBack()
                }
            } else {
                override!.multiDay = multiDay

                let startStr = localDateFormatter.string(from: self.start!)
                let endStr = localDateFormatter.string(from: self.end!)

                let start = localDateFormatter.date(from: startStr)
                let end = localDateFormatter.date(from: endStr)

                override?.start = start

                if override!.multiDay == true {
                    override!.end = end
                } else {
                    var endComponents = DateComponents()
                    endComponents.day = 1
                    let endDate = Calendar.current.date(byAdding: endComponents, to: start!)!
                    override!.end = endDate
                }

                override!.update { success in
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
        tableView.tableHeaderView?.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }
}
