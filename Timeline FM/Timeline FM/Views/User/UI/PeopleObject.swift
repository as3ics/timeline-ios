//
//  PeopleObject.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/4/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import Material
import PKHUD

class PeopleObject: UIView, NibProtocol, ThemeSupportedProtocol {
    
    static var controlEvent: UIControlEvents = .touchUpInside
    
    typealias Item = PeopleObject
    static var reuseIdentifier: String = "PeopleObject"
    static var size: CGSize {
        return CGSize(width: 230, height: 122.5)
    }

    var user: User?
    var userStream: UserStream?

    @IBOutlet var ShadowView: UIView!
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var name: UILabel!
    @IBOutlet var org: UILabel!
    @IBOutlet var status: UILabel!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var messageButton: FlatButton!
    @IBOutlet var callButton: FlatButton!
    @IBOutlet var locateButton: FlatButton!
    @IBOutlet var iconButton: FlatButton!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var activityLabel: UILabel!
    @IBOutlet var clockLabel: UILabel!
    @IBOutlet var favoriteIcon: UIImageView!
    

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

    func populate(_ user: User) {
        self.user = user
        
        self.status.text = ""
        self.clockLabel.text = ""
        self.activityLabel.text = ""
        
        self.userStream = Stream.shared[user.id]
        
        self.name.text = String(format: "%@ %@", user.firstName ?? "John", user.lastName ?? "Doe")
        
        self.icon.image = user.profilePicture
        self.org.text = user.orgName
        self.status.text = "Unknown"
        self.favoriteIcon.image = self.user!.favorite == true ? AssetManager.shared.favorited : AssetManager.shared.unfavorited
        
        self.refresh()
        
        NotificationManager.shared.user_stream_updated.observe(self, selector: #selector(userStreamNotification))
    }

    @objc func refresh() {

        DispatchQueue.main.async {
            
            if self.userStream != nil {
                
                if let _ = self.userStream?.sheet {
                    self.status.text = "Active"
                    self.status.textColor = Color.green.base
                    
                    self.locateButton.isEnabled = true
                    self.locateButton.alpha = 1.0
                } else {
                    self.status.text = "Not Active"
                    self.status.textColor = Color.red.base
                    
                    self.locateButton.isEnabled = false
                    self.locateButton.alpha = 0.5
                }
                
                if let location = self.userStream?.entry?.location {
                    self.org.text = location.name
                } else {
                    self.org.text = self.user?.orgName ?? nil
                }
                
                if let time = self.userStream?.entry?.start, let activity = self.userStream?.entry?.activity?.name {
                    let duration = -time.timeIntervalSinceNow
                    let string = String(format: "%@ for %1.0fh %1.0fm", activity, clockHours(duration), clockMinutes(duration))
                    self.clockLabel.text = string
                } else {
                    self.clockLabel.text = nil
                }
                
                self.activityLabel.text = String(format: "%i Photos", self.user?.photos.count ?? 0)
            } else {
                self.status.text = "Not Active"
                self.status.textColor = UIColor.red
                
                self.clockLabel.text = ""
                self.activityLabel.text = ""
            }
        }
    }

    var i: Int = 0
    @objc func applyTheme() {
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cardPressed)))
        self.messageButton.addTarget(self, action: #selector(self.message), for: PeopleObject.controlEvent)
        self.callButton.addTarget(self, action: #selector(self.call), for: PeopleObject.controlEvent)
        self.locateButton.addTarget(self, action: #selector(self.focus), for: PeopleObject.controlEvent)
        self.iconButton.addTarget(self, action: #selector(self.view), for: PeopleObject.controlEvent)
        self.favoriteIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.favorite)))
        self.favoriteIcon.isUserInteractionEnabled = true
        
        self.locateButton.alpha = 0.5
        self.locateButton.isEnabled = false
        
        tag = i
        backgroundColor = UIColor.clear
        
        backgroundView.corner = 7.5
        backgroundView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        backgroundView.shadowColor = UIColor.black
        backgroundView.shadowOffset = CGSize(width: 1, height: 5)
        backgroundView.shadowRadius = 14.0
        backgroundView.shadowOpacity = 0.5

        org.textColor = Theme.shared.active.secondaryFontColor
        status.textColor = Theme.shared.active.alternativeFontColor

        icon.circle = true
        
        iconButton.style(UIColor.clear, image: nil)
        iconButton.circle = true
        
        messageButton.style(Color.blue.darken2, image: AssetManager.shared.message)
        callButton.style(Color.blue.darken2, image: AssetManager.shared.call)
        locateButton.style(Color.blue.darken2, image: AssetManager.shared.centerMapFilled)
        
        
        messageButton.corner = 7.5
        callButton.corner = 7.5
        locateButton.corner = 7.5
        
        /*
        messageButton.circle = true
        callButton.circle = true
        locateButton.circle = true
        */
        
        favoriteIcon.tintColor = UIColor.white
    }

    @objc func call() {
        delay(0.2) {
            External.shared.dial(self.user?.phoneNumber)
        }
    }

    @objc func message() {
        delay(0.2) {
            self.user?.message()
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
    
    @objc func cardPressed(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.user?.view()
        }
    }
    
    @objc func favorite(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        guard let user = self.user else {
            return
        }
        
        setFavorite(!user.favorite)
        
    }
    
    func setFavorite(_ bool: Bool) {
        
        switch bool {
        case true:
            self.user?.favorite = bool
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Added to Favorites")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT / 2)
            
            DispatchQueue.main.async {
                self.favoriteIcon.image = bool == true ? AssetManager.shared.favorited : AssetManager.shared.unfavorited
            }
            break
        case false:
            self.user?.favorite = bool
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Removed from Favorites")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT / 2)
            
            DispatchQueue.main.async {
                self.favoriteIcon.image = bool == true ? AssetManager.shared.favorited : AssetManager.shared.unfavorited
            }
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
