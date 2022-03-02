//
//  SettingsSwitchCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/15/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import UIKit
import Material

class SettingsSwitchCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = SettingsSwitchCell
    static var reuseIdentifier: String = "SettingsSwitchCell"

    @IBOutlet var icon: UIImageView!
    @IBOutlet var label: UILabel!
    @IBOutlet var onSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        onSwitch.layer.masksToBounds = true
        onSwitch.layer.cornerRadius = onSwitch.layer.height / 2

        let fontSize: CGFloat = DEFAULT_SYSTEM_FONT_SIZE

        label.font = label.font.withSize(fontSize)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
        icon.tintColor = Theme.shared.active.alternateIconColor
        onSwitch.thumbTintColor = Theme.shared.active.secondaryBackgroundColor
        onSwitch.tintColor = Theme.shared.active.secondaryBackgroundColor
        onSwitch.onTintColor = Theme.shared.active.alternativeFontColor
        label.textColor = Theme.shared.active.primaryFontColor
        label.autoResize()
    }
}
