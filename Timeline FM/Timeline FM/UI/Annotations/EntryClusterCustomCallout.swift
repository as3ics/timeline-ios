//
//  EntryClusterCustomCallout.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/27/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Material

class EntryClusterCustomCallout: UIView, UIScrollViewDelegate, NibProtocol, ThemeSupportedProtocol {
    typealias Item = EntryClusterCustomCallout
    static var reuseIdentifier: String = "EntryClusterCustomCallout"
    
    @IBOutlet var scrollView: UIScrollView!
    
    var objects: [EntryCustomCallout] = [EntryCustomCallout]()
    var entries: Entries!

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
        return max(Int(floor(Double(((scrollView.contentOffset.x) / EntryCustomCallout.size.width)))), 0)
    }
    
    func focusIndex(_ index: Int) {
        guard index < objects.count else { return }
        
        UIView.animate(withDuration: 0.25) {
            for _cell in self.objects {
                if _cell.index != index {
                    _cell.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
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
        
        let contentOffset = CGPoint(x: CGFloat(index) * EntryCustomCallout.size.width, y: 0)
        self.scrollView.setContentOffset(contentOffset, animated: true)
        self.focusIndex(index)
    }
    
    func populate(_ entries: [Entry]) {
        
        self.entries = Entries(sheet: nil)
        
        for item in entries {
            self.entries.add(item)
        }
        
        self.entries.sortReverse()
        
        let count = self.entries.count
        
        for i in 0 ... count - 1 {
            let frame = CGRect(x: (CGFloat(i) * EntryCustomCallout.size.width), y: 0, width: EntryCustomCallout.size.width, height: EntryCustomCallout.size.height)
            if let callout = EntryCustomCallout.loadNib() {
                self.entries.items[i].clusterIndex = i
                callout.populate(self.entries.items[i])
                let view = UIView(frame: frame)
                view.addSubview(callout)
                callout.index = i
                
                self.objects.append(callout)
                self.scrollView.addSubview(view)
                
                if i != 0 {
                    callout.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                    callout.alpha = 0.5
                }
            }
        }
        
        self.scrollView.contentSize = CGSize(width: EntryCustomCallout.size.width * CGFloat(count), height: EntryCustomCallout.size.height)
        self.scrollView.frame = scrollView.frame.applying(CGAffineTransform(scaleX: (CGFloat(count) * EntryCustomCallout.size.width) / CGFloat(self.width), y: 0))
        
        self.scrollView.setContentOffset(CGPoint.zero, animated: true)
        self.objects[0].transform = .identity
        self.objects[0].alpha = 1.0
    }
    
    func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let index = max(Int(floor(Double(((targetContentOffset.pointee.x) / EntryCustomCallout.size.width)))), 0)
        Generator.bump()
        focusIndex(index)
    }
    
    func scrollViewDidScroll(_: UIScrollView) {
        scrollView.contentOffset.y = 0
    }
    
    
    func cleanse() {
        
        self.objects.removeAll()
        self.entries.items.removeAll()
        
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
