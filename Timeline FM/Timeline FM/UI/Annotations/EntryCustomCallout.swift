//
//  EntryCustomCallout.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/23/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Material

class EntryCustomCallout: UIView, NibProtocol {
    typealias Item = EntryCustomCallout
    static var reuseIdentifier: String = "EntryCustomCallout"
    static let size = CGSize(width: 200, height: 105)
    
    var index: Int = -1
    var entry: Entry!
    var location: Location! {
        return entry.location
    }
    
    @IBOutlet var image: UIImageView!
    @IBOutlet var date: UILabel!
    @IBOutlet var locationName: UILabel!
    @IBOutlet var activity: UILabel!
    @IBOutlet var duration: UILabel!
    @IBOutlet var timespanLabel: UILabel!
    @IBOutlet var indexLabel: UILabel!
    
    
    var timer_1000ms: Timer?
    var formatter = DateFormatter()
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        formatter.dateFormat = "h:mm a"
        
        locationName.textColor = Theme.shared.active.primaryFontColor
        indexLabel.textColor = Theme.shared.active.primaryFontColor
        duration.textColor = UIColor.darkGray
        timespanLabel.textColor = UIColor.darkGray
        activity.textColor = Theme.shared.active.alternativeFontColor
        
        layer.masksToBounds = true
        layer.cornerRadius = 7.5
        
        self.shadowOffset = CGSize(width: 1.0, height: 5.0)
        self.shadowRadius = 15.0
        self.shadowColor = UIColor.black
        self.shadowOpacity = 0.6
        
        backgroundColor = Theme.shared.active.primaryBackgroundColor //Theme.shared.active.primaryBackgroundColor
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goViewEntry)))
        Notifications.shared.model_updated.observe(self, selector: #selector(update))
        
        
    }
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate else {
            return
        }
        
        if let entry = update.model as? Entry, entry.sheet?.id == self.entry?.sheet?.id {
            self.update()
        }
    }
    
    func populate(_ entry: Entry?) {
        guard let entry = entry else {
            return
        }
        
        self.entry = entry
        self.locationName.text = location.name
        //self.image.setImage(image: location.dequeSnapshot())
        
        if let start = entry.start {
            let formatter: DateFormatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            
            date.text = formatter.string(from: start)
        } else {
            date.text = nil
        }
        
        self.update()
    }
    
    func observeUpdates() {
        if entry.sheet?.id == DeviceUser.shared.sheet?.id, let entries = entry.sheet?.entries, let index = entries.index(id: entry.id), index == 0 {
            
            timer_1000ms?.invalidate()
            timer_1000ms = nil
            timer_1000ms = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
                
                print("Timer - Entry Custom Callout")
                
                self.update()
                
                if DeviceUser.shared.sheet?.id == self.entry.sheet?.id, let index = self.entry.sheet?.entries.index(id: self.entry.id), index != 0 {
                    timer.invalidate()
                    self.timer_1000ms?.invalidate()
                    self.timer_1000ms = nil
                }
            })
            
            timer_1000ms?.fire()
        }
    }
    
    func unobserveUpdates() {
        self.timer_1000ms?.invalidate()
        self.timer_1000ms = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func update() {
        
        var activityString: String?
        if let activityName = entry.activity?.name {
            activityString = activityName
        }
        
        var durationString: String?
        if let entries = entry.sheet?.entries, let index = entries.index(id: entry?.id), let duration = entry.sheet?.duration(index: index) {
            durationString = String(format: "%.0fh %0.fm %0.fs", arguments:[clockHours(duration), clockMinutes(duration), clockSeconds(duration)])
            
        }
        
        // Set timespan string
        var timespanText: String?
        var indexString: String?
        if let entries = entry.sheet?.entries, let index = entries.index(id: entry?.id) {
            if entry.sheet?.submissionDate == nil, index == 0, let startString = entry.startString {
                timespanText = String(format: "%@ - Now", arguments: [startString])
            } else if entry.sheet?.submissionDate != nil, index == 0 {
                let start = entry.start!
                let end = entry.sheet!.submissionDate!
                timespanText = String(format: "%@ - %@", arguments: [self.formatter.string(from: start), self.formatter.string(from: end)])
            } else if let previousEntry = entries[index - 1], let previousStartString = previousEntry.startString, let startString = entry.startString {
                timespanText = String(format: "%@ - %@", arguments: [startString, previousStartString])
            }
            
            let maxIndex = entries.count
            indexString = String(format: "Entry %i of %i",  maxIndex - index, maxIndex)
        }
        
        DispatchQueue.main.async {
            self.activity.text = activityString
            self.indexLabel.text = indexString
            self.duration.text = durationString
            self.timespanLabel.text = timespanText
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func goViewEntry(_ sender: UITapGestureRecognizer) {
        
        sender.view?.touchAnimation()
        
        delay(0.2) {
            let destination = UIStoryboard.Main(identifier: "EntryReview") as! EntryReview
            
            destination.sheet = self.entry?.sheet
            destination.index = self.entry?.sheet?.entries.index(id: self.entry?.id)
            destination.entry = self.entry
            
            Presenter.push(destination, animated: true, completion: nil)
        }
    }
}
