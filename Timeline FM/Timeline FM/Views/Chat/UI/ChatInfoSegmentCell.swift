//
//  ChatInfoSegmentCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 6/7/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class ChatInfoSegmentCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ChatInfoSegmentCell
    static var reuseIdentifier: String = "ChatInfoSegmentCell"

    @IBOutlet var segment: UISegmentedControl!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16.0)
        segment.setTitleTextAttributes([NSAttributedStringKey.font: font!], for: .normal)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear // Theme.shared.active.secondaryBackgroundColor
    }
}
