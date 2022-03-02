//
//  LocationCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/7/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import MapKit
import Material
import UIKit

class LocationCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = LocationCell

    @IBOutlet var line1: UILabel!
    @IBOutlet var line2: UILabel!
    @IBOutlet var line3: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var snapshot: UIImageView!
    @IBOutlet var indicator: UIImageView!

    let normalFontSize: CGFloat = 12.0

    let fontSizeDifference: CGFloat = -2.0

    weak var location: Location?

    static var reuseIdentifier: String = "LocationCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        let fontSize: CGFloat = 14.0

        line1.font = line1.font.withSize(fontSize)
        line2.font = line2.font.withSize(fontSize + fontSizeDifference)
        line3.font = line3.font.withSize(fontSize + fontSizeDifference)

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
        NotificationManager.shared.new_latest_location.observe(self, selector: #selector(updateDistance))

        applyTheme()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        super.setSelected(false, animated: true)
        // Configure the view for the selected state
    }
    
    override func setHighlighted(_: Bool, animated _: Bool) {
        super.setHighlighted(false, animated: false)
    }

    func populate(_ location: Location) {
        self.location = location
        
        self.snapshot.image = location.dequeSnapshot()
        
        if let name = location.name, let address = location.addressString {
            line1.text = name
            line2.text = address
            
            let count = location.presentUsers().count
            
            line3.text = count == 1 ? String(format: "%i User", count) : String(format: "%i Users", count)
            indicator.alpha = count > 0 ? 0.9 : 0.0
        } else {
            line1.text = nil
            line2.text = nil
            line3.text = nil
            indicator.alpha = 0.0
        }

        if location.distance != Double.greatestFiniteMagnitude {
            distanceLabel.text = String(format: "%0.1f mi", arguments: [location.distance * CONVERSION_METERS_TO_MILES_MULTIPLIER])
        } else {
            distanceLabel.text = nil
        }
    }
    
    func refresh() {
        if let distance = location?.distance {
            distanceLabel.text = String(format: "%0.1f mi", arguments: [distance * CONVERSION_METERS_TO_MILES_MULTIPLIER])
        } else {
            distanceLabel.text = nil
        }
        
        self.snapshot.image = location?.dequeSnapshot()
    }

    @objc func updateDistance() {
        if let distance = self.location?.distance {
            distanceLabel.text = String(format: "%0.1f mi", arguments: [distance * CONVERSION_METERS_TO_MILES_MULTIPLIER])
        } else {
            distanceLabel.text = nil
        }
    }

    @objc func applyTheme() {
        indicator.circle = true
        indicator.image = AssetManager.shared.indicator
        
        snapshot.circle = true
        
        backgroundColor = UIColor.clear
        line1.textColor = Theme.shared.active.primaryFontColor
        line2.textColor = Theme.shared.active.secondaryFontColor
        line3.textColor = Theme.shared.active.secondaryFontColor
        distanceLabel.textColor = Theme.shared.active.primaryFontColor
        self.alpha = 0.9
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
