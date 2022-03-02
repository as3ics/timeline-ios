//
//  SettingsSelectionCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/10/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import UIKit

class SettingsSelectionCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = SettingsSelectionCell
    static var reuseIdentifier: String = "SettingsSelectionCell"

    @IBOutlet var carotImage: UIImageView!
    @IBOutlet var label: UILabel!
    @IBOutlet var selectorLabel: UILabel!
    @IBOutlet var icon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_SYSTEM_FONT_SIZE

        icon.image = UIImage(named: "language")?.withRenderingMode(.alwaysTemplate)
        
        label.font = label.font?.withSize(fontSize)
        selectorLabel.font = selectorLabel.font?.withSize(fontSize)

        carotImage.image = carotImage.image?.withRenderingMode(.alwaysTemplate)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        icon.tintColor = Theme.shared.active.alternateIconColor
        label.textColor = Theme.shared.active.primaryFontColor
        selectorLabel.textColor = Theme.shared.active.placeholderColor
        carotImage.tintColor = Theme.shared.active.placeholderColor
        label.autoResize()
        selectorLabel.autoResize()
        backgroundColor = UIColor.clear
    }
}
