//
//  OverrideSwitchCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/26/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class OverrideSwitchCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = OverrideSwitchCell
    static var reuseIdentifier: String = "OverrideSwitchCell"

    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var selector: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setOn() {
        titleLabel.text = "Automate Schedule"
    }

    func setOff() {
        titleLabel.text = "Time Off"
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
    }
}
