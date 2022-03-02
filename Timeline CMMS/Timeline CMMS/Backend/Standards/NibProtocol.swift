//
//  NibProtocol.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/12/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import UIKit

protocol NibProtocol {
    associatedtype Item
    
    static var reuseIdentifier: String { get }
}

extension NibProtocol {
    static func loadNib(_ tableView: UITableView) -> Item {
        return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! Item
    }
    
    static func register(_ tableView: UITableView) {
        tableView.register(UINib(nibName: reuseIdentifier, bundle: Bundle.main), forCellReuseIdentifier: reuseIdentifier)
    }
    
    static func loadNib() -> Item? {
        let nib = Bundle.main.loadNibNamed(reuseIdentifier, owner: self, options: nil)?[0] as? Item
        return nib
    }
}
