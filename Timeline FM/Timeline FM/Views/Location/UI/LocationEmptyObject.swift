//
//  LocationEmptyObject.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/30/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation
import MapKit
import Material

class LocationEmptyObject: UIView, NibProtocol, ThemeSupportedProtocol {
    typealias Item = LocationEmptyObject
    static var reuseIdentifier: String = "LocationEmptyObject"
    
    @IBOutlet var icon: UIImageView!
    @IBOutlet var label: UILabel!
    
    var index: Int = -1
    
    static var size: CGSize {
        return CGSize(width: 210, height: 125)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cardPressed)))
        
        applyTheme()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func cardPressed(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            Location().create()
        }
    }
    
    @objc func applyTheme() {
        self.backgroundColor = UIColor.clear
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
