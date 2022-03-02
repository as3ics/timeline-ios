//
//  StandardDescriptionCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/20/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class StandardDescriptionCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = StandardDescriptionCell

    static var reuseIdentifier: String = "StandardDescriptionCell"

    @IBOutlet var content: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_DESCRIPTION_FONT_SIZE

        content.font = content.font?.withSize(fontSize)
        content.masksToBounds = false

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))

        applyTheme()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        content.textColor = Theme.shared.active.subHeaderFontColor
        content.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        backgroundColor = Theme.shared.active.subHeaderBackgroundColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
