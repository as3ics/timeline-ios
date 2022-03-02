//
//  PhotoFooterCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/28/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class PhotoFooterCell: UITableViewCell, NibProtocol, ThemeSupportedProtocol {
    typealias Item = PhotoFooterCell
    static var reuseIdentifier: String = "PhotoFooterCell"
    
    static let cellHeight: CGFloat = 100.0
    
    @IBOutlet var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        applyTheme()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func applyTheme() {
        self.backgroundColor = UIColor.clear
    }
    
    func populate(count: Int) {
        
        label.text = String(format: "%i Photos", count)
        
    }
    
}
