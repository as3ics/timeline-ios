//
//  HistoryCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/9/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import UIKit
import Material

class HistoryCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = HistoryCell
    static var reuseIdentifier: String = "HistoryCell"

    @IBOutlet var dateNumberLabel: UILabel!
    @IBOutlet var dateDayLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var timespanLabel: UILabel!
    @IBOutlet var approvedLabel: UILabel!
    @IBOutlet var horizontalView: UIView!
    @IBOutlet var activityCountLabel: UILabel!
    @IBOutlet var locationCountLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var entryCountLabel: UILabel!

    var dayFormatter = DateFormatter()
    var dateFormatter = DateFormatter()
    var timeFormatter = DateFormatter()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        dayFormatter.dateFormat = "EEE"
        dateFormatter.dateFormat = "d"
        timeFormatter.dateFormat = "h:mm a"

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        super.setSelected(false, animated: true)
        // Configure the view for the selected state
    }
    
    override func setHighlighted(_: Bool, animated _: Bool) {
        super.setHighlighted(false, animated: false)
    }

    func populate(sheet: Sheet) {
        dateNumberLabel.text = dateFormatter.string(from: sheet.date!)
        dateDayLabel.text = dayFormatter.string(from: sheet.date!)

        if sheet.approved == true {
            approvedLabel.text = "Approved"
            approvedLabel.textColor = Color.green.base
            horizontalView.backgroundColor = Color.green.base
        } else if sheet.submitted == true {
            approvedLabel.text = "Submitted"
            approvedLabel.textColor = Color.orange.base
            horizontalView.backgroundColor = Color.orange.base
        } else {
            approvedLabel.text = "Open"
            approvedLabel.textColor = Color.red.base
            horizontalView.backgroundColor = Color.red.base
        }

        if let startDate = sheet.date {
            
            let endDate = sheet.submissionDate ?? Date()
            let startTime = timeFormatter.string(from: startDate)
            let endTime = timeFormatter.string(from: endDate)
            
            let duration = -startDate.timeIntervalSince(endDate)
            let hours = clockHours(duration)
            let minutes = clockMinutes(duration)

            let timeString = String(format: "%@ - %@", startTime, endTime)
            let durationString = String(format: "%.0f hours %.0f minutes", hours, minutes)
            
            timespanLabel.text = timeString
            durationLabel.text = durationString
        } else {
            timespanLabel.text = nil
            durationLabel.text = nil
        }

        if let stats = sheet.statistics, sheet.submitted == true {
            let activityCount = stats.totalActivites
            var activityCountString: String
            if activityCount == 1 {
                activityCountString = String(format: "%i Activity", arguments: [activityCount])
            } else {
                activityCountString = String(format: "%i Activities", arguments: [activityCount])
            }

            let locationCount = stats.totalLocations
            var locationCountString: String
            if locationCount == 1 {
                locationCountString = String(format: "%i Location", arguments: [locationCount])
            } else {
                locationCountString = String(format: "%i Locations", arguments: [locationCount])
            }

            var distanceString: String = ""
            if let distance = stats.summary["distance"] as? Double {
                distanceString = String(format: "%0.1f mi", arguments: [distance * CONVERSION_METERS_TO_MILES_MULTIPLIER])
            }

            var entryCountString: String = ""
            if let entryCount = stats.summary["entries"] as? Int {
                if entryCount == 1 {
                    entryCountString = String(format: "%i Entry", arguments: [entryCount])
                } else {
                    entryCountString = String(format: "%i Entries", arguments: [entryCount])
                }
            }

            activityCountLabel.text = activityCountString
            locationCountLabel.text = locationCountString
            distanceLabel.text = distanceString
            entryCountLabel.text = entryCountString

        } else {
            activityCountLabel.text = nil
            locationCountLabel.text = nil
            distanceLabel.text = nil
            entryCountLabel.text = nil
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func applyTheme() {
    }
}
