//
//  NavBar.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import Material
import UIKit
import CoreLocation

enum NavStyle: Int {
    case Custom = 0
    case Root = 1
    case Sub = 2
}

enum NavLayout: Int {
    case Bottom = 0
    case Top = 1
    case Middle = 2
}

enum NavHeight: Int {
    case Tall = 0
    case Short = 1
}

class NavWrapper: UIView {
    static let TagNumber: Int = Int.max - 22

    @IBInspectable override var tag: Int {
        didSet {
            super.tag = NavWrapper.TagNumber
            super.backgroundColor = UIColor.clear
        }
    }
}

class NavBar: UIView {
    /**
     Tag number to be applied to container view in parent view controller

     - Author: Zachary DeGeorge

     - returns: A very large obscure Int

     - Important: This value was choosen so as to eliminate the possibility of conflicts, but it is up to the designer to verify this value does not conflict with their implementation

     - Version: 0.1

     */

    var leftButton = FlatButton()
    var rightButton = FlatButton()
    var titleView = UIView()
    var titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /**
     Custom initializer that automatically adds navigation bar to parent view controller. If a NavWrapper exists in the subview stack constraints will be applied to inset content, else will just overlay navigation bar over controllers content view

     - Author: Zachary DeGeorge

     - parameters:
     - parent: view controller to have navigation bar applied to

     - returns: (void)

     - Important: Verify propper constraints generated before deployment

     - Version: 0.1

     */
    init(_ parent: UIViewController) {
        super.init(frame: NavBar.defaultFrame)

        self.parent = parent
        
        parent.view.addSubview(self)
        
        if let container = parent.view.viewWithTag(NavWrapper.TagNumber) {
            
            NSLayoutConstraint(item: container, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: container, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: container, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0.0).isActive = true
            parent.view.setNeedsUpdateConstraints()
            parent.view.setNeedsLayout()
        }
    }
    
    func relinquish() {
        
        self.removeConstraints(self.constraints)
        
        self.leftButton.removeTargets()
        self.rightButton.removeTargets()
        
        for view in self.centerView?.subviews ?? [] {
            view.removeFromSuperview()
        }
        
        self.centerView?.removeFromSuperview()
        
        self.parent = nil
        
        for view in subviews {
            view.removeFromSuperview()
        }
        
        removeFromSuperview()
        
        delay(0.3) {
            self.leftEnclosure = nil
            self.rightEnclosure = nil
        }
    }

    func reapplyBounds() {
        if let bounds = self.parent?.view.bounds {
            let titleWidth = titleLabel.bounds.width

            let targetX = (bounds.width / 2.0) - (titleWidth / 2.0)
            let currentX = titleLabel.frame.minX
            let deltaX = targetX - currentX

            titleLabel.frame = titleLabel.frame.offsetBy(dx: deltaX, dy: 0)
            titleLabel.layoutIfNeeded()
        }
    }

    /**
     Quick access to set the background color of the view

     - Author: Zachary DeGeorge

     - parameters:
     - UIColor?: if string is nil the alpha of the title label will be set to clear

     - returns: string? of center title label text value

     - Important:

     - Version: 0.1

     */
    var _background: UIColor?
    var background: UIColor? {
        set {
            if newValue != nil {
                backgroundColor = newValue
                _background = newValue
            } else {
                backgroundColor = UIColor.clear
                _background = UIColor.clear
            }
        } get {
            return _background
        }
    }

    /**
     Quick access to add a UITapGestureRecognizer on the title label

     - Author: Zachary DeGeorge

     - parameters:
     - UITapGestureRecognizer?: if tap is nil the gesture recognizers of the button will be cleared

     - returns: UITapGestureRecognizer? of first applied gesture recognizer

     - Important:

     - Version: 0.1

     */
    var titleAction: UITapGestureRecognizer? {
        set {
            if newValue != nil {
                titleLabel.addGestureRecognizer(newValue!)
                titleLabel.isUserInteractionEnabled = true
            } else {
                gestureRecognizers?.removeAll()
            }
        } get {
            if titleLabel.gestureRecognizers != nil, titleLabel.gestureRecognizers!.count > 0 {
                return titleLabel.gestureRecognizers![0] as? UITapGestureRecognizer
            } else {
                return nil
            }
        }
    }

    /**
     Quick access to set the title of the center title label

     - Author: Zachary DeGeorge

     - parameters:
     - string?: if string is nil the alpha of the title label will be set to 0.0

     - returns: string? of center title label text value

     - Important:

     - Version: 0.1

     */
    var title: String? {
        set {
            if newValue != nil {
                DispatchQueue.main.async {
                    self.titleLabel.text = newValue
                    self.titleView.alpha = 0.0
                }
            } else {
                titleLabel.alpha = 0.0
            }
        } get {
            return titleLabel.text
        }
    }

    /**
     Quick access to set the center view of the nav bar

     - Author: Zachary DeGeorge

     - parameters:
     - view?: if view is nil the alpha of the center viewwill be set to 0.0

     - returns: view? of center title view

     - Important:

     - Version: 0.1

     */
    var centerView: UIView? {
        set {
            if newValue != nil {
                DispatchQueue.main.async {
                    let x = (self.bounds.width / 2.0) - (newValue!.bounds.width / 2.0)
                    let y = NavBar.defaultTitleTopY!
                    let width = newValue!.bounds.width
                    let height = newValue!.bounds.height

                    newValue!.frame = CGRect(x: x, y: y, width: width, height: height)
                    self.titleView.addSubview(newValue!)

                    let xconstraint = NSLayoutConstraint(item: newValue!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.titleView, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
                    let yconstraint = NSLayoutConstraint(item: newValue!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.leftButton, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)

                    xconstraint.isActive = true
                    yconstraint.isActive = true

                    self.titleView.layoutIfNeeded()
                    self.titleLabel.alpha = 0.0
                }
            } else {
                titleView.alpha = 0.0
                titleLabel.alpha = 1.0
            }
        } get {
            guard titleView.subviews.count > 0 else {
                return nil
            }

            return titleView.subviews[0]
        }
    }

    /**
     Quick access to add a UITapGestureRecognizer on the title view

     - Author: Zachary DeGeorge

     - parameters:
     - UITapGestureRecognizer?: if tap is nil the gesture recognizers of the view will be cleared

     - returns: UITapGestureRecognizer? of first applied gesture recognizer

     - Important:

     - Version: 0.1

     */
    var centerAction: UITapGestureRecognizer? {
        set {
            if newValue != nil {
                titleView.addGestureRecognizer(newValue!)
                titleView.isUserInteractionEnabled = true
            } else {
                gestureRecognizers?.removeAll()
            }
        } get {
            if titleView.gestureRecognizers != nil, titleView.gestureRecognizers!.count > 0 {
                return titleView.gestureRecognizers![0] as? UITapGestureRecognizer
            } else {
                return nil
            }
        }
    }

    var leftEnclosure: Enclosure? {
        didSet {
            leftButton.removeTargets()

            guard leftEnclosure != nil else {
                return
            }

            leftButton.addTarget(self, action: #selector(leftSelector), for: .touchUpInside)
            leftButton.pulseColor = UIColor.clear // UIColor.white
            leftButton.pulseOpacity = 0.0
            leftButton.animateTouch()
        }
    }

    @objc fileprivate func leftSelector() {
        delay(0.2) {
            self.leftEnclosure?()
        }
    }

    var rightEnclosure: Enclosure? {
        didSet {
            rightButton.removeTargets()
            
            guard rightEnclosure != nil else {
                return
            }

            rightButton.addTarget(self, action: #selector(rightSelector), for: .touchUpInside)
            rightButton.pulseColor = UIColor.clear // UIColor.white
            rightButton.pulseOpacity = 0.0
            rightButton.animateTouch()
        }
    }

    @objc fileprivate func rightSelector() {
        delay(0.2) {
            self.rightEnclosure?()
        }
    }

    /**
     Quick access to add a UITapGestureRecognizer on the left button

     - Author: Zachary DeGeorge

     - parameters:
     - UITapGestureRecognizer?: if tap is nil the gesture recognizers of the button will be cleared

     - returns: UITapGestureRecognizer? of first applied gesture recognizer

     - Important:

     - Version: 0.1

     */
    var leftAction: UITapGestureRecognizer? {
        set {
            if newValue != nil {
                leftButton.addGestureRecognizer(newValue!)
                leftButton.isUserInteractionEnabled = true
            } else {
                gestureRecognizers?.removeAll()
            }
        } get {
            if leftButton.gestureRecognizers != nil, leftButton.gestureRecognizers!.count > 0 {
                return leftButton.gestureRecognizers![0] as? UITapGestureRecognizer
            } else {
                return nil
            }
        }
    }

    /**
     Quick access to set the image of the left button

     - Author: Zachary DeGeorge

     - parameters:
     - UIImage?: if set to nil will set the alpha of the left button to 0.0

     - returns:

     - Important:

     - Version: 0.1

     */
    var leftImage: UIImage? {
        set {
            if newValue != nil {
                leftButton.image = newValue?.withRenderingMode(.alwaysTemplate)
            } else {
                leftButton.alpha = 0.0
            }
        } get {
            return leftButton.image
        }
    }

    /**
     Quick access to add a UITapGestureRecognizer on the button

     - Author: Zachary DeGeorge

     - parameters:
     - UITapGestureRecognizer?: if tap is nil the gesture recognizers of the button will be cleared

     - returns: UITapGestureRecognizer? of first applied gesture recognizer

     - Important:

     - Version: 0.1

     */
    var rightAction: UITapGestureRecognizer? {
        set {
            if newValue != nil {
                rightButton.addGestureRecognizer(newValue!)
                rightButton.isUserInteractionEnabled = true
            } else {
                rightButton.gestureRecognizers?.removeAll()
            }
        } get {
            if rightButton.gestureRecognizers != nil, rightButton.gestureRecognizers!.count > 0 {
                return rightButton.gestureRecognizers![0] as? UITapGestureRecognizer
            } else {
                return nil
            }
        }
    }

    /**
     Quick access to set the image of the right button

     - Author: Zachary DeGeorge

     - parameters:
     - UIImage?: if set to nil will set the alpha of the button to 0.0

     - returns:

     - Important:

     - Version: 0.1

     */
    var rightImage: UIImage? {
        set {
            if newValue != nil {
                rightButton.image = newValue?.withRenderingMode(.alwaysTemplate)
                rightButton.alpha = 1.0
            } else {
                rightButton.alpha = 0.0
            }
        } get {
            return rightButton.image
        }
    }

    /**
     Quick access to set a standard styling scheme to the navigation bar

     - Author: Zachary DeGeorge

     - parameters:
     - .Root: applies styling for root view controller
     - .Sub: applies styling for sub view controller
     - .Custom: does note apply any styling to the view controller

     - returns: the current style of the navigation bar

     - Important:

     - Version: 0.1

     */
    fileprivate var _style: NavStyle! = .Root
    var style: NavStyle {
        set {
            _style = newValue

            switch newValue {
            case .Root:
                alpha = 1.0
                backgroundColor = Theme.shared.active.rootHeaderBackgroundColor
                leftButton.tintColor = Theme.shared.active.rootHeaderFontColor
                rightButton.tintColor = Theme.shared.active.rootHeaderFontColor
                titleLabel.textColor = Theme.shared.active.rootHeaderFontColor
                break
            case .Sub:
                alpha = 1.0
                backgroundColor = Theme.shared.active.subHeaderBackgroundColor
                leftButton.tintColor = Theme.shared.active.subHeaderFontColor
                rightButton.tintColor = Theme.shared.active.subHeaderFontColor
                titleLabel.textColor = Theme.shared.active.subHeaderFontColor
                break
            default:
                break
            }
        } get {
            return _style
        }
    }

    /**
     Quick access to set the position of the standard views of the navigation bar

     - Author: Zachary DeGeorge

     - parameters:
     - .Bottom: positions sub views to bottom of navigation bar
     - .Top: positions sub views to top of navigation bar
     - .Middle: positions sub views to middle of navigation bar

     - returns: the current postion setting of the navigation bar

     - Important:

     - Version: 0.1

     */
    fileprivate var _verticalLayout: NavLayout = .Middle
    var verticalLayout: NavLayout {
        get {
            return _verticalLayout
        } set {
            if _verticalLayout != newValue {
                _verticalLayout = newValue
                updateChildren()
            }
        }
    }

    /**
     Quick access to set the height of the navigation bar

     - Author: Zachary DeGeorge

     - parameters:
     - .Tall: extends the height of the navigation bar
     - .Short: retracts the height of the navigation bar

     - returns: the current height setting of the navigation bar

     - Important:

     - Version: 0.1

     */
    fileprivate var _layoutHeight: NavHeight! = .Tall
    var layoutHeight: NavHeight! {
        get {
            return _layoutHeight
        } set {
            if _layoutHeight != newValue {
                _layoutHeight = newValue
                updateParent()
            }
        }
    }

    func expand(_ height: CGFloat) {
        frame = CGRect(x: frame.minX, y: frame.minY, width: width, height: self.height + height)
    }
    
    func offsetButtons(_ height: CGFloat) {
        self.leftButton.frame = self.leftButton.frame.offsetBy(dx: 0, dy: height)
        self.rightButton.frame = self.rightButton.frame.offsetBy(dx: 0, dy: height)
    }

    func offset(_ distance: CGFloat) {
        frame = frame.offsetBy(dx: 0, dy: distance)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if subviews.count < 4 {
            switch _verticalLayout {
            case .Bottom:
                leftButton.frame = CGRect(x: NavBar.buttonLateralMargin, y: NavBar.defaultButtonBottomY, width: NavBar.buttonWidth, height: NavBar.buttonHeight)
                rightButton.frame = CGRect(x: NavBar.viewWidth - NavBar.buttonWidth - NavBar.buttonLateralMargin, y: NavBar.defaultButtonBottomY, width: NavBar.buttonWidth, height: NavBar.buttonHeight)
                titleLabel.frame = CGRect(x: NavBar.titleX, y: NavBar.defaultTitleBottomY, width: NavBar.titleWidth, height: NavBar.titleHeight)
                titleView.frame = CGRect(x: NavBar.titleX, y: NavBar.defaultTitleBottomY, width: NavBar.titleWidth, height: NavBar.titleHeight)
                break
            case .Top:
                leftButton.frame = CGRect(x: NavBar.buttonLateralMargin, y: NavBar.defaultButtonTopY, width: NavBar.buttonWidth, height: NavBar.buttonHeight)
                rightButton.frame = CGRect(x: NavBar.viewWidth - NavBar.buttonWidth - NavBar.buttonLateralMargin, y: NavBar.defaultButtonTopY, width: NavBar.buttonWidth, height: NavBar.buttonHeight)
                titleLabel.frame = CGRect(x: NavBar.titleX, y: NavBar.defaultTitleTopY, width: NavBar.titleWidth, height: NavBar.titleHeight)
                titleView.frame = CGRect(x: NavBar.titleX, y: NavBar.defaultTitleBottomY, width: NavBar.titleWidth, height: NavBar.titleHeight)
                break
            case .Middle:
                leftButton.frame = CGRect(x: NavBar.buttonLateralMargin, y: NavBar.defaultButtonMiddleY, width: NavBar.buttonWidth, height: NavBar.buttonHeight)
                rightButton.frame = CGRect(x: NavBar.viewWidth - NavBar.buttonWidth - NavBar.buttonLateralMargin, y: NavBar.defaultButtonMiddleY, width: NavBar.buttonWidth, height: NavBar.buttonHeight)
                titleLabel.frame = CGRect(x: NavBar.titleX, y: NavBar.defaultTitleMiddleY, width: NavBar.titleWidth, height: NavBar.titleHeight)
                titleView.frame = CGRect(x: NavBar.titleX, y: NavBar.defaultTitleBottomY, width: NavBar.titleWidth, height: NavBar.titleHeight)
                break
            }

            leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, (NavBar.buttonWidth / 2.0) - (leftButton.imageView!.width / 2))
            leftButton.backgroundColor = UIColor.clear
            leftButton.contentMode = .scaleAspectFit
            leftButton.circle = true

            rightButton.imageEdgeInsets = UIEdgeInsetsMake(0, (NavBar.buttonWidth / 2.0) - (rightButton.imageView!.width / 2), 0, 0)
            rightButton.backgroundColor = UIColor.clear
            rightButton.contentMode = .scaleAspectFit
            rightButton.circle = true

            titleLabel.font = NavBar.titleFont
            titleLabel.textAlignment = .center
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = 0.5
            titleLabel.numberOfLines = 2

            titleView.masksToBounds = false
            titleView.clipsToBounds = false
            titleView.backgroundColor = UIColor.clear

            addSubview(titleLabel)
            addSubview(leftButton)
            addSubview(rightButton)
            addSubview(titleView)
        }
    }

    enum SubviewIndex: Int {
        case titleLabel = 0
        case leftButton = 1
        case rightButton = 2
        case titleView = 3
    }

    weak var parent: UIViewController?
    static var extraHeight: CGFloat = 0.0
    
    fileprivate static let viewWidth: CGFloat! = UIScreen.main.bounds.width
    static var defaultViewHeight: CGFloat! { return NavBar.extraHeight + NavBar.tallHeight + NavBar.topInset }
    static var defaultFrame: CGRect! { return CGRect(x: 0, y: 0, width: NavBar.viewWidth, height: NavBar.defaultViewHeight) }
    
    fileprivate static let tallHeight: CGFloat! = 64
    fileprivate static let shortHeight: CGFloat! = 44
    fileprivate static let heightDifference: CGFloat! = NavBar.tallHeight - NavBar.shortHeight
    fileprivate static let buttonHeight: CGFloat = 30.0
    fileprivate static let buttonWidth: CGFloat = 60.0
    fileprivate static let buttonLateralMargin: CGFloat = 10.0
    fileprivate static var verticalMarginTop: CGFloat = 10.0
    fileprivate static let verticalMarginBottom: CGFloat = 10.0
    fileprivate static let titleWidth: CGFloat = 200.0
    fileprivate static let titleHeight: CGFloat = 20.0
    fileprivate static let titleFont: UIFont! = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16.5)!
    fileprivate static var defaultTitleBottomY: CGFloat! { return NavBar.extraHeight + NavBar.defaultViewHeight - NavBar.titleHeight - NavBar.verticalMarginBottom }
    fileprivate static var defaultTitleTopY: CGFloat!  { return NavBar.extraHeight + NavBar.topInset + NavBar.verticalMarginTop }
    static var defaultTitleMiddleY: CGFloat!{ return (NavBar.topInset / 2.0) + (NavBar.defaultViewHeight / 2.0) - (NavBar.titleHeight / 2.0) }
    fileprivate static let titleX: CGFloat! = (NavBar.viewWidth / 2.0) - (NavBar.titleWidth / 2.0)
    fileprivate static var defaultButtonBottomY: CGFloat! { return NavBar.defaultViewHeight - NavBar.buttonHeight - NavBar.verticalMarginBottom }
    fileprivate static var defaultButtonTopY: CGFloat! { return NavBar.topInset + NavBar.verticalMarginTop }
    fileprivate static var defaultButtonMiddleY: CGFloat! { return (NavBar.topInset / 2.0) + (NavBar.defaultViewHeight / 2.0) - (NavBar.buttonHeight / 2.0) }

    fileprivate static var topInset: CGFloat! {
        if Device.hasNotch == true {
            return 32
        } else {
            return 10
        }
    }

    fileprivate func updateChildren() {
        if _layoutHeight == .Tall {
            if _verticalLayout == .Top {
                leftButton.frame = leftButton.frame.offsetBy(dx: 0, dy: (NavBar.defaultButtonTopY - leftButton.frame.minY))
                rightButton.frame = rightButton.frame.offsetBy(dx: 0, dy: (NavBar.defaultButtonTopY - rightButton.frame.minY))
                titleLabel.frame = titleLabel.frame.offsetBy(dx: 0, dy: (NavBar.defaultButtonTopY - titleLabel.frame.minY))
                titleView.frame = titleLabel.frame.offsetBy(dx: 0, dy: (NavBar.defaultButtonTopY - titleLabel.frame.minY))
            } else if _verticalLayout == .Middle {
                leftButton.frame = leftButton.frame.offsetBy(dx: 0, dy: (frame.midY + (NavBar.topInset / 2.0) - leftButton.frame.midY))
                rightButton.frame = rightButton.frame.offsetBy(dx: 0, dy: (frame.midY + (NavBar.topInset / 2.0) - rightButton.frame.midY))
                titleLabel.frame = titleLabel.frame.offsetBy(dx: 0, dy: (frame.midY + (NavBar.topInset / 2.0) - titleLabel.frame.midY))
                titleView.frame = titleLabel.frame.offsetBy(dx: 0, dy: (frame.midY + (NavBar.topInset / 2.0) - titleLabel.frame.midY))
            } else if verticalLayout == .Bottom {
                leftButton.frame = leftButton.frame.offsetBy(dx: 0, dy: (frame.maxY - (NavBar.buttonHeight + NavBar.verticalMarginBottom)) - leftButton.frame.minY)
                rightButton.frame = rightButton.frame.offsetBy(dx: 0, dy: (frame.maxY - (NavBar.buttonHeight + NavBar.verticalMarginBottom)) - rightButton.frame.minY)
                titleLabel.frame = titleLabel.frame.offsetBy(dx: 0, dy: (frame.maxY - (NavBar.buttonHeight + NavBar.verticalMarginBottom)) - titleLabel.frame.minY)
                titleView.frame = titleLabel.frame.offsetBy(dx: 0, dy: (frame.maxY - (NavBar.buttonHeight + NavBar.verticalMarginBottom)) - titleLabel.frame.minY)
            }
        } else if _layoutHeight == .Short {
            if _verticalLayout == .Top {
                let deltaY = NavBar.defaultButtonTopY - leftButton.frame.minY + NavBar.heightDifference
                leftButton.frame = leftButton.frame.offsetBy(dx: 0, dy: deltaY)
                rightButton.frame = rightButton.frame.offsetBy(dx: 0, dy: deltaY)
                titleLabel.frame = titleLabel.frame.offsetBy(dx: 0, dy: deltaY)
                titleView.frame = titleLabel.frame.offsetBy(dx: 0, dy: deltaY)
            } else if _verticalLayout == .Middle {
                let deltaY = frame.maxY / 2.0 + NavBar.heightDifference - leftButton.frame.midY + NavBar.topInset / 2.0
                leftButton.frame = leftButton.frame.offsetBy(dx: 0, dy: deltaY)
                rightButton.frame = rightButton.frame.offsetBy(dx: 0, dy: deltaY)
                titleLabel.frame = titleLabel.frame.offsetBy(dx: 0, dy: deltaY)
                titleView.frame = titleLabel.frame.offsetBy(dx: 0, dy: deltaY)
            } else if verticalLayout == .Bottom {
                let deltaY = frame.maxY - NavBar.buttonHeight - NavBar.verticalMarginBottom + NavBar.heightDifference - leftButton.frame.minY
                leftButton.frame = leftButton.frame.offsetBy(dx: 0, dy: deltaY)
                rightButton.frame = rightButton.frame.offsetBy(dx: 0, dy: deltaY)
                titleLabel.frame = titleLabel.frame.offsetBy(dx: 0, dy: deltaY)
                titleView.frame = titleLabel.frame.offsetBy(dx: 0, dy: deltaY)
            }
        }

        parent?.view.layoutIfNeeded()
    }

    fileprivate func updateParent() {
        if _layoutHeight == .Short {
            frame = frame.offsetBy(dx: 0, dy: -NavBar.heightDifference)
        } else if _layoutHeight == .Tall {
            frame = frame.offsetBy(dx: 0, dy: NavBar.heightDifference)
        }

        updateChildren()
    }
}
