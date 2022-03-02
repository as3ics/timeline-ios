//
//  EditEntryHeaderTableViewCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/2/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class StandardHeaderCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = StandardHeaderCell
    static var reuseIdentifier: String = "StandardHeaderCell"

    @IBOutlet var title: UILabel!
    @IBOutlet var footer: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_SYSTEM_FONT_SIZE

        title.font = title.font.withSize(fontSize)
        footer.font = footer.font?.withSize(fontSize)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        title.textColor = Theme.shared.active.subHeaderFontColor
        footer.textColor = Theme.shared.active.subHeaderFontColor
        footer.font = Device.phoneType == .iPhone5 ? footer.font.withSize(footer.font.pointSize - 2.0) : footer.font
        title.autoResize()
        footer.autoResize()
        backgroundColor = Theme.shared.active.subHeaderBackgroundColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
