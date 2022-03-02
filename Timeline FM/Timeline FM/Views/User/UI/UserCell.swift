//
//  UserCell.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 7/1/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import UIKit
import Material

class UserCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = UserCell

    static var reuseIdentifier: String = "UserCell"
    static var cellHeight: CGFloat = 60.0
    
    @IBOutlet var icon: UIImageView!
    @IBOutlet var firstName: UILabel!
    @IBOutlet var lastName: UILabel!
    @IBOutlet var details: UILabel!
    @IBOutlet var indicator: UIImageView!

    var user: User?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        applyTheme()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        super.setSelected(false, animated: true)
        // Configure the view for the selected state
    }
    
    override func setHighlighted(_: Bool, animated _: Bool) {
        super.setHighlighted(false, animated: false)
    }

    func populate(_ user: User?) {
        self.user = user
        
        guard let user = self.user else {
            firstName.text = nil
            lastName.text = nil
            details.text = nil
            icon.image = nil
            return
        }

        firstName.text = user.firstName
        lastName.text = user.lastName
        details.text = Stream.shared[user.id]?.entry?.location?.name ?? Stream.shared[user.id]?.entry?.activity?.name ?? user.orgName
        indicator.alpha = Stream.shared[user.id]?.sheet != nil ? 0.9 : 0.0
        icon.image = user.profilePicture
    }

    @objc func applyTheme() {
        
        indicator.circle = true
        indicator.image = AssetManager.shared.indicator
        backgroundColor = UIColor.clear
        
        firstName.textColor = Theme.shared.active.primaryFontColor
        lastName.textColor = Theme.shared.active.primaryFontColor
        details.textColor = Theme.shared.active.secondaryFontColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        firstName.text = nil
        lastName.text = nil
        details.text = nil
        icon.image = nil
        
        self.gestureRecognizers?.removeAll()
    }
}
