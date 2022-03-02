//
//  CreateLocationViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/4/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import MapKit
import PKHUD
import UIKit
import CoreLocation

// MARK: - CreateLocation

class CreateLocation: ViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UITextViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }

    var matchingItems: [MKMapItem] = []

    var location: Location?
    var searchController: UISearchController = UISearchController(searchResultsController: nil)

    // For creating region for local search
    
    let SEARCH_DELTA_REGION_LAT: Double = 2.0
    let SEARCH_DELTA_REGION_LON: Double = 2.0
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tableView.addGestureRecognizer(tap)

        definesPresentationContext = true
        tableView.tableHeaderView?.height = DEFAULT_SEARCHBAR_HEADER_HEIGHT
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.sizeToFit()
        styleSearchBar(searchController)

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        if self.location == nil {
            self.location = Location()
        }
        
        if self.location!.name == nil {
            if let placemark = LocationManager.shared.latestPlacemark, let latitude = placemark.location?.coordinate.latitude, let longitude = placemark.location?.coordinate.longitude {
                self.location?.name = placemark.name
                self.location?.address = String(format: "%@ %@", arguments: [placemark.subThoroughfare ?? "", placemark.thoroughfare ?? ""])
                self.location?.city = placemark.locality
                self.location?.state = placemark.administrativeArea
                self.location?.zip = placemark.postalCode
                self.location?.lat = latitude
                self.location?.lon = longitude
                self.location?.notes = ""
            }
        }
        
        StandardMapCell.register(tableView)
        StandardHeaderCell.register(tableView)
        StandardTextFieldCell.register(tableView)
        StandardTextViewCell.register(tableView)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if searchController.searchBar.text?.isEmpty ?? true {
            searchController.searchBar.setShowsCancelButton(false, animated: true)
        }
        
        matchingItems.removeAll()
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.sizeThatFits(UIScreen.main.bounds.size)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        searchController.dismiss(animated: true, completion: nil)
        
        prepareForDeinit()
    }

    override func setupNavBar() {
        navBar?.title = "Create Location"
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
        
        navBar?.rightImage = UIImage(named: "next-red")
        navBar?.rightEnclosure = { self.goNext() }
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        if matchingItems.count == 0 || searchController.searchBar.text == "" {
            return 4
        } else {
            return 1
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if matchingItems.count == 0 || searchController.searchBar.text == "" {
            switch section {
            case 0:
                return 1
            case 1:
                return 2
            case 2:
                return 5
            case 3:
                return 2
            default:
                return 0
            }
        } else {
            return matchingItems.count
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if matchingItems.count == 0 || searchController.searchBar.text == "" {
            switch indexPath.section {
            case 0:
                return 250
            case 3:
                switch indexPath.row {
                case 0:
                    return 50
                default:
                    return 130
                }
            default:
                return 50
            }
        } else {
            return 50
        }
    }

    /* Zach - This is where you setup the details for each activity entry in a timesheet */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if matchingItems.count == 0 || searchController.searchBar.text == "" {
            switch indexPath.section {
            case 0:
                let cell = StandardMapCell.loadNib(tableView)

                if let latitude = location?.lat, let longitude = location?.lon, let name = location?.name, let address = location?.address {
                    cell.populateMap(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), title: name, subtitle: address)
                }

                cell.mapView.mapType = .hybrid
                cell.selectionStyle = .none

                return cell
            case 1:
                switch indexPath.row {
                case 0:
                    let cell = StandardHeaderCell.loadNib(tableView)

                    cell.footer.text = ""
                    cell.title.text = "Location Name"

                    cell.selectionStyle = .none

                    return cell
                default:
                    let cell = StandardTextFieldCell.loadNib(tableView)

                    cell.label.text = "Name"
                    cell.placeholder = "Enter Name"
                    cell.contents.tag = 5
                    cell.contents.textColor = UIColor(hex: "929292")
                    cell.contents.text = location?.name
                    cell.contents.delegate = self
                    // cell.contents.becomeFirstResponder()
                    cell.selectionStyle = .none
                    return cell
                }
            case 2:
                switch indexPath.row {
                case 0:
                    let cell = StandardHeaderCell.loadNib(tableView)

                    cell.footer.text = ""
                    cell.title.text = "Address"

                    cell.selectionStyle = .none
                    return cell
                case 1:
                    let cell = StandardTextFieldCell.loadNib(tableView)

                    cell.label.text = "Address"
                    cell.placeholder = "Enter Address"
                    cell.contents.tag = 1
                    cell.contents.textColor = UIColor(hex: "929292")
                    cell.contents.delegate = self
                    cell.contents.text = location?.address

                    cell.selectionStyle = .none
                    return cell
                case 2:
                    let cell = StandardTextFieldCell.loadNib(tableView)

                    cell.label.text = "City"
                    cell.placeholder = "Enter City"
                    cell.contents.tag = 2
                    cell.contents.textColor = UIColor(hex: "929292")
                    cell.contents.delegate = self
                    cell.contents.text = location?.city

                    cell.selectionStyle = .none
                    return cell
                case 3:
                    let cell = StandardTextFieldCell.loadNib(tableView)

                    cell.label.text = "State"
                    cell.placeholder = "Enter State"
                    cell.contents.tag = 3
                    cell.contents.textColor = UIColor(hex: "929292")
                    cell.contents.delegate = self
                    cell.contents.text = location?.state

                    cell.selectionStyle = .none
                    return cell
                default:
                    let cell = StandardTextFieldCell.loadNib(tableView)

                    cell.label.text = "Zip"
                    cell.placeholder = "Enter Zip"
                    cell.contents.tag = 4
                    cell.contents.textColor = UIColor(hex: "929292")
                    cell.contents.delegate = self
                    cell.contents.text = location?.zip

                    cell.selectionStyle = .none
                    return cell
                }
            default:
                switch indexPath.row {
                case 0:
                    let cell = StandardHeaderCell.loadNib(tableView)

                    cell.footer.text = ""
                    cell.title.text = "Notes"

                    cell.selectionStyle = .none

                    return cell
                default:
                    let cell = StandardTextViewCell.loadNib(tableView)

                    cell.contents.text = location?.notes

                    cell.selectionStyle = .none
                    cell.contents.delegate = self

                    return cell
                }
            }
        } else {
            let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "cell")

            let tap = UITapGestureRecognizer(target: self, action: #selector(didSelect))
            cell.isUserInteractionEnabled = true
            cell.addGestureRecognizer(tap)
            cell.tag = indexPath.row

            let selectedItem = matchingItems[indexPath.row].placemark
            cell.textLabel?.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: cell.textLabel!.font.pointSize)
            cell.textLabel?.text = selectedItem.name
            cell.detailTextLabel?.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: cell.detailTextLabel!.font.pointSize)
            cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell
        }
    }
    
    // MARK: UIText Delegate
    
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        tableView.scrollRectToVisible(tableView.tableHeaderView!.frame, animated: true)
        return false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        location?.notes = textView.text
    }
    
    
    // MARK: - Search Control Delegate
    
    func didDismissSearchController(_: UISearchController) {
        searchController.searchBar.text = ""
        searchController.dismiss(animated: true, completion: nil)
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_: UISearchBar) {
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        
        if let location = LocationManager.shared.currentLocation {
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: SEARCH_DELTA_REGION_LAT, longitudeDelta: SEARCH_DELTA_REGION_LON))
            request.region = region
        }
        
        // request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else { return }
            
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        self.tableView.reloadData()
        
        delay(0.1) {
            self.tableView.contentSize.height = CGFloat(830) + self.view.safeAreaInsets.bottom
        }
    }

    
    // MARK: - Other Functions

    @objc func didSelect(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag, index < self.matchingItems.count else {
            dismissKeyboard()
            return
        }

        let placemark = matchingItems[index].placemark

        var name: String?
        var address: String?
        var city: String?
        var state: String?
        var zip: String?
        var coordinates: CLLocationCoordinate2D?

        if placemark.subThoroughfare != nil && placemark.thoroughfare != nil {
            address = placemark.subThoroughfare! + " " + placemark.thoroughfare!
        }

        if placemark.locality != nil {
            city = placemark.locality!
        }

        if placemark.administrativeArea != nil {
            state = placemark.administrativeArea!
        }

        if placemark.postalCode != nil {
            zip = placemark.postalCode!
        }

        if placemark.name != nil {
            name = placemark.name!
        } else {
            name = address
        }

        coordinates = placemark.coordinate

        guard address != nil, city != nil, zip != nil else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Sorry this entry does not fullfil the address requirements, please select another entry.")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT)
            return
        }

        location?.name = name
        location?.address = address
        location?.city = city
        location?.state = state
        location?.zip = zip
        location?.lat = coordinates?.latitude
        location?.lon = coordinates?.longitude

        searchController.isActive = false
        matchingItems.removeAll()
        dismissKeyboard()
        searchBarController?.dismiss(animated: true, completion: nil)
        tableView.reloadData()
    }

    @objc func goNext() {

        searchController.dismiss(animated: false, completion: nil)
        definesPresentationContext = true

        guard location?.name != "" else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: NSLocalizedString("CreateLocationViewController_PKHUD_Error", comment: ""))
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT)
            return
        }

        let destination = UIStoryboard.Location(identifier: "CenterLocation") as! CenterLocation

        destination.location = location

        navigationController?.pushViewController(destination, animated: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 5 {
            location?.name = textField.text
        } else if textField.tag == 1 {
            location?.address = textField.text
        } else if textField.tag == 2 {
            location?.city = textField.text
        } else if textField.tag == 3 {
            location?.state = textField.text
        } else if textField.tag == 4 {
            location?.zip = textField.text
        }
    }

    func parseAddress(selectedItem: MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format: "%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )

        return addressLine
    }

    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.tableHeaderView?.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        navBar?.rightButton.tintColor = UIColor.red
    }
}

