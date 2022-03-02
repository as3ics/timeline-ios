//
//  MainSectionActionView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/18/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import Material
import PKHUD
import BetterSegmentedControl

class MainSectionActionView: UIView, NibProtocol, ThemeSupportedProtocol, UIScrollViewDelegate {
    
    typealias Item = MainSectionActionView
    static var reuseIdentifier: String = "MainSectionActionView"
    
    static var cellHeight: CGFloat = 100.0
    
    var actions: [MainAction]?
    
    var objects: [MainSectionActionItem] = [MainSectionActionItem]()
    var initialized: Bool = false
    
    @IBOutlet var scrollView: UIScrollView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        scrollView.delegate = self
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.masksToBounds = false
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = true
        
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(((UIApplication.shared.keyWindow?.bounds.width ?? 360) - scrollView.width) / 2.0, ((UIApplication.shared.keyWindow?.bounds.width ?? 360) - scrollView.width - 30.0), -11, 0)
        
        applyTheme()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var index: Int {
        return max(Int(floor(Double(((scrollView.contentOffset.x) / MainSectionActionItem.size.width)))), 0)
    }
    
    func focusIndex(_ index: Int) {
        guard index < objects.count else { return }
        
        UIView.animate(withDuration: 0.25) {
            for object in self.objects {
                if object.index != index {
                    object.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    object.alpha = 1.0
                } else {
                    object.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    object.alpha = 1.0
                }
            }
        }
    }
    
    func populate(section: MainSectionStyle) {
        
        let info = InfoGenerator.getInfo(section: section)
        self.actions = info["Actions"] as? [MainAction]
        
        guard self.initialized == false, self.actions?.count ?? 0 > 0 else { return }
        
        for i in 0 ... self.actions!.count - 1 {
            let action = self.actions![i]
            let frame = CGRect(x: (CGFloat(i) * MainSectionActionItem.size.width), y: 0, width: MainSectionActionItem.size.width, height: MainSectionActionItem.size.height)
            if let cell = MainSectionActionItem.loadNib() {
                let view = UIView(frame: frame)
                view.addSubview(cell)
                cell.index = i
                cell.card.animateTouch()
                cell.populate(action: action)
                self.objects.append(cell)
                self.scrollView.addSubview(view)
                
                cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                cell.alpha = 1.0
            }
        }
        
        self.scrollView.contentSize = CGSize(width: MainSectionActionItem.size.width * CGFloat(self.actions?.count ?? 1), height: MainSectionActionItem.size.height)
        
        self.scrollView.setContentOffset(CGPoint.zero, animated: true)
        
        self.initialized = true
        self.layoutIfNeeded()
    }
    
    func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        guard self.initialized == true else { return }
        
        let index = max(Int(floor(Double(((targetContentOffset.pointee.x) / MainSectionActionItem.size.width)))), 0)
        Generator.bump()
        focusIndex(index)
    }
    
    func scrollViewDidEndDecelerating(_: UIScrollView) {
        
        guard self.initialized == true else { return }
    
    }
    
    func scrollViewDidScroll(_: UIScrollView) {
        
        guard self.initialized == true else { return }
        
        scrollView.contentOffset.y = 0
        
    }
    
    
    func clear() {
        self.cleanse()
    }
    
    func cleanse() {
        
        for object in self.objects {
            object.removeFromSuperview()
        }
        
        self.objects.removeAll()
        
        for view in self.scrollView.subviews {
            view.removeFromSuperview()
        }
        
        self.initialized = false
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applyTheme() {
        
    }
    
}
