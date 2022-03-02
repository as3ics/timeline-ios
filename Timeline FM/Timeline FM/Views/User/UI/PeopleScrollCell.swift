//
//  PeopleScrollCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/4/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class PeopleScrollCell: UITableViewCell, UIScrollViewDelegate, NibProtocol, ThemeSupportedProtocol {
    typealias Item = PeopleScrollCell
    static var reuseIdentifier: String = "PeopleScrollCell"
    static var cellHeight: CGFloat = PeopleObject.size.height + 10.0
    static var shared: PeopleScrollCell?
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var label: UILabel!
    
    var objects: [PeopleObject] = [PeopleObject]()
    var initialized: Bool = false
    var users: Users = Users(lean: true)
    
    static var mode: PeopleScrollCellMode = .Active {
        didSet {
            guard let scrollCell = PeopleScrollCell.shared else { return }
            
            scrollCell.clear()
            scrollCell.populate(3)
        }
    }
    
    enum PeopleScrollCellMode: Int {
        case Active = 0
        case All = 1
        case Favorites = 110
        case Nearby = 10
    }
    
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
        return max(Int(floor(Double(((scrollView.contentOffset.x) / PeopleObject.size.width)))), 0)
    }
    
    func focusIndex(_ index: Int) {
        guard index < objects.count else { return }
        
        UIView.animate(withDuration: 0.25) {
            for _cell in self.objects {
                if _cell.index != index {
                    _cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    _cell.alpha = 0.4
                } else {
                    _cell.iconButton.pulse(point: CGPoint(x: _cell.iconButton.width / 2, y: _cell.iconButton.height / 2))
                    _cell.transform = .identity
                    _cell.alpha = 1.0
                }
            }
        }
    }

    func clear() {
        guard let scrollCell = PeopleScrollCell.shared else { return }
        
        scrollCell.cleanse()
    }
    
    func paginate(_ count: Int) {
        
        guard let scrollCell = PeopleScrollCell.shared else { return }
        
        let currentCount = scrollCell.objects.count
        
        let _count = min(scrollCell.users.count, currentCount + count)
        
        guard _count > currentCount else { return }
        
        for i in currentCount..._count - 1 {
            let frame = CGRect(x: (CGFloat(i) * PeopleObject.size.width), y: 0, width: PeopleObject.size.width, height: PeopleObject.size.height)
            if let cell = scrollCell.users.items[i].dequeCard() {
                let view = UIView(frame: frame)
                view.addSubview(cell)
                cell.index = i
                
                scrollCell.objects.append(cell)
                scrollCell.scrollView.addSubview(view)
            }
        }
        
        let currentOffset = scrollCell.scrollView.contentOffset
        scrollCell.scrollView.contentSize = CGSize(width: PeopleObject.size.width * CGFloat(_count), height: PeopleObject.size.height)
        scrollCell.scrollView.frame = scrollView.frame.applying(CGAffineTransform(scaleX: (CGFloat(_count) * PeopleObject.size.width) / CGFloat(contentView.width), y: 0))
        scrollCell.scrollView.setContentOffset(currentOffset, animated: false)
        scrollCell.focusIndex(scrollCell.index)
    }


    func populate(_ count: Int) {
        guard let scrollCell = PeopleScrollCell.shared else { return }
        
        guard scrollCell.initialized == false || self.objects.count == 0 else { return }
        
        switch PeopleScrollCell.mode {
        case .All:
            scrollCell.users.items = Users.shared.items
            break
        case .Active:
            scrollCell.users.items = Users.shared.active
            break
        case .Nearby, .Favorites:
            scrollCell.users.items.removeAll()
            break
        }
        
        scrollCell.users.sort()
    
        let _count = min(scrollCell.users.count, count)
        
        guard _count > 0 else {
            scrollCell.scrollView.transform = .identity
            return
        }
        
        for i in 0 ... _count - 1 {
            let frame = CGRect(x: (CGFloat(i) * PeopleObject.size.width), y: 0, width: PeopleObject.size.width, height: PeopleObject.size.height)
            if let cell = scrollCell.users.items[i].dequeCard() {
                let view = UIView(frame: frame)
                view.addSubview(cell)
                cell.index = i
                
                scrollCell.objects.append(cell)
                scrollCell.scrollView.addSubview(view)
                
                if i != 0 {
                    cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    cell.alpha = 0.5
                }
            }
        }

        scrollCell.scrollView.contentSize = CGSize(width: PeopleObject.size.width * CGFloat(_count), height: PeopleObject.size.height)
        scrollCell.scrollView.frame = scrollView.frame.applying(CGAffineTransform(scaleX: (CGFloat(_count) * PeopleObject.size.width) / CGFloat(contentView.width), y: 0))
        
        scrollCell.scrollView.setContentOffset(CGPoint.zero, animated: true)
        scrollCell.objects[0].transform = .identity
        scrollCell.objects[0].alpha = 1.0
        //scrollCell.focusIndex(0)
        
        scrollCell.scrollView.transform = .identity
        scrollCell.initialized = true
    }
    
    func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        guard self.initialized == true else { return }
        
        let index = max(Int(floor(Double(((targetContentOffset.pointee.x) / PeopleObject.size.width)))), 0)
        Generator.bump()
        focusIndex(index)
    }
    
    func scrollViewDidEndDecelerating(_: UIScrollView) {
        
        guard self.initialized == true else { return }
        
        let index = self.index
        
        if objects.count - index <= 3 {
            paginate(3)
        }
    }
    
    func scrollViewDidScroll(_: UIScrollView) {
        
        guard self.initialized == true else { return }
        
        scrollView.contentOffset.y = 0
        
    }
    
    
    func cleanse() {
        
        guard let scrollCell = PeopleScrollCell.shared else { return }
        
        scrollCell.objects.removeAll()
        
        scrollCell.users.items.removeAll()
        
        for view in scrollCell.scrollView.subviews {
            view.removeFromSuperview()
        }
        
        scrollCell.initialized = false
    }
    

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func applyTheme() {
        backgroundColor = UIColor.clear
        contentView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        label.textColor = Theme.shared.active.secondaryFontColor
    }
}
