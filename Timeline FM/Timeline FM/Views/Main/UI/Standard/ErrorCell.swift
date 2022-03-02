//
//  ScheduleErrorCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class ErrorCell: UITableViewCell, ThemeSupportedProtocol {
    @IBOutlet var label: UILabel!
    @IBOutlet var _image: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        _image.image = _image.image?.withRenderingMode(.alwaysTemplate)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
        _image.tintColor = Theme.shared.active.primaryFontColor
        label.textColor = Theme.shared.active.primaryFontColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
