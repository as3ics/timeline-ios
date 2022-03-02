//
//  MainValueCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/15/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Material
import UIKit

class MainValueCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = MainValueCell
    static var reuseIdentifier: String = "MainValueCell"
    static var cellHeight: CGFloat = 30.0
    
    @IBOutlet var title: UILabel!
    @IBOutlet var value: UILabel!
    @IBOutlet var view: UIView!
    @IBOutlet var nibble1: UIView!
    @IBOutlet var nibble2: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyTheme()
        
        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        super.setSelected(false, animated: false)
        // Configure the view for the selected state
    }
    
    override func setHighlighted(_: Bool, animated _: Bool) {
        super.setHighlighted(false, animated: false)
    }
    
    @objc func applyTheme() {
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        nibble1.backgroundColor = UIColor.clear // UIColor.lightGray
        nibble2.backgroundColor = UIColor.clear // UIColor.lightGray
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
