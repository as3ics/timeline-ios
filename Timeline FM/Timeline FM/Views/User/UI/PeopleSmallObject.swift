//
//  PeopleSmallObject.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 11/13/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//


import Foundation
import Material
import PKHUD

class PeopleSmallObject: UIView, NibProtocol, ThemeSupportedProtocol {
    
    static var controlEvent: UIControlEvents = .touchUpInside
    
    typealias Item = PeopleSmallObject
    
    static var reuseIdentifier: String = "PeopleSmallObject"
    static var size: CGSize {
        return CGSize(width: 100.0, height: 70.0)
    }
    
    var user: User?
    var userStream: UserStream?
    
    @IBOutlet var ShadowView: UIView!
    @IBOutlet var name: UILabel!
    
    @IBOutlet var icon: UIImageView!
    @IBOutlet var iconButton: FlatButton!
    @IBOutlet var backgroundView: UIView!
    
    @IBOutlet var activityIcon: UIImageView!
    @IBOutlet var clockIcon: UIImageView!
    @IBOutlet var photoIcon: UIImageView!
    
    @IBOutlet var activityLabel: UILabel!
    @IBOutlet var clockLabel: UILabel!
    @IBOutlet var photoLabel: UILabel!
    
    
    var index: Int = -1
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyTheme()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func populate(user: User) {
        self.user = user
        
        self.clockLabel.text = ""
        self.activityLabel.text = ""
        self.photoLabel.text = ""
        
        self.userStream = Stream.shared[user.id]
        
        self.name.text = String(format: "%@ %@", user.firstName ?? "John", user.lastName ?? "Doe")
        
        self.icon.image = user.profilePicture
        
        self.refresh()
        
        NotificationManager.shared.user_stream_updated.observe(self, selector: #selector(userStreamNotification))
    }
    
    @objc func refresh() {
        
        DispatchQueue.main.async {
            
            if let stream = self.userStream {
                
                let activityString = stream.entry?.activity?.name ?? "Unknown"
                let photoString = String(format: "%i Photos", Users.shared[stream.user.id]?.photos.count ?? 0 )
                
                let time = stream.entry?.start ?? Date()
                let duration = time.timeIntervalSinceNow
                let clockString = String(format: "%1.0fh %1.0fm", clockHours(duration), clockMinutes(duration))

                self.clockLabel.text = clockString
                self.activityLabel.text = activityString
                self.photoLabel.text = photoString
                
            }
        }
    }
    
    var i: Int = 0
    @objc func applyTheme() {
        
        self.iconButton.addTarget(self, action: #selector(self.view), for: .touchUpInside)
        
        tag = i
        backgroundColor = UIColor.clear
        backgroundView.corner = 2.5
        backgroundView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        backgroundView.shadowColor = UIColor.black
        backgroundView.shadowOffset = CGSize(width: 1, height: 5)
        backgroundView.shadowRadius = 14.0
        backgroundView.shadowOpacity = 0.5
        
        activityIcon.image = AssetManager.shared.activity
        clockIcon.image = AssetManager.shared.clock
        photoIcon.image = AssetManager.shared.camera?.withRenderingMode(.alwaysTemplate)
        
        activityIcon.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        clockIcon.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        photoIcon.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        
        icon.circle = true
        
        iconButton.style(UIColor.clear, image: nil)
        iconButton.circle = true
    }
    
    @objc func call() {
        delay(0.2) {
            External.shared.dial(self.user?.phoneNumber)
        }
    }
    
    @objc func message() {
        delay(0.2) {
            External.shared.smsMessage(self.user?.phoneNumber)
        }
    }
    
    @objc func focus() {
        self.user?.focus()
    }
    
    @objc func view() {
        icon.touchAnimation()
        iconButton.touchAnimation(true)
        
        delay(0.2) {
            self.user?.view()
        }
    }
    
    @objc func userStreamNotification(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as? JSON, let stream = userInfo["userStream"] as? UserStream, stream.user.id == self.user?.id else {
            
            delay(1.0) {
                if Stream.shared[self.user?.id] == nil, self.userStream != nil {
                    self.userStream = nil
                    self.refresh()
                }
            }
            
            return
        }
        
        userStream = stream
        refresh()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
