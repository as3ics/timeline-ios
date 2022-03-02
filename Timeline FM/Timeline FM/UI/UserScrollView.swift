//
//  ChatUserView.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import Material
import CoreLocation

class UserView {
    var view: UIView!
    var avatarView: UIView!
    var labelView: UIView!
    var indicatorView: UIView!
    var circleView: CAShapeLayer!
    var originalRect: CGRect!
    var originalAvatarRect: CGRect!
    var originalLabelRect: CGRect!
    var originalCircleRect: CGRect!
    var originalIndicatorRect: CGRect!
    var user: ChatUser!

    init(_ container: UIView, _ avatar: UIView, _ label: UIView, _ indicator: UIView, _ circleView: CAShapeLayer, _ user: ChatUser) {
        view = container
        avatarView = avatar
        labelView = label
        indicatorView = indicator
        self.circleView = circleView
        self.user = user

        originalAvatarRect = avatarView.frame
        originalLabelRect = labelView.frame
        originalIndicatorRect = indicatorView.frame
        originalRect = view.frame
        originalCircleRect = self.circleView.frame

        view.addSubview(avatarView)
        view.addSubview(labelView)
        view.addSubview(indicatorView)
        view.layer.addSublayer(self.circleView)

        (view.layer.sublayers!.last as! CAShapeLayer).strokeColor = UIColor.clear.cgColor
    }

    func setConnected(_ value: Bool) {
        if value == true {
            view.subviews[2].alpha = 1.0
        } else {
            view.subviews[2].alpha = 0.0
        }
    }

    func setCircle(_ value: Bool) {
        if value == true {
            (view.layer.sublayers!.last as! CAShapeLayer).strokeColor = Color.blue.lighten1.cgColor
        } else {
            (view.layer.sublayers!.last as! CAShapeLayer).strokeColor = UIColor.clear.cgColor
        }
    }
}

class UserScrollViewConfiguration {
    var viewHeight: CGFloat?
    var maxViewWidth: CGFloat?
    var cellWidth: CGFloat?
    var cellHeight: CGFloat?
    var imageSize: CGFloat?
    var topInset: CGFloat?
    var viewLateralInsets: CGFloat?
    var roundedCorners: Bool?
    var centered: Bool?
    var minViewWidth: CGFloat?
    var fontSize: CGFloat?
    var indicatorSize: CGFloat?
    var labelTopInset: CGFloat?
}

class UserScrollView: UIViewController, UIScrollViewDelegate {
    var chatroom: Chatroom?
    var chatroomUsers: [ChatUser]?

    var navView: UIScrollView!
    var leftButton: UIImageView!
    var rightButton: UIImageView!
    var parentView: UIView!
    var userViews = [UserView]()
    var originalContentOffset: CGPoint?
    var configuration: UserScrollViewConfiguration?
    weak var _parent: UIViewController!

    init(_ chatroom: Chatroom?, _ parentView: UIView, _ configuration: UserScrollViewConfiguration, _ parent: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        
        self.chatroom = chatroom
        self.parentView = parentView
        self.configuration = configuration
        self._parent = parent
        
        let viewHeight: CGFloat! = configuration.viewHeight
        let maxViewWidth: CGFloat! = configuration.maxViewWidth
        let cellWidth: CGFloat! = configuration.cellWidth
        let cellHeight: CGFloat! = configuration.cellHeight
        let imageSize: CGFloat! = configuration.imageSize
        let topInset: CGFloat! = configuration.topInset
        let viewLateralInsets: CGFloat! = configuration.viewLateralInsets
        let fontSize: CGFloat! = configuration.fontSize
        let indicatorSize: CGFloat! = configuration.indicatorSize
        let labelTopInset: CGFloat! = configuration.labelTopInset
        
        let userCount = self.chatroom!.chatUsers.count
        let lateralImageInsets: CGFloat = (cellWidth - imageSize) / 2.0
        let labelY: CGFloat = imageSize + topInset + labelTopInset
        let labelWidth: CGFloat = cellWidth
        let labelHeight: CGFloat = 10.0
        let totalViewWidth: CGFloat = (CGFloat(userCount) * cellWidth) + (2.0 * viewLateralInsets)
        let viewWidth: CGFloat = max(min(totalViewWidth, maxViewWidth), configuration.minViewWidth ?? 0)
        let viewY: CGFloat = self.parentView.height - viewHeight
        
        let phantomViewX: CGFloat = configuration.centered == true ? self.parentView.center.x - (totalViewWidth / 2.0) : 0.0
        let viewX: CGFloat = configuration.centered == true ? self.parentView.center.x - (viewWidth / 2.0) : 0.0
        
        navView = UIScrollView(frame: CGRect(x: viewX, y: viewY, width: viewWidth, height: viewHeight))
        navView.delegate = self
        navView.isScrollEnabled = true
        navView.showsHorizontalScrollIndicator = false
        navView.alwaysBounceHorizontal = true
        navView.alwaysBounceVertical = false
        navView.showsVerticalScrollIndicator = false
        navView.isPagingEnabled = false
        
        if configuration.roundedCorners == true {
            navView.cornerRadius = viewHeight / 2
        }
        
        let extra = configuration.centered == true ? ((maxViewWidth - viewWidth) / 2.0 ) : 0.0
        navView.contentSize = CGSize(width: extra + totalViewWidth, height: viewHeight)
        navView.contentInset = UIEdgeInsetsMake(0, (viewX - phantomViewX)  , 0, -(viewX - phantomViewX) )
        userViews.removeAll()
        
        if userCount > 0 {
            for i in 0 ... userCount - 1 {
                
                let extra = configuration.centered == true ? ((maxViewWidth - viewWidth) / 2.0) + (viewLateralInsets! / 2.0) : viewLateralInsets!
                let containerView = UIView(frame: CGRect(x: extra + (phantomViewX - viewX) + lateralImageInsets + (CGFloat(i) * cellWidth), y: 0.0, width: cellWidth, height: cellHeight))
                
                let imageView = UIImageView(frame: CGRect(x: lateralImageInsets, y: topInset, width: imageSize, height: imageSize))
                imageView.circle = true
                imageView.image = Users.shared[self.chatroom?.chatUsers[i]?.user?.id]?.profilePicture
                imageView.backgroundColor = UIColor.white
                imageView.contentMode = .scaleAspectFit
                imageView.tag = i
                imageView.isUserInteractionEnabled = true
                
                let label = UILabel(frame: CGRect(x: 0, y: labelY, width: labelWidth, height: labelHeight))
                label.text = "\(self.chatroom!.chatUsers[i]!.user!.firstName!)"
                label.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: fontSize)
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.5
                label.textColor = UIColor.black
                label.textAlignment = .center
                label.tag = i
                
                let indicatorView = UIView(frame: CGRect(x: lateralImageInsets + (imageSize * 0.87) - (indicatorSize / 2.0), y: topInset + (imageSize * 0.67), width: indicatorSize, height: indicatorSize))
                indicatorView.clipsToBounds = true
                indicatorView.circle = true
                indicatorView.alpha = 0.0
                indicatorView.backgroundColor = Color.blue.lighten1
                
                let circlePath = UIBezierPath(arcCenter: imageView.center, radius: (imageSize / 2.0) + 3.0, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
                
                let shapeLayer = CAShapeLayer()
                shapeLayer.path = circlePath.cgPath
                
                // change the fill color
                shapeLayer.fillColor = UIColor.clear.cgColor
                // you can change the stroke color
                shapeLayer.strokeColor = Color.blue.lighten1.withAlphaComponent(0.75).cgColor
                // you can change the line width
                shapeLayer.lineWidth = 2.0
                
                containerView.tag = i
                
                let userView = UserView(containerView, imageView, label, indicatorView, shapeLayer, chatroom!.chatUsers[i]!)
                userViews.append(userView)
                navView.addSubview(userView.view)
            }
        }
        
        let scaleFactor = maxViewWidth / viewWidth
        
        navView.frame = navView.frame.applying(CGAffineTransform(scaleX: scaleFactor, y: 1.0))
        
        if configuration.centered == true {
            navView.center.x = self.parentView.center.x
            //navView.contentInset = UIEdgeInsetsMake(0, (maxViewWidth - viewWidth) / 2.0, 0, 0)
        }
        
        navView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 35.0, -1.0, 35.0)
        
        navView.clipsToBounds = false // phantomViewX != viewX
        navView.masksToBounds = true // phantomViewX != viewX
        navView.tag = 200
        
        originalContentOffset = navView.contentOffset
    }
    
    func relinquish() {
        
        self.navView.delegate = nil
        
        self.chatroomUsers?.removeAll()
        
        for userView in userViews {
            for view in userView.view.subviews {
                view.removeFromSuperview()
            }
            
            userView.view.removeConstraints(userView.view.constraints)
            userView.view.removeFromSuperview()
            userView.user = nil
        }
        
        self.userViews.removeAll()
        self.configuration = nil
        self._parent = nil
        self.removeFromParentViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    subscript(id: String?) -> UserView? {
        guard let id = id else {
            return nil
        }

        for view in userViews {
            if let userId = view.user?.user?.id {
                if userId == id {
                    return view
                }
            }
        }

        return nil
    }

    var activated: Bool = false

    func indexFromOffset(_ offset: CGFloat, _ chatroom: Chatroom?) -> Int? {
        guard let count = chatroom?.chatUsers.count else {
            return nil
        }

        let _offset = offset - (max(navView!.contentSize.width - configuration!.maxViewWidth!,0))
        let scaleFactor: CGFloat = count < 4 ? 3.5 : 2.0 // will effect behavior
        let maxOffset: CGFloat = 180.0 // is a given from scrollview


        if count == 2 {
            if _offset > 0 { return 1 } else { return 0 }
        } else {
            let saturationPoint: CGFloat = maxOffset / scaleFactor

            let scaledOffset = _offset * scaleFactor

            var saturatedOffset: CGFloat!
            if scaledOffset >= 0 { saturatedOffset = min((scaledOffset * saturationPoint) / maxOffset, saturationPoint) } else {
                saturatedOffset = max((scaledOffset * saturationPoint) / maxOffset, -saturationPoint) }

            let normalizedOffset = (saturatedOffset / saturationPoint)
            let processedOffset = normalizedOffset * maxOffset

            let index = max(userViews.count - 1 - Int(max(0, floor((CGFloat(userViews.count - 1) * ((maxOffset - processedOffset) / 2.0) / maxOffset) + 0.5))), 0)

            print("Offset Proccessed: \(processedOffset) Index: \(index)")

            return index
        }
    }

    func alphaFromIndex(_ index: Int, _ offset: CGFloat, _ userView: UserView) -> CGFloat? {
        guard let userIndex = userView.user?.index else {
            return nil
        }

        let step: CGFloat = 0.15
        let cubeFactor: CGFloat = 0.25
        let cubeValue: CGFloat = 1.0 - cubeFactor
        let maxOffset: CGFloat = 180.0

        let distance = index - userIndex
        let stepFactor = step * CGFloat(abs(distance))
        let proccessedAlpha = max(1.0 - stepFactor, 0.25)
        let dynamicScale = min(max((1.0 - (cubeFactor * (abs(offset) / maxOffset))), cubeValue), 1.0)
        let newAlpha = min((((dynamicScale * dynamicScale * dynamicScale) * (proccessedAlpha * proccessedAlpha)) * 1.2), 1.0)

        print("Alpha generated for index \(userIndex): \(newAlpha)")

        return newAlpha
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.x + scrollView.contentInset.left

        guard activated == true, scrollView.isDragging == true, let index = self.indexFromOffset(currentOffset, self.chatroom) else {
            return
        }

        for userView in userViews {
            guard let i = userView.user.index else {
                continue
            }

            if i == index {
                //animateUser(userView)
            } else {
             
                UIView.animate(withDuration: 0.2) {
                    self.unanimateUser(userView, alpha: 1.0)
                    userView.view.setNeedsDisplay()
                    userView.view.layoutIfNeeded()
                }
            }
        }
    }

    func resetAnimation() {
        UIView.animate(withDuration: 0.2) {
            for userView in self.userViews {
                self.unanimateUser(userView, alpha: 1.0)
            }

            self.navView.layoutIfNeeded()
        }
    }

    static var navBarConfiguration: UserScrollViewConfiguration {
        let configuration = UserScrollViewConfiguration()
        configuration.viewHeight = 80.0
        configuration.maxViewWidth = Device.phoneType == iPhone.iPhone5 ? 225 : 250.0
        configuration.cellWidth = 55.0
        configuration.cellHeight = 60.0
        configuration.imageSize = 40.0
        configuration.topInset = 20.0
        configuration.viewLateralInsets = 12.5
        configuration.fontSize = 9.5
        configuration.indicatorSize = 10.0
        configuration.labelTopInset = 2.0

        configuration.centered = true
        configuration.roundedCorners = true

        return configuration
    }

    static var headerViewConfiguration: UserScrollViewConfiguration {
        let configuration = UserScrollViewConfiguration()
        configuration.viewHeight = 100.0
        configuration.minViewWidth = UIScreen.main.bounds.width
        configuration.maxViewWidth = UIScreen.main.bounds.width
        configuration.cellWidth = 60.0
        configuration.cellHeight = 90.0
        configuration.imageSize = 47.5
        configuration.topInset = 30.0
        configuration.viewLateralInsets = 12.5
        configuration.centered = false
        configuration.roundedCorners = false
        configuration.fontSize = 10.0
        configuration.indicatorSize = 12.0
        configuration.labelTopInset = 4.0

        return configuration
    }


    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func unanimateUser(_ userView: UserView, alpha: CGFloat, _: Int? = nil) {
        
        if alpha < 1.0, userView.view.transform != .identity {
            userView.view.alpha = alpha * 1.2
            userView.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } else {
            userView.view.alpha = 1.0
            userView.view.transform = .identity
        }
        
        userView.view.setNeedsDisplay()
        userView.view.layoutIfNeeded()
    }

    func animateUser(_ userView: UserView) {
        
        UIView.animate(withDuration: 0.2, animations: {
            
            userView.view.alpha = 1.0
            userView.view.transform = CGAffineTransform.init(scaleX: 1.1, y: 1.1)
            userView.view.layoutIfNeeded()
        })
    }
}
