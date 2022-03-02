//
//  SidebarHeaderCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/3/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import Pulsar
import UIKit

class SidebarHeader: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = SidebarHeader
    static var reuseIdentifier: String = "SidebarHeader"

    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var companyLabel: UILabel!

    @IBOutlet var shiftsLabel: UILabel!
    @IBOutlet var hoursLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    
    var user: User?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    func populate(_ user: User?) {
        
        self.user = user
        
        profileImageView.image = user?.profilePicture
        
        profileImageView.borderWidth = 0.0

        let firstName = user?.firstName ?? "John"
        let lastName = user?.lastName ?? "Doe"
        nameLabel.text = String(format: "%@ %@", arguments: [firstName, lastName])

        let org = user?.orgName ?? "Timeline"
        companyLabel.text = String(format: "%@", arguments: [org])

        shiftsLabel.text = String(format: "%i", (user?.statistics?.shifts ?? 0)!)
        hoursLabel.text = String(format: "%.0f", (user?.statistics?.hours ?? 0)!)
        distanceLabel.text = String(format: "%.0f", (user?.statistics?.distance ?? 0)! * CONVERSION_METERS_TO_MILES_MULTIPLIER)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
    }
}
