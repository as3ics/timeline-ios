//
//  HistoryViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/3/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import JTAppleCalendar
import Material
import PKHUD
import UIKit
import CoreLocation

// MARK: - ViewHistory

class ViewHistory: ViewController, UITableViewDelegate, UITableViewDataSource, SidebarSectionProtocol {
    static var section: String = "History"

    @IBOutlet var tableView: UITableView!

    @IBOutlet var myCalendar: JTAppleCalendarView!
    @IBOutlet var monthLabel: UILabel!
    @IBOutlet var downCarrot: UIImageView!
    @IBOutlet var nameLabel: UILabel!

    @IBOutlet var dateSelectionContainer: UIView!
    var formatter = DateFormatter()
    var dayOfWeekFormatter = DateFormatter()
    var monthFormatter = DateFormatter()
    var fromMonthFormatter = DateFormatter()
    var cellDateFormatter = DateFormatter()

    var JTCalendarDate: Date?

    var startOfMonth: Date?
    var endOfMonth: Date?
    var startOfWeek: Date?
    var endOfWeek: Date?
    var currentMonth: Int?
    var currentYear: Int?

    let FirstYear = 2017
    var user: User?
    var sheets: Sheets = Sheets()
    var weekSheets = [Sheet]()
    var loadingError: Bool = false
    var initialLoad: Bool = false
    
    var months = [
        NSLocalizedString("january", comment: ""),
        NSLocalizedString("february", comment: ""),
        NSLocalizedString("march", comment: ""),
        NSLocalizedString("april", comment: ""),
        NSLocalizedString("may", comment: ""),
        NSLocalizedString("june", comment: ""),
        NSLocalizedString("july", comment: ""),
        NSLocalizedString("august", comment: ""),
        NSLocalizedString("september", comment: ""),
        NSLocalizedString("october", comment: ""),
        NSLocalizedString("november", comment: ""),
        NSLocalizedString("december", comment: ""),
        ]
    
    var years = [
        "2017",
        "2018",
        "2019",
        "2020",
        "2021",
        "2022",
        "2023",
        "2024",
        "2025"
    ]

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
        tableView.alpha = 0.0

        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(grabMonthOfTimesheets), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        dayOfWeekFormatter.dateFormat = "EEE"
        monthFormatter.dateFormat = "LLLL yyyy"
        fromMonthFormatter.dateFormat = "MMMM"
        cellDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

        let calendar = Calendar.current
        currentMonth = calendar.component(.month, from: Date())
        currentYear = calendar.component(.year, from: Date())

        downCarrot.image = downCarrot.image?.withRenderingMode(.alwaysTemplate)

        HistoryCell.register(tableView)

        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        didSelectRow = false
        monthLabel.text = String(format: "%@ %i", months[currentMonth! - 1], currentYear!)
        nameLabel.text = Users.shared[self.sheets.user]?.fullName ?? DeviceUser.shared.user?.fullName ?? ""
    }
    
    override func setupNavBar() {
        navBar?.title = nil
        
        dateSelectionContainer.removeFromSuperview()
        navBar?.centerView = dateSelectionContainer
        navBar?.centerAction = UITapGestureRecognizer(target: self, action: #selector(ViewHistory.monthSelect))
        
        if let userId = self.user?.id ?? Auth.shared.id, userId == Auth.shared.id {
            navBar?.leftImage = AssetManager.shared.menu
            navBar?.leftEnclosure = { self.menuPressed() }
        } else {
            navBar?.leftImage = AssetManager.shared.arrowLeft
            navBar?.leftEnclosure = { self.goBack() }
        }
        
        navBar?.rightImage = AssetManager.shared.plus
        navBar?.rightEnclosure = { self.createPastTimesheet(nil) }
    }
    
    @objc func createPastTimesheet(_ sender: Any?) {
        if let sender = sender as? UITapGestureRecognizer {
            sender.view?.touchAnimation()
        }
        
        guard self.user?.sheet == nil else {
            PKHUD.message(text: "This user already has an open sheet")
            PKHUD.hide(delay: 1.0)
            return
        }
        
        let minimum = Date(timeIntervalSince1970: 0)
        let maximum = Date()
        
        let picker = ActionSheetDatePicker(title: "Select Sheet Start", datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: maximum, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(commitPastTimesheet), cancelAction: nil, origin: self.navBar)
        
        picker?.maximumDate = maximum
        picker?.minimumDate = minimum
        
        self.styleActionSheetDatePicker(picker)
        
        picker?.show()
        
    }
    
    @objc func commitPastTimesheet(_ date: Date) {
        
        if let user = self.user ?? DeviceUser.shared.user {
            let sheet = Sheet()
            sheet.user = user.id
            sheet.date = date
            
            PKHUD.loading()
            Async.waterfall(nil, [sheet.create, sheet.entries.retrieve], end: { (error, _) in
                guard error == nil else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
                
                if user !== DeviceUser.shared.user {
                    Async.waterfall(nil, [Stream.shared.retrieve], end: { (_, _) in })
                }
                
                DispatchQueue.main.async {
                    self.grabMonthOfTimesheets()
                }
            })
        }
    }

    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        return max(weekSheets.count, 1)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if weekSheets.count > 0 && indexPath.section < weekSheets.count {
            return 60
        } else if weekSheets.count > 0 && indexPath.section >= weekSheets.count {
            return 0
        } else {
            return 200
        }
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if weekSheets.count > 0 && indexPath.section < weekSheets.count {
            let cell = HistoryCell.loadNib(tableView)

            cell.populate(sheet: weekSheets[indexPath.section])

            cell.backgroundColor = UIColor.clear
            return cell
        } else if weekSheets.count > 0 && indexPath.section >= weekSheets.count {
            return UITableViewCell()
        } else if loadingError == true {
            let views = Bundle.main.loadNibNamed("ErrorCell", owner: self, options: nil)
            let cell = views![0] as! ErrorCell

            cell.selectionStyle = .none
            return cell
        } else {
            let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
            let cell = views![0] as! EmptyCell

            cell.selectionStyle = .none
            return cell
        }
    }

    var didSelectRow: Bool = false
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        Generator.bump()

        if weekSheets.count > 0 {
            if didSelectRow == false {
                if indexPath.section < weekSheets.count {
                    didSelectRow = true

                    let sheet = weekSheets[indexPath.section]
                    
                    let destination = UIStoryboard.History(identifier: "HistoryTimesheetController") as! HistoryTimesheetController
                    destination.sheet = sheet
                    
                    self.navigationController?.pushViewController(destination, animated: true)
                    
                    self.didSelectRow = false
                }
                
            }
        }
    }

    func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        guard user === DeviceUser.shared.user || System.shared.adminAccess == true else {
            return false
        }
        
        if weekSheets.count > 0 && indexPath.section < weekSheets.count {
            return true
        }

        return false
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let index = indexPath.section
        let sheet = self.weekSheets[index]
        
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete", handler: { _, _ in

            Generator.bump()

            PKHUD.loading()

            sheet.delete({ success in
                guard success == true else {
                    PKHUD.failure()
                    return
                }
                
                if let user = Users.shared[sheet.user] ?? DeviceUser.shared.user {
                    if sheet.id == user.sheet?.id {
                        user.sheet = nil
                    }
                    
                    Async.waterfall(nil, [user.retrieveStatistics], end: { (_, _) in
                        PKHUD.success()
                        
                        if user === DeviceUser.shared.user {
                            Sidebar.refresh()
                        }
                    })
                }
            })
        })
        
        let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit", handler: { _, _ in
            
            Generator.bump()
            
            sheet.edit()
        })

        deleteRowAction.backgroundColor = UIColor.red.withAlphaComponent(0.75)
        editRowAction.backgroundColor = UIColor.gray.withAlphaComponent(0.75)

        return sheet.submitted ? [editRowAction, deleteRowAction] : [editRowAction]
    }

    // MARK: Model Updater

    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate, update.action == .Delete else {
            return
        }

        if let sheet = update.model as? Sheet {
            if update.action == .Delete {
                sheets.remove(sheet)
                grabWeekOfSheets(start: startOfWeek!, end: endOfWeek!)
                tableView.reloadData()
            } else if update.action == .Create {
                grabMonthOfTimesheets()
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - Other Functions
    
    @objc func monthSelect() {
        Generator.bump()
        
        let acp = ActionSheetMultipleStringPicker(title: NSLocalizedString("HistoryViewController_Date", comment: ""), rows: [
            months,
            years,
            ], initialSelection: [currentMonth! - 1, currentYear! - FirstYear], doneBlock: {
                _, indexes, _ in
                
                Generator.bump()
                
                let monthIndex = indexes![0] as! Int
                let yearIndex = indexes![1] as! Int
                
                self.currentMonth = monthIndex + 1
                self.currentYear = yearIndex + self.FirstYear
                
                self.monthLabel.text = String(format: "%@ %i", self.months[self.currentMonth! - 1], self.currentYear!)
                
                self.myCalendar.reloadData()
                
                delay(0.5, closure: {
                    self.myCalendar.scrollToDate(self.startOfMonth!)
                })
                
                return
        }, cancel: { _ in return }, origin: view)
        
        acp!.show()
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        //navBar?.layoutHeight = .Short
        //navBar?.verticalLayout = .Bottom
        
        myCalendar.backgroundColor = Theme.shared.active.primaryBackgroundColor
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        monthLabel.textColor = Theme.shared.active.subHeaderFontColor
        downCarrot.tintColor = Theme.shared.active.subHeaderFontColor
    }
}

extension ViewHistory: JTAppleCalendarViewDelegate, JTAppleCalendarViewDataSource {
    func calendar(_: JTAppleCalendarView, willDisplay _: JTAppleCell, forItemAt _: Date, cellState _: CellState, indexPath _: IndexPath) {
    }

    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt _: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CalendarCell", for: indexPath) as! CalendarViewCell

        if indexPath.row == 0 {
            let calendar = Calendar.current
            startOfWeek = cellState.date

            var components = DateComponents()
            components.day = 7
            components.second = -1

            endOfWeek = calendar.date(byAdding: components, to: startOfWeek!)
        }

        cell.label?.text = cellState.text
        cell.cellHeader?.text = dayOfWeekFormatter.string(from: cellState.date)

        cell.backgroundColor = UIColor.clear

        if cellState.dateBelongsTo == DateOwner.previousMonthOutsideBoundary || cellState.dateBelongsTo == DateOwner.followingMonthOutsideBoundary {
            cell.label?.textColor = UIColor.lightGray
        } else {
            cell.label?.textColor = UIColor.black
        }

        return cell
    }

    func calendar(_: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        let dates = visibleDates.monthDates

        startOfWeek = dates[0].date
        endOfWeek = dates[dates.count - 1].date

        let cal = Calendar.current
        var components = DateComponents()
        components.day = 1
        // components.second = -1
        endOfWeek = cal.date(byAdding: components, to: endOfWeek!)

        grabWeekOfSheets(start: startOfWeek!, end: endOfWeek!)
        tableView.alpha = 1.0
        tableView.reloadData()
    }

    @objc func grabMonthOfTimesheets() {
        guard startOfMonth != nil, endOfMonth != nil else {
            return
        }

        sheets.items.removeAll()
        sheets.user = self.user?.id ?? Auth.shared.id
        sheets.start = startOfMonth
        sheets.end = endOfMonth

        sheets.retrieve({ error, _ in
            self.tableView?.refreshControl?.endRefreshing()
            guard error == nil else {
                self.loadingError = true
                self.myCalendar.scrollToDate(Date())
                return
            }
            
            self.loadingError = false
            if self.initialLoad == false {
                self.initialLoad = true
                self.myCalendar.scrollToDate(Date())
            } else {
                self.grabWeekOfSheets(start: self.startOfWeek!, end: self.endOfWeek!)
                self.myCalendar.scrollToDate(self.startOfWeek!)
                
            }
        }, nil)
    }

    func grabWeekOfSheets(start: Date, end: Date) {
        weekSheets.removeAll()

        for sheet in sheets.items {
            if sheet.date! < end && sheet.date! > start {
                weekSheets.insert(sheet, at: 0)
                // Don't put current timesheet in list
                /*
                if sheet.id! != DeviceUser.shared.sheet?.id {
                    weekSheets.insert(sheet, at: 0)
                }
                */
            }
        }
    }

    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy MM dd"

        let calendar = Calendar.current

        /* Initialize the current Year and Month if not already set. */
        if currentMonth == nil || currentYear == nil {
            let initComponents = calendar.dateComponents(in: TimeZone.current, from: Date())
            currentMonth = initComponents.month
            currentYear = initComponents.year
        }

        /* Get the current month components for the JTCalendar */
        let components = DateComponents(calendar: calendar, timeZone: nil, era: nil, year: currentYear!, month: currentMonth!, day: 1, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)

        JTCalendarDate = calendar.date(from: components)

        startOfMonth = JTCalendarDate

        var comps2 = DateComponents()
        comps2.month = 1
        // comps2.second = -1
        endOfMonth = calendar.date(byAdding: comps2, to: startOfMonth!)

        let parameters = ConfigurationParameters(startDate: JTCalendarDate!, endDate: JTCalendarDate!, numberOfRows: 1, calendar: nil, generateInDates: InDateCellGeneration.forAllMonths, generateOutDates: OutDateCellGeneration.tillEndOfRow, firstDayOfWeek: DaysOfWeek(rawValue: 1), hasStrictBoundaries: false)

        grabMonthOfTimesheets()

        return parameters
    }
}
