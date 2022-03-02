//
//  OverrideTitleCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/27/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class OverrideTextInputCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = OverrideTextInputCell
    static var reuseIdentifier: String = "OverrideTextInputCell"

    @IBOutlet var textInput: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

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
