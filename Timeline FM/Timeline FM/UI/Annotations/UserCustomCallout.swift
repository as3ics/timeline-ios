//
//  UserCustomCallout.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/25/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Material
import PKHUD

class UserCustomCallout: UIView, NibProtocol, ThemeSupportedProtocol {
    
    static var controlEvent: UIControlEvents = .touchUpInside
    
    typealias Item = UserCustomCallout
    static var reuseIdentifier: String = "UserCustomCallout"
    static var size: CGSize {
        return CGSize(width: 210, height: 105)
    }
    
    var user: User?
    var userStream: UserStream?
    
    @IBOutlet var shadowView: UIView!
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var name: UILabel!
    @IBOutlet var org: UILabel!
    @IBOutlet var status: UILabel!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var activityLabel: UILabel!
    @IBOutlet var clockLabel: UILabel!
    @IBOutlet var cancel: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    
    var index: Int = -1
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyTheme()
        
        cancel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(remove)))
        cancel.isUserInteractionEnabled = true
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(view)))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func populate(_ user: User) {
        self.user = user
        
        self.activityIndicator.alpha = 1.0
        self.activityIndicator.startAnimating()
        
        self.userStream = Stream.shared[user.id]
        
        self.refresh()
        
        self.icon.image = user.profilePicture
        
        NotificationManager.shared.user_stream_updated.observe(self, selector: #selector(userStreamNotification))
    }
    
    @objc func refresh() {
        guard let user = self.user else { return }
        
        DispatchQueue.main.async {
            
            self.name.text = String(format: "%@ %@", user.firstName ?? "John", user.lastName ?? "Doe")
            
            if self.userStream != nil {
                
                self.activityIndicator.alpha = 0.0
                self.activityIndicator.stopAnimating()
                
                if let _ = self.userStream?.sheet {
                    self.status.text = "Active"
                } else {
                    self.status.text = nil
                }
                
                if let location = self.userStream?.entry?.location {
                    self.org.text = location.name
                } else {
                    self.org.text = user.orgName
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
                self.org.text = ""
                self.status.text = ""
                self.clockLabel.text = ""
                self.activityLabel.text = ""
            }
        }
    }
    
    var i: Int = 0
    @objc func applyTheme() {
        
        tag = i
        backgroundColor = UIColor.clear
        shadowView.backgroundColor = UIColor.clear
        backgroundView.corner = 7.5
        backgroundView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        backgroundView.shadowColor = UIColor.black
        backgroundView.shadowOffset = CGSize(width: 1, height: 5)
        backgroundView.shadowRadius = 14.0
        backgroundView.shadowOpacity = 0.5
        
        cancel.image = AssetManager.shared.deleteTrash
        cancel.tintColor = UIColor.white
        
        icon.circle = true
        icon.layer.shadowColor = UIColor.black.cgColor
        icon.layer.shadowOffset = CGSize(width: 1.0, height: 5.0)
        icon.layer.shadowRadius = 15.0
        icon.layer.shadowOpacity = 1.0
    }
    
    @objc func view(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.user?.view()
        }
    }
    
    @objc func remove(_ sender: UITapGestureRecognizer) {
        
        sender.view?.touchAnimation()
        
        delay(0.2) {
            
            guard let id = self.user?.id else {
                return
            }
            
            for (index, item) in Subscriptions.shared.items.enumerated() {
                if item.user == id {
                    let _ = item.leave(Socket.shared.socket)
                    
                    for (index, connection) in Socket.shared.connections.enumerated() {
                        if let room = connection["room"] as? String, room == "user", let userId = connection["roomid"] as? String, userId == id {
                            Socket.shared.connections.remove(at: index)
                            break
                        }
                    }
                    
                    item.annotation = nil
                    item.breadcrumb = nil
                    item.sheet = nil
                    
                    if index < Subscriptions.shared.items.count {
                        Subscriptions.shared.items.remove(at: index)
                    }
                    
                    
                    Notifications.shared.map_focus_user.post(["user": id as JSONObject])
                }
            }
        }
    }
    
    @objc func userStreamNotification(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as? JSON, let stream = userInfo["userStream"] as? UserStream, stream.user.id == self.user?.id else {
            return
        }
        
        userStream = stream
        
        refresh()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
