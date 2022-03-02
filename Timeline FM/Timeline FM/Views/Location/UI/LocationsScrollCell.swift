//
//  LocationsScrollCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/3/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import CoreLocation
import UIKit

class LocationsScrollCell: UITableViewCell, UIScrollViewDelegate, NibProtocol, ThemeSupportedProtocol {
    typealias Item = LocationsScrollCell
    static var reuseIdentifier: String = "LocationsScrollCell"
    static var cellHeight: CGFloat = LocationObject.size.height + 20.0
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var label: UILabel!

    var objects: [LocationObject] = [LocationObject]()
    var initialized: Bool = false
    
    var locations: Locations = Locations(lean: true)

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

    func focusIndex(_ index: Int) {
        guard index < objects.count else {
            return
        }

        UIView.animate(withDuration: 0.25) {
            for _cell in self.objects {
                if _cell.index != index {
                    _cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    _cell.alpha = 0.5
                } else {
                    _cell.transform = .identity
                    _cell.alpha = 1.0
                }
            }
        }
    }

    var index: Int {
        return max(Int(floor(Double(((scrollView.contentOffset.x) / LocationObject.size.width)))), 0)
    }

    func cleanse() {
        objects.removeAll()

        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        
        self.scrollView.setContentOffset(CGPoint.zero, animated: false)

        initialized = false
        locations.items.removeAll()
    }

    func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let index = max(Int(floor(Double(((targetContentOffset.pointee.x) / LocationObject.size.width)))), 0)

        Generator.bump()

        focusIndex(index)
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        let remainder = scrollView.contentOffset.x.truncatingRemainder(dividingBy: LocationObject.size.width)
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x - remainder, y: scrollView.contentOffset.y), animated: true)
        
        let index = self.index
        
        if self.objects.count - index <= 3 {
            self.paginate(4)
        }
    }

    func scrollViewDidScroll(_: UIScrollView) {
        scrollView.contentOffset.y = 0
    }
    
    func paginate(_ count: Int) {
        
        let currentCount = self.objects.count
        
        let _count = min(locations.count, currentCount + count)
        
        guard _count > currentCount else { return }
        
        for i in currentCount..._count - 1 {
            let frame = CGRect(x: (CGFloat(i) * LocationObject.size.width), y: 0, width: LocationObject.size.width, height: LocationObject.size.height)
            if let cell = locations.items[i].dequeCard() {
                let view = UIView(frame: frame)
                view.addSubview(cell)
                cell.index = i
                cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                
                objects.append(cell)
                scrollView.addSubview(view)
            }
        }
        
        let currentOffset = scrollView.contentOffset
        scrollView.contentSize = CGSize(width: LocationObject.size.width * CGFloat(_count), height: LocationObject.size.height)
        scrollView.frame = scrollView.frame.applying(CGAffineTransform(scaleX: (CGFloat(_count) * LocationObject.size.width) / CGFloat(contentView.width), y: 0))
        scrollView.setContentOffset(currentOffset, animated: false)
        focusIndex(index)
    }

    func populate(_ count: Int) {
        guard initialized == false else {
            return
        }
        
        cleanse()
        
        initialized = true
        locations.items = Locations.shared.items
        locations.sortByDistance()

        let _count = min(locations.count, count)
        
        guard _count > 0 else {
            return
        }

        for i in 0 ... _count - 1 {
            let frame = CGRect(x: (CGFloat(i) * LocationObject.size.width), y: 0, width: LocationObject.size.width, height: LocationObject.size.height)
            let view = UIView(frame: frame)
            
            if let cell = locations.items[i].dequeCard() {
                view.addSubview(cell)
                cell.index = i
                cell.transform = i == 0 ? .identity : CGAffineTransform(scaleX: 0.9, y: 0.9)
                objects.append(cell)
            }
            
            scrollView.addSubview(view)
        }

        let remainder = scrollView.contentOffset.x.truncatingRemainder(dividingBy: LocationObject.size.width)
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x - remainder, y: scrollView.contentOffset.y), animated: true)

        scrollView.contentSize = CGSize(width: LocationObject.size.width * CGFloat(_count), height: LocationObject.size.height)
        scrollView.frame = scrollView.frame.applying(CGAffineTransform(scaleX: (CGFloat(_count) * LocationObject.size.width) / CGFloat(contentView.width), y: 0))
        scrollView.layoutIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
        label.textColor = Theme.shared.active.secondaryFontColor
        contentView.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }
}
