//
//  EditEntryFieldTableViewCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/19/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class StandardTextFieldCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = StandardTextFieldCell
    static var reuseIdentifier: String = "StandardTextFieldCell"

    @IBOutlet var label: UILabel!
    @IBOutlet var carrot: UIImageView!
    @IBOutlet var contents: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let fontSize: CGFloat = DEFAULT_SYSTEM_FONT_SIZE

        carrot.image = carrot.image?.withRenderingMode(.alwaysTemplate)

        label.font = label.font.withSize(fontSize)
        contents.font = contents.font?.withSize(fontSize)

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    var placeholder: String? {
        didSet {
            contents.attributedPlaceholder = NSAttributedString(string: placeholder ?? "",
                                                                attributes: [NSAttributedStringKey.foregroundColor: Theme.shared.active.placeholderColor])
        }
    }

    @objc func applyTheme() {
        backgroundColor = Theme.shared.active.secondaryBackgroundColor
        label.textColor = Theme.shared.active.primaryFontColor
        contents.textColor = Theme.shared.active.secondaryFontColor
        carrot.tintColor = Theme.shared.active.placeholderColor
        contents.autoResize()
        // self.label.autoResize()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.gestureRecognizers?.removeAll()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
