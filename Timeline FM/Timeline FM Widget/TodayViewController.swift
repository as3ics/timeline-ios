//
//  TodayViewController.swift
//  Timeline Widget
//
//  Created by Zachary DeGeorge on 3/30/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet var leftTitle: UILabel!
    @IBOutlet var rightTitle: UILabel!
    @IBOutlet var activityLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var shiftDurationLabel: UILabel!
    @IBOutlet var milesLabel: UILabel!
    @IBOutlet var footerLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateTask()
        
        timer = Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(self.updateTask), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var timer : Timer?
    
    @objc func updateTask() {
        // Do something
        
        let totalDurationValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "totalDurationString")
        let totalDistanceValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "totalDistanceString")
        let entryDurationValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "entryDurationString")
        let activityNameValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "activityNameString")
        let locationNameValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "locationNameString")
        let entryDistanceValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "entryDistanceString")
        let footerValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "footerText")
        
        //let locationAddressValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "locationAddressString")
        //let entryTimespanValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "entryTimespanString")
        
        if(footerValue as? String != "")
        {
            if(activityNameValue as? String == "Traveling" )
            {
                self.activityLabel.text = activityNameValue as? String
                self.locationLabel.text = entryDurationValue as? String
                self.addressLabel.text = entryDistanceValue as? String
                self.shiftDurationLabel.text = totalDurationValue as? String
                self.milesLabel.text = totalDistanceValue as? String
                self.footerLabel.text = footerValue as? String
                self.rightTitle.text = "Shift Totals"
                self.leftTitle.text = "Current Entry"
            }
            else if(activityNameValue as? String == "Break")
            {
                self.activityLabel.text = activityNameValue as? String
                self.locationLabel.text = entryDurationValue as? String
                self.addressLabel.text = ""
                self.shiftDurationLabel.text = totalDurationValue as? String
                self.milesLabel.text = totalDistanceValue as? String
                self.footerLabel.text = footerValue as? String
                self.rightTitle.text = "Shift Totals"
                self.leftTitle.text = "Current Entry"
            }
            else if(activityNameValue as? String == "No Active Timesheet")
            {
                self.activityLabel.text = ""
                self.locationLabel.text = ""
                self.addressLabel.text = ""
                self.shiftDurationLabel.text = ""
                self.milesLabel.text = ""
                self.footerLabel.text = footerValue as? String
                self.rightTitle.text = ""
                self.leftTitle.text = activityNameValue as? String
            }
            else
            {
                self.activityLabel.text = activityNameValue as? String
                self.locationLabel.text = locationNameValue as? String
                self.addressLabel.text = entryDurationValue as? String
                self.shiftDurationLabel.text = totalDurationValue as? String
                self.milesLabel.text = totalDistanceValue as? String
                self.footerLabel.text = footerValue as? String
                self.rightTitle.text = "Shift Totals"
                self.leftTitle.text = "Current Entry"
            }
            //completionHandler(NCUpdateResult.newData)
        }
        else
        {
            //completionHandler(NCUpdateResult.noData)
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        if let footerValue = UserDefaults.init(suiteName: "group.com.timelinefm.iPhone")?.value(forKey: "footerText") as? String, footerValue != "" {
            completionHandler(NCUpdateResult.newData)
        } else {
            completionHandler(NCUpdateResult.noData)
        }
    }
}
