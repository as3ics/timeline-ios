//
//  ChatAddUserCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/11/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UICheckbox_Swift
import UIKit

class ChatAddUserCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ChatAddUserCell
    static var reuseIdentifier: String = "ChatAddUserCell"

    @IBOutlet var avatar: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var checkbox: UICheckbox!

    var user: User?

    override func awakeFromNib() {
        super.awakeFromNib()

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func populate(_ user: User) {
        self.user = user

        self.avatar.image = user.profilePicture

        if let firstName = user.firstName, let lastName = user.lastName {
            nameLabel.text = String(format: "%@ %@", arguments: [firstName, lastName])
        }

        checkbox.isSelected = false
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
    }
}
