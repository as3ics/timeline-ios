//
//  APIExtensions.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/24/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

protocol RegionProtocol {
    
    var region: MKCoordinateRegion? { get set }
}


protocol SearchControllerProtocol: UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    
    associatedtype Item: APIModelProtocol
    
    var tableView: UITableView! { get set }
    var items: [Item] { get }
    var filtering: Bool { get set }
    var searchController: UISearchController { get set }
    var filteredItems: [Item] { get set }
    var keypaths: [KeyPath<Item, String?>] { get set }
}

protocol AssetsProtocol {
    
    var assets: JSON { get set }
    static var assetKeys: [String] { get set }
    
    func asset(named: String) -> JSONObject?
    func addAsset(named: String, _ value: JSONObject?)
    func clearAssets()
}

protocol LocationProtocol {
    
    var latitude: String? { get set }
    var longitude: String? { get set }
    var lat: Double? { get set }
    var lon: Double? { get set }
    var coordinate: CLLocationCoordinate2D? { get set }
    var location: CLLocation? { get set }
}


extension LocationProtocol {
    
    var lat: Double? {
        get {
            guard let latitude = latitude else {
                return nil
            }
            
            return Double(latitude)
        }
        
        set {
            guard let latitude = newValue else {
                return
            }
            
            self.latitude = String(format: "%0.7f", latitude)
        }
    }
    
    var lon: Double? {
        get {
            guard let longitude = longitude else {
                return nil
            }
            
            return Double(longitude)
        }
        
        set {
            guard let longitude = newValue else {
                return
            }
            
            self.longitude = String(format: "%0.7", longitude)
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        
        get {
            guard let latitude = lat, let longitude = lon else {
                return nil
            }
            
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        set {
            guard let coordinate = newValue else {
                return
            }
            
            lat = coordinate.latitude
            lon = coordinate.longitude
        }
    }
    
    var location: CLLocation? {
        
        get {
            guard let latitude = lat, let longitude = lon else {
                return nil
            }
            
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        
        set {
            guard let location = newValue else {
                return
            }
            
            lat = location.coordinate.latitude
            lon = location.coordinate.longitude
        }
    }
}

extension AssetsProtocol {
    
    func asset(named: String) -> JSONObject? {
        return self.assets[named]
    }
    
    func addAsset(named: String, _ value: JSONObject?) {
        guard let asset = value else { return }
        
        var assets = self.assets
        assets[named] = asset
    }
    
    func clearAssets() {
        var assets = self.assets
        
        for key in type(of: self).assetKeys {
            assets[key] = nil
        }
    }
}

