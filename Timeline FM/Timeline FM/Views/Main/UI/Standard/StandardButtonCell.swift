//
//  EditButtonTableViewCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 2/17/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class StandardButtonCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = StandardButtonCell
    static var reuseIdentifier: String = "StandardButtonCell"

    @IBOutlet var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_BUTTON_FONT_SIZE
        /*
         if(deviceUser.miniScreenHeight == true) {
         fontSize = formsButtonMiniFontSize
         } else if(deviceUser.smallScreenHeight == true) {
         fontSize = formsButtonSmallFontSize
         }
         */

        label.font = label.font?.withSize(fontSize)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        label.textColor = Theme.shared.active.alternativeFontColor
        label.autoResize()
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
