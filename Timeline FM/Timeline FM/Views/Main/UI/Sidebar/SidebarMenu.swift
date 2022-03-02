//
//  SidebarMenuCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/3/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import Material
import UIKit

class SidebarMenu: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = SidebarMenu
    static var reuseIdentifier: String = "SidebarMenu"

    @IBOutlet var label: UILabel!
    @IBOutlet var view: UIView!
    @IBOutlet var indicatorView: UIView!
    @IBOutlet var indicatorLabel: UILabel!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var button: FlatButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    func populate(_ section: String, _ icon: String) {
        label.text = section
        self.icon.image = UIImage(named: icon)?.withRenderingMode(.alwaysTemplate)
        self.icon.tintColor = UIColor.white.withAlphaComponent(0.9)

        indicatorView.alpha = 0.0
    }
    
    func setIndicator(count: Int?) {
        
        Notifications.shared.badge_updated.observe(self, selector: #selector(updateIndicator))
        
        guard let value = count, value > 0 else {
            indicatorView.alpha = 0.0
            return
        }
        
        indicatorView.alpha = 1.0
        indicatorLabel.text = String(format: "%d", value)
    }
    
    @objc func updateIndicator(_ sender: Any?) {
        
        let value = Chatrooms.shared.unreadMessages
        
        guard value > 0 else {
            indicatorView.alpha = 0.0
            return
        }
        
        indicatorView.alpha = 1.0
        indicatorLabel.text = String(format: "%d", value)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
    }
}
