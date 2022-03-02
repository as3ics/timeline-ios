//
//  Cursor.swift
//  Timeline Core
//
//  Created by Zachary DeGeorge on 12/27/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Pulsar

let AnimationDuration: TimeInterval = 0.6

class Cursor {
    
    
    var parent: UIViewController
    private var cursor: UIImageView
    
    var color: UIColor {
        didSet {
            self.cursor.tintColor = color
        }
    }
    
    init(parent: UIViewController) {
        self.parent = parent
        self.cursor = UIImageView(frame: CGRect.zero)
        self.cursor.contentMode = .scaleAspectFit
        self.cursor.image = Assets.shared.cursor
        self.cursor.alpha = 0.0
        self.color = UIColor.black
        self.parent.view.addSubview(self.cursor)
        
        self.cursor.snp.makeConstraints { (make) in
            make.center.equalTo(self.parent.view.snp.center)
            make.height.equalTo(65)
            make.width.equalTo(60)
        }
    }
    
    var count: Int = 0
    func move(point: CGPoint, animated: Bool = true, duration: TimeInterval = AnimationDuration) {
        count += 1
        self.parent.view.bringSubview(toFront: self.cursor)
        UIView.animate(withDuration: animated ? duration : 0.0) {
            if(self.count == 1) {
                self.cursor.snp.makeConstraints({ (make) in
                    make.center.equalTo(point)
                })
            } else {
                self.cursor.snp.updateConstraints({ (make) in
                    make.center.equalTo(point)
                })
            }
            
            self.parent.view.layoutIfNeeded()
        }
    }
    
    func show(animated: Bool = true, duration: TimeInterval = AnimationDuration) {
        
        UIView.animate(withDuration: animated ? duration : 0.0) {
            self.cursor.alpha = 0.9
        }
    }
    
    func press() {
        self.cursor.touchAnimation(true)
        self.cursor.layer.addPulse { pulse in
            pulse.borderColors = [UIColor.darkGray.cgColor, UIColor.darkGray.cgColor]
            pulse.backgroundColors = colorsWithOpacity([UIColor.darkGray.cgColor, UIColor.darkGray.cgColor], 0.45)
            pulse.path = UIBezierPath(ovalIn: self.cursor.bounds.offsetBy(dx: -self.cursor.bounds.width / 2, dy: -self.cursor.bounds.height)).cgPath
            pulse.transformBefore = CATransform3DMakeScale(0.1, 0.1, 0.1)
            pulse.transformAfter = CATransform3DMakeScale(1.2, 1.2, 1.2)
            pulse.duration = 1.5
            pulse.repeatDelay = 0.5
            pulse.lineWidth = 0.0
        }
    }
}
