//
//  AccountButtonCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/20/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import Material

class AccountButtonCell: UITableViewCell, NibProtocol {
    typealias Item = AccountButtonCell
    static var reuseIdentifier: String = "AccountButtonCell"
    
    static let cellHeight: CGFloat = 65.0
    
    @IBOutlet var button: FlatButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.button.style(Color.blue.base, image: nil, title: "Next")
        self.button.corner = 7.5
        self.backgroundColor = UIColor.white
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
