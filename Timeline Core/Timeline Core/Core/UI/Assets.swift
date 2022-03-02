//
//  Assets.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import UIKit

class Assets {
    
    static let shared: Assets = Assets()
    
    var avatar: UIImage?
    var clear: UIImage?
    var cursor: UIImage?
    
    func initialize() {
        self.avatar = UIImage(named: "avatar")
        self.clear = UIImage(named: "clear")
        self.cursor = UIImage(named: "cursor")?.withRenderingMode(.alwaysTemplate)
    }
}
