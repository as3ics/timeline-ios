//
//  UserClusterCustomCallout.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/2/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit


import Foundation
import CoreLocation
import MapKit
import Material

class UserClusterCustomCallout: UIView, UIScrollViewDelegate, NibProtocol, ThemeSupportedProtocol {
    typealias Item = UserClusterCustomCallout
    static var reuseIdentifier: String = "UserClusterCustomCallout"
    
    @IBOutlet var scrollView: UIScrollView!
    
    var objects: [UserCustomCallout] = [UserCustomCallout]()
    var subscriptions: [Subscription] = [Subscription]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        scrollView.delegate = self
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = true
        
        applyTheme()
        
        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }
    
    var index: Int {
        return max(Int(floor(Double(((scrollView.contentOffset.x) / UserCustomCallout.size.width)))), 0)
    }
    
    func focusIndex(_ index: Int) {
        guard index < objects.count else { return }
        
        UIView.animate(withDuration: 0.25) {
            for _cell in self.objects {
                if _cell.index != index {
                    _cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    _cell.alpha = 0.4
                } else {
                    _cell.transform = .identity
                    _cell.alpha = 1.0
                }
            }
        }
    }
    
    func scrollTo(_ index: Int) {
        guard index < objects.count else { return }
        
        let contentOffset = CGPoint(x: CGFloat(index) * UserCustomCallout.size.width, y: 0)
        self.scrollView.setContentOffset(contentOffset, animated: true)
        self.focusIndex(index)
    }
    
    func populate(_ subscriptions: [Subscription]) {
        
        self.subscriptions = subscriptions
        
        let count = self.subscriptions.count
        
        guard count > 0 else {
            return
        }
        
        for i in 0 ... count - 1 {
            let frame = CGRect(x: (CGFloat(i) * UserCustomCallout.size.width), y: 0, width: UserCustomCallout.size.width, height: UserCustomCallout.size.height)
            if let callout = UserCustomCallout.loadNib() {
                
                guard let user = Users.shared[self.subscriptions[i].user] else {
                    continue
                }
                
                callout.populate(user)
                let view = UIView(frame: frame)
                view.addSubview(callout)
                callout.index = i
                
                self.objects.append(callout)
                self.scrollView.addSubview(view)
                
                if i != 0 {
                    callout.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    callout.alpha = 0.5
                }
            }
        }
        
        self.scrollView.contentSize = CGSize(width: UserCustomCallout.size.width * CGFloat(count), height: UserCustomCallout.size.height)
        self.scrollView.frame = scrollView.frame.applying(CGAffineTransform(scaleX: (CGFloat(count) * UserCustomCallout.size.width) / CGFloat(self.width), y: 0))
        
        self.scrollView.setContentOffset(CGPoint.zero, animated: true)
        self.objects[0].transform = .identity
        self.objects[0].alpha = 1.0
    }
    
    func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let index = max(Int(floor(Double(((targetContentOffset.pointee.x) / UserCustomCallout.size.width)))), 0)
        Generator.bump()
        focusIndex(index)
    }
    
    func scrollViewDidScroll(_: UIScrollView) {
        scrollView.contentOffset.y = 0
    }
    
    
    func cleanse() {
        
        self.objects.removeAll()
        self.subscriptions.removeAll()
        
        for view in self.scrollView.subviews {
            view.removeFromSuperview()
        }
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func applyTheme() {
        backgroundColor = UIColor.clear
    }
}
