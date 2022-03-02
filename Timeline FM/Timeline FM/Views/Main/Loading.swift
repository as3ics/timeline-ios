//
//  Loading.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/15/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import RevealingSplashView

class Loading: UIViewController, CLLocationManagerDelegate, MapViewProtocol, MKMapViewDelegate {

    @IBOutlet var mapView: MapView!
    @IBOutlet var largeLogo: UIImageView!
    @IBOutlet var loadingLabel: UILabel!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = mapView
        
        mapView.mapType = .satelliteFlyover
        mapView.alpha = 1.0
        largeLogo.alpha = 0.0
        loadingLabel.alpha = 0.0
        
        splash()
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
    
    // Do not touch if don't have to
    @objc func loading() {
        mapView.alpha = 0.0
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude + 30.0)
        region.span = MKCoordinateSpan(latitudeDelta: ABSOLUTE_MAX_DELTA_LAT / 6.0, longitudeDelta: ABSOLUTE_MAX_DELTA_LON / 6.0)
        mapView.setRegion(region, animated: false)
        mapView.showsUserLocation = false
        mapView.alpha = 1.0
        clearMap(all: false)
        largeLogo.image = AssetManager.shared.launchLogo?.withRenderingMode(.alwaysTemplate)
        largeLogo.tintColor = UIColor.white.withAlphaComponent(0.9)
        loadingLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        
        Notifications.shared.observeSystemMessage(label: loadingLabel)
        Notifications.shared.system_message.observe(self, selector: #selector(loadingProgressHandler))
        
        delay(2.0) {
            LocationManager.shared.holdState(true)
            Commander.shared.load { _ in
                LocationManager.shared.holdState(false)
                Notifications.shared.releaseSystemMessageObserver()
            }
        }
        
        UIView.animate(withDuration: 1.5, delay: 1.25, options: [.curveLinear], animations: {
            self.largeLogo.alpha = 1.0
            self.loadingLabel.alpha = 1.0
        }, completion: nil)
        
        MKMapView.animate(withDuration: 90.0, delay: 0.01, usingSpringWithDamping: 1.0, initialSpringVelocity: 2.0, options: [UIViewAnimationOptions.curveEaseInOut, UIViewAnimationOptions.allowAnimatedContent], animations: {
            var region = MKCoordinateRegion()
            region.center = CLLocationCoordinate2D(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude - 30.0)
            region.span = MKCoordinateSpan(latitudeDelta: ABSOLUTE_MAX_DELTA_LAT / 6.0, longitudeDelta: ABSOLUTE_MAX_DELTA_LON / 6.0)
            
            self.mapView.setRegion(region, animated: true)
        })
    }
    
    
    // Do not touch if don't have to
    @objc func loadingCompleted() {
        loadingLabel.removeFromSuperview()
        
        var region = MKCoordinateRegion()
        region.center = self.mapView.userLocation.coordinate // coordinate
        region.span = MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0)
        MKMapView.animate(withDuration: 1.6, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 60.0, options: [.curveEaseOut], animations: {
            self.mapView.setRegion(region, animated: true)
        }, completion: nil)
        
        self.animateIn()
    }
    
    // Do not touch if don't have to
    @objc func animateIn() {
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [], animations: {
            self.largeLogo.alpha = CGFloat(0.0)
        }, completion: nil)
        
        UIView.animate(withDuration: 0.75, delay: 0.25, options: [.curveLinear], animations: {
            self.mapView.alpha = 0.00
        }, completion: nil)
        
        delay(1.25) {
            self.completeAnimateIn()
        }
    }
    
    // Do not touch if don't have to
    @objc func completeAnimateIn() {
        
        largeLogo.removeFromSuperview()
        App.shared.isLoaded = true
        
        let transitionView = UIStoryboard.Main(identifier: "TransitionView")
        transitionView.view.backgroundColor = UIColor.black
        transitionView.view.alpha = 0.0
        var options = UIWindow.TransitionOptions(direction: .fade, style: .linear)
        options.duration = 0.05
        options.background = UIWindow.TransitionOptions.Background.customView(transitionView)
        
        Navigator.shared.goTo(section: Navigator.shared.sections[0], options: options)
    }
    
    // Do not touch if don't have to
    @objc func loadingProgressHandler(_: NSNotification) {
        delay(0.1) {
            let _words = self.loadingLabel.text?.split(separator: " ", maxSplits: 10, omittingEmptySubsequences: false)
            
            guard let words = _words, words.count > 0 else {
                return
            }
            
            if words[0] == "Error" {
                delay(1.0) {
                    Shortcuts.goLogin()
                }
            } else if self.loadingLabel.text == "No Active Timesheet" || self.loadingLabel.text == "Timesheet Loaded" {
                delay(1.0) {
                    Notifications.shared.releaseSystemMessageObserver()
                    self.loadingLabel.text = nil
                    self.loadingCompleted()
                }
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
