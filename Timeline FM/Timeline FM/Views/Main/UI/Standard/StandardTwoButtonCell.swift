//
//  StandardTwoButtonCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/20/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import Material

class StandardTwoButtonCell: UITableViewCell, NibProtocol {
    typealias Item = StandardTwoButtonCell
    static var reuseIdentifier: String = "StandardTwoButtonCell"
    
    @IBOutlet var leftButton: FlatButton!
    @IBOutlet var rightButton: FlatButton!
    
    static let cellHeight: CGFloat = 50.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.leftButton.corner = 7.5
        self.leftButton.titleLabel?.sizeToFit()
        
        self.rightButton.corner = 7.5
        self.rightButton.titleLabel?.sizeToFit()
        
        self.backgroundColor = UIColor.clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.leftButton.removeTargets()
        self.rightButton.removeTargets()
    }
    
}
