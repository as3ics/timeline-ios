//
//  CreateBoundaryForLocationViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/5/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import MapKit
import PKHUD
import UIKit
import CoreLocation
import Material


let CONVERSION_RADIUS_TO_REGION_DIVISOR: CLLocationDegrees = 30000.0

// MARK: - CreateBoundary

class CreateBoundary: ViewController, UITableViewDelegate, UITableViewDataSource, MapViewProtocol, MKMapViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var mapView: MapView!
    
    override var usesIQKeyboard: Bool {
        return true
    }

    var location: Location?
    var originalLocation: Location?
    var updateId: String?
    var tempBoundaries = [CLLocationCoordinate2D]()
    
    var selectionHeader = [NSLocalizedString("CreateBoundaryForLocationViewController_ByRadius", comment: ""), NSLocalizedString("CreateBoundaryForLocationViewController_Custom", comment: "")]
    var selectionDescription = [NSLocalizedString("CreateBoundaryForLocationViewController_CircleDetail", comment: ""), NSLocalizedString("CreateBoundaryForLocationViewController_CustomDetail", comment: "")]

    var tempRadius: Double = 25.0
    var tempCenter: CLLocationCoordinate2D?

    var selectionMode: SelectionMode = .circle
    
    enum SelectionMode: Int {
        case circle = 0
        case boundary = 1
    }
    
    // Max and Min Radius's for Create Circle Boundary in Meters
    
    let MAX_LOCATION_RADIUS_M: Double = 1000.0
    let MIN_LOCATION_RADIUS_M: Double = 25.0
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
        
        mapView.delegate = mapView

        if mode == ViewingMode.Creating {
            location!.radius = String(25.0)
            tempRadius = 25.0
            tempCenter = location?.coordinate

        } else if mode == ViewingMode.Editing {
            originalLocation = Location()

            if updateId == nil {
                goBack()
                return
            } else if let id = updateId,  let location = Locations.shared[id] {
               
                originalLocation?.latitude = location.latitude
                originalLocation?.longitude = location.longitude

                tempRadius = Double(location.radius!)!
                if location.boundaryType == "Polygon" {
                    tempBoundaries = location.boundaryCoordinates
                }

                tempCenter = location.coordinate
            }
        }

        StandardHeaderCell.register(tableView)
        StandardTextFieldCell.register(tableView)
        StandardDescriptionCell.register(tableView)
        StandardSliderCell.register(tableView)
        StandardTwoButtonCell.register(tableView)

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        updateOverlay()
        updateAnnotation()

        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressRecogniser.minimumPressDuration = 0.1
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if mode == ViewingMode.Editing {
            selectionMode = tempBoundaries.count > 0 ? .boundary : .circle
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        prepareForDeinit()
    }
    
    override func setupNavBar() {
        navBar?.title = mode == ViewingMode.Creating ? "Create Boundary" : "Update Boundary"
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
        
        navBar?.rightImage = mode == ViewingMode.Creating ? AssetManager.shared.add : AssetManager.shared.save
        navBar?.rightEnclosure = mode == ViewingMode.Creating ? { self.create() } : { self.save() }
    }
    
    @objc override func goBack() {
        if let originalLocation = originalLocation {
            if let location = Locations.shared[updateId] {
                location.latitude = originalLocation.latitude
                location.longitude = originalLocation.longitude
            }
        }

        super.goBack()
    }

    // MARK: - UITableView Delegate and DataSource

    func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 60
        } else {
            return 50
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = StandardDescriptionCell.loadNib(tableView)

                cell.content.text = NSLocalizedString("CreateBoundaryForLocationViewController_Description", comment: "")

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Boundary Method"

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 2 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = NSLocalizedString("CreateBoundaryForLocationViewController_Boundary", comment: "")
                cell.contents.text = selectionHeader[selectionMode.rawValue]
                cell.contents.isUserInteractionEnabled = false

                cell.selectionStyle = .none
                return cell
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = StandardDescriptionCell.loadNib(tableView)

                cell.content.text = selectionDescription[selectionMode.rawValue]

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 1 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Controls"

                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == 2 {
                if selectionMode == .circle {
                    let cell = StandardSliderCell.loadNib(tableView)

                    let radiusValue = (Float(tempRadius) - Float(MIN_LOCATION_RADIUS_M)) / Float(MAX_LOCATION_RADIUS_M - MIN_LOCATION_RADIUS_M)

                    cell.slider.value = radiusValue
                    cell.label.text = String(format: "%.1fm", Double(tempRadius))

                    cell.slider.addTarget(self, action: #selector(CreateBoundary.sliderValueChanged), for: UIControlEvents.valueChanged)

                    updateOverlay()

                    cell.selectionStyle = .none
                    return cell
                } else if selectionMode == .boundary {
                    let cell = StandardTwoButtonCell.loadNib(tableView)

                    cell.leftButton.style(Color.blue.darken3, image: nil, title: "Remove All")
                    cell.leftButton.addTarget(self, action: #selector(clearButtonPressed), for: .touchUpInside)
                    
                    cell.rightButton.style(Color.green.darken3, image: nil, title: "Remove Last")
                    cell.rightButton.addTarget(self, action: #selector(removeLastButtonPressed), for: .touchUpInside)

                    updatePolygonRender()

                    cell.selectionStyle = .none
                    return cell
                }
            }
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.setSelected(false, animated: true)

        if (indexPath.section == 0) && (indexPath.row == 2) {
            
            Generator.bump()
            
            let picker = ActionSheetStringPicker(title: NSLocalizedString("CreateBoundaryForLocationViewController_SelectOption", comment: ""), rows: selectionHeader, initialSelection: selectionMode.rawValue, doneBlock: {
                _, index, _ in
                Generator.bump()
                self.selectionMode = SelectionMode(rawValue: index)!

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
    
    @objc func create() {
        
        PKHUD.loading()
        
        guard var location = location else {
            PKHUD.failure()
            return
        }
        
        location.lat = tempCenter?.latitude
        location.lon = tempCenter?.longitude
        
        if selectionMode == .boundary {
            
            guard tempBoundaries.count > 2 else {
                Generator.failure()
                PKHUD.failure()
                return
            }
            
            location.boundaryCoordinates = tempBoundaries
            location.boundaryType = "Polygon"
        } else {
            location.radius = String(tempRadius)
            location.boundaryType = "Circle"
        }
        
        Async.waterfall(0, [location.updateAssets, location.create], end: { error, _ in
            guard error == nil else {
                Generator.failure()
                PKHUD.failure()
                return
            }
            
            Generator.confirm()
            PKHUD.success()
            
            self.navigationController?.popToRootViewController(animated: true)
            
        })
    }

    @objc func save() {
        
        PKHUD.loading()

        guard updateId != nil, var location = Locations.shared[updateId] else {
            Generator.failure()
            PKHUD.failure()
            return
        }
        
        if selectionMode == .boundary {
            
            guard tempBoundaries.count > 2 else {
                Generator.failure()
                PKHUD.failure()
                return
            }
            
            location.boundaryCoordinates = tempBoundaries
            location.boundaryType = "Polygon"

        } else {
            location.radius = String(tempRadius)
            location.boundaryType = "Circle"
        }
        
        location.coordinate = tempCenter
        
        location.reprocessAssets { (success) in
            guard success == true else {
                Generator.failure()
                PKHUD.failure()
                return
            }
            
            self.originalLocation = nil
            Generator.confirm()
            PKHUD.success()
            self.goBack()
        }
    }

    @objc func sliderValueChanged() {
        let indexPath = IndexPath(row: 2, section: 1)
        let cell = tableView.cellForRow(at: indexPath) as! StandardSliderCell
        updateRadius(sliderCell: cell)
    }

    func updateRadius(sliderCell: StandardSliderCell) {
        let sliderValue = pow(sliderCell.slider.value, 4)

        tempRadius = (Double(sliderValue) * (MAX_LOCATION_RADIUS_M - MIN_LOCATION_RADIUS_M)) + MIN_LOCATION_RADIUS_M
        sliderCell.label.text = String(format: "%.1fm", tempRadius)

        updateOverlay()
    }

    func updateOverlay() {
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)

        if selectionMode == .circle {
            let circle = MKCircle(center: tempCenter!, radius: tempRadius)
            mapView.add(circle)

            let region = MKCoordinateRegion(center: tempCenter!, span: MKCoordinateSpan(latitudeDelta: tempRadius / CONVERSION_RADIUS_TO_REGION_DIVISOR, longitudeDelta: tempRadius / CONVERSION_RADIUS_TO_REGION_DIVISOR))
            mapView.setRegion(region, animated: false)
        }
    }

    @objc func handleLongPress(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != .began { return }

        Generator.bump()
        
        if selectionMode == .boundary {

            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            tempBoundaries.append(touchMapCoordinate)

            updatePolygonRender()
        } else if selectionMode == .circle {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            tempCenter! = touchMapCoordinate

            updateAnnotation()
            updateOverlay()
        }
    }

    @objc func clearButtonPressed() {
        
        tempBoundaries.removeAll()
        updatePolygonRender()
    }

    @objc func removeLastButtonPressed() {
        if tempBoundaries.count >= 1 {
            
            tempBoundaries.removeLast()
            updatePolygonRender()
        }
    }

    func updatePolygonRender() {
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)

        if selectionMode == .boundary {
            // is in polygon mode
            var boundaries = tempBoundaries

            // To complete the polygon add first entry to end
            if boundaries.count > 0 {
                // Complete the path of the polygon
                boundaries.append(boundaries[0])

                let polyOverlay = MKPolygon(coordinates: boundaries, count: boundaries.count)
                let lineOverlay = MKPolyline(coordinates: boundaries, count: boundaries.count)

                mapView.add(polyOverlay)
                mapView.add(lineOverlay)
            }
        }
    }

    func updateAnnotation() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)

        // Drop a pin
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = tempCenter!

        var name: String?
        if mode == ViewingMode.Creating {
            name = location?.name
        } else {
            name = Locations.shared[updateId]?.name
        }

        dropPin.title = name
        mapView.addAnnotation(dropPin)
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        navBar?.rightButton.tintColor = UIColor.red
    }
}
