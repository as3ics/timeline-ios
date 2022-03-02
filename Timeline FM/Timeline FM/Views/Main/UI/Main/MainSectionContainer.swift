//
//  MainSectionContainer.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/18/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import SnapKit
import BetterSegmentedControl
import Material

// MARK: - MainSectionContainer

class MainSectionContainer: UITableViewCell, NibProtocol, ThemeSupportedProtocol, UIScrollViewDelegate {
    
    typealias Item = MainSectionContainer
    static var reuseIdentifier: String = "MainSectionContainer"
    
    static let cellHeight: CGFloat = 80.0
    
    @IBOutlet var view: UIView!
    @IBOutlet var banner: UIImageView!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var imageIcon: UIImageView!
    @IBOutlet var section: UILabel!
    @IBOutlet var title: UILabel!
    @IBOutlet var showMore: UILabel!
    @IBOutlet var content: UIView!
    @IBOutlet var reorderIcon: UIImageView!
    @IBOutlet var value: UILabel!
    @IBOutlet var viewHeight: NSLayoutConstraint!
    @IBOutlet var subTitle: UILabel!
    
    @IBOutlet var contentHeight: NSLayoutConstraint!
    @IBOutlet var infoSection: UIView!
    @IBOutlet var contentSection: UIView!
    @IBOutlet var scrollView: UIScrollView!
    
    var tableView: UITableView!
    
    var sections = [[MainInfo]]()
    
    var objects: [MainSectionTableView] = [MainSectionTableView]()
    var initialized: Bool = false
    
    var timer_1000ms: Timer?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        scrollView.delegate = self
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.masksToBounds = false
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = true
        
        applyTheme()
        
        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        super.setSelected(false, animated: true)
        // Configure the view for the selected state
    }
    
    override func setHighlighted(_: Bool, animated _: Bool) {
        super.setHighlighted(false, animated: false)
    }
    
    // MARK: - Setters
    
    var expanded: Bool = false {
        didSet {
            
            if self.expanded == true, hasMore == true {
                
                self.showMore.text = "Show Less"
                
                self.content.alpha = 0.0
                self.reset()
                
                self.populate(section: self.style)
                
                let actions = MainSectionActionView.loadNib()!
                actions.tag = self.style.rawValue
                
                contentSection.addSubview(actions)
                actions.sizeToFit()
                contentSection.layoutIfNeeded()
                
                actions.populate(section: self.style)
                
                let moreHeight: CGFloat = 160.0 + MainSectionActionView.cellHeight
                let lastScrollOffset = self.tableView.contentOffset
                
                self.tableView.isScrollEnabled = false
                self.tableView.contentInset.bottom += moreHeight
                self.tableView.beginUpdates()
                self.contentHeight.constant = moreHeight
                self.viewHeight.constant = MainSectionContainer.cellHeight + moreHeight
                //self.content.backgroundColor = UIColor.white
                self.tableView.endUpdates()
                self.tableView.layer.removeAllAnimations()
                self.tableView.setContentOffset(lastScrollOffset, animated: false)
                self.tableView.isScrollEnabled = true
                self.tableView.contentInset.bottom -= moreHeight
                
                for object in self.objects {
                    if object.updates.count > 0 {
                        object.update = true
                    } else {
                        object.update = false
                    }
                }
                
                UIView.animate(withDuration: 0.3) {
                    self.content.alpha = 1.0
                }
                
                UIView.transition(with: self.banner,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: { self.banner.image = UIImage(named: "header-black") },
                                  completion: nil)
            } else {
                
                self.showMore.text = "Show More"
                
                self.cleanse()
                
                let lastScrollOffset = self.tableView?.contentOffset
                
                self.tableView?.isScrollEnabled = false
                self.tableView?.beginUpdates()
                self.contentHeight.constant = 0
                self.viewHeight.constant = MainSectionContainer.cellHeight
                //self.content.backgroundColor = Theme.shared.active.placeholderColor
                self.tableView?.endUpdates()
                self.tableView?.setContentOffset(lastScrollOffset ?? CGPoint.zero, animated: true)
                self.tableView?.layer.removeAllAnimations()
                self.tableView?.isScrollEnabled = true
                
                UIView.animate(withDuration: 0.3) {
                    self.content.alpha = 0.0
                }
                
                UIView.transition(with: self.banner,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: { self.banner.image = UIImage(named: "header-blue") },
                                  completion: nil)
            }
        }
    }
    
    
    var style: MainSectionStyle = .User {
        didSet {
            
            guard let _ = self.value else {
                return
            }
            
            NotificationCenter.default.removeObserver(self)
            
            self.cleanse()
            
            switch style {
            case .User:
                self.section.text = "User"
                self.title.text = DeviceUser.shared.user?.fullName
                self.subTitle.text = DeviceUser.shared.user?.orgName
                self.banner.image = UIImage(named: "header-blue")
                self.icon.image = DeviceUser.shared.user?.profilePicture ?? AssetManager.shared.avatar
                self.status = nil //AssetManager.shared.select
                self.hasMore = true
                self.value.text = nil
                self.updates = false
                break
            case .Location:
                self.section.text = "Location"
                self.banner.image = UIImage(named: "header-blue")
                self.value.text = nil
                
                if System.shared.state == .LoggedIn, let location = DeviceUser.shared.sheet?.entries.latest?.location {
                    
                    self.title.text = location.name
                    self.status = AssetManager.shared.select
                    self.icon.image = location.dequeSnapshot()
                    self.subTitle.text = location.address
                    self.value.text = location.addressString
                    self.hasMore = true
                    self.updates = false
                    
                } else if System.shared.state == .Break {
                        
                    self.title.text = "Unavailable"
                    self.subTitle.text = "GPS Not Enabled"
                    self.status = AssetManager.shared.delete
                    self.hasMore = false
                    self.icon.image = AssetManager.shared.noGpsGlyph
                    self.value.text = nil
                    self.updates = false
                    
                } else if System.shared.state == .Empty || System.shared.state == .Traveling {
                    
                    self.icon.image = AssetManager.shared.locationGlyph
                    self.value.text = nil
                    
                    self.updateEnclosure = {
                        DispatchQueue.main.async {
                            if let placemark = LocationManager.shared.latestPlacemark {
                                
                                var number: String = ""
                                if let subThoroughfare = placemark.subThoroughfare {
                                    number = String(format: "%@ ", subThoroughfare)
                                }
                                
                                let addr1 = String(format: "%@%@", number, placemark.thoroughfare ?? "")
                                let addr2 = String(format: "%@, %@ %@", placemark.locality ?? "", placemark.administrativeArea ?? "", placemark.postalCode ?? "")
                                
                                self.title.text = placemark.name != addr1 ? placemark.name : addr1
                                self.subTitle.text = addr2
                                self.status = AssetManager.shared.commuting
                                self.hasMore = true
                            } else {
                                LocationManager.shared.fetchLocation({ (location) in
                                    guard let location = location else {
                                        return
                                    }
                                    
                                    LocationManager.shared.currentLocation = nil
                                    LocationManager.shared.currentLocation = location
                                })
                                
                                self.title.text = "Searching..."
                                self.subTitle.text = "Looking for Location"
                                self.status = AssetManager.shared.ok
                                self.hasMore = false
                            }
                            
                        }
                    }
                    
                    self.updates = true
                } else {
                    self.title.text = "Unavailable"
                    self.subTitle.text = "GPS Not Enabled"
                    self.status = AssetManager.shared.delete
                    self.hasMore = false
                    self.icon.image = AssetManager.shared.noGpsGlyph
                    self.value.text = nil
                    self.updates = false
                }
                break
            case .Entry:
                self.section.text = "Entry"
                self.banner.image = UIImage(named: "header-blue")
                let activity = DeviceUser.shared.sheet?.entries.latest?.activity
                self.title.text = activity?.name ?? "Not Active"
                self.status = activity == nil ? AssetManager.shared.delete : AssetManager.shared.select
                self.icon.image = activity?.breaking == true ? AssetManager.shared.cafeGlyph : activity?.traveling == true ? AssetManager.shared.locationGlyph : AssetManager.shared.activityGlyph
                self.hasMore = activity == nil ? false : true
                
                if let start = DeviceUser.shared.sheet?.entries.latest?.start {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a"
                    self.subTitle.text = String(format: "Since %@", formatter.string(from: start))
                    
                    if activity?.traveling == true, let distance = DeviceUser.shared.sheet?.entries.latest?.meters {
                        self.value.text = String(format: "%0.1f mi", distance * CONVERSION_METERS_TO_MILES_MULTIPLIER)
                    } else {
                        let seconds = DeviceUser.shared.sheet?.duration(index: 0) ?? 0
                        self.value.text = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                    }
                    
                    self.updateEnclosure = {
                        DispatchQueue.main.async {
                            if let activity = DeviceUser.shared.sheet?.entries.latest?.activity {
                                if activity.traveling == true, let distance = DeviceUser.shared.sheet?.entries.latest?.meters {
                                    self.value.text = String(format: "%0.1f mi", distance * CONVERSION_METERS_TO_MILES_MULTIPLIER)
                                } else {
                                    let seconds = DeviceUser.shared.sheet?.duration(index: 0) ?? 0
                                    self.value.text = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                                }
                            }
                        }
                    }
                    
                    self.updates = true
                } else {
                    self.value.text = nil
                    self.subTitle.text = nil
                    self.updates = false
                }
                break
            case .Schedule:
                self.section.text = "Schedule"
                self.title.text = nil
                self.banner.image = UIImage(named: "header-blue")
                self.icon.image = AssetManager.shared.calendarGlyph
                self.status = AssetManager.shared.ok
                self.hasMore = false
                self.value.text = nil
                self.updates = false
                break
            case .Sheet:
                self.section.text = "Timesheet"
                self.banner.image = UIImage(named: "header-blue")
                self.icon.image = AssetManager.shared.scheduleGlyph
                
                if let sheet = DeviceUser.shared.sheet, let start = sheet.date {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEE MMM d, yyyy"
                    
                    self.title.text = "Clocked In"
                    self.subTitle.text = formatter.string(from: start)
                    
                    let seconds =  sheet.totalSeconds
                    self.value.text = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                    self.status = AssetManager.shared.select
                    self.hasMore = true
                    
                    self.updateEnclosure = {
                        DispatchQueue.main.async {
                            if let sheet = DeviceUser.shared.sheet {
                                let seconds =  sheet.totalSeconds
                                self.value.text = String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                            }
                        }
                    }
                    
                    self.updates = true
                } else {
                    self.title.text = "Clocked Out"
                    self.value.text = nil
                    self.subTitle.text = nil
                    self.status = AssetManager.shared.delete
                    self.hasMore = false
                    self.updates = false
                }
                break
            default:
                break
            }
        }
    }
    
    var updates: Bool = false {
        willSet {
            guard newValue != updates else {
                return
            }
            
            if newValue == false {
                timer_1000ms?.invalidate()
                timer_1000ms = nil
                
                for object in self.objects {
                    object.update = false
                }
            } else if newValue == true, timer_1000ms == nil {
                timer_1000ms = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
                    
                    print("Timer - Main Section Container")
                    
                    self.updateEnclosure()
                })
                
                timer_1000ms?.fire()
            }
        }
    }
    
    var status: UIImage? {
        didSet {
            if status != nil {
                self.imageIcon.image = status
                self.imageIcon.borderWidth = 1
                self.imageIcon.borderColor = UIColor.white
            } else {
                self.imageIcon.image = nil
                self.imageIcon.borderWidth = 0
                self.imageIcon.borderColor = UIColor.clear
            }
        }
    }
    
    var hasMore: Bool = false {
        didSet {
            if hasMore == true {
                showMore.alpha = 1.0
            } else {
                showMore.alpha = 0.0
            }
        }
    }
    
    var index: Int {
        return max(Int(floor(Double(((scrollView.contentOffset.x) / scrollView.frame.width)))), 0)
    }
    
    func focusIndex(_ index: Int) {
        guard index < objects.count else { return }
        
        UIView.animate(withDuration: 0.25) {
            for (row, object) in self.objects.enumerated() {
                switch row == index {
                case true:
                    object.alpha = 1.0
                    object.transform = .identity
                    break
                case false:
                    object.alpha = 0.5
                    object.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                    break
                }
            }
        }
    }
    
    func populate(section: MainSectionStyle) {
        
        self.cleanse()
        
        let info = InfoGenerator.getInfo(section: section)
        
        if let data = info["Sections"] as? [[MainInfo]] {
            sections.append(contentsOf: data)
        }
        
        let width: CGFloat = scrollView.frame.width
        let height: CGFloat = 150.0
        
        for (index, section) in sections.enumerated() {
            
            let frame = CGRect(x: (CGFloat(index) * width), y: 0, width: width, height: height)
            
            if let cell = MainSectionTableView.loadNib() {
                let container = UIView(frame: frame)
                
                cell.tag = index
                
                container.addSubview(cell)
                cell.sizeToFit()
                
                if Device.osType != .iOS11 {
                    cell.snp.makeConstraints { (make) in
                        make.width.equalTo(container.snp.width)
                        make.height.equalTo(container.snp.height)
                    }
                } else {
                    cell.frame = CGRect(x: (CGFloat(0) * width), y: 0, width: width, height: height)
                    cell.setNeedsLayout()
                }
                
                cell.populate(section: section)
                cell.setIndex(index + 1, of: sections.count)
                
                objects.append(cell)
                scrollView.addSubview(container)
                
                cell.transform = index == 0 ? .identity : CGAffineTransform(scaleX: 0.9, y: 0.9)
                cell.alpha = index == 0 ? 1.0 : 0.5
                
                container.layer.shadowColor = UIColor.black.cgColor
                container.layer.shadowOpacity = 0.2
                container.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
                view.layer.shadowRadius = 14.0
            }
            
        }
        
        self.scrollView.contentSize = CGSize(width: width * CGFloat(sections.count), height: height)
        
        self.scrollView.setContentOffset(CGPoint.zero, animated: true)
        
        self.initialized = true
        self.layoutIfNeeded()
    }
    
    
    func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        guard self.initialized == true else { return }
        
        let index = max(Int(floor(Double(((targetContentOffset.pointee.x) / scrollView.width)))), 0)
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
    
    func cleanse() {
        
        for object in self.objects {
            object.update = false
            object.removeFromSuperview()
        }
        
        self.objects.removeAll()
        self.sections.removeAll()
        
        for view in self.scrollView.subviews {
            view.removeFromSuperview()
        }
        
        if let actions = self.contentSection.subviews.first as? MainSectionActionView {
            for view in actions.scrollView.subviews {
                view.removeFromSuperview()
            }
            
            actions.removeFromSuperview()
        }
        
        self.initialized = false
    }
    
    // MARK: - Reset Functions
    
    func reload(collapse: Bool = false) {
        
        DispatchQueue.main.async {
            let style = self.style
            self.style = style
            
            if collapse == true || self.hasMore == false {
                self.expanded = false
            } else if self.expanded == true {
                self.expanded = true
            }
        }
    }

    func reset() {
        for section in Main.sections {
            if section.expanded == true, section !== self {
                UIView.animate(withDuration: 0.3, animations: {
                    section.expanded = false
                }, completion: nil)
            }
        }
        
        for section in Dashboard.sections {
            if section.expanded == true, section !== self {
                UIView.animate(withDuration: 0.3, animations: {
                    section.expanded = false
                }, completion: nil)
            }
        }
    }
    
    var updateEnclosure: Enclosure = { }
    
    // MARK: - Other Functions
    
    @objc func applyTheme() {
        
        self.reorderIcon.tintColor = UIColor.white.withAlphaComponent(0.25)
        self.reorderIcon.image = AssetManager.shared.reorder
        self.imageIcon.circle = true
        self.icon.circle = true
        self.icon.tintColor = Theme.shared.active.alternateIconColor
        self.icon.backgroundColor = Theme.shared.active.primaryBackgroundColor
        self.view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        self.backgroundColor = UIColor.clear
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 20.0
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 1, height: 5)
    }
    
    deinit {
        timer_1000ms?.invalidate()
        timer_1000ms = nil
        NotificationCenter.default.removeObserver(self)
    }
    
}
