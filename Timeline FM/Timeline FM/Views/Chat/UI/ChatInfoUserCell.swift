//
//  ChatInfoUserCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 6/7/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class ChatInfoUserCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ChatInfoUserCell
    static var reuseIdentifier: String = "ChatInfoUserCell"

    @IBOutlet var label: UILabel!
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var icon: UIImageView!

    var user: User?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        icon.image = AssetManager.shared.profile
        avatar.circle = true
        
        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func populate(_ user: User?) {
        self.user = user

        guard let user = self.user else {
            label.text = nil
            avatar.image = AssetManager.shared.avatar
            return
        }

        self.avatar.image = user.profilePicture

        label.text = user.fullName
    }

    @objc func applyTheme() {
        backgroundColor = Theme.shared.active.secondaryBackgroundColor
        
        icon.tintColor = Theme.shared.active.alternateIconColor
        
        avatar.backgroundColor = UIColor.white
    }
}
