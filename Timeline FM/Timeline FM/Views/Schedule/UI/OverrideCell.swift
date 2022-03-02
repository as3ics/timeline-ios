//
//  OverrideCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/29/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class OverrideCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = OverrideCell
    static var reuseIdentifier: String = "OverrideCell"

    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var upperDateLabel: UILabel!
    @IBOutlet var lowerDateLabel: UILabel!

    let miniScreenFontSize: CGFloat = 10.0
    let smallScreenFontSize: CGFloat = 12.0
    let normalScreenFontSize: CGFloat = 14.0
    let titleSizeDifference: CGFloat = 2.0

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = normalScreenFontSize
        /*
         if(deviceUser.miniScreenHeight == true) {
         fontSize = miniScreenFontSize
         } else if(deviceUser.smallScreenHeight == true) {
         fontSize = smallScreenFontSize
         }
         */

        titleLabel.font = titleLabel.font.withSize(fontSize + titleSizeDifference)
        numberLabel.font = numberLabel.font.withSize(fontSize + titleSizeDifference)
        typeLabel.font = typeLabel.font.withSize(fontSize)
        upperDateLabel.font = upperDateLabel.font.withSize(fontSize)
        lowerDateLabel.font = lowerDateLabel.font.withSize(fontSize)

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
