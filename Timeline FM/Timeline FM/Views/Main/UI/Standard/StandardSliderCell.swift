//
//  StandardSliderCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/6/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import UIKit

class StandardSliderCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = StandardSliderCell
    static var reuseIdentifier: String = "StandardSliderCell"

    @IBOutlet var slider: UISlider!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_SYSTEM_FONT_SIZE

        titleLabel.font = titleLabel.font.withSize(fontSize)
        label.font = label.font.withSize(fontSize - 3.0)

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))

        applyTheme()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = Theme.shared.active.secondaryBackgroundColor
        titleLabel.textColor = Theme.shared.active.primaryFontColor
        label.textColor = Theme.shared.active.subHeaderFontColor
        slider.thumbTintColor = Theme.shared.active.subHeaderBackgroundColor
        titleLabel.autoResize()
        label.autoResize()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
