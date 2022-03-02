//
//  SettingsBasicCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/10/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import UIKit

class SettingsBasicCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = SettingsBasicCell
    static var reuseIdentifier: String = "SettingsBasicCell"

    @IBOutlet var icon: UIImageView!
    @IBOutlet var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_SYSTEM_FONT_SIZE

        label.font = label.font?.withSize(fontSize)

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
        label.textColor = Theme.shared.active.primaryFontColor
        label.autoResize()
    }
}
