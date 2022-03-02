//
//  EntriesHeaderCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 2/17/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class EntriesHeaderCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = EntriesHeaderCell
    static var reuseIdentifier: String = "EntriesHeaderCell"
    static var cellHeight: CGFloat = 100

    @IBOutlet var leftTitle: UILabel!
    @IBOutlet var rightTitle: UILabel!

    @IBOutlet var activityName: UILabel!
    @IBOutlet var entryDuration: UILabel!
    @IBOutlet var entryTime: UILabel!
    @IBOutlet var locationName: UILabel!

    @IBOutlet var sheetDate: UILabel!
    @IBOutlet var sheetTime: UILabel!
    @IBOutlet var travelMiles: UILabel!
    @IBOutlet var paidTime: UILabel!

    @IBOutlet var arrowDownView: UIView?

    var sheet: Sheet?

    let baseFontSize: CGFloat = 16.0
    let titleFontDifference: CGFloat = 2.0
    
    var timer_1000ms: Timer?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = baseFontSize

        leftTitle.font = leftTitle.font.withSize(fontSize + titleFontDifference)
        rightTitle.font = rightTitle.font.withSize(fontSize + titleFontDifference)

        activityName.font = activityName.font.withSize(fontSize)
        entryDuration.font = entryDuration.font.withSize(fontSize)
        entryTime.font = entryTime.font.withSize(fontSize)
        locationName.font = locationName.font.withSize(fontSize)

        sheetDate.font = sheetDate.font.withSize(fontSize)
        sheetTime.font = sheetTime.font.withSize(fontSize)
        travelMiles.font = travelMiles.font.withSize(fontSize)
        paidTime.font = paidTime.font.withSize(fontSize)
        
        NotificationManager.shared.focues_entry_updated.observe(self, selector: #selector(update))
        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
        
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editTimesheet)))
        self.contentView.isUserInteractionEnabled = true
        
        applyTheme()
    }

    @objc func update() {
        DispatchQueue.main.async {
            self.updateValues()
        }
    }

    func updateValues() {
        guard let sheet = self.sheet else {
            activityName.text = nil
            entryTime.text = nil
            entryDuration.text = nil
            locationName.text = nil
            sheetTime.text = nil
            travelMiles.text = nil
            paidTime.text = nil
            sheetDate.text = nil

            return
        }
        
        var entry: Entry?
        
        if self.sheet === _focusedEntry.sheet, _focusedEntry.isSet() == true {
            entry = self.sheet?.entries[_focusedEntry.entryId]
        }
        
        if self.sheet === _historyFocusedEntry.sheet, _historyFocusedEntry.isSet() == true {
            entry = self.sheet?.entries[_historyFocusedEntry.entryId]
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        if entry == nil {
            sheetDate.alpha = 1.0
            sheet.updateTimes()
            
            let seconds = sheet.totalSeconds
            let durationString = String(format: "%.0fh %02.0fm %02.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
            sheetTime.text = durationString
            
            let travelMeters = sheet.distance
            let travelString = String(format: "%0.1f miles", arguments: [travelMeters * CONVERSION_METERS_TO_MILES_MULTIPLIER])
            travelMiles.text = travelString
            
            let paidDurationString = String(format: "%@ - %@", arguments: [formatter.string(from: sheet.date!), formatter.string(from: sheet.submissionDate ?? Date())])
            paidTime.text = paidDurationString
            
            rightTitle.text = "Shift Totals"
        } else {
            sheetDate.alpha = 0.0
            
            sheetTime.text = nil
            travelMiles.text = nil
            paidTime.text = nil
            rightTitle.text = nil
        }
        
        if let entry = entry, let activityName = entry.activity?.name, let index = sheet.entries.index(id: entry.id) {
            
            leftTitle.text = "Past Entry"
            
            self.activityName.text = activityName
            
            if let entrySeconds = sheet.duration(index: index) {
                let entryTimeString = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(entrySeconds), clockMinutes(entrySeconds), clockSeconds(entrySeconds)])
                entryTime.text = entryTimeString
            } else {
                entryTime.text = nil
            }
            
            // Set timespan string
            var timespanText: String?
            if index == 0, sheet.submissionDate == nil, let startString = entry.startString {
                timespanText = String(format: "%@ - Present", arguments: [startString])
            } else if index == 0, self.sheet?.submissionDate != nil, let start = entry.start, let end = self.sheet?.submissionDate {
                timespanText = String(format: "%@ - %@", arguments: [formatter.string(from: start), formatter.string(from: end)])
            } else if let previousEntry = self.sheet?.entries[index - 1], let previousStartString = previousEntry.startString, let startString = entry.startString {
                timespanText = String(format: "%@ - %@", arguments: [startString, previousStartString])
            }
            
            entryDuration.text = timespanText
            
            if let location = entry.location, let locationName = location.name {
                self.locationName.text = locationName
            } else if let activity = entry.activity, activity.traveling, let meters = entry.meters {
                locationName.text = String(format: "%0.1f miles", arguments: [meters * CONVERSION_METERS_TO_MILES_MULTIPLIER])
            } else {
                locationName.text = entryDuration.text
                entryDuration.text = nil
                
            }
        } else if let entry = sheet.entries.latest, let startDate = entry.start, let activityName = entry.activity?.name {
            
            leftTitle.text = "Current Entry"
            
            self.activityName.text = activityName

            if let entrySeconds = sheet.duration(index: 0) {
                let entryTimeString = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(entrySeconds), clockMinutes(entrySeconds), clockSeconds(entrySeconds)])
                entryTime.text = entryTimeString
            } else {
                entryTime.text = nil
            }

            let startString = formatter.string(from: startDate)
            let timespanString = String(format: "%@", arguments: [startString])
            entryDuration.text = timespanString

            if let location = entry.location, let locationName = location.name {
                self.locationName.text = locationName
            } else if let activity = entry.activity, activity.traveling, let meters = entry.meters {
                locationName.text = String(format: "%0.1f mile", arguments: [meters * CONVERSION_METERS_TO_MILES_MULTIPLIER])
            } else {
                locationName.text = entryDuration.text
                entryDuration.text = nil
            }
        } else {
            activityName.text = "No Time Entries"
            entryTime.text = nil
            entryDuration.text = nil
            locationName.text = nil
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func populate(_ sheet: Sheet?) {
        self.sheet = sheet

        updateValues()
        
        if let start = sheet?.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "eee LLL d, YYYY"
            
            DispatchQueue.main.async {
                self.sheetDate.text = formatter.string(from: start)
            }
        }

        guard sheet == DeviceUser.shared.sheet else {
            return
        }
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
                    
                    print("Timer - Entry Header Cell")
                    
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
    
    @objc func editTimesheet(_ sender: UIGestureRecognizer) {
        Generator.bump()
        
        self.sheet?.edit(sender.view!)
    }

    @objc func applyTheme() {
        leftTitle.textColor = Theme.shared.active.placeholderColor
        rightTitle.textColor = Theme.shared.active.placeholderColor
        sheetDate.textColor = UIColor.white
        activityName.textColor = UIColor.white
        entryDuration.textColor = UIColor.white
        entryTime.textColor = UIColor.white
        locationName.textColor = UIColor.white
        sheetTime.textColor = UIColor.white
        travelMiles.textColor = UIColor.white
        paidTime.textColor = UIColor.white

        leftTitle.autoResize()
        rightTitle.autoResize()
        activityName.autoResize()
        entryDuration.autoResize()
        entryTime.autoResize()
        locationName.autoResize()
        sheetTime.autoResize()
        travelMiles.autoResize()
        paidTime.autoResize()
        sheetDate.autoResize()
    }

    deinit {
        updates = false
        NotificationCenter.default.removeObserver(self)
    }
}
