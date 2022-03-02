//
//  Extensions.swift
//  Timeline CMMS
//
//  Created by Zachary DeGeorge on 9/23/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import Alamofire
import AlamofireImage
import AudioToolbox
import CoreLocation
import Foundation
import KeychainAccess
import MapKit
import Material
import PKHUD
import UIKit

extension UIWindow {
    
    var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom()
    }
    
    static func getVisibleViewControllerFrom(_ vc: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(tc.selectedViewController)
        } else if let dv = vc as? NavigationDrawerController {
            return UIWindow.getVisibleViewControllerFrom(dv.rootViewController)
        } else if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(nc.topViewController)
        } else if let pv = vc?.presentedViewController {
            return UIWindow.getVisibleViewControllerFrom(pv)
        } else {
            return vc
        }
    }
    
    var topViewController: UIViewController? {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            return topController
        }
        
        return nil
    }
    
    /// Transition Options
    struct TransitionOptions {
        /// Curve of animation
        ///
        /// - linear: linear
        /// - easeIn: ease in
        /// - easeOut: ease out
        /// - easeInOut: ease in - ease out
        enum Curve {
            case linear
            case easeIn
            case easeOut
            case easeInOut
            
            /// Return the media timing function associated with curve
            var function: CAMediaTimingFunction {
                let key: String!
                switch self {
                case .linear: key = kCAMediaTimingFunctionLinear
                case .easeIn: key = kCAMediaTimingFunctionEaseIn
                case .easeOut: key = kCAMediaTimingFunctionEaseOut
                case .easeInOut: key = kCAMediaTimingFunctionEaseInEaseOut
                }
                return CAMediaTimingFunction(name: key)
            }
        }
        
        /// Direction of the animation
        ///
        /// - fade: fade to new controller
        /// - toTop: slide from bottom to top
        /// - toBottom: slide from top to bottom
        /// - toLeft: pop to left
        /// - toRight: push to right
        enum Direction {
            case fade
            case toTop
            case toBottom
            case toLeft
            case toRight
            case middle
            
            /// Return the associated transition
            ///
            /// - Returns: transition
            func transition() -> CATransition {
                let transition = CATransition()
                transition.type = kCATransitionPush
                switch self {
                case .fade:
                    transition.type = kCATransitionFade
                    transition.subtype = nil
                case .toLeft:
                    transition.subtype = kCATransitionFromLeft
                case .toRight:
                    transition.subtype = kCATransitionFromRight
                case .toTop:
                    transition.subtype = kCATransitionFromTop
                case .toBottom:
                    transition.subtype = kCATransitionFromBottom
                case .middle:
                    transition.type = kCATransitionFade
                    transition.subtype = kCATruncationMiddle
                }
                return transition
            }
        }
        
        /// Background of the transition
        ///
        /// - solidColor: solid color
        /// - customView: custom view
        enum Background {
            case solidColor(_: UIColor)
            case customView(_: UIViewController)
        }
        
        /// Duration of the animation (default is 0.20s)
        var duration: TimeInterval = 0.35
        
        /// Direction of the transition (default is `toRight`)
        var direction: TransitionOptions.Direction = .toRight
        
        /// Style of the transition (default is `linear`)
        var style: TransitionOptions.Curve = .linear
        
        /// Background of the transition (default is `nil`)
        var background: TransitionOptions.Background?
        
        /// Initialize a new options object with given direction and curve
        ///
        /// - Parameters:
        ///   - direction: direction
        ///   - style: style
        init(direction: TransitionOptions.Direction = .toRight, style: TransitionOptions.Curve = .linear, _ duration: TimeInterval = 0.35) {
            self.duration = duration
            self.direction = direction
            self.style = style
        }
        
        init() {}
        
        /// Return the animation to perform for given options object
        var animation: CATransition {
            let transition = direction.transition()
            transition.duration = duration
            transition.timingFunction = style.function
            return transition
        }
    }
    
    /// Change the root view controller of the window
    ///
    /// - Parameters:
    ///   - controller: controller to set
    ///   - options: options of the transition
    func setRootViewController(_ controller: UIViewController, options: TransitionOptions = TransitionOptions()) {
        var transitionWnd: UIWindow?
        if let background = options.background {
            transitionWnd = UIWindow(frame: UIScreen.main.bounds)
            switch background {
            case let .customView(view):
                transitionWnd?.rootViewController = view
            case let .solidColor(color):
                transitionWnd?.backgroundColor = color
            }
            transitionWnd?.makeKeyAndVisible()
        }
        
        // Make animation
        layer.add(options.animation, forKey: kCATransition)
        rootViewController = controller
        makeKeyAndVisible()
        
        if let wnd = transitionWnd {
            DispatchQueue.main.asyncAfter(deadline: (.now() + 1 + options.duration), execute: {
                wnd.removeFromSuperview()
            })
        }
    }
}

extension UITableViewCell {
    static func defaultCell() -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        return cell
    }
}

extension UIImage {
    
    static func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func base64String() -> String? {
        let data: Data? = UIImagePNGRepresentation(self)
        
        return data?.base64EncodedString(options: .lineLength64Characters)
    }
    
    func correctlyOrientedImage() -> UIImage {
        if imageOrientation == UIImageOrientation.up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    var isPortrait: Bool { return size.height > size.width }
    var isLandscape: Bool { return size.width > size.height }
    var breadth: CGFloat { return min(size.width, size.height) }
    var breadthSize: CGSize { return CGSize(width: breadth, height: breadth) }
    var breadthRect: CGRect { return CGRect(origin: .zero, size: breadthSize) }
    var circleMasked: UIImage? {
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait ? floor((size.height - size.width) / 2) : 0), size: breadthSize)) else { return nil }
        UIBezierPath(ovalIn: breadthRect).addClip()
        UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation).draw(in: breadthRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIImageView {
    
    func setImage(image: UIImage?) {
        guard let image = image else {
            return
        }
        
        DispatchQueue.main.async {
            self.image = image
        }
    }
}


extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(red: (rgb >> 16) & 0xFF, green: (rgb >> 8) & 0xFF, blue: rgb & 0xFF)
    }
    
    convenience init?(hex: String) {
        let colorString = hex
        
        var a: CGFloat = 1
        var r: CGFloat = 1
        var b: CGFloat = 1
        var g: CGFloat = 1
        
        if colorString.characters.count == 3 { // #RGB
            a = 1.0
            r = UIColor.colorComponentFrom(colorString, start: 0, length: 1)
            g = UIColor.colorComponentFrom(colorString, start: 1, length: 1)
            b = UIColor.colorComponentFrom(colorString, start: 2, length: 1)
            
        } else if colorString.characters.count == 4 { // #ARGB
            a = UIColor.colorComponentFrom(colorString, start: 0, length: 1)
            r = UIColor.colorComponentFrom(colorString, start: 1, length: 1)
            g = UIColor.colorComponentFrom(colorString, start: 2, length: 1)
            b = UIColor.colorComponentFrom(colorString, start: 3, length: 1)
            
        } else if colorString.characters.count == 6 { // #RRGGBB
            a = 1.0
            r = UIColor.colorComponentFrom(colorString, start: 0, length: 2)
            g = UIColor.colorComponentFrom(colorString, start: 2, length: 2)
            b = UIColor.colorComponentFrom(colorString, start: 4, length: 2)
            
        } else if colorString.characters.count == 8 { // #AARRGGBB
            a = UIColor.colorComponentFrom(colorString, start: 0, length: 2)
            r = UIColor.colorComponentFrom(colorString, start: 2, length: 2)
            g = UIColor.colorComponentFrom(colorString, start: 4, length: 2)
            b = UIColor.colorComponentFrom(colorString, start: 6, length: 2)
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    class func colorComponentFrom(_ string: String, start: Int, length: Int) -> CGFloat {
        let substring = string.substring(with: string.characters.index(string.startIndex, offsetBy: start) ..< string.characters.index(string.startIndex, offsetBy: start + length))
        let fullHex = length == 2 ? substring : String(format: "%@%@", arguments: [substring, substring])
        let hexComponent: UnsafeMutablePointer<UInt32> = UnsafeMutablePointer.allocate(capacity: 1)
        Scanner(string: fullHex).scanHexInt32(hexComponent)
        return CGFloat(hexComponent.pointee) / CGFloat(255.0)
    }
    
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0
        
        return String(format: "%06x", arguments: [rgb])
    }
}

extension UIViewController {
    
    func styleSearchBar(_ searchController: UISearchController) {
        let searchBar = searchController.searchBar
        
        searchBar.searchBarStyle = UISearchBarStyle.default
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextPositionAdjustment = UIOffsetMake(10, 0)
        searchBar.placeholder = "Search Here"
        searchBar.setSearchFieldBackgroundImage(AssetManager.shared.clear, for: UIControlState.normal)
        searchBar.cornerRadius = 0
        searchBar.height = DEFAULT_SEARCHBAR_HEADER_HEIGHT
        searchBar.showsCancelButton = true
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!], for: [.normal])
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16.0)
        textFieldInsideUISearchBar?.textColor = ThemeManager.shared.theme.primaryFontColor
        textFieldInsideUISearchBar?.autoresizesSubviews = true
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self as? UISearchBarDelegate
        searchController.delegate = self as? UISearchControllerDelegate
        searchController.searchResultsUpdater = self as? UISearchResultsUpdating
    }
    
    func styleNavSearchBar(_ searchBar: UISearchBar) {
        searchBar.searchBarStyle = UISearchBarStyle.prominent
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextPositionAdjustment = UIOffsetMake(10, 0)
        searchBar.placeholder = "Search Here"
        searchBar.cornerRadius = 25
        searchBar.height = 50
        searchBar.tintColor = UIColor.white
        searchBar.image(for: UISearchBarIcon.search, state: UIControlState.normal)
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!], for: [.normal])
        
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16.0)
        textFieldInsideUISearchBar?.alpha = 0.85
        //textFieldInsideUISearchBar?.textColor = UIColor.white
        //textFieldInsideUISearchBar?.layer.height = (textFieldInsideUISearchBar?.layer.height)! + 5
        //textFieldInsideUISearchBar?.layer.cornerRadius = (textFieldInsideUISearchBar?.layer.height)! / 2.0
        //textFieldInsideUISearchBar?.layer.masksToBounds = true
    }
    
    func styleActionSheetStringPicker(_ picker: ActionSheetStringPicker) {
        picker.pickerTextAttributes.addEntries(from: [NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!])
        picker.titleTextAttributes = [NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!]
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: nil, action: nil)
        cancelButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!], for: [.normal])
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: nil, action: nil)
        doneButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!], for: [.normal])
        
        picker.setCancelButton(cancelButton)
        picker.setDoneButton(doneButton)
    }
    
    func styleActionSheetDatePicker(_ sender: ActionSheetDatePicker?) {
        guard let picker = sender else {
            return
        }
        
        picker.pickerTextAttributes.addEntries(from: [NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!])
        picker.titleTextAttributes = [NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!]
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: nil, action: nil)
        cancelButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!], for: [.normal])
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: nil, action: nil)
        doneButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 16)!], for: [.normal])
        
        picker.setCancelButton(cancelButton)
        picker.setDoneButton(doneButton)
    }
    
    func styleSwitch(_ swtch: UISwitch) {
        swtch.thumbTintColor = ThemeManager.shared.theme.secondaryBackgroundColor
        swtch.tintColor = ThemeManager.shared.theme.secondaryBackgroundColor
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func is3DTouchAvailable() -> Bool {
        return traitCollection.forceTouchCapability == UIForceTouchCapability.available
    }
    
    @objc func goBack() {
        guard let navigationController = self.navigationController else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        navigationController.popViewController(animated: true)
    }
    
    @objc func menuPressed() {
        navigationDrawerController?.openLeftView()
        navigationDrawerController?.isLeftPanGestureEnabled = true
    }
}

extension UIView {
    
    @objc func animateTouch() {
        if self is FlatButton {
            (self as! FlatButton).addTarget(self, action: #selector(touchAnimation), for: .touchUpInside)
        } else if self is UIButton {
            (self as! UIButton).addTarget(self, action: #selector(touchAnimation), for: .touchUpInside)
        } else {
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(touchAnimation)))
            isUserInteractionEnabled = true
        }
    }
    
    @objc func touchAnimation(_ silent: Bool = false) {
        if !silent {
            System.bump()
        }
        
        UIView.animateAndChain(withDuration: 0.1, delay: 0.0, options: [], animations: {
            self.transform = CGAffineTransform(scaleX: self.height > 75 ? 0.95 : 0.875, y: self.height > 75 ? 0.95 : 0.875)
        }, completion: nil).animateAndChain(withDuration: 0.1, delay: 0.0, options: [], animations: {
            self.transform = .identity
        }, completion: nil)
    }
    
    func purge(complete: Bool) {
        if self.subviews.count != 0 {
            for view in self.subviews {
                view.removeConstraints(view.constraints)
                for gesture in view.gestureRecognizers ?? []  {
                    view.removeGestureRecognizer(gesture)
                }
                view.purge(complete: true)
                view.removeFromSuperview()
            }
        }
        
        self.removeConstraints(self.constraints)
        for gesture in self.gestureRecognizers ?? []  {
            self.removeGestureRecognizer(gesture)
        }
        
        if complete == true {
            self.removeFromSuperview()
        }
    }
    
    var circle: Bool {
        set {
            switch newValue {
            case true:
                self.layer.masksToBounds = true
                self.layer.cornerRadius = self.layer.height / 2
                break
            case false:
                self.layer.masksToBounds = false
                self.layer.cornerRadius = 0
            }
        }
        
        get {
            return self.layer.cornerRadius != 0 && self.layer.masksToBounds == true
        }
    }
    
    var corner: CGFloat {
        set {
            self.layer.masksToBounds = true
            self.layer.cornerRadius = newValue
        }
        
        get {
            return self.layer.cornerRadius
        }
    }
}

extension String {
    
    func base64Image() -> UIImage? {
        let data: Data = Data(base64Encoded: self, options: .ignoreUnknownCharacters)!
        
        return UIImage(data: data)
    }
    
    subscript(i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
    subscript(i: Int) -> String {
        return String(self[i] as Character)
    }
}

extension FlatButton {
    
    func style(_ color: UIColor, image: UIImage?, title: String? = nil) {
        backgroundColor = color
        self.image = image?.withRenderingMode(.alwaysTemplate)
        self.title = title
        imageEdgeInsets = UIEdgeInsetsMake(6.5, 6.5, 6.5, 6.5)
        imageView?.contentMode = .scaleAspectFit
        tintColor = UIColor.white
        pulseColor = UIColor.white
        titleColor = UIColor.white
        isEnabled = true
        layer.masksToBounds = true
        animateTouch()
    }
    
    func removeTargets() {
        removeTarget(nil, action: nil, for: .allEvents)
    }
}

extension UILabel {
    func autoResize() {
        adjustsFontSizeToFitWidth = true
        allowsDefaultTighteningForTruncation = true
        minimumScaleFactor = 0.6
    }
}

extension UITextField {
    func autoResize() {
        adjustsFontSizeToFitWidth = true
        minimumFontSize = font!.pointSize * 0.6
    }
    
    func setLeftPadding(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    
    func setRightPadding(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}


// MARK: - Navigation Extensions

extension UIStoryboard {
    
    class func Main(identifier: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: identifier)
    }
}
