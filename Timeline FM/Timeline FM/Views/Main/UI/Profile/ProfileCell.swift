//
//  ProfileCellBasic.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/6/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class ProfileCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ProfileCell
    static var reuseIdentifier: String = "ProfileCell"

    @IBOutlet var content: UILabel!
    @IBOutlet var title: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_SYSTEM_FONT_SIZE

        content.font = content.font?.withSize(fontSize)
        title.font = title.font?.withSize(fontSize)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = Theme.shared.active.secondaryBackgroundColor
        content.textColor = Theme.shared.active.secondaryFontColor
        title.textColor = Theme.shared.active.primaryFontColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
