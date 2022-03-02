//
//  SettingsOrgCodeCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 12/20/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import UIKit

class SettingsOrgCodeCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = SettingsOrgCodeCell
    static var reuseIdentifier: String = "SettingsOrgCodeCell"

    @IBOutlet var humanIdLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var icon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_SYSTEM_FONT_SIZE

        humanIdLabel.font = humanIdLabel.font?.withSize(fontSize)
        titleLabel.font = titleLabel.font?.withSize(fontSize)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
        humanIdLabel.autoResize()
    }
}
