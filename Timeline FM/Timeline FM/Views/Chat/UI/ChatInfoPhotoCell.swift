//
//  ChatInfoPhotoCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 6/7/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class ChatInfoPhotoCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ChatInfoPhotoCell
    static var reuseIdentifier: String = "ChatInfoPhotoCell"

    @IBOutlet var image1: UIImageView!
    @IBOutlet var image2: UIImageView!

    var images: [UIImageView]!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        images = [image1, image2]

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
