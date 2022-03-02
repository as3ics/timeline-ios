//
//  PhotosHeaderView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/29/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import SnapKit

class PhotosHeaderView: UITableViewHeaderFooterView, NibProtocol, ThemeSupportedProtocol {
    typealias Item = PhotosHeaderView
    static var reuseIdentifier: String = "PhotosHeaderView"
    
    static let cellHeight: CGFloat = 40.0
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subLabel: UILabel!
    @IBOutlet var view: UIView!
    @IBOutlet var titleCenterConstraint: NSLayoutConstraint!
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func prepareForReuse() {
        titleLabel.text = nil
        subLabel.text = nil
        titleCenterConstraint.constant = 0.0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        applyTheme()
        
        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }
    
    @objc func applyTheme() {
        
        titleLabel.textColor = Theme.shared.active.primaryFontColor
        subLabel.textColor = Theme.shared.active.alternateIconColor
        
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }

}
