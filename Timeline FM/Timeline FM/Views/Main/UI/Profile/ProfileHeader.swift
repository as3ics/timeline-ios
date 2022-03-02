//
//  ProfileNameAndPictureCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 5/8/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit
import Material
import PKHUD

class ProfileHeader: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ProfileHeader
    static var reuseIdentifier: String = "ProfileHeader"

    @IBOutlet var profilePicture: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var company: UILabel!
    @IBOutlet var role: UILabel!
    @IBOutlet var cameraButton: UIImageView!

    @IBOutlet var shiftsLabel: UILabel!
    @IBOutlet var hoursLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!

    @IBOutlet var shiftsAnchor: UILabel!
    @IBOutlet var hoursAnchor: UILabel!
    @IBOutlet var distanceAnchor: UILabel!
    
    @IBOutlet var callButton: FlatButton!
    @IBOutlet var messageButton: FlatButton!
    @IBOutlet var timelineMessageButton: FlatButton!
    @IBOutlet var favoriteButton: FlatButton!

    var user: User?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    func populate(_ user: User? = nil) {
        self.user = user ?? DeviceUser.shared.user

        name.text = user?.fullName
        company.text = user?.orgName ?? "Timeline"
        role.text = user?.userRole.rawValue.lowercased() ?? UserRole.User.rawValue.lowercased()
        
        profilePicture.image = user?.profilePicture
        
        shiftsLabel.text = String(format: "%i", (user?.statistics?.shifts ?? 0)!)
        hoursLabel.text = String(format: "%.0f", (user?.statistics?.hours ?? 0)!)
        distanceLabel.text = String(format: "%.0f", (user?.statistics?.distance ?? 0)! * CONVERSION_METERS_TO_MILES_MULTIPLIER)
        
        DispatchQueue.main.async {
            self.favoriteButton.style(Color.blue.base, image: self.user?.favorite ?? false ? AssetManager.shared.favorited : AssetManager.shared.unfavorited, inset: 11)
        }
        
        if user === DeviceUser.shared.user {
            messageButton.alpha = 0.0
            callButton.alpha = 0.0
            timelineMessageButton.alpha = 0.0
            favoriteButton.alpha = 0.0
            cameraButton.alpha = 0.95
        } else {
            cameraButton.alpha = 0.0
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func applyTheme() {
        backgroundColor = Theme.shared.active.primaryBackgroundColor
        name.textColor = Theme.shared.active.primaryFontColor
        company.textColor = Color.darkGray
        role.textColor = Color.lightGray

        shiftsAnchor.textColor = Theme.shared.active.darkIconColor
        hoursAnchor.textColor = Theme.shared.active.darkIconColor
        distanceAnchor.textColor = Theme.shared.active.darkIconColor
        
        messageButton.style(Color.blue.base, image: AssetManager.shared.sms, inset: 11)
        callButton.style(Color.blue.base, image: AssetManager.shared.call, inset: 11)
        timelineMessageButton.style(Color.blue.base, image: AssetManager.shared.message, inset: 11)
        
        messageButton.circle = true
        callButton.circle = true
        favoriteButton.circle = true
        timelineMessageButton.circle = true
        
        timelineMessageButton.addTarget(self, action: #selector(timelineMessage), for: .touchUpInside)
        messageButton.addTarget(self, action: #selector(self.message), for: .touchUpInside)
        callButton.addTarget(self, action: #selector(self.call), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(self.favorite), for: .touchUpInside)
        
        name.numberOfLines = 2
        name.minimumScaleFactor = 0.6
        name.adjustsFontSizeToFitWidth = true
        
    }
    
    @objc func call() {
        delay(0.2) {
            External.shared.dial(self.user?.phoneNumber)
        }
    }
    
    @objc func timelineMessage() {
        self.user?.message()
    }
    
    @objc func message() {
        delay(0.2) {
            External.shared.smsMessage(self.user?.phoneNumber)
        }
    }
    
    @objc func favorite(_ sender: FlatButton?) {
        sender?.touchAnimation()
        
        guard let user = self.user else {
            return
        }
        
        setFavorite(!user.favorite)
        
    }
    
    func setFavorite(_ bool: Bool) {
        
        switch bool {
        case true:
            self.user!.favorite = bool
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Added to Favorites")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT / 2)
            
            DispatchQueue.main.async {
                self.favoriteButton.style(Color.blue.base, image: bool ? AssetManager.shared.favorited : AssetManager.shared.unfavorited, inset: 11)
            }
            break
        case false:
            self.user!.favorite = bool
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Removed from Favorites")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT / 2)
            
            DispatchQueue.main.async {
                self.favoriteButton.style(Color.blue.base, image: bool ? AssetManager.shared.favorited : AssetManager.shared.unfavorited, inset: 11)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
