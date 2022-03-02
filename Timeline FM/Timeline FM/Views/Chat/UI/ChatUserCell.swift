//
//  ChatUserCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/11/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class ChatUserCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ChatUserCell
    static var reuseIdentifier: String = "ChatUserCell"

    @IBOutlet var avatar: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var removeButton: UIImageView!

    weak var user: User?

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

        if let firstName = user.firstName, let lastName = user.lastName {
            nameLabel.text = String(format: "%@ %@", arguments: [firstName, lastName])
        }

        avatar.image = user.profilePicture
    }

    @objc func applyTheme() {
        backgroundColor = Theme.shared.active.secondaryBackgroundColor
    }
}
