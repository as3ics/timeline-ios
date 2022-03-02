//
//  SchedulerController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/26/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import Material
import PKHUD
import UICheckbox_Swift
import UIKit
import CoreLocation

// MARK: - SchedulerController

class SchedulerController: ViewController, UITableViewDelegate, UITableViewDataSource, SidebarSectionProtocol {
    static var section: String = "Schedule"

    @IBOutlet var tableView: UITableView!

    let formatter = DateFormatter()
    var dayImages: [UIImage]?
    var dayImagesFilled: [UIImage]?

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        formatter.dateFormat = "h:mm a"

        dayImages = [UIImage(named: "sunday"), UIImage(named: "monday"), UIImage(named: "tuesday"), UIImage(named: "wednesday"), UIImage(named: "thursday"), UIImage(named: "friday"), UIImage(named: "saturday")] as? [UIImage]

        dayImagesFilled = [UIImage(named: "sunday-filled"), UIImage(named: "monday-filled"), UIImage(named: "tuesday-filled"), UIImage(named: "wednesday-filled"), UIImage(named: "thursday-filled"), UIImage(named: "friday-filled"), UIImage(named: "saturday-filled")] as? [UIImage]

        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.alpha = 0.5
        refreshControl.addTarget(self, action: #selector(reloadSchedule), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        StandardDescriptionCell.register(tableView)
        ScheduleDayCell.register(tableView)
        SettingsSwitchCell.register(tableView)

        reloadSchedule()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    override func setupNavBar() {
        navBar?.title = "Schedule"
        
        navBar?.leftImage = AssetManager.shared.menu
        navBar?.leftEnclosure = { self.menuPressed() }
        
        navBar?.rightImage = AssetManager.shared.save
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    @objc func enableSaveButton() {
        navBar?.rightEnclosure = { self.save() }
        navBar?.rightButton.tintColor = UIColor.red
    }

    func resetSaveButton() {
        navBar?.rightEnclosure = nil
        navBar?.rightButton.tintColor = Theme.shared.active.subHeaderFontColor
    }
    
    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        if DeviceUser.shared.schedule == nil {
            return 1
        } else {
            return 8
        }
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section < 1 {
            return 0
        } else {
            return DEFAULT_HEIGHT_FOR_SECTION_HEADER
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if DeviceUser.shared.schedule == nil {
            return 1
        } else if section == 0 {
            return 4
        } else if section < 8 {
            return 1
        } else {
            return 2
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if DeviceUser.shared.schedule == nil {
            return 200
        } else if indexPath.section == 0 {
            if indexPath.row % 2 == 0 {
                return 45
            } else {
                return 60
            }
        } else {
            return 60
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if DeviceUser.shared.schedule == nil {
            let views = Bundle.main.loadNibNamed("ErrorCell", owner: self, options: nil)
            let cell = views![0] as! ErrorCell

            cell.backgroundColor = UIColor.clear

            let tap = UITapGestureRecognizer(target: self, action: #selector(reloadSchedule))
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true

            cell.selectionStyle = .none
            return cell
        } else if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = SettingsSwitchCell.loadNib(tableView)

                if DeviceSettings.shared.schedulingMode == true {
                    cell.onSwitch.setOn(true, animated: false)
                } else {
                    cell.onSwitch.setOn(false, animated: false)
                }

                cell.onSwitch.addTarget(self, action: #selector(schedulingSwitchValueDidChange), for: .valueChanged)

                cell.icon.image = AssetManager.shared.calendar
                cell.label.text = "Automatic Timesheets"

                cell.backgroundColor = UIColor.clear
                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardDescriptionCell.loadNib(tableView)

                cell.content.text = "Turn automatic timesheets on to have Timeline automatically start and end timesheets for you based on your schedule and overrides"

                cell.content.font = cell.content.font?.withSize(11.0)
                cell.backgroundColor = UIColor.clear
                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 2 {
                let cell = SettingsSwitchCell.loadNib(tableView)

                if DeviceSettings.shared.schedulingAwaitLocation == true {
                    cell.onSwitch.setOn(true, animated: false)
                } else {
                    cell.onSwitch.setOn(false, animated: false)
                }

                cell.onSwitch.addTarget(self, action: #selector(schedulingActiveSwitchValueDidChange), for: .valueChanged)

                cell.icon.image = UIImage(named: "sedan-blue")
                cell.label.text = "Await Location"

                cell.backgroundColor = UIColor.clear
                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 3 {
                let cell = StandardDescriptionCell.loadNib(tableView)

                cell.content.text = "Turn on to have Timeline automatically start a timesheet only when you have entered a location"

                cell.content.font = cell.content.font?.withSize(11.0)
                cell.backgroundColor = UIColor.clear
                cell.selectionStyle = .none
                return cell
            }
        } else if indexPath.section < 8 {
            let cell = ScheduleDayCell.loadNib(tableView)

            cell.startTime.tag = indexPath.section - 1
            cell.endTime.tag = indexPath.section - 1
            cell.checkbox.tag = indexPath.section - 1

            cell.applyTheme()

            let daySchedule = DeviceUser.shared.schedule?[indexPath.section - 1]

            if let start = daySchedule?.start {
                cell.startTime.text = formatter.string(from: start)
            }

            if let end = daySchedule?.end {
                cell.endTime.text = formatter.string(from: end)
            }

            if let active = daySchedule?.active {
                cell.checkbox.isSelected = active

                if active == true {
                    cell.dayImage.image = dayImagesFilled![indexPath.section - 1]
                    cell.applyTheme()
                    cell.setDayTextColor(UIColor.black)
                    cell.setAlpha(1.0)
                } else {
                    cell.dayImage.image = dayImages![indexPath.section - 1]
                    cell.applyTheme()
                    cell.setDayTextColor(UIColor.lightGray)
                    cell.setAlpha(1.0)
                }
            }

            let tap1 = UITapGestureRecognizer(target: self, action: #selector(selectStartTime))
            cell.startTime.addGestureRecognizer(tap1)
            cell.startTime.isUserInteractionEnabled = true

            let tap2 = UITapGestureRecognizer(target: self, action: #selector(selectEndTime))
            cell.endTime.addGestureRecognizer(tap2)
            cell.endTime.isUserInteractionEnabled = true

            cell.checkbox.addTarget(self, action: #selector(checkmarkValueChanged), for: UIControlEvents.touchUpInside)

            cell.backgroundColor = UIColor.clear
            cell.selectionStyle = .none
            return cell
        }

        return UITableViewCell()
    }
    
    // MARK: - Other Functions

    fileprivate var selectedIndex: Int?
    @objc func selectStartTime(_ sender: UITapGestureRecognizer) {
        Generator.bump()

        if let index = sender.view?.tag {
            let daySchedule = DeviceUser.shared.schedule?[index]

            if let startTime = daySchedule?.start, let endTime = daySchedule?.end {
                var components = DateComponents()
                components.minute = -15
                let maxTime = Calendar.current.date(byAdding: components, to: endTime)

                let picker = ActionSheetDatePicker(title: "Start Time:", datePickerMode: UIDatePickerMode.time, selectedDate: startTime, target: self, action: #selector(startTimeSelected), origin: tableView)

                selectedIndex = index
                picker!.maximumDate = maxTime
                picker!.minuteInterval = 15

                styleActionSheetDatePicker(picker!)

                picker!.show()
            }
        }
    }

    @objc func selectEndTime(_ sender: UITapGestureRecognizer) {
        Generator.bump()

        if let index = sender.view?.tag {
            let daySchedule = DeviceUser.shared.schedule?[index]

            if let startTime = daySchedule?.start, let endTime = daySchedule?.end {
                var components = DateComponents()
                components.minute = 15
                let minTime = Calendar.current.date(byAdding: components, to: startTime)

                let picker = ActionSheetDatePicker(title: "End Time:", datePickerMode: UIDatePickerMode.time, selectedDate: endTime, target: self, action: #selector(endTimeSelected), origin: tableView)

                selectedIndex = index
                picker!.minimumDate = minTime
                picker!.minuteInterval = 15

                styleActionSheetDatePicker(picker!)

                picker!.show()
            }
        }
    }

    @objc func startTimeSelected(_ date: Date) {
        if let index = self.selectedIndex {
            if let daySchedule = DeviceUser.shared.schedule?[index] {
                Generator.bump()

                daySchedule.start = date
                enableSaveButton()

                let sections = [index + 1]
                let indexSet = IndexSet(sections)
                tableView.reloadSections(indexSet, with: UITableViewRowAnimation.none)
            }
        }

        selectedIndex = nil
    }

    @objc func endTimeSelected(_ date: Date) {
        if let index = self.selectedIndex {
            if let daySchedule = DeviceUser.shared.schedule?[index] {
                Generator.bump()

                daySchedule.end = date
                enableSaveButton()

                let sections = [index + 1]
                let indexSet = IndexSet(sections)
                tableView.reloadSections(indexSet, with: UITableViewRowAnimation.none)
            }
        }
        selectedIndex = nil
    }

    @objc func checkmarkValueChanged(_ sender: UICheckbox) {
        let index = sender.tag

        if let daySchedule = DeviceUser.shared.schedule?[index] {
            Generator.bump()

            daySchedule.active = sender.isSelected
            enableSaveButton()

            let sections = [index + 1]
            let indexSet = IndexSet(sections)
            tableView.reloadSections(indexSet, with: UITableViewRowAnimation.none)
        }
    }

    @objc func save() {
        PKHUD.loading()

        DeviceUser.shared.schedule?.update({ success in
            if success == true {
                Generator.confirm()

                self.resetSaveButton()

                PKHUD.success()
            } else {
                Generator.failure()

                PKHUD.failure()
            }
        })
    }

    @objc func reloadSchedule() {

        Async.waterfall(nil, [Schedule().retrieve]) { _, response in
            self.tableView.refreshControl?.endRefreshing()
            guard let data = response as? JSON, let schedule = data["model"] as? Schedule else {
                self.tableView.reloadData()
                return
            }

            DeviceUser.shared.schedule = schedule
            self.tableView.reloadData()
            self.resetSaveButton()
        }
    }
    
    @objc func schedulingSwitchValueDidChange(_ sender: UISwitch) {
        Generator.bump()

        DeviceSettings.shared.schedulingMode = sender.isOn
    }

    @objc func schedulingActiveSwitchValueDidChange(_ sender: UISwitch) {
        Generator.bump()

        DeviceSettings.shared.schedulingAwaitLocation = sender.isOn
    }
    
    override func prepareForDeinit() {
        
        if navBar?.rightEnclosure != nil {
            reloadSchedule()
        }
        
        super.prepareForDeinit()
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.tableHeaderView?.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        navBar?.rightButton.tintColor = Theme.shared.active.subHeaderFontColor
    }
}
