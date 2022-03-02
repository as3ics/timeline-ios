//
//  TimelineOnboard.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/3/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import Material
import SnapKit
import CoreLocation
import UserNotifications
import PKHUD
import MapKit
import RevealingSplashView

@objc class TimelineOnboard: UIViewController, UIScrollViewDelegate, CLLocationManagerDelegate, MapViewProtocol, MKMapViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var indicatorView: UIView!
    
    @IBOutlet var mapView: MapView!
    @IBOutlet var largeLogo: UIImageView!
    @IBOutlet var loadingLabel: UILabel!
    
    let pageCount: Int = 4
    var locationManager = CLLocationManager()
    fileprivate var width: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    fileprivate var height: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    var previousIndex:Int = 0
    var initialized: Bool = false {
        didSet {
            if initialized == true {
                self.loadScrollView()
                self.updateLocationValues()
                self.updateNotificationValues()
            }
        }
    }
    
    @objc var locationStatus: CLAuthorizationStatus = .notDetermined {
        didSet {
            if index == ScrollViewPage.page4_Verification.rawValue {
                (self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.button.rawValue] as! FlatButton).isEnabled = locationStatus == .authorizedAlways ? true : false
                (self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.button.rawValue] as! FlatButton).alpha = locationStatus == .authorizedAlways ? 1.0 : 0.5
            }
        }
    }
    
    @objc var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    enum ScrollViewPage: Int {
        case page1_Welcome = 0
        case page2_Location = 1
        case page3_Notification = 2
        case page4_Verification = 3
    }
    
    enum Page1_Welcome: Int {
        case title = 0
        case subtitle = 1
        case webView = 2
        case label = 3
    }
    
    enum Page2_Location: Int {
        case title = 0
        case subtitle = 1
        case image = 2
        case button = 3
        case checkmark = 4
    }
    
    enum Page3_Notification: Int {
        case title = 0
        case subtitle = 1
        case image = 2
        case button = 3
        case checkmark = 4
    }
    
    enum Page4_Verification: Int {
        case notificationVerification = 0
        case locationVerification = 1
        case title = 2
        case subtitle = 3
        case button = 4
        case image = 5
    }
    
    enum VerificationLabel: Int {
        case status = 0
        case label = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        
        view.backgroundColor = UIColor.black
        
        scrollView.delegate = self
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            self.notificationStatus = settings.authorizationStatus
        }
        
        NotificationManager.shared.notifications_registered.observe(self, selector: #selector(notificationAuthorizationNotification))
        
        mapView.delegate = mapView
        
        indicatorView.backgroundColor = UIColor.blue
        
        mapView.mapType = .satelliteFlyover
        mapView.alpha = 1.0
        largeLogo.alpha = 0.0
        loadingLabel.alpha = 0.0
        
        splash()
     }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard initialized == true else {
            return
        }
        
        updateNotificationValues()
    }
    
    func loadScrollView() {
        
        self.locationStatus = LocationManager.shared.authorizationStatus
        
        scrollView.addSubview(page1)
        scrollView.addSubview(page2)
        scrollView.addSubview(page3)
        scrollView.addSubview(page4)
        
        scrollView.contentSize = CGSize(width: width * CGFloat(pageCount), height: height)
        scrollView.frame = scrollView.frame.applying(CGAffineTransform(scaleX: CGFloat(pageCount), y: 1))
        scrollView.bounds = UIScreen.main.bounds
        scrollView.layoutIfNeeded()
        scrollView.isPagingEnabled = true
        // Do any additional setup after loading the view.
        
        scrollView.backgroundColor = UIColor.clear
        
        self.view.backgroundColor = UIColor.black
        backgroundImage.image = UIImage(named: "flyover")
        backgroundImage.alpha = 0.8
    }
    
    // Do not touch if don't have to
    @objc func loading() {
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: 43.0, longitude: -80.0)
        region.span = MKCoordinateSpan(latitudeDelta: ABSOLUTE_MAX_DELTA_LAT / 5.0, longitudeDelta: ABSOLUTE_MAX_DELTA_LON / 5.0)
        mapView.setRegion(region, animated: false)
        mapView.showsUserLocation = false
        clearMap()
        largeLogo.image = UIImage(named: "launch-logo")?.withRenderingMode(.alwaysTemplate)
        largeLogo.tintColor = UIColor.white.withAlphaComponent(0.9)
        loadingLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        loadingLabel.text = "Preparing for first use"
        
        MKMapView.animate(withDuration: 25.0, delay: 0.01, usingSpringWithDamping: 1.0, initialSpringVelocity: 2.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            var region = MKCoordinateRegion()
            region.center = CLLocationCoordinate2D(latitude: 43.0, longitude: -110.0)
            region.span = MKCoordinateSpan(latitudeDelta: ABSOLUTE_MAX_DELTA_LAT / 5.0, longitudeDelta: ABSOLUTE_MAX_DELTA_LON / 5.0)
            
            self.mapView.setRegion(region, animated: true)
        })
        
        //self.loadingLabel.transform = CGAffineTransform(translationX: 0, y: -self.height)
        //self.largeLogo.transform = CGAffineTransform(translationX: 0, y: -self.height)
        self.largeLogo.alpha = 0.0
        self.loadingLabel.alpha = 0.0
        UIView.animateAndChain(withDuration: 1.5, delay: 1.5, options: [], animations: {
            //self.loadingLabel.transform = .identity
            //self.largeLogo.transform = .identity
            self.loadingLabel.alpha = 1.0
            self.largeLogo.alpha = 1.0
        }, completion: nil).animate(withDuration: 2.0, delay: 2.0, options: [], animations: {
            //self.loadingLabel.transform = CGAffineTransform(translationX: -self.width, y: 0)
            //self.largeLogo.transform = CGAffineTransform(translationX: -self.width, y: 0)
            self.loadingLabel.alpha = 0.0
            self.largeLogo.alpha = 0.0
            self.view.alpha = 0.0
            
            var region = MKCoordinateRegion()
            region.center = CLLocationCoordinate2D(latitude: 43.0, longitude: -82.0) // coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0)
            MKMapView.animate(withDuration: 3.0, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 60.0, options: [.curveEaseOut], animations: {
                self.mapView.setRegion(region, animated: true)
            }, completion: nil)
            
        }, completion: { _ in
            self.initialized = true
            self.mapView.alpha = 0.0
        }).animate(withDuration: 1.0) {
            self.view.alpha = 1.0
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func splash() {
        
        let imageView = UIImageView(image: UIImage(named: "launch-logo"))
        imageView.contentMode = .scaleAspectFit
        
        let revealingSplashView = RevealingSplashView(iconImage: imageView.image!, iconInitialSize: CGSize(width: UIScreen.main.bounds.width, height: Device.phoneType == .iPhone5 ? 140 : 163), backgroundColor: Theme.shared.active.primaryBackgroundColor)
        
        self.view.addSubview(revealingSplashView)
        
        delay(0.5) {
            self.loading()
            revealingSplashView.startAnimation { revealingSplashView.removeFromSuperview() }
        }
    }
    
    var page1: UIView {
        let frame = CGRect(x: width * CGFloat(0), y: 0, width: width, height: height)
        let view = UIView(frame: frame)
        view.backgroundColor = UIColor.clear
        
        let title = UILabel()
        title.text = "Welcome to Timeline!"
        title.numberOfLines = 1
        title.height = 50.0
        
        view.addSubview(title)
        
        styleTitle(label: title)
        
        let subtitle = UILabel()
        subtitle.text = "Please take a moment to learn about Timeline"
        subtitle.numberOfLines = 2
        subtitle.height = 50.0
        
        view.addSubview(subtitle)
        
        styleSubtitle(label: subtitle)
        
        let webView = UIWebView()
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        webView.backgroundColor = UIColor.black
        webView.scrollView.backgroundColor = UIColor.black
        webView.alpha = 1.0
        webView.scrollView.isScrollEnabled = false
        webView.shadowColor = UIColor.black
        webView.shadowOffset = CGSize(width: 1, height: 5)
        webView.shadowRadius = 20.0
        webView.shadowOpacity = 1.0
        //webView.layer.masksToBounds = true
        //webView.layer.cornerRadius = 7.5
        
        webView.loadHTMLString(self.html, baseURL: Bundle.main.resourceURL)
        
        view.addSubview(webView)
        
        webView.snp.makeConstraints { (make) in
            make.height.equalTo(165)
            make.width.equalTo(300)
            make.centerX.equalTo(view.snp.centerX)
            make.centerY.equalTo(height/2.0 + 45.0)
        }
        
        let label = UILabel()
        label.text = "Pinch out on video to expand"
        label.font = UIFont(name: FONT_APPLE_SD_GOTHIC_NEO, size: Device.phoneType == iPhone.iPhone5 ? 12.0 : 14.0)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.shadowColor = UIColor.black.withAlphaComponent(0.3)
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.shadowOpacity = 0.5
        label.height = 20.0
        
        view.addSubview(label)
        
        label.snp.makeConstraints { (make) in
            make.width.equalTo(width * 0.9)
            make.height.equalTo(label.height)
            make.centerX.equalTo(label.superview!.snp.centerX)
            make.top.equalTo(height / 2.0 + 150.0)
        }
        
        return view
    }
    
    var page2: UIView {
        
        let frame = CGRect(x: width * CGFloat(1), y: 0, width: width, height: height)
        let view = UIView(frame: frame)
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
    
        let title = UILabel()
        title.text = "Authorize Location Access"
        title.numberOfLines = 2
        title.height = 50.0
        
        view.addSubview(title)
        
        styleTitle(label: title)
        
        let subtitle = UILabel()
        
        subtitle.numberOfLines = 5
        subtitle.height = 100.0
        
        view.addSubview(subtitle)
        
        styleSubtitle(label: subtitle)
        
        let image = self.locationStatus == .authorizedAlways || self.locationStatus == .authorizedWhenInUse ? UIImageView(image: UIImage(named: "map-check")) : UIImageView(image: UIImage(named: "always-allow"))
        image.tintColor = UIColor.white
        image.contentMode = .scaleAspectFit
        image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(authorizeLocationServices)))
        image.isUserInteractionEnabled = true
        
        view.addSubview(image)
        
        image.snp.makeConstraints { (make) in
            make.width.equalTo(250)
            make.height.equalTo(250)
            make.centerX.equalTo(view.snp.centerX)
            make.top.equalTo(Device.hasNotch == true ? height * 0.45 : height * 0.475)
        }
        
        image.transform = CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0)
        
        let button = FlatButton()
        button.style(Color.blue.darken3, image: nil, title: "Authorize Location")
        
        view.addSubview(button)
        
        styleButton(button: button)
        
        let checkmark = UIImageView()
        
        view.addSubview(checkmark)
        
        checkmark.snp.makeConstraints({ (make) in
            make.height.equalTo(27.5)
            make.width.equalTo(27.5)
            make.centerX.equalTo(button.snp.right)
            make.centerY.equalTo(button.snp.top)
        })
        
        return view
    }
    
    
    func updateLocationValues() {
        
        DispatchQueue.main.async {
            
            self.updateVerificationLabels()
            
            let locationCheckmark = self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.locationVerification.rawValue].subviews[VerificationLabel.status.rawValue] as! UIImageView
            
            
            UIView.animateAndChain(withDuration: 0.2, delay: 0.0, options: [], animations: {
                locationCheckmark.transform = CGAffineTransform(scaleX: 0, y: 0)
            }, completion: { _ in
                locationCheckmark.image = self.locationStatus == .authorizedAlways || self.locationStatus == .authorizedWhenInUse ? UIImage(named: "Select") : UIImage(named: "Delete")
            }).animate(withDuration: 0.2, animations: {
                locationCheckmark.transform = .identity
            })
            
            
            let status = self.locationStatus
            
            let button = self.scrollView.subviews[ScrollViewPage.page2_Location.rawValue].subviews[Page2_Location.button.rawValue] as! FlatButton
            let checkmark = self.scrollView.subviews[ScrollViewPage.page2_Location.rawValue].subviews[Page2_Location.checkmark.rawValue] as! UIImageView
            let image = self.scrollView.subviews[ScrollViewPage.page2_Location.rawValue].subviews[Page2_Location.image.rawValue] as! UIImageView
            let subtitle = self.scrollView.subviews[ScrollViewPage.page2_Location.rawValue].subviews[Page2_Location.subtitle.rawValue] as! UILabel
        
            UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                image.transform = CGAffineTransform(translationX: -self.width, y: 0)
                checkmark.transform = CGAffineTransform(scaleX: 0, y: 0)
            }, completion: { _ in
                image.transform = CGAffineTransform(translationX: self.width, y: 0)
                image.image = status == .authorizedAlways || self.locationStatus == .authorizedWhenInUse ? UIImage(named:"map-check") : UIImage(named:"always-allow")
                checkmark.image = status == .authorizedAlways || self.locationStatus == .authorizedWhenInUse ? UIImage(named: "Select") : status == .notDetermined ? nil : UIImage(named: "Delete")
            })
            
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                
                image.snp.makeConstraints({ (make) in
                    make.width.equalTo(Device.phoneType != .iPhone5 ? 250 : 200)
                    make.height.equalTo(Device.phoneType != .iPhone5 ? 250 : 200)
                })
                
                UIView.animate(withDuration: 0.4, delay: 0.4, options: [], animations: {
                    button.backgroundColor = Color.green.darken3
                    button.title = "Location Authorized"
                    subtitle.text = "You have authorized Timeline to access your location. Swipe left to continue."
                }, completion: { _ in
                
                })
                
                button.removeTarget(button, action: #selector(button.touchAnimation), for: .allEvents)
                button.removeTarget(self, action: #selector(self.authorizeLocationServices), for: .allEvents)
                
                guard self.index == ScrollViewPage.page2_Location.rawValue else {
                    return
                }
                
                UIView.animateAndChain(withDuration: 0.4, delay: 0.5, options: [], animations: {
                    image.transform = .identity
                }, completion: nil).animate(withDuration: 0.2, animations: {
                    checkmark.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }).animate(withDuration: 0.2, animations: {
                    checkmark.transform = .identity
                })
            } else {
                
                image.snp.makeConstraints({ (make) in
                    make.width.equalTo(Device.phoneType != .iPhone5 ? 250 : 200)
                    make.height.equalTo(Device.phoneType != .iPhone5 ? 250 : 200)
                })
                
                UIView.animate(withDuration: 0.4, delay: 0.4, options: [], animations: {
                    button.backgroundColor = status == .notDetermined ? Color.blue.darken3 : Color.red.darken3
                    button.title = "Authorize Location"
                    subtitle.text = "Timeline can use your location to automate many features. Provide Timeline access?"
                }, completion: nil)
                
                button.animateTouch()
                button.addTarget(self, action: #selector(self.authorizeLocationServices), for: .touchUpInside)
                
                guard self.index == ScrollViewPage.page2_Location.rawValue else {
                    return
                }
                
                UIView.animateAndChain(withDuration: 0.4, delay: 0.5, options: [], animations: {
                    image.transform = .identity
                }, completion: nil).animate(withDuration: 0.2, animations: {
                    checkmark.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }).animate(withDuration: 0.2, animations: {
                    checkmark.transform = .identity
                })
            }
        }
    }
    
    var page3: UIView {
        let frame = CGRect(x: width * CGFloat(2), y: 0, width: width, height: height)
        let view = UIView(frame: frame)
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        
        let title = UILabel()
        title.text = "Authorize Notifications"
        title.numberOfLines = 2
        title.height = 50.0
        
        view.addSubview(title)
        
        styleTitle(label: title)
        
        let subtitle = UILabel()
        subtitle.numberOfLines = 3
        subtitle.height = 75.0
        
        view.addSubview(subtitle)
        
        styleSubtitle(label: subtitle)
        
        let image = UIImageView(image: UIImage(named: "notification"))
        image.tintColor = UIColor.white
        image.contentMode = .scaleAspectFit
        image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(authorizeNotifications)))
        image.isUserInteractionEnabled = true
        
        view.addSubview(image)
        
        image.snp.makeConstraints { (make) in
            make.width.equalTo(300.0)
            make.height.equalTo(350.0)
            make.centerX.equalTo(view.snp.centerX)
            make.top.equalTo(Device.hasNotch == true ? height * 0.35: height * 0.3)
        }
        
        let button = FlatButton()
        button.style(Color.blue.darken3, image: nil, title: "Authorize Notifications")
        
        view.addSubview(button)
        
        styleButton(button: button)
        
        let checkmark = UIImageView()
        
        view.addSubview(checkmark)
        
        checkmark.snp.makeConstraints({ (make) in
            make.height.equalTo(27.5)
            make.width.equalTo(27.5)
            make.centerX.equalTo(button.snp.right)
            make.centerY.equalTo(button.snp.top)
        })
        
        return view
    }
    
    func updateNotificationValues() {
            self.updateVerificationLabels()
            
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
                self.notificationStatus = settings.authorizationStatus
                
                
                DispatchQueue.main.async {
                    
                let notificationCheckmark = self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.notificationVerification.rawValue].subviews[VerificationLabel.status.rawValue] as! UIImageView
                
                UIView.animateAndChain(withDuration: 0.2, delay: 0.0, options: [], animations: {
                    notificationCheckmark.transform = CGAffineTransform(scaleX: 0, y: 0)
                }, completion: { _ in
                    notificationCheckmark.image = self.notificationStatus == .authorized ? UIImage(named: "Select") : UIImage(named: "Delete")
                }).animate(withDuration: 0.2, animations: {
                    notificationCheckmark.transform = .identity
                })
                
                let status = self.notificationStatus
                
                let button = self.scrollView.subviews[ScrollViewPage.page3_Notification.rawValue].subviews[Page3_Notification.button.rawValue] as! FlatButton
                let checkmark = self.scrollView.subviews[ScrollViewPage.page3_Notification.rawValue].subviews[Page3_Notification.checkmark.rawValue] as! UIImageView
                let image = self.scrollView.subviews[ScrollViewPage.page3_Notification.rawValue].subviews[Page3_Notification.image.rawValue] as! UIImageView
                let subtitle = self.scrollView.subviews[ScrollViewPage.page3_Notification.rawValue].subviews[Page3_Notification.subtitle.rawValue] as! UILabel
                
                
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    image.transform = CGAffineTransform(translationX: -self.width, y: 0)
                    checkmark.transform = CGAffineTransform(scaleX: 0, y: 0)
                }, completion: { _ in
                    image.transform = CGAffineTransform(translationX: self.width, y: 0)
                    image.image = status == .authorized ? UIImage(named:"notification-check") : UIImage(named:"notification-error")
                    checkmark.image = status == .authorized ? UIImage(named: "Select") : status == .notDetermined ? nil : UIImage(named: "Delete")
                })
                
                if status == .authorized {
                    
                    UIView.animate(withDuration: 0.4, delay: 0.4, options: [], animations: {
                        button.backgroundColor = Color.green.darken3
                        button.title = "Notifications Authorized"
                        subtitle.text = "You have authorized notifications for Timeline. Swipe left to continue."
                    }, completion: { _ in
                        
                    })
                    
                    button.removeTarget(button, action: #selector(button.touchAnimation), for: .allEvents)
                    button.removeTarget(self, action: #selector(self.authorizeNotifications), for: .allEvents)
                    
                    guard self.index == ScrollViewPage.page3_Notification.rawValue else {
                        return
                    }
                    
                    UIView.animateAndChain(withDuration: 0.4, delay: 0.5, options: [], animations: {
                        image.transform = .identity
                    }, completion: nil).animate(withDuration: 0.2, animations: {
                        checkmark.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }).animate(withDuration: 0.2, animations: {
                        checkmark.transform = .identity
                    })
                } else {
                    
                    UIView.animate(withDuration: 0.4, delay: 0.4, options: [], animations: {
                        button.backgroundColor = status == .notDetermined ? Color.blue.darken3 : Color.red.darken3
                        button.title = "Authorize Notifications"
                        subtitle.text = status == .notDetermined ? "Recieve alerts for important events and messages." : "Allow notifications to recieve important status changes in Timeline."
                    }, completion: nil)
                    
                    button.animateTouch()
                    button.addTarget(self, action: #selector(self.authorizeNotifications), for: .touchUpInside)
                    
                    guard self.index == ScrollViewPage.page3_Notification.rawValue else {
                        return
                    }
                    
                    UIView.animateAndChain(withDuration: 0.4, delay: 0.5, options: [], animations: {
                        image.transform = .identity
                    }, completion: nil).animate(withDuration: 0.2, animations: {
                        checkmark.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }).animate(withDuration: 0.2, animations: {
                        checkmark.transform = .identity
                    })
                }
            }
        })
    }
    
    var page4: UIView {
        let frame = CGRect(x: width * CGFloat(3), y: 0, width: width, height: height)
        let view = UIView(frame: frame)
        view.backgroundColor = UIColor.clear
        
        DispatchQueue.main.async {
            
            let labelBackgroundNotifications = UIImageView(image: UIImage(named: "labelBackground"))
            
            let labelStatusNotifications = UIImageView()
            
            if self.notificationStatus != .authorized {
                labelStatusNotifications.image = UIImage(named: "Delete")
            } else {
                labelStatusNotifications.image = UIImage(named: "Select")
            }
            
            let labelNotifications = UILabel()
            labelNotifications.text = "Notifications"
            labelNotifications.font = UIFont(name: FONT_APPLE_SD_GOTHIC_NEO, size: 18.0)
            labelNotifications.textColor = UIColor.black
            labelNotifications.textAlignment = .center
            
            labelBackgroundNotifications.addSubview(labelStatusNotifications)
            labelBackgroundNotifications.addSubview(labelNotifications)
            
            labelStatusNotifications.snp.makeConstraints({ (make) in
                make.centerY.equalTo(labelBackgroundNotifications.snp.centerY)
                make.left.equalTo(7.5)
                make.height.equalTo(22)
                make.width.equalTo(22)
            })
            
            labelNotifications.snp.makeConstraints({ (make) in
                make.centerY.equalTo(labelBackgroundNotifications.snp.centerY)
                make.centerX.equalTo(labelBackgroundNotifications.snp.centerX)
                make.height.equalTo(22)
                make.width.equalTo(250)
            })
            
            labelBackgroundNotifications.alpha = 0.0
            labelBackgroundNotifications.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.authorizeNotifications)))
            labelBackgroundNotifications.isUserInteractionEnabled = true
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].addSubview(labelBackgroundNotifications)
            
            labelBackgroundNotifications.snp.makeConstraints({ (make) in
                make.centerX.equalTo(labelBackgroundNotifications.superview!.snp.centerX)
                make.top.equalTo(Device.hasNotch == true ? self.height - 180.0 : self.height - 130.0)
                make.height.equalTo(40)
                make.width.equalTo(300)
            })
        
            let labelBackgroundLocation = UIImageView(image: UIImage(named: "labelBackground"))
            
            let labelStatusLocation = UIImageView()
            
            if self.locationStatus == .authorizedAlways || self.locationStatus == .authorizedWhenInUse {
                labelStatusLocation.image = UIImage(named: "Select")
            } else {
                labelStatusLocation.image = UIImage(named: "Delete")
            }
            
            
            let labelLocations = UILabel()
            labelLocations.text = "Location Services"
            labelLocations.font = UIFont(name: FONT_APPLE_SD_GOTHIC_NEO, size: 18.0)
            labelLocations.textColor = UIColor.black
            labelLocations.textAlignment = .center
            
            labelBackgroundLocation.addSubview(labelStatusLocation)
            labelBackgroundLocation.addSubview(labelLocations)
            
            labelStatusLocation.snp.makeConstraints({ (make) in
                make.centerY.equalTo(labelBackgroundLocation.snp.centerY)
                make.left.equalTo(7.5)
                make.height.equalTo(22)
                make.width.equalTo(22)
            })
            
            labelLocations.snp.makeConstraints({ (make) in
                make.centerY.equalTo(labelBackgroundLocation.snp.centerY)
                make.centerX.equalTo(labelBackgroundLocation.snp.centerX)
                make.height.equalTo(22)
                make.width.equalTo(250)
            })
            
            labelBackgroundLocation.alpha = 0.0
            labelBackgroundLocation.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.authorizeLocationServices)))
            labelBackgroundLocation.isUserInteractionEnabled = true
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].addSubview(labelBackgroundLocation)
            
            labelBackgroundLocation.snp.makeConstraints({ (make) in
                make.centerX.equalTo(labelBackgroundLocation.superview!.snp.centerX)
                make.top.equalTo(Device.hasNotch == true ? self.height - 240.0 : self.height - 180.0)
                make.height.equalTo(40)
                make.width.equalTo(300)
            })
    
            
            let title = UILabel()
            title.text = nil
            title.numberOfLines = 3
            title.height = 75.0
            
            title.alpha = 0.0
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].addSubview(title)
            
            self.styleTitle(label: title)
            
            let subtitle = UILabel()
            subtitle.text = nil
            subtitle.numberOfLines = 5
            subtitle.height = 100.0
            
            subtitle.alpha = 0.0
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].addSubview(subtitle)
            
            self.styleSubtitle(label: subtitle)
            
            let button = FlatButton()
            button.style(Color.blue.darken3, image: nil, title: "Continue")
            button.addTarget(self, action: #selector(self.goLogin), for: .touchUpInside)
            button.isEnabled = self.locationStatus == .authorizedAlways || self.locationStatus == .authorizedWhenInUse ? true : false
            
            button.alpha = 0.0
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].addSubview(button)
            
            self.styleButton(button: button)
            
            let image = UIImageView(image: UIImage(named: "ndp-check"))
            image.contentMode = .scaleAspectFit
            image.animateTouch()
            
            image.alpha = 0.0
            view.addSubview(image)
            
            image.snp.makeConstraints { (make) in
                make.width.equalTo(Device.phoneType == .iPhone5 ? 250 : 250)
                make.height.equalTo(Device.phoneType == .iPhone5 ? 150 : 250)
                make.centerX.equalTo(view.snp.centerX)
                make.centerY.equalTo(self.height / 2 + 35.0)
            }
        }
        
        return view
    }
    
    var index: Int {
        let offset = min(max(scrollView.contentOffset.x, 0), scrollView.contentSize.width)
        
        let index = Int(offset / width)
        return index
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print(index)
        
        if index != ScrollViewPage.page4_Verification.rawValue, previousIndex ==  ScrollViewPage.page4_Verification.rawValue {
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.title.rawValue].alpha = 0.0
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.subtitle.rawValue].alpha = 0.0
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.locationVerification.rawValue].alpha = 0.0
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.notificationVerification.rawValue].alpha = 0.0
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.image.rawValue].alpha = 0.0
            self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.button.rawValue].alpha = 0.0
        }
        
        if index != ScrollViewPage.page2_Location.rawValue {
            (self.scrollView.subviews[ScrollViewPage.page2_Location.rawValue].subviews[Page2_Location.image.rawValue] as! UIImageView).transform = index <= 0 ? CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0) :  CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
            (self.scrollView.subviews[ScrollViewPage.page2_Location.rawValue].subviews[Page2_Location.checkmark.rawValue] as! UIImageView).transform = CGAffineTransform(scaleX: 0, y: 0)
        }
        
        if index != ScrollViewPage.page3_Notification.rawValue {
            (self.scrollView.subviews[ScrollViewPage.page3_Notification.rawValue].subviews[Page3_Notification.image.rawValue] as! UIImageView).transform = index <= 1 ? CGAffineTransform(translationX: UIScreen.main.bounds.width, y: 0) :  CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
            (self.scrollView.subviews[ScrollViewPage.page3_Notification.rawValue].subviews[Page2_Location.checkmark.rawValue] as! UIImageView).transform = CGAffineTransform(scaleX: 0, y: 0)
        }
        
        if index == ScrollViewPage.page1_Welcome.rawValue, previousIndex != ScrollViewPage.page1_Welcome.rawValue {
            DispatchQueue.main.async {
                
                UIView.transition(with: self.backgroundImage,
                                  duration:0.5,
                                  options: .transitionCrossDissolve,
                                  animations: { self.backgroundImage.image = UIImage(named: "flyover") },
                                  completion: nil)
                
                let webView = self.scrollView.subviews[ScrollViewPage.page1_Welcome.rawValue].subviews[Page1_Welcome.webView.rawValue] as! UIWebView
                
                webView.loadHTMLString(self.html, baseURL: Bundle.main.resourceURL)
            }
            
            previousIndex = index
        } else if index > ScrollViewPage.page1_Welcome.rawValue {
            let webView = self.scrollView.subviews[ScrollViewPage.page1_Welcome.rawValue].subviews[Page1_Welcome.webView.rawValue] as! UIWebView
            
            webView.loadHTMLString("", baseURL: nil)
            
            if index == ScrollViewPage.page2_Location.rawValue {
                UIView.transition(with: self.backgroundImage,
                                  duration:0.5,
                                  options: .transitionCrossDissolve,
                                  animations: { self.backgroundImage.image = UIImage(named: "chicago") },
                                  completion: nil)
                
                let checkmark = self.scrollView.subviews[ScrollViewPage.page2_Location.rawValue].subviews[Page2_Location.checkmark.rawValue] as! UIImageView
                
                 let image = self.scrollView.subviews[ScrollViewPage.page2_Location.rawValue].subviews[Page2_Location.image.rawValue] as! UIImageView
                
                let button = self.scrollView.subviews[ScrollViewPage.page2_Location.rawValue].subviews[Page2_Location.button.rawValue] as! FlatButton
                
                
                UIView.animateAndChain(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    image.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }, completion: nil).animate(withDuration: 0.2) {
                    image.transform = .identity
                }
                
                checkmark.transform = CGAffineTransform(scaleX: 0, y: 0)
                UIView.animateAndChain(withDuration: 0.2, delay: 0.5, options: [], animations: {
                    checkmark.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                }, completion: nil).animate(withDuration: 0.2) {
                    checkmark.transform = .identity
                }
                
                UIView.animateAndChain(withDuration: 0.2, delay: 0.5, options: [], animations: {
                    button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }, completion: nil).animate(withDuration: 0.2) {
                    button.transform = .identity
                }
                
                /*
                if self.locationStatus != .authorizedAlways {
                    delay(1.0) {
                        self.authorizeLocationServices(self)
                    }
                }
                */
                
            } else if index == ScrollViewPage.page3_Notification.rawValue {
                UIView.transition(with: self.backgroundImage,
                                  duration:0.5,
                                  options: .transitionCrossDissolve,
                                  animations: { self.backgroundImage.image = UIImage(named: "newyork") },
                                  completion: nil)
                
                let checkmark = self.scrollView.subviews[ScrollViewPage.page3_Notification.rawValue].subviews[Page3_Notification.checkmark.rawValue] as! UIImageView
                
                let image = self.scrollView.subviews[ScrollViewPage.page3_Notification.rawValue].subviews[Page3_Notification.image.rawValue] as! UIImageView
                
                let button = self.scrollView.subviews[ScrollViewPage.page3_Notification.rawValue].subviews[Page3_Notification.button.rawValue] as! FlatButton
                
                UIView.animateAndChain(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    image.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }, completion: nil).animate(withDuration: 0.2) {
                    image.transform = .identity
                }
                
                checkmark.transform = CGAffineTransform(scaleX: 0, y: 0)
                UIView.animateAndChain(withDuration: 0.2, delay: 0.5, options: [], animations: {
                    checkmark.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                }, completion: nil).animate(withDuration: 0.2) {
                    checkmark.transform = .identity
                }
                
                UIView.animateAndChain(withDuration: 0.2, delay: 0.5, options: [], animations: {
                    button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }, completion: nil).animate(withDuration: 0.2) {
                    button.transform = .identity
                }
                
                /*
                if self.notificationStatus != .authorized {
                    delay(1.0) {
                        self.authorizeNotifications(self)
                    }
                }
                */
                
            } else if index == ScrollViewPage.page4_Verification.rawValue, self.previousIndex != ScrollViewPage.page4_Verification.rawValue {
                UIView.transition(with: self.backgroundImage,
                                  duration:0.5,
                                  options: .transitionCrossDissolve,
                                  animations: { self.backgroundImage.image = UIImage(named: "frankfort") },
                                  completion: nil)
                
               
                
                DispatchQueue.main.async {
                    
                    PKHUD.loading()
                    
                    self.updateVerificationLabels()
                    
                    DispatchQueue.main.async {
                        (self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.locationVerification.rawValue].subviews[VerificationLabel.status.rawValue] as! UIImageView).image = self.locationStatus == .authorizedAlways || self.locationStatus == .authorizedWhenInUse ? UIImage(named: "Select") : UIImage(named: "Delete")
                        
                        (self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.notificationVerification.rawValue].subviews[VerificationLabel.status.rawValue] as! UIImageView).image = self.notificationStatus == .authorized ? UIImage(named: "Select") : UIImage(named: "Delete")
                    }
                    
                    self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.notificationVerification.rawValue].subviews[VerificationLabel.status.rawValue].transform = CGAffineTransform(scaleX: 0, y: 0)
                    self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.locationVerification.rawValue].subviews[VerificationLabel.status.rawValue].transform = CGAffineTransform(scaleX: 0, y: 0)
                    
                    UIView.animateAndChain(withDuration: 0.5, delay: 0.25, options: [], animations: {
                         self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.locationVerification.rawValue].alpha = 1.0
                    }, completion: nil).animate(withDuration: 0.2, animations: {
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.locationVerification.rawValue].subviews[VerificationLabel.status.rawValue].transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                    }).animate(withDuration: 0.2, animations: {
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.locationVerification.rawValue].subviews[VerificationLabel.status.rawValue].transform = .identity
                    }).animate(withDuration: 0.5, animations: {
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.notificationVerification.rawValue].alpha = 1.0
                        
                    }).animate(withDuration: 0.2, animations: {
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.notificationVerification.rawValue].subviews[VerificationLabel.status.rawValue].transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                        
                    }).animate(withDuration: 0.2, animations: {
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.notificationVerification.rawValue].subviews[VerificationLabel.status.rawValue].transform = .identity
                    }).animate(withDuration: 0.0, animations: {
                        PKHUD.success()
                    }).animate(withDuration: 0.5, animations: {
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.title.rawValue].alpha = 1.0
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.subtitle.rawValue].alpha = 1.0
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.button.rawValue].alpha = 1.0 // self.locationStatus == .authorizedAlways || self.locationStatus ==  .authorizedWhenInUse ? 1.0 : 0.5
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.image.rawValue].alpha = 1.0
                    }).animate(withDuration: 0.2, animations: {
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.image.rawValue].transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    }).animate(withDuration: 0.2, animations: {
                        self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.image.rawValue].transform = .identity
                    })
                }
            }
            
            previousIndex = index
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = (scrollView.contentOffset.x / (width * 3.0)) * indicatorView.width * 3.0
        
        indicatorView.transform = CGAffineTransform(translationX: offset, y: 0)
        
        
    }
    
    @objc func authorizeLocationServices(_ sender: Any) {
        if let sender = sender as? UITapGestureRecognizer {
            sender.view?.touchAnimation()
        }
        
        delay(0.2) {
            if LocationManager.shared.authorizationStatus == .notDetermined {
                LocationManager.shared.requestAuthorization()
            } else if LocationManager.shared.authorizationStatus != .authorizedAlways {
                External.shared.phoneSettings()
            } else {
                self.updateLocationValues()
                /*
                 PKHUD.message(text: "Location services already authorized")
                 PKHUD.sharedHUD.hide(afterDelay: 0.75)
                 */
            }
            
        }
    }
    
    @objc func authorizeNotifications(_ sender: Any) {
        if let sender = sender as? UITapGestureRecognizer {
            sender.view?.touchAnimation()
        }
        
        delay(0.2) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .notDetermined {
                        Notifications.shared.registerForPushNotifications()
                    } else if settings.authorizationStatus != .authorized {
                        External.shared.phoneSettings()
                    } else {
                        self.updateNotificationValues()
                        /*
                         PKHUD.message(text: "Notifications already authorized")
                         PKHUD.sharedHUD.hide(afterDelay: 0.75)
                         */
                    }
                }
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        guard initialized == true else {
            return
        }
        
        self.locationStatus = status
        
        self.updateLocationValues()
        
        /*
        if status == .authorizedAlways, index > ScrollViewPage.page1_Welcome.rawValue {
            PKHUD.message(text: "Location Authorized")
            PKHUD.sharedHUD.hide(afterDelay: 0.5)
        }
        */
    }
    
    
    @objc func notificationAuthorizationNotification(_ sender: NSNotification) {
        guard let userInfo = sender.userInfo as? JSON, let success = userInfo["success"] as? Bool else {
            return
        }
        
        DispatchQueue.main.async {
            switch success {
            case true:
                self.notificationStatus = .authorized
                /*
                if self.index > ScrollViewPage.page1_Welcome.rawValue {
                    PKHUD.message(text: "Notifications Authorized")
                    PKHUD.sharedHUD.hide(afterDelay: 0.5)
                }
                */
                break
            case false:
                self.notificationStatus = .denied
            
                break
            }
            
            self.updateNotificationValues()
        }
    }
    
    func updateVerificationLabels() {
        
        guard index == ScrollViewPage.page4_Verification.rawValue else {
            return
        }
        
        DispatchQueue.main.async {
            
            var titleText: String?
            var subtitleText: String?
            var image: UIImage?
            var authorized: Bool = false
            if self.notificationStatus == .authorized, self.locationStatus == .authorizedAlways || self.locationStatus == .authorizedWhenInUse {
                titleText = "Timeline is Ready!"
                subtitleText = "Thank you for setting up Timeline. Press continue to login!"
                image = UIImage(named: "ndp-check")
                authorized = true
            } else if self.notificationStatus != .authorized, self.locationStatus != .authorizedAlways && self.locationStatus != .authorizedWhenInUse {
                titleText = "Location services have not been enabled"
                subtitleText = "For full functionality please enable location services, although you may continue."
                image = UIImage(named: "always-allow")
                authorized = true
            } else if self.notificationStatus != .authorized {
                titleText = "You're okay to continue"
                subtitleText = "You can setup notifications in the future if you wish from the settings menu."
                image = UIImage(named: "notification-error")
                authorized = true
            } else {
                titleText = "Location services have not been enabled"
                subtitleText = "For full functionality please enable location services, although you may continue."
                image = UIImage(named: "always-allow")
                authorized = true
            }
            
           
            (self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.title.rawValue] as! UILabel).text = titleText
            (self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.subtitle.rawValue] as! UILabel).text = subtitleText
            (self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.button.rawValue] as! FlatButton).isEnabled = authorized
            (self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.button.rawValue] as! FlatButton).alpha = authorized == true ? 1.0 : 0.5
            
            let imageview = self.scrollView.subviews[ScrollViewPage.page4_Verification.rawValue].subviews[Page4_Verification.image.rawValue] as! UIImageView
            
            UIView.animateAndChain(withDuration: 0.4, delay: 0.0, options: [], animations: {
               imageview.transform = CGAffineTransform(translationX: -self.width, y: 0)
            }, completion: { _ in
                imageview.image = image
            }).animate(withDuration: 0.4, animations: {
                imageview.transform = .identity
            })
            
        }
    }
    
    func styleTitle(label: UILabel) {
        label.font = UIFont(name: FONT_APPLE_SD_GOTHIC_NEO, size: Device.phoneType == iPhone.iPhone5 ? 21.0 : 24.0)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.shadowColor = UIColor.black.withAlphaComponent(0.3)
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.shadowOpacity = 0.5
        //label.backgroundColor = Theme.shared.active.placeholderColor
        //label.layer.masksToBounds = true
        //label.layer.cornerRadius = 7.5
        
        label.snp.makeConstraints { (make) in
            make.width.equalTo(width * 0.8)
            make.height.equalTo(label.height)
            make.centerX.equalTo(label.superview!.snp.centerX)
            make.top.equalTo(Device.hasNotch == true ? height * 0.15 : height * 0.15)
        }
    }
    
    func styleSubtitle(label: UILabel) {
        label.font = UIFont(name: FONT_APPLE_SD_GOTHIC_NEO, size: Device.phoneType == iPhone.iPhone5 ? 17.0 : 19.0)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.shadowColor = UIColor.black.withAlphaComponent(0.3)
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.shadowOpacity = 0.5
        //label.backgroundColor = Theme.shared.active.placeholderColor
        //label.layer.masksToBounds = true
        //label.layer.cornerRadius = 7.5
        
        label.snp.makeConstraints { (make) in
            make.width.equalTo(width * 0.9)
            make.height.equalTo(label.height)
            make.centerX.equalTo(label.superview!.snp.centerX)
            make.top.equalTo(Device.hasNotch == true ? height * 0.28 : height * 0.3)
        }
    }
    
    func styleButton(button: FlatButton) {
        button.corner = 5.0
        button.titleLabel?.font = UIFont(name: FONT_APPLE_SD_GOTHIC_NEO, size: button.titleLabel!.font.pointSize)
        button.shadowColor = UIColor.black
        button.shadowOffset = CGSize(width: 1, height: 5)
        button.shadowRadius = 10.0
        button.shadowOpacity = 0.5
        
        button.snp.makeConstraints { (make) in
            make.width.equalTo(260.0)
            make.height.equalTo(45.0)
            make.centerX.equalTo(button.superview!.snp.centerX)
            make.top.equalTo(Device.hasNotch == true ? height - 122.5: height - 80.0)
        }
    }
    
    @objc func goLogin(_ sender: Any) {
        
        DeviceSettings.shared.onboarded = true
        
        Auth.shared.flush()
        
        delay(0.2) {
            Shortcuts.goLogin()
        }
    }
    
    var html: String {
        return String(format: "<html> <body style='margin:0px;padding:0px;'><script type='text/javascript' src='http://www.youtube.com/iframe_api'></script><script type='text/javascript'>function onYouTubeIframeAPIReady(){ytplayer=new YT.Player('playerId',{events:{onReady:onPlayerReady}})}function onPlayerReady(a){a.target.playVideo();}</script><iframe id='playerId' type='text/html' width='%d' height='%d' src='http://www.youtube.com/embed/%@?enablejsapi=1&rel=0&playsinline=1&autoplay=1' frameborder='0'></body></html>", 300, 170, "-rNpddKkkXI")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
