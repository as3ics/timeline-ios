//
//  ChatRoomCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 6/14/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class ChatRoomCell: UITableViewCell, ThemeSupportedProtocol, NibProtocol {
    typealias Item = ChatRoomCell
    static var reuseIdentifier: String = "ChatRoomCell"

    @IBOutlet var avatars: UIView!
    @IBOutlet var title: UILabel!
    @IBOutlet var date: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var dot: UIImageView!

    var chatroom: Chatroom?
    var initialized: Bool = false
    var _avatars: [UIImageView] = [UIImageView]()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

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
    
    func refresh() {
        guard let chatroom = self.chatroom else { return }
        
        if self._avatars.count == 0 { self.avatars.addSubview(generateAvatars()) }
        
        if chatroom.chatUsers.count > 1 { title.text = chatroom.name }
        else if chatroom.chatUsers.chatUsers.count > 0, let firstName = chatroom.chatUsers[0]?.user?.firstName, let lastName = chatroom.chatUsers[0]?.user?.lastName {
            title.text = String(format: "%@ %@", arguments: [firstName, lastName])
        }
        
        if chatroom.unreadMessages > 0 {
            dot.alpha = 1.0
            if chatroom.unreadMessages == 1 { subtitle.text = String(format: "1 unread message", arguments: [])
            } else { subtitle.text = String(format: "%i unread messages", arguments: [chatroom.unreadMessages]) }
        } else {
            dot.alpha = 0.0
            
            if let content = chatroom.latestMessage?.content { subtitle.text = String(format: "%@", arguments: [content])
            } else { subtitle.text = "" }
        }
        
        if let date = chatroom.latestMessage?.timestamp {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) == true {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                self.date.text = formatter.string(from: date)
            } else if calendar.isDateInYesterday(date) == true {
                self.date.text = "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM dd"
                self.date.text = formatter.string(from: date)
            }
        } else {
            date.text = ""
        }
        
    }

    func populate(_ chatroom: Chatroom?) {
        guard let chatroom = chatroom else {
            title.text = nil
            date.text = nil
            avatars.alpha = 0.0
            dot.alpha = 0.0
            subtitle.text = nil

            return
        }
        
        guard self.initialized == false else {
            return
        }
        
        self.initialized = true
        
        self.chatroom = chatroom
        for view in avatars.subviews {
            view.removeFromSuperview()
        }

        avatars.addSubview(generateAvatars())
        avatars.backgroundColor = UIColor.clear

        if chatroom.chatUsers.count > 1 {
            title.text = chatroom.name
        } else {
            if chatroom.chatUsers.chatUsers.count > 0, let firstName = chatroom.chatUsers[0]?.user?.firstName, let lastName = chatroom.chatUsers[0]?.user?.lastName {
                title.text = String(format: "%@ %@", arguments: [firstName, lastName])
            }
        }

        if chatroom.unreadMessages > 0 {
            dot.alpha = 1.0
            if chatroom.unreadMessages == 1 {
                subtitle.text = String(format: "1 unread message", arguments: [])
            } else {
                subtitle.text = String(format: "%i unread messages", arguments: [chatroom.unreadMessages])
            }
        } else {
            dot.alpha = 0.0

            if let content = chatroom.latestMessage?.content {
                subtitle.text = String(format: "%@", arguments: [content])
            } else {
                subtitle.text = ""
            }
        }

        if let date = chatroom.latestMessage?.timestamp {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) == true {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                self.date.text = formatter.string(from: date)
            } else if calendar.isDateInYesterday(date) == true {
                self.date.text = "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM dd"
                self.date.text = formatter.string(from: date)
            }
        } else {
            date.text = ""
        }

        avatars.layoutIfNeeded()
    }

    fileprivate func generateAvatars() -> UIView {
        guard let chatroom = self.chatroom else {
            return UIView(frame: avatars.bounds)
        }

        let container: UIView = UIView(frame: avatars.bounds)
        container.backgroundColor = UIColor.clear
        _avatars.removeAll()
        
        if chatroom.chatUsers.count == 1, let user = chatroom.chatUsers[0] {
            let imageSize: CGFloat = container.height * 0.85
            let dx: CGFloat = (container.width - imageSize) / 2.0
            let dy: CGFloat = (container.height - imageSize) / 2.0

            let avatar = UIImageView(frame: CGRect(x: dx, y: dy, width: imageSize, height: imageSize))

            avatar.clipsToBounds = true
            avatar.circle = true
            avatar.image = AssetManager.shared.avatar
            avatar.backgroundColor = UIColor.white
            avatar.contentMode = .scaleAspectFit

            avatar.image = Users.shared[user.user?.id]?.profilePicture
            container.addSubview(avatar)
            _avatars.append(avatar)
        } else {
            guard chatroom.chatUsers.count >= 2 else {
                return container
            }

            let count = min(chatroom.chatUsers.count, 3)

            var tempSize: CGFloat?
            if count == 2 {
                tempSize = container.height * 0.75
            } else {
                tempSize = container.height * 0.65
            }

            let imageSize = tempSize!
            let dx: CGFloat = (container.width - imageSize) / CGFloat(count - 1)
            let dy: CGFloat = (container.height - imageSize) / CGFloat(count - 1)

            var i: Int = 0
            for user in chatroom.chatUsers.chatUsers {
                if i >= count {
                    let label = UILabel(frame: CGRect(x: -7.0, y: container.height - 14.5, width: container.width / 2.0, height: 10.0))
                    label.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 12.0)
                    label.textColor = UIColor.lightGray
                    label.text = String(format: "+\(chatroom.chatUsers.count - 3)")
                    container.addSubview(label)
                    break
                }

                let avatar = UIImageView(frame: CGRect(x: CGFloat(i) * dx, y: CGFloat(i) * dy, width: imageSize, height: imageSize))
                avatar.clipsToBounds = true
                avatar.masksToBounds = true
                avatar.cornerRadius = avatar.height / 2
                avatar.image = AssetManager.shared.avatar?.withRenderingMode(.alwaysOriginal)
                avatar.backgroundColor = UIColor.white
                avatar.contentMode = .scaleAspectFit

                avatar.image = Users.shared[user.user?.id]?.profilePicture
                container.addSubview(avatar)
                _avatars.append(avatar)
                
                i = i + 1
            }
        }

        return container
    }

    @objc func applyTheme() {
        backgroundColor = Theme.shared.active.secondaryBackgroundColor
    }
}
