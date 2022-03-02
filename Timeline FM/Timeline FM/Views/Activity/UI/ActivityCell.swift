//
//  ReviewActivityCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/7/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import UIKit

class ActivityCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ActivityCell
    static var reuseIdentifier: String = "ActivityCell"

    @IBOutlet var nameLabel: UILabel!
    
    static let cellHeight: CGFloat = 42.5

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        backgroundColor = UIColor.clear

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))

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

    func populate(_ activity: Activity) {
        nameLabel.text = activity.name
    }

    @objc func applyTheme() {
        nameLabel.textColor = Theme.shared.active.primaryFontColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
