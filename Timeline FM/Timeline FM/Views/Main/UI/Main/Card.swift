//
//  Card.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/18/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Material

@IBDesignable open class Card: UIView {
    
    // Storyboard Inspectable vars
    /**
     Color for the card's labels.
     */
    @IBInspectable public var textColor: UIColor = UIColor.black
    /**
     Amount of blur for the card's shadow.
     */
    @IBInspectable public var shadowBlur: CGFloat = 3 {
        didSet{
            self.layer.shadowRadius = shadowBlur
            self.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        }
    }
    /**
     Alpha of the card's shadow.
     */
    @IBInspectable public var _shadowOpacity: Float = 0.2 {
        didSet{
            self.layer.shadowOpacity = _shadowOpacity
        }
    }
    /**
     Color of the card's shadow.
     */
    @IBInspectable public var _shadowColor: UIColor = UIColor.black {
        didSet{
            self.layer.shadowColor = _shadowColor.cgColor
        }
    }
    /**
     The image to display in the background.
     */
    @IBInspectable public var backgroundImage: UIImage? {
        didSet{
            self.backgroundIV.image = backgroundImage
        }
    }
    /**
     Corner radius of the card.
     */
    @IBInspectable public var cardRadius: CGFloat = 7.5 {
        didSet{
            self.layer.cornerRadius = cardRadius
        }
    }
    /**
     Insets between card's content and edges ( in percentage )
     */
    @IBInspectable public var contentInset: CGFloat = 15 {
        didSet {
            insets = LayoutHelper(rect: originalFrame).X(contentInset)
        }
    }
    /**
     Color of the card's background.
     */
    override open var backgroundColor: UIColor? {
        didSet(new) {
            if let color = new { backgroundIV.backgroundColor = color }
            if backgroundColor != UIColor.clear { backgroundColor = UIColor.clear }
        }
    }
    
    /**
     If the card should display parallax effect.
     */
    public var hasParallax: Bool = true {
        didSet {
            if self.motionEffects.isEmpty && hasParallax { goParallax() }
            else if !hasParallax && !motionEffects.isEmpty { motionEffects.removeAll() }
        }
    }
    
    //Private Vars
    fileprivate var tap = UITapGestureRecognizer()
    var originalFrame = CGRect.zero
    public var backgroundIV = UIImageView()
    public var insets = CGFloat()
    
    //MARK: - View Life Cycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    open func initialize() {
        
        // Tap gesture init
        self.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        
        // Adding Subviews
        self.addSubview(backgroundIV)
        
        backgroundIV.isUserInteractionEnabled = true
        backgroundColor = Color.blue.darken3
        
        if backgroundIV.backgroundColor == nil {
            backgroundIV.backgroundColor = UIColor.white
            super.backgroundColor = UIColor.clear
        }
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        originalFrame = rect
        
        self.layer.shadowOpacity = _shadowOpacity
        self.layer.shadowColor = _shadowColor.cgColor
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = shadowBlur
        self.layer.cornerRadius = cardRadius
        
        backgroundIV.image = backgroundImage
        backgroundIV.layer.cornerRadius = self.layer.cornerRadius
        backgroundIV.clipsToBounds = true
        backgroundIV.contentMode = .scaleAspectFill
        
        backgroundIV.frame.origin = bounds.origin
        backgroundIV.frame.size = CGSize(width: bounds.width, height: bounds.height)
        contentInset = 6
    }
    
    
    //MARK: - Layout
    
    open func layout(animating: Bool = true){ }
    
    
    //MARK: - Actions
    
    @objc func cardTapped() {
        pushBackAnimated()
        
        delay(0.2) {
            self.resetAnimated()
        }
    }
    
    
    //MARK: - Animations
    
    private func pushBackAnimated() {
        
        UIView.animate(withDuration: 0.2, animations: { self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) })
    }
    
    private func resetAnimated() {
        
        UIView.animate(withDuration: 0.2, animations: { self.transform = CGAffineTransform.identity })
    }
    
    func goParallax() {
        let amount = 20
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        self.addMotionEffect(group)
    }
    
}

extension UILabel {
    
    func lineHeight(_ height: CGFloat) {
        
        let attributedString = NSMutableAttributedString(string: self.text!)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = height
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        self.attributedText = attributedString
    }
    
}

import UIKit

@IBDesignable open class CardHighlight: Card {
    
    /**
     Text of the title label.
     */
    @IBInspectable public var title: String = "welcome \nto \ncards !" {
        didSet{
            titleLbl.text = title.uppercased()
            titleLbl.lineHeight(0.70)
        }
    }
    /**
     Max font size the title label.
     */
    @IBInspectable public var titleSize:CGFloat = 10.0
    /**
     Max font size the subtitle label of the item at the bottom.
     */
    @IBInspectable public var itemTitleSize: CGFloat = 8
    /**
     Text of the subtitle label of the item at the bottom.
     */
    @IBInspectable public var itemSubtitle: String = "Flap that !" {
        didSet{
            itemSubtitleLbl.text = itemSubtitle
        }
    }
    /**
     Max font size the subtitle label of the item at the bottom.
     */
    @IBInspectable public var itemSubtitleSize: CGFloat = 8
    /**
     Image displayed in the icon ImageView.
     */
    @IBInspectable public var icon: UIImage? {
        didSet{
            iconIV.image = icon
            bgIconIV.image = icon
            
            iconIV.backgroundColor = UIColor.white
            bgIconIV.backgroundColor = UIColor.white
        }
    }
    /**
     Corner radius for the icon ImageView
     */
    @IBInspectable public var iconRadius: CGFloat = 3.75 {
        didSet{
            iconIV.layer.cornerRadius = iconRadius
            bgIconIV.layer.cornerRadius = iconRadius*2
        }
    }
    /**
     Text for the card's button.
     */
    @IBInspectable public var buttonText: String = "Go" {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    @objc var action: (() -> Void)?
    
    @objc func execute(_ sender: Any?) {
        
        delay(0.3) {
            self.action?()
        }
    }
    
    public var actionBtn = UIButton()
    
    //Priv Vars
    private var iconIV = UIImageView()
    private var titleLbl = UILabel ()
    private var itemSubtitleLbl = UILabel()
    private var lightColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
    private var bgIconIV = UIImageView()
    
    fileprivate var btnWidth = CGFloat()
    
    // View Life Cycle
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override open func initialize() {
        super.initialize()
        
        backgroundIV.addSubview(iconIV)
        backgroundIV.addSubview(titleLbl)
        backgroundIV.addSubview(itemSubtitleLbl)
        backgroundIV.addSubview(actionBtn)
        
        if backgroundImage == nil {  backgroundIV.addSubview(bgIconIV); }
        else { bgIconIV.alpha = 0 }
    }
    
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
        //Draw
        bgIconIV.image = icon
        bgIconIV.alpha = backgroundImage != nil ? 0 : 0.6
        bgIconIV.clipsToBounds = true
        
        iconIV.image = icon
        iconIV.clipsToBounds = true
        
        titleLbl.text = title.uppercased()
        titleLbl.textColor = textColor
        titleLbl.font = UIFont.systemFont(ofSize: titleSize, weight: .heavy)
        titleLbl.adjustsFontSizeToFitWidth = true
        titleLbl.lineHeight(0.70)
        titleLbl.minimumScaleFactor = 0.1
        titleLbl.lineBreakMode = .byTruncatingTail
        titleLbl.numberOfLines = 3
        titleLbl.clipsToBounds = false
        backgroundIV.bringSubview(toFront: titleLbl)
        
        itemSubtitleLbl.textColor = textColor
        itemSubtitleLbl.text = itemSubtitle
        itemSubtitleLbl.font = UIFont.systemFont(ofSize: itemSubtitleSize)
        itemSubtitleLbl.adjustsFontSizeToFitWidth = true
        itemSubtitleLbl.lineHeight(0.70)
        itemSubtitleLbl.minimumScaleFactor = 0.1
        itemSubtitleLbl.lineBreakMode = .byTruncatingTail
        itemSubtitleLbl.numberOfLines = 2
        
        actionBtn.backgroundColor = UIColor.clear
        actionBtn.layer.backgroundColor = lightColor.cgColor
        actionBtn.clipsToBounds = true
        let btnTitle = NSAttributedString(string: buttonText.uppercased(), attributes: [ NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12, weight: .black), NSAttributedString.Key.foregroundColor : self.tintColor])
        actionBtn.setAttributedTitle(btnTitle, for: .normal)
        actionBtn.addTarget(self, action: #selector(execute), for: .touchUpInside)
        btnWidth = CGFloat((buttonText.count + 2) * 10)
        
        layout()
        
    }
    
    override open func layout(animating: Bool = true) {
        super.layout(animating: animating)
        
        let gimme = LayoutHelper(rect: backgroundIV.frame)
        
        iconIV.frame = CGRect(x: insets,
                              y: insets,
                              width: gimme.Y(25),
                              height: gimme.Y(25))
        
        titleLbl.frame.origin = CGPoint(x: insets, y: gimme.Y(5, from: iconIV))
        titleLbl.frame.size.width = (originalFrame.width * 0.8) + ((backgroundIV.bounds.width - originalFrame.width)/3)
        titleLbl.frame.size.height = gimme.Y(25)
        
        actionBtn.frame = CGRect(x: gimme.RevX(0, width: btnWidth) - insets,
                                 y: gimme.RevY(0, height: 16) - insets,
                                 width: btnWidth,
                                 height: 16)
        actionBtn.layer.cornerRadius = actionBtn.layer.bounds.height/2
        actionBtn.animateTouch()
        backgroundIV.bringSubview(toFront: actionBtn)
        
        itemSubtitleLbl.frame.origin = CGPoint(x: insets, y: titleLbl.frame.maxY - 2.5)
        itemSubtitleLbl.frame.size.width = gimme.X(60)
        itemSubtitleLbl.frame.size.height = gimme.Y(20)
        
        bgIconIV.transform = CGAffineTransform.identity
        
        iconIV.layer.cornerRadius = iconRadius
        
        bgIconIV.frame.size = CGSize(width: iconIV.bounds.width * 2.3, height: iconIV.bounds.width * 2.3)
        bgIconIV.frame.origin = CGPoint(x: gimme.RevX(0, width: bgIconIV.frame.width) + LayoutHelper.Width(40, of: bgIconIV) , y: 0)
        
        
        bgIconIV.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/6))
        bgIconIV.layer.cornerRadius = iconRadius * 2
    }
    
    //Actions
}


//
//  Lay.swift
//  Cards
//
//  Created by Paolo on 15/10/17.
//  Copyright © 2017 Apple. All rights reserved.
//
import Foundation
import UIKit

open class LayoutHelper {
    
    let rect: CGRect
    
    public init(rect: CGRect) {
        self.rect = rect
    }
    
    open func X(_ percentage: CGFloat) -> CGFloat {
        return percentage * rect.width / 100
    }
    
    open func Y(_ percentage: CGFloat) -> CGFloat {
        return percentage * rect.height / 100
    }
    
    open func X(_ percentage: CGFloat, from: UIView) -> CGFloat {
        return X(percentage) + from.frame.maxX
    }
    
    open func Y(_ percentage: CGFloat, from: UIView) -> CGFloat {
        return Y(percentage) + from.frame.maxY
    }
    
    open func RevX(_ percentage: CGFloat, width: CGFloat) -> CGFloat {
        return (rect.width - X(percentage)) - width
    }
    
    open func RevY(_ percentage: CGFloat, height: CGFloat) -> CGFloat {
        return (rect.height - Y(percentage)) - height
    }
    
    open func RevY(_ percentage: CGFloat, height: CGFloat, from: UIView) -> CGFloat {
        return from.frame.minY - Y(percentage) - height
    }
    
    static public func Width(_ percentage: CGFloat, of view: UIView) -> CGFloat {
        return view.frame.width * (percentage / 100)
    }
    
    static public func Height(_ percentage: CGFloat, of view: UIView) -> CGFloat {
        return view.frame.height * (percentage / 100)
    }
    
    static public func XScreen(_ percentage: CGFloat) -> CGFloat {
        
        
        return percentage * UIScreen.main.bounds.height / 100
        
    }
    
    static public func YScreen(_ percentage: CGFloat) -> CGFloat {
        
        
        return percentage * UIScreen.main.bounds.width / 100
        
    }
    
}

extension CGRect {
    
    var center: CGPoint {
        return CGPoint(x: width/2 + minX, y: height/2 + minY)
    }
}
