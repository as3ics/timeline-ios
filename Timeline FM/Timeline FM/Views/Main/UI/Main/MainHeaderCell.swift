//
//  MainHeaderCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/15/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Material
import UIKit

class MainHeaderCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = MainHeaderCell
    static var reuseIdentifier: String = "MainHeaderCell"
    static var cellHeight: CGFloat = MainValueCell.cellHeight
    
    @IBOutlet var title: UILabel!
    @IBOutlet var view: UIView!
    @IBOutlet var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.applyTheme()
        
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
    
    func setIndex(_ index: Int, of: Int) {
        self.label.text = String(format: "%i of %i", index, of)
    }
    
    @objc func applyTheme() {
        self.view.backgroundColor = Theme.shared.active.placeholderColor
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
