//
//  ScheduleDayCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/26/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UICheckbox_Swift
import UIKit

class ScheduleDayCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ScheduleDayCell
    static var reuseIdentifier: String = "ScheduleDayCell"

    @IBOutlet var checkbox: UICheckbox!
    @IBOutlet var startTime: UILabel!
    @IBOutlet var endTime: UILabel!
    @IBOutlet var spacer: UILabel!
    @IBOutlet var dayImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    func setStart(_ time: String) {
        startTime.text = time
    }

    func setEnd(_ time: String) {
        endTime.text = time
    }

    func setDayTextColor(_ color: UIColor) {
        spacer.textColor = color
        startTime.textColor = color
        endTime.textColor = color
    }

    func setAlpha(_ alpha: CGFloat) {
        dayImage.alpha = alpha
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
        dayImage.image = dayImage.image?.withRenderingMode(.alwaysTemplate)
        dayImage.tintColor = Theme.shared.active.alternativeFontColor
        checkbox.tintColor = Theme.shared.active.alternativeFontColor
        checkbox.backgroundColor = UIColor.clear
    }
}
