//
//  CenterLocationViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/6/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import MapKit
import UIKit
import CoreLocation

// MARK: - CenterLocation

class CenterLocation: ViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var mapView: MapView!
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }

    var originalLat: Double?
    var originalLon: Double?

    var location: Location?

    var selectionIndex: Int = 0
    var selectionHeader = [NSLocalizedString("CenterLocationViewController_Address", comment: ""), NSLocalizedString("CenterLocationViewController_Location", comment: ""), NSLocalizedString("CenterLocationViewController_Custom", comment: "")]
    var selectionDescription = [NSLocalizedString("CenterLocationViewController_AddressDetail", comment: ""), NSLocalizedString("CenterLocationViewController_LocationDetail", comment: ""), NSLocalizedString("CenterLocationViewController_CustomDetail", comment: "")]

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none

        mapView.delegate = mapView
        
        if location != nil {
            let address = String(format: "%@, %@, %@ %@", location!.address!, location!.city!, location!.state!, location!.zip!)

            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(address) { placemarks, _ in
                guard
                    let placemarks = placemarks,
                    let location = placemarks.first?.location
                else {
                    // handle no location found
                    return
                }

                // Use your location
                self.location?.lat = location.coordinate.latitude
                self.location?.lon = location.coordinate.longitude

                self.originalLat = self.location?.lat
                self.originalLon = self.location?.lon

                let coordinate = CLLocationCoordinate2D(latitude: Double(self.originalLat!), longitude: Double(self.originalLon!))

                let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: DEFAULT_DELTA_REGION_LAT, longitudeDelta: DEFAULT_DELTA_REGION_LON))
                self.mapView.setRegion(region, animated: false)

                self.updateAnnotation(coordinate)
                self.updateLocation()
            }
        }

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        StandardTextFieldCell.register(tableView)
        StandardHeaderCell.register(tableView)
        StandardDescriptionCell.register(tableView)
        StandardTextFieldCell.register(tableView)

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        prepareForDeinit()
    }
    
    override func setupNavBar() {
        navBar?.title = "Center Location"
        
        navBar?.rightImage = UIImage(named: "next-red")
        navBar?.rightEnclosure = { self.goNext() }
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
    }

    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else if section == 1 {
            return 4
        } else {
            return 0
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = StandardDescriptionCell.loadNib(tableView)

                cell.content.text = NSLocalizedString("CenterLocationViewController_Description", comment: "")

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Center Location Method"

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = NSLocalizedString("CenterLocationViewController_Center", comment: "")
                cell.contents.text = selectionHeader[selectionIndex]
                cell.contents.isUserInteractionEnabled = false

                cell.selectionStyle = .none
                return cell
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = StandardDescriptionCell.loadNib(tableView)

                cell.content.text = selectionDescription[selectionIndex]

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Determined Coordinates"

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = NSLocalizedString("CenterLocationViewController_Latitude", comment: "")
                cell.contents.text = location!.latitude!
                cell.contents.isUserInteractionEnabled = false

                cell.contents.textColor = UIColor.lightGray
                cell.carrot.alpha = 0
                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 3 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = NSLocalizedString("CenterLocationViewController_Longitude", comment: "")
                cell.contents.text = location!.longitude!
                cell.contents.isUserInteractionEnabled = false

                cell.contents.textColor = UIColor.lightGray
                cell.carrot.alpha = 0
                cell.selectionStyle = .none
                return cell
            }
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.setSelected(false, animated: true)

        if (indexPath.section == 0) && (indexPath.row == 2) {
            Generator.bump()

            let picker = ActionSheetStringPicker(title: NSLocalizedString("CenterLocationViewController_SelectOption", comment: ""), rows: selectionHeader, initialSelection: selectionIndex, doneBlock: {
                _, index, _ in

                Generator.bump()

                self.selectionIndex = index as Int
                self.updateLocation()
                self.tableView.reloadData()
                return
            }, cancel: { _ in
                Generator.bump()
                return
            }, origin: tableView)

            styleActionSheetStringPicker(picker!)

            picker!.show()
        }
    }
    
    // MARK: - Other Functions

    func updateLocation() {
        if selectionIndex == 0 {
            self.location!.lat = originalLat
            self.location!.lon = originalLon

            let location = CLLocationCoordinate2D(latitude: self.location!.lat!, longitude: self.location!.lon!)
            updateAnnotation(location)

            tableView.reloadData()

        } else if selectionIndex == 1 {
            self.location!.lat = mapView.userLocation.coordinate.latitude
            self.location!.lon = mapView.userLocation.coordinate.longitude

            let location = CLLocationCoordinate2D(latitude: self.location!.lat!, longitude: self.location!.lon!)
            updateAnnotation(location)

            let coordinate = CLLocationCoordinate2D(latitude: self.location!.lat!, longitude: self.location!.lon!)
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: DEFAULT_DELTA_REGION_LAT, longitudeDelta: DEFAULT_DELTA_REGION_LON))
            mapView.setRegion(region, animated: false)

            tableView.reloadData()
        } else if selectionIndex == 2 {
            let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPressRecogniser.minimumPressDuration = 0.1
            mapView.addGestureRecognizer(longPressRecogniser)
        }
    }

    @objc func handleLongPress(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != .began { return }

        if selectionIndex == 2 {
            Generator.bump()

            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            location!.lat = touchMapCoordinate.latitude
            location!.lon = touchMapCoordinate.longitude

            updateAnnotation(touchMapCoordinate)

            tableView.reloadData()
        }
    }

    func updateAnnotation(_ location: CLLocationCoordinate2D) {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)

        // Drop a pin
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = location

        if let name = self.location!.name {
            dropPin.title = name
        } else {
            dropPin.title = NSLocalizedString("CenterLocationViewController_NewLocation", comment: "")
        }

        mapView.addAnnotation(dropPin)
    }

    @objc func goNext() {
        
        let destination = UIStoryboard.Location(identifier: "CreateBoundary") as! CreateBoundary
        destination.location = location
        destination.mode = ViewingMode.Creating

        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        navBar?.rightButton.tintColor = UIColor.red
    }
}
