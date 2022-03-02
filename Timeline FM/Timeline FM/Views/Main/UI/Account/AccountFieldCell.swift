//
//  AccountFieldCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/20/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import Material

class AccountFieldCell: UITableViewCell, NibProtocol {
    typealias Item = AccountFieldCell
    static var reuseIdentifier: String = "AccountFieldCell"
    
    static let cellHeight: CGFloat = 85.0
    @IBOutlet var field: TextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.field.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16.0)
        self.field.detailLabel.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 12.0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
