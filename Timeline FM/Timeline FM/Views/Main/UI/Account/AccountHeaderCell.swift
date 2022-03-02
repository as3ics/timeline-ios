//
//  AccountHeaderCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/20/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import Material

// Custom Cell with value type: Bool
// The cell is defined using a .xib, so we can set outlets :)
class AccountHeaderCell: UITableViewCell, NibProtocol {
    typealias Item = AccountHeaderCell
    static var reuseIdentifier: String = "AccountHeaderCell"
    
    static let cellHeight: CGFloat = 130.0
    
    @IBOutlet var typeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.typeLabel.textColor = Color.darkGray
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
