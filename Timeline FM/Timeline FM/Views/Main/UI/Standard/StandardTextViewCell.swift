//
//  EditEntryTextTableViewCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/19/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class StandardTextViewCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = StandardTextViewCell
    static var reuseIdentifier: String = "StandardTextViewCell"

    @IBOutlet var contents: UITextView!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_SYSTEM_FONT_SIZE

        contents.font = contents.font?.withSize(fontSize)

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))

        applyTheme()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = Theme.shared.active.secondaryBackgroundColor
        contents.backgroundColor = UIColor.clear
        contents.textColor = Theme.shared.active.primaryFontColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
