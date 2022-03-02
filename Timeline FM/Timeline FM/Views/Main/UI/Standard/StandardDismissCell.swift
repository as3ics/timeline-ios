//
//  StandardDismissCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 6/23/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class StandardDismissCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = StandardDismissCell
    static var reuseIdentifier: String = "StandardDismissCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
    }
}
