//
//  SidebarFooterCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/3/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import UIKit

class SidebarFooter: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = SidebarFooter
    static var reuseIdentifier: String = "SidebarFooter"

    @IBOutlet var label: UILabel!
    @IBOutlet var aboutLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    func populate() {
        label.text = version()
    }

    func version() -> String {
        let dictionary = Bundle.main.infoDictionary!

        var value: String = ""
        if let version = dictionary["CFBundleShortVersionString"] as? String, let build = dictionary["CFBundleVersion"] as? String {
            value = String(format: "Version %@ (Build %@)", arguments: [version, build])
        }

        return value
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
    }
}
