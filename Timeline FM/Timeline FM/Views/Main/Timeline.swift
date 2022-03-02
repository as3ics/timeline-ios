
//
//  Timeline.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 2/16/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import ActionSheetPicker_3_0
import Floaty
import IQKeyboardManagerSwift
import KCFloatingActionButton
import KeychainAccess
import MapKit
import CoreLocation
import Material
import MobileCoreServices
import PKHUD
import Pulsar
import RevealingSplashView
import UIKit
import BetterSegmentedControl
import SnapKit


// MARK: - Timeline


class Timeline: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SidebarSectionProtocol, MapViewProtocol, MKMapViewDelegate {
    
    static var section: String = "Map"

    // MARK: - Timeline Theme Containers
    
    var views = [UIView]()
    var primaryLabels = [UILabel]()
    var secondaryLabels = [UILabel]()
    var alternativeLabels = [UILabel]()
    var switches = [UISwitch]()

    // MARK: - Timeline Filtered Objects
    
    var filteredUsers = [User]()
    var searchController = UISearchController(searchResultsController: nil)
    var filtering: Bool = false {
        didSet {
            if self.filtering == true {
                self.filteredUsers = Users.shared.items
                self.reloadTableView()
                self.updatePeopleViewHeight()
            } else {
                self.filteredUsers.removeAll()
                self.reloadTableView()
            }
        }
    }

    // MARK: - Timeline Reference Objects
    
    var sheet:  Sheet? {
        if DeviceUser.shared.sheet != nil, focusedEntry.sheet !== DeviceUser.shared.sheet {
            focusedEntry.sheet = DeviceUser.shared.sheet
            focusedEntry.clear()
        } else if DeviceUser.shared.sheet == nil {
            focusedEntry.sheet = nil
            focusedEntry.clear()
        }
        
        return DeviceUser.shared.sheet
    }
    
    var focusedEntry: FocusedEntry! = _focusedEntry
    fileprivate var fabState: SystemState?
    
    // MARK: - Timeline Storyboard Outlets
    
    @IBOutlet var mapView: MapView!
    @IBOutlet var fab: Floaty!
    @IBOutlet var overlayView: UIView!
    @IBOutlet var largeLogo: UIImageView!
    @IBOutlet var loadingLabel: UILabel!
    @IBOutlet var logo: UIImageView!


    // MARK: - Timeline Layout Sections
    
    @IBOutlet var navigationView: UIView!
    @IBOutlet var mapButtonsView: UIView!
    @IBOutlet var mapFocusButtonsView: UIView!
    @IBOutlet var peopleView: UIView!
    @IBOutlet var statusView: UIView!
    @IBOutlet var settingsView: UIView!
    @IBOutlet var checkInAlertView: UIView!
    @IBOutlet var travelingAlertView: UIView!

    // MARK: - Timeline NavigationView Section Outlets
    
    @IBOutlet var menuButton: FlatButton!
    @IBOutlet var gpsStrengthButton: FlatButton!
    @IBOutlet var gpsStrengthPhantomImageView: UIImageView!
    @IBOutlet var messageButton: FlatButton!
    @IBOutlet var messageIndicator: UIView!
    @IBOutlet var cameraButton: FlatButton!
    @IBOutlet var clock: UILabel!
    @IBOutlet var shiftClock: UILabel!
    @IBOutlet var dayClock: UILabel!
    
    // MARK: - Timeline MapButtonsView Section Outlets
    
    @IBOutlet var settingsButton: FlatButton!
    @IBOutlet var mapSpanButton: FlatButton!
    @IBOutlet var centerMapButton: FlatButton!
    @IBOutlet var lockButton: FlatButton!
    @IBOutlet var mapButtonsPulloutView: UIView!
    @IBOutlet var mapButtonsPulloutImage: UIImageView!
    
    // MARK: - Timeline MapFocusButtonsView Section Outlets
    
    @IBOutlet var indexLabel: UILabel!
    @IBOutlet var arrowViewCenterView: UIView!
    @IBOutlet var leftButton: FlatButton!
    @IBOutlet var rightButton: FlatButton!
    @IBOutlet var mapFocusButtonsPulloutView: UIView!
    @IBOutlet var mapFocusButtonsPulloutImage: UIImageView!

    // MARK: - Timeline PeopleView Section Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var peopleViewPulloutView: UIView!
    @IBOutlet var peopleViewPulloutImage: UIImageView!
    
    // MARK: - Timeline StatusView Section Outlets
    
    @IBOutlet var tabStatusView: UIView!
    @IBOutlet var tabStatusImage: UIImageView!
    @IBOutlet var tabStatusLabel: UILabel!
    @IBOutlet var tabStatusDownArrow: UIImageView!
    @IBOutlet var tabStatusFlatButton: FlatButton!
    
    @IBOutlet var tabLocationsView: UIView!
    @IBOutlet var tabLocationsImage: UIImageView!
    @IBOutlet var tabLocationsLabel: UILabel!
    @IBOutlet var tabLocationsDownArrow: UIImageView!
    @IBOutlet var tabLocationsFlatButton: FlatButton!
    
    @IBOutlet var tabPeopleView: UIView!
    @IBOutlet var tabPeopleImage: UIImageView!
    @IBOutlet var tabPeopleLabel: UILabel!
    @IBOutlet var tabPeopleDownArrow: UIImageView!
    @IBOutlet var tabPeopleFlatButton: FlatButton!
    
    // MARK: - Timeline SettingsView Section Outlets
    
    @IBOutlet var mapSettingsArrowView: UIView!
    @IBOutlet var settingsTitle: UILabel!
    @IBOutlet var mapSegmentLabel: UILabel!
    @IBOutlet var trafficSwitchLabel: UILabel!
    @IBOutlet var gpsSwitchLabel: UILabel!
    @IBOutlet var breadcrumbsSwitchLabel: UILabel!
    @IBOutlet var toleranceSliderLabel: UILabel!
    @IBOutlet var userAnnotationLabel: UILabel!
    @IBOutlet var mapTypeSegment: UISegmentedControl!
    @IBOutlet var gpsStatusTextView: UITextView!
    @IBOutlet var toleranceValueLabel: UILabel!
    @IBOutlet var toleranceSlider: UISlider!
    @IBOutlet var crumbSwitch: UISwitch!
    @IBOutlet var gpsSwitch: UISwitch!
    @IBOutlet var trafficSwitch: UISwitch!
    @IBOutlet var userAnnotationSwitch: UISwitch!
    @IBOutlet var mapAnnotationSwitch: UISwitch!
    @IBOutlet var mapAnnotationLabel: UILabel!
    @IBOutlet var breadcrumbsTextView: UITextView!
    @IBOutlet var userAnnotationTextView: UITextView!
    @IBOutlet var toleranceTextView: UITextView!
    @IBOutlet var mapAnnotationTextView: UITextView!
    
    // MARK: - Timeline Alert Outlets
    
    @IBOutlet var checkInAlertLine1: UILabel!
    @IBOutlet var checkInAlertLine2: UILabel!
    @IBOutlet var travelAlertLine1: UILabel!
    @IBOutlet var travelAlertLine2: UILabel!
    @IBOutlet var checkInAlertButton: UIButton!
    @IBOutlet var travelAlertButton: UIButton!

    // MARK: - Timeline Layout Constraints
    
    @IBOutlet var mapButtonsLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var arrowViewCenterViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var peopleViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var peopleViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var mapFocusButtonsTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var statusViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var navigationViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var travelingAlertViewBottomContraint: NSLayoutConstraint!
    @IBOutlet var checkInAlertViewBottomContsraint: NSLayoutConstraint!
    @IBOutlet var mapSettingsBottomConstraint: NSLayoutConstraint!

    fileprivate var mapFocusButtonsTrailingConstraintOriginal: CGFloat = 0.0
    fileprivate var mapButtonsLeadingConstraintOriginal: CGFloat! = 0.0
    fileprivate var navigationViewTopConstraintOriginal: CGFloat = 0.0
    fileprivate var peopleViewBottomConstraintOriginal: CGFloat = 0.0
    fileprivate var peopleViewHeightConstraintOriginal: CGFloat = 0.0
    fileprivate var statusViewHeightConstraintOriginal: CGFloat = 0.0
    fileprivate var originalPeopleViewHeight: CGFloat = 0.0
    fileprivate var originalSettingsViewBottomConstraint: CGFloat = 0.0

    // MARK: - Timeline Formatters
    
    fileprivate var clockFormatter: DateFormatter?
    fileprivate var timeFormatter: DateFormatter?
    fileprivate var dayFormatter: DateFormatter?
    
    // MARK: - Timeline Other Variables
    
    fileprivate var mapButtonsPanViewThreshold: CGFloat { return mapButtonsLeadingConstraintOriginal - 12.5 - (mapButtonsView.width / 2.0) }
    fileprivate var mapFocusButtonsPanViewThreshold: CGFloat { return mapFocusButtonsTrailingConstraintOriginal - (mapFocusButtonsView.width / 2.0) - 12.5 }
    
    fileprivate var mapButtonsHidden: Bool = false
    fileprivate var mapFocusButtonsHidden: Bool = false
    fileprivate var _mapButtonsHidden: Bool = false
    fileprivate var _mapFocusButtonsHidden: Bool = false

    fileprivate var previousRawLocation: CLLocation?
    fileprivate var shouldShowCheckInAlert: Bool = false
    fileprivate var shouldShowTravelingAlert: Bool = false

    fileprivate var mapGesture: UITapGestureRecognizer?
    fileprivate var peoplePanGesture: UIPanGestureRecognizer?
    fileprivate var tableViewSwipeGesture: UISwipeGestureRecognizer?

    fileprivate let baseFontSize: CGFloat = 18.0
    fileprivate let titleFontDifference: CGFloat = 3.0
    fileprivate let locationTitleFontDifference: CGFloat = 0
    fileprivate let locationValueFontDifference: CGFloat = -3.0
    fileprivate let clockFontSizeDifference: CGFloat = 0
    fileprivate let alertFontSizeDifference: CGFloat = -5.0
    
    var initialLoad: Bool = !App.shared.isLoaded
    var initialized: Bool = false
    
    var timer_1000ms: Timer?
    
    fileprivate var peopleVisible: Bool {
        get {
            return peopleViewHeightConstraint.constant != peopleViewHeightConstraintOriginal
        } set {
            peopleViewHeightConstraint.constant = newValue == false ? peopleViewHeightConstraintOriginal : peopleViewHeightConstraint.constant
            
            if newValue == false {
                self.filtering = false
                self.resetTabs()
            }
        }
    }
    
    fileprivate var settingsVisible: Bool {
        get {
            return self.mapSettingsBottomConstraint.constant != -self.settingsView.height
        } set {
            self.mapSettingsBottomConstraint.constant = newValue == false ? -self.settingsView.height : 0.0
        }
    }
    
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        
        mapView.delegate = mapView
        navigationDrawerController?.delegate = self
        fab.fabDelegate = self
        
        initializeInitialConstraints()
        initializeThemeObjects()
        initializeFonts()
        initializeFormatters()
        initializeGestures()
        initializeNotifications()
        initializeTableView()
        initializeNavTab()
        initializeSettings()
        initializeButtons()
        touchupStyling()
        
        initializeTimelineForPresentation()
        
        LocationManager.shared.updateLocation()
        
        if initialLoad == true {
            splash()
        } else {
            mapView.alpha = 0.0
            self.completeAnimateIn()
        }
        
        Notifications.shared.updateBadge()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard App.shared.isLoaded == true else {
            return
        }
        
        DispatchQueue.main.async {
            Async.waterfall(nil, [Stream.shared.retrieve], end: { _, _ in })
        }
        
        DispatchQueue.main.async {
            self.fab.setNeedsUpdateConstraints()
            self.fab.setNeedsLayout()
            
            self.fab.close()
            self.view.bringSubview(toFront: self.fab)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timer_1000ms?.invalidate()
        timer_1000ms = nil
        timer_1000ms = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            
            print("Timer - Timeline")
            
            self.task_1000ms()
        })
        
        timer_1000ms?.fire()
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer_1000ms?.invalidate()
        timer_1000ms = nil
    }
    
    // MARK: - Timeline Bottum Navigation Tab Functions
    
    enum TimelineNavTab: Int {
        case Status
        case Locations
        case People
    }
    
    let defaultTab = TimelineNavTab.Status
    let backupTab = TimelineNavTab.Locations

    func initializeNavTab() {
        tabStatusFlatButton.tag = TimelineNavTab.Status.rawValue
        tabStatusView.tag = TimelineNavTab.Status.rawValue
        tabStatusImage.image = tabStatusImage.image?.withRenderingMode(.alwaysTemplate)
        tabStatusDownArrow.image = tabStatusDownArrow.image?.withRenderingMode(.alwaysTemplate)

        tabLocationsFlatButton.tag = TimelineNavTab.Locations.rawValue
        tabLocationsView.tag = TimelineNavTab.Locations.rawValue
        tabLocationsImage.image = tabLocationsImage.image?.withRenderingMode(.alwaysTemplate)
        tabLocationsDownArrow.image = tabLocationsDownArrow.image?.withRenderingMode(.alwaysTemplate)

        tabPeopleFlatButton.tag = TimelineNavTab.People.rawValue
        tabPeopleView.tag = TimelineNavTab.People.rawValue
        tabPeopleImage.image = tabPeopleImage.image?.withRenderingMode(.alwaysTemplate)
        tabPeopleDownArrow.image = tabPeopleDownArrow.image?.withRenderingMode(.alwaysTemplate)

        peopleVisible = false
    }

    var selectedTab: TimelineNavTab? {
        didSet {
            resetTabs()
            
            guard let tab = self.selectedTab, self.initialized else { return }
            
            switch tab {
            case .Status:
                guard sheet === DeviceUser.shared.sheet else { return }
                tabStatusImage.tintColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabStatusLabel.textColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabStatusDownArrow.tintColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabStatusDownArrow.alpha = 1.0
                break
            case .Locations:
                
                tabLocationsImage.tintColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabLocationsLabel.textColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabLocationsDownArrow.tintColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabLocationsDownArrow.alpha = 1.0
                break
            case .People:
                
                tabPeopleImage.tintColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabPeopleLabel.textColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabPeopleDownArrow.tintColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabPeopleDownArrow.alpha = 1.0
                break
            }
            
            DispatchQueue.main.async {
                UIView.transition(with: self.tableView, duration: 0.5, options: [], animations: {
                    self.reloadTableView()
                }, completion: nil)
            }
        }
    }

    fileprivate func resetTabs() {
        tabPeopleImage.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        tabPeopleLabel.textColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        tabLocationsImage.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        tabLocationsLabel.textColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        tabStatusImage.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        tabStatusLabel.textColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        tabStatusDownArrow.alpha = 0.0
        tabLocationsDownArrow.alpha = 0.0
        tabPeopleDownArrow.alpha = 0.0

        tabStatusImage.alpha = System.shared.state == .Off ? 0.5 : 1.0
        tabStatusLabel.alpha = System.shared.state == .Off ? 0.5 : 1.0
        
        tableView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    // MARK: - Image Picker Delegate Function
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        if picker.sourceType == .photoLibrary {
            
            if let image = info[UIImagePickerControllerEditedImage] as? UIImage, let user = DeviceUser.shared.user {
                
                PKHUD.loading()
                
                user.photo = UIImage.resizeImage(image: image, targetSize: CGSize(width: 200.0, height: 200.0)).base64String()
                
                user.update { success in
                    guard success == true else {
                        PKHUD.failure()
                        picker.dismiss(animated: true, completion: nil)
                        return
                    }
                    
                    let sections = Main.sections.filter({ (section) -> Bool in
                        return section.style == MainSectionStyle.User
                    })
                    
                    sections.first?.reload()
                    
                    Sidebar.refresh()
                    PKHUD.success()
                    Generator.confirm()
                    
                    picker.dismiss(animated: true, completion: nil)
                    return
                }
            } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                let destination = UIStoryboard.Main(identifier: "PhotoCreate") as! PhotoCreate
                
                destination.editingMode = ViewingMode.Creating
                
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                
                let height: CGFloat = 1000.0
                let width: CGFloat = image.width * (1000.0 / image.height)
                
                destination.image = imageView.image?.af_imageAspectScaled(toFill: CGSize(width: width, height: height))
                destination.source = "PhotoLibrary"
                
                if let coordinate = LocationManager.shared.currentLocation?.coordinate {
                    destination.latitude = coordinate.latitude
                    destination.longitude = coordinate.longitude
                }
                
                if let sheet = DeviceUser.shared.sheet, let entry = sheet.entries.latest {
                    destination.sheet = sheet
                    destination.entry = entry
                    
                    picker.dismiss(animated: true) {
                        Presenter.push(destination, animated: true, completion: nil)
                    }
                } else {
                    LocationManager.shared.isInKnownLocation { (location) in
                        guard let location = location else {
                            picker.dismiss(animated: true) {
                                Presenter.push(destination, animated: true, completion: nil)
                            }
                            return
                        }
                        
                        destination.location = location
                        picker.dismiss(animated: true) {
                            Presenter.push(destination, animated: true, completion: nil)
                        }
                    }
                }
            } else {
                PKHUD.failure()
                picker.dismiss(animated: true, completion: nil)
            }
        } else if picker.sourceType == .camera {
            
            let destination = UIStoryboard.Main(identifier: "PhotoCreate") as! PhotoCreate
            
            destination.editingMode = ViewingMode.Creating
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                PKHUD.failure()
                return
            }
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            
            let height: CGFloat = 1000.0
            let width: CGFloat = image.width * (1000.0 / image.height)
            
            destination.image = imageView.image?.af_imageAspectScaled(toFill: CGSize(width: width, height: height))
            destination.source = "Camera"
            
            if let coordinate = LocationManager.shared.currentLocation?.coordinate {
                destination.latitude = coordinate.latitude
                destination.longitude = coordinate.longitude
            }
            
            if let sheet = DeviceUser.shared.sheet, let entry = sheet.entries.latest {
                destination.sheet = sheet
                destination.entry = entry
                
                picker.dismiss(animated: true) {
                    Presenter.push(destination, animated: true, completion: nil)
                }
            } else {
                LocationManager.shared.isInKnownLocation { (location) in
                    guard let location = location else {
                        picker.dismiss(animated: true) {
                            Presenter.push(destination, animated: true, completion: nil)
                        }
                        return
                    }
                    
                    destination.location = location
                    picker.dismiss(animated: true) {
                        Presenter.push(destination, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Deinit
    
    func prepareForDeinit() {
        self.clearMap(all: true)
        
        for cell in tableView.visibleCells {
            if let value = cell as? EntriesCell {
                value.updates = false
            } else if let value = cell as? EntriesHeaderCell {
                value.updates = false
            } else if let value = cell as? PeopleScrollCell {
                value.cleanse()
            }
        }
        
        DeviceUser.shared.sheet?.entries.clearAnnotations()
        NotificationCenter.default.removeObserver(self)
        
        timer_1000ms?.invalidate()
        timer_1000ms = nil
        
        for item in fab.items {
            fab.removeItem(item: item)
        }
        
        fab.removeFromSuperview()
    }

    deinit {
        print("Timeline Deinit'd")
    }
}

// MARK: - Timeline Map Functions

typealias TimelineMapFunctions = Timeline
extension TimelineMapFunctions {
    
    
    // MARK: - Timeline Map Functions
    
    @objc func resetMap() {
        
        focusedEntry.clear()
        
        hideMapFocusButtons()
        closeFocusedEntryCenterView()
        deselectAllAnnotations()
        closeInfo(self)
        
        focusMap()
        unhighlightMap(sheet: sheet)
        tableView.reloadData()
        
        menuButton.removeTargets()
        menuButton.styleTimeline(AssetManager.shared.menu)
        menuButton.addTarget(self, action: #selector(menuPressed), for: .touchUpInside)
    }
    
    
    @objc func prepareMap() {
        switch System.shared.state {
        case .Off:
            prepareMapNoTimesheet()
        default:
            prepareMapForTimesheet()
        }
    }
    
    func prepareMapForTimesheet() {
        clearMap(all: false)
        
        if DeviceSettings.shared.mapAnnotations {
            populate(sheet: sheet)
        }
        
        Locations.shared.sort()
        populateOverlays(locations: Locations.shared.items)
        
        cameraButton.alpha = 1.0
        cameraButton.isEnabled = true
    }
    
    func prepareMapNoTimesheet() {
        clearMap(all: false)
        
        if DeviceSettings.shared.mapAnnotations {
            Locations.shared.sort()
            populate(locations: Locations.shared.items)
        }
        
        cameraButton.alpha = 1.0
        cameraButton.isEnabled = true
    }
    
}

// MARK: - Timeline Timesheet Functions

typealias TimelineTimesheetFunctions = Timeline
extension TimelineTimesheetFunctions {
    
    // MARK: - Timesheet Functions
    
    @objc func createTimesheet(_ sender: Any?) {
        (sender as? UITapGestureRecognizer)?.view?.touchAnimation()
        
        self.fab.close()
        delay(0.2) {
            
            let minimum = Date(timeIntervalSince1970: 0)
            let maximum = Date()
            
            let picker = ActionSheetDatePicker(title: "Select Start Time", datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: maximum, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(self.commitCreateTimesheet), cancelAction: nil, origin: self.view)
            
            picker?.maximumDate = maximum
            picker?.minimumDate = minimum
            
            self.styleActionSheetDatePicker(picker)
            
            picker?.show()
        }
    }
    
    @objc func commitCreateTimesheet(_ date: Date) {
        
        let sheet: Sheet = Sheet()
        sheet.user = Auth.shared.id
        sheet.date = date
        
        PKHUD.loading()
        
        Async.waterfall(nil, [sheet.create], end: { (error, _) in
            guard error == nil else {
                PKHUD.failure()
                return
            }
            
            PKHUD.success()
            DeviceUser.shared.sheet = sheet
            
            self.fab.close()
        })
    }
    
    @objc func submitTimeSheet(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            guard let sheet = DeviceUser.shared.sheet else {
                self.prepareFab()
                return
            }
            
            if sheet.entries.count == 0 {
                PKHUD.loading()
                
                sheet.delete({ success in
                    guard success == true else {
                        PKHUD.failure()
                        return
                    }
                    
                    PKHUD.success()
                })
            } else {
                let minimum = sheet.entries.latest!.start!
                let maximum = Date()
                
                let picker = ActionSheetDatePicker(title: NSLocalizedString("TimelineViewController_SelectTimesheetEndTime", comment: ""), datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: maximum, minimumDate: minimum, maximumDate: maximum, target: self, action: #selector(self.commitTimesheet), cancelAction: nil, origin: self.fab)
                
                picker?.maximumDate = maximum
                picker?.minimumDate = minimum
                
                self.styleActionSheetDatePicker(picker)
                
                picker?.show()
            }
        }
    }
    
    @objc func commitTimesheet(_ date: Date) {
        let userInfo: [AnyHashable: Any] = ["end": date as Any]
        
        NotificationManager.shared.submit_timesheet.post(userInfo)
    }
    
    @objc func manualEntryCreate(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            guard System.shared.state != .Off else { return }
            
            let destination = UIStoryboard.Main(identifier: "EntryCreate") as! EntryCreate
            destination.sheet = DeviceUser.shared.sheet
            
            let navigation = UINavigationController(rootViewController: destination)
            navigation.navigationBar.isHidden = true
            
            Presenter.present(navigation, animated: true, completion: nil)
        }
    }
    
    @objc func createNewEntry(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            NotificationManager.shared.create_entry.post()
        }
    }
    
    @objc func createTravelingEntry(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            NotificationManager.shared.create_traveling_entry.post()
        }
    }
    
    @objc func createBreakEntry(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.fab.close()
            
            NotificationManager.shared.create_break_entry.post()
        }
    }
    
    @objc func endBreakEntry(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        PKHUD.loading()
        
        delay(0.2) {
            self.fab.close()
            
            LocationManager.shared.isInKnownLocation({ (location) in
                
                PKHUD.hide()
                
                var alert: UIAlertController?
                
                if let location = location, let name = location.name {
                    alert = UIAlertController(title: "Timeline", message: "You are coming off a break and are in the viscinity of a known location. Would you like to clock into \(name)?", preferredStyle: .actionSheet)
                    
                    alert?.addAction(UIAlertAction(title: "Clock In", style: .default) { _ in
                        Generator.bump()
                        
                        let userInfo: JSON = [
                            "location": location as JSONObject
                        ]
                        
                        NotificationManager.shared.create_entry.post(userInfo) })
                    alert?.addAction(UIAlertAction(title: "Traveling Mode", style: .default) { _ in
                        Generator.bump()
                        NotificationManager.shared.create_traveling_entry.post() })
                    alert?.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { _ in
                        Generator.bump()
                        LocationManager.shared.currentLocation = nil
                        /* foo */ })
                } else {
                    alert = UIAlertController(title: "Timeline", message: "You are either not in a known location or your location can not be verified at this time. Enter Traveling Mode or manual create entry?", preferredStyle: .actionSheet)
                    
                    alert?.addAction(UIAlertAction(title: "Traveling Mode", style: .default) { _ in
                        Generator.bump()
                        NotificationManager.shared.create_traveling_entry.post() })
                    alert?.addAction(UIAlertAction(title: "Add Entry", style: .default) { _ in
                        Generator.bump()
                        self.fab.close()
                        
                        guard System.shared.state != .Off else { return }
                        
                        let destination = UIStoryboard.Main(identifier: "EntryCreate") as! EntryCreate
                        destination.sheet = DeviceUser.shared.sheet
                        
                        let navigation = UINavigationController(rootViewController: destination)
                        navigation.navigationBar.isHidden = true
                        
                        Presenter.present(navigation, animated: true, completion: nil) })
                    alert!.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { _ in
                        Generator.bump()
                        LocationManager.shared.currentLocation = nil
                        /* foo */ })
                }
                
                guard let _alert = alert else { return }
                
                Presenter.present(_alert, animated: true)
            })
            
            
        }
    }
}

// MARK: - Timeline Layout Conrollers

typealias TimelineLayoutControllers = Timeline
extension TimelineLayoutControllers {
    
    
    @objc func closeInfo(_: Any) {
        
        tableView.refreshControl?.endRefreshing()
        
        if self.filtering == true {
            self.dismissSearch(UITapGestureRecognizer())
        }
        
        self.selectedTab = nil
        
        if settingsVisible == true {
            settingsVisible = false
            mapSettingsArrowView.touchAnimation()
            UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
                self.settingsButton.transform = self.settingsButton.transform.rotated(by: 0.9999 * CGFloat.pi / 2.0)
                self.settingsButton.layoutIfNeeded()
            }
        }
        
        peopleVisible = false
        self.peopleView.shadowOpacity = 0.0
        UIView.animate(withDuration: 0.15) {
            self.peopleViewPulloutImage.image = AssetManager.shared.pullout
            self.view.layoutIfNeeded()
        }
        
        statusViewHeightConstraint.constant = statusViewHeightConstraintOriginal
        UIView.animate(withDuration: 0.15, animations: {
            self.view.layoutIfNeeded()
            
            self.fab.layoutIfNeeded()
            self.fab.alpha = self.shouldFabBeVisible() == true ? 1.0 : 0.0
            
            self.overlayView.alpha = 0.0
            self.peopleView.shadowOpacity = 0.0
            
            if self.shouldShowCheckInAlert == true { self.showCheckInAlert() }
            if self.shouldShowTravelingAlert == true { self.showTravelingAlert() }
        }, completion: nil)
    }

    func closeFocusedEntryCenterView() {
        arrowViewCenterViewHeightConstraint.constant = 0.0
        UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func showFocusedEntryCenterView(index: Int, maxIndex: Int) {
        if arrowViewCenterViewHeightConstraint.constant != 44.0 {
            arrowViewCenterViewHeightConstraint.constant = 44.0
            UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION, animations: {
                self.view.layoutIfNeeded()
                // self.menuButton.alpha = TIMELINE_VIEW_BUTTON_ALPHA
            }) { _ in
                let indexString = String(format: "%i of %i", arguments: [index, maxIndex])
                self.indexLabel.text = indexString
            }
        } else {
            let indexString = String(format: "%i of %i", arguments: [index, maxIndex])
            indexLabel.text = indexString
        }
    }
    
    
    @objc func updatePeopleViewHeight() {
        let target = self.maxTableViewHeight
        
        if peopleViewHeightConstraint.constant != target {
            peopleViewHeightConstraint.constant = target
            
            UIView.animate(withDuration: self.filtering == true ? 0.1 : DEFAULT_ANIMATION_DURATION) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    
    @objc func hideControls(_: Any) {
        guard peopleVisible == false else {
            closeInfoWithBump()
            return
        }
        
        mapView.removeGestureRecognizer(mapGesture!)
        mapGesture = nil
        mapGesture = UITapGestureRecognizer(target: self, action: #selector(showControls))
        mapGesture?.numberOfTouchesRequired = 3
        mapView.addGestureRecognizer(mapGesture!)
        
        _mapButtonsHidden = mapButtonsHidden
        _mapFocusButtonsHidden = mapFocusButtonsHidden
        
        navigationViewTopConstraint.constant = -150.0
        statusViewHeightConstraint.constant = 0.0
        
        if !mapFocusButtonsHidden {
            hideMapFocusButtons(DEFAULT_TIMELINE_CONTROLS_ANIMATION_TIME)
        }
        
        if !mapButtonsHidden {
            hideMapButtons(DEFAULT_TIMELINE_CONTROLS_ANIMATION_TIME)
        }
        
        peopleView.alpha = 0.0
        UIView.animate(withDuration: DEFAULT_TIMELINE_CONTROLS_ANIMATION_TIME) {
            self.view.layoutIfNeeded()
            self.fab.alpha = 0.0
            self.mapFocusButtonsView.alpha = 0.0
            self.mapFocusButtonsPulloutView.alpha = 0.0
            self.mapButtonsView.alpha = 0.0
            self.mapButtonsPulloutView.alpha = 0.0
            self.navigationView.alpha = 0.0
            self.peopleViewPulloutView.alpha = 0.0
            self.statusView.alpha = 0.0
            self.mapButtonsView.layoutIfNeeded()
        }
    }
    
    @objc func showControls(_: Any) {
        guard peopleVisible == false else {
            return
        }
        
        mapView.removeGestureRecognizer(mapGesture!)
        mapGesture = nil
        mapGesture = UITapGestureRecognizer(target: self, action: #selector(hideControls))
        mapGesture?.numberOfTouchesRequired = 3
        mapView.addGestureRecognizer(mapGesture!)
        
        navigationViewTopConstraint.constant = navigationViewTopConstraintOriginal
        statusViewHeightConstraint.constant = statusViewHeightConstraintOriginal
        
        if !_mapFocusButtonsHidden {
            showMapFocusButtons(DEFAULT_TIMELINE_CONTROLS_ANIMATION_TIME)
        }
        
        if !_mapButtonsHidden {
            showMapButtons(DEFAULT_TIMELINE_CONTROLS_ANIMATION_TIME)
        }
        
        UIView.animate(withDuration: DEFAULT_TIMELINE_CONTROLS_ANIMATION_TIME, animations: {
            self.view.layoutIfNeeded()
            self.fab.alpha = self.shouldFabBeVisible() == true ? 1.0 : 0.0
            self.mapFocusButtonsView.alpha = 1.0
            self.mapFocusButtonsPulloutView.alpha = 1.0
            self.mapButtonsView.alpha = 1.0
            self.mapButtonsPulloutView.alpha = 1.0
            self.navigationView.alpha = 1.0
            self.peopleViewPulloutView.alpha = 1.0
            self.statusView.alpha = 1.0
            self.mapButtonsView.layoutIfNeeded()
        }, completion: { _ in
            self.peopleView.alpha = 1.0
        })
    }
    
}

// MARK: - Timeline Loading Animations

typealias TimelineLoadingAnimations = Timeline
extension TimelineLoadingAnimations {
    
    
    // Do not touch if don't have to
    @objc func loading() {
        mapView.alpha = 0.0
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude + 30.0)
        region.span = MKCoordinateSpan(latitudeDelta: ABSOLUTE_MAX_DELTA_LAT / DEFAULT_TIMELINE_ANIMATION_SPAN_DIVISOR, longitudeDelta: ABSOLUTE_MAX_DELTA_LON / DEFAULT_TIMELINE_ANIMATION_SPAN_DIVISOR)
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
            let previous = LocationManager.shared.getStateHoldValue()
            LocationManager.shared.holdState(true)
            Commander.shared.load { _ in
                LocationManager.shared.holdState(previous)
                Notifications.shared.releaseSystemMessageObserver()
            }
        }
        
        UIView.animate(withDuration: 1.5, delay: 1.25, options: [.curveLinear], animations: {
            self.largeLogo.alpha = 1.0
            self.loadingLabel.alpha = 1.0
        }, completion: nil)
        
        MKMapView.animate(withDuration: 90.0, delay: 0.01, usingSpringWithDamping: 1.0, initialSpringVelocity: 2.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            var region = MKCoordinateRegion()
            region.center = CLLocationCoordinate2D(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude - 30.0)
            region.span = MKCoordinateSpan(latitudeDelta: ABSOLUTE_MAX_DELTA_LAT / DEFAULT_TIMELINE_ANIMATION_SPAN_DIVISOR, longitudeDelta: ABSOLUTE_MAX_DELTA_LON / DEFAULT_TIMELINE_ANIMATION_SPAN_DIVISOR)
            
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
        
        UIView.animateAndChain(withDuration: 0.0, delay: 0.2, options: [], animations: {
            
            guard let center = LocationManager.shared.currentLocation?.coordinate else {
                LocationManager.shared.fetchLocation({ (center) in
                    
                    var coord: CLLocationCoordinate2D!
                    if center == nil, let region = DeviceUser.shared.sheet?.region {
                        coord = region.center
                    } else if let coordinate = DeviceUser.shared.sheet?.entries.latest?.location?.coordinate {
                        coord = coordinate
                    } else {
                        coord = self.mapView.userLocation.coordinate
                    }
                    
                    let camera = MKMapCamera()
                    camera.centerCoordinate = coord!
                    camera.pitch = DEFAULT_TIMELINE_CAMERA_PITCH
                    camera.heading = 0.0
                    camera.altitude = 350.0
                    self.mapView.setCamera(camera, animated: false)
                    
                    self.initializeTimeline()
                    self.prepareMap()
                })
                
                return
            }
            
            let camera = MKMapCamera()
            camera.centerCoordinate = center
            camera.pitch = DEFAULT_TIMELINE_CAMERA_PITCH
            camera.heading = 0.0
            camera.altitude = 350.0
            self.mapView.setCamera(camera, animated: false)
            
            self.initializeTimeline()
            self.prepareMap()
        }, completion: {(complete) in
            self.navigationViewTopConstraint.constant = self.navigationViewTopConstraintOriginal
            self.statusViewHeightConstraint.constant = self.statusViewHeightConstraintOriginal
            self.showMapButtons(0.5)
        }).animate(withDuration: 1.0, animations: {
            self.mapButtonsPulloutView.alpha = 1.0
            self.mapFocusButtonsPulloutView.alpha = 1.0
            self.peopleViewPulloutView.alpha = 1.0
            self.logo.alpha = 1.0
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
            self.mapView.alpha = 1.0
            self.fab.alpha = 1.0
            self.logo.image = DeviceSettings.shared.mapType == .standard ? AssetManager.shared.launchLogo : AssetManager.shared.launchLogo?.withRenderingMode(.alwaysTemplate)
        }, completion: nil)
        
        delay(1.2) {
            if self.initialLoad {
                App.shared.isLoaded = true
                LocationManager.shared.checkAuthorizationStatus(self)
            }
        }
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
    
    func splash() {
        
        let imageView = UIImageView(image: AssetManager.shared.launchLogo)
        imageView.contentMode = .scaleAspectFit
        
        let revealingSplashView = RevealingSplashView(iconImage: imageView.image!, iconInitialSize: CGSize(width: UIScreen.main.bounds.width, height: Device.phoneType == .iPhone5 ? 140 : 163), backgroundColor: Theme.shared.active.primaryBackgroundColor)
        
        self.view.addSubview(revealingSplashView)
        
        delay(0.5) {
            self.loading()
            revealingSplashView.startAnimation { revealingSplashView.removeFromSuperview() }
        }
    }
    
    
    @objc func initializeTimeline() {
        
        IQKeyboardManager.shared.enable = false
        LocationManager.shared.updateHold(false)
        
        selectedTab = nil
        resetTabs()
        
        prepareFab()
        
        gpsUpdated()
        task_1000ms()
        
        Notifications.shared.updateBadge()
        
        if let sidebar = self.navigationDrawerController?.leftViewController as? Sidebar {
            sidebar.reloadTableView()
        }
        
        navigationDrawerController?.isEnabled = true
        navigationDrawerController?.isLeftPanGestureEnabled = false
        
        searchController.searchBar.setShowsCancelButton(false, animated: true)
        
        mapView.mapType = DeviceSettings.shared.mapType
        mapView.showsUserLocation = true
        setPulloutsTintColor()
        
        self.initialized = true
    }
}

// MARK: - Navigation Drawer Delegate

typealias TimelineNavigationDrawerDelegate = Timeline
extension TimelineNavigationDrawerDelegate: NavigationDrawerControllerDelegate {
    
    func navigationDrawerController(navigationDrawerController: NavigationDrawerController, didOpen position: NavigationDrawerPosition) {
        navigationDrawerController.isLeftPanGestureEnabled = true
    }
    
    func navigationDrawerController(navigationDrawerController: NavigationDrawerController, didClose position: NavigationDrawerPosition) {
        navigationDrawerController.isLeftPanGestureEnabled = false
    }
}

// MARK: - Timeline Notification Functions

typealias TimelineNotificationInitializers = Timeline
extension TimelineNotificationInitializers {
    func initializeNotifications() {
        
        // Setup notifications

        NotificationManager.shared.user_subscription_updated.observe(self, selector: #selector(userSubscriptionNotification))
        NotificationManager.shared.focues_entry_updated.observe(self, selector: #selector(focusedEntryUpdated))
        NotificationManager.shared.new_current_location.observe(self, selector: #selector(rawLocationUpdated))
        NotificationManager.shared.gps_sensitivity_updated.observe(self, selector: #selector(gpsUpdated))
        NotificationManager.shared.location_manager_debouncing.observe(self, selector: #selector(debounceUpdated))
        NotificationManager.shared.map_view_region_changed.observe(self, selector: #selector(mapViewRegionChanged))
        NotificationManager.shared.map_focus_location.observe(self, selector: #selector(focusLocationNotification))
        NotificationManager.shared.new_breadcrumb.observe(self, selector: #selector(crumbsUpdated))
        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
        Notifications.shared.map_focus_user.observe(self, selector: #selector(focusUserNotification))
        Notifications.shared.badge_updated.observe(self, selector: #selector(badgeValueUpdated))
        
        NSNotification.Name.UIKeyboardDidShow.observe(self, selector: #selector(keyboardDidShow))
        NSNotification.Name.UIKeyboardWillHide.observe(self, selector: #selector(keyboardWillHide))
        NSNotification.Name.UIKeyboardWillShow.observe(self, selector: #selector(keyboardWillShow))
        
    }
    
    
    @objc func task_1000ms() {
        DispatchQueue.main.async {
            
            self.dayClock.text = self.dayFormatter?.string(from: Date())
            
            if let sheet = self.sheet /* , let start = sheet.date */ {
                //sheet.updateTimes()
                
                let seconds = sheet.totalSeconds
                let durationString = String(format: "%02.0fh %02.0fm %02.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
                self.shiftClock.text = durationString
                
                let time = self.timeFormatter?.string(from: Date())
                let dayTime = self.dayFormatter?.string(from: Date())
                self.clock.text = String(format: "%@, %@", dayTime!, time!)
                
            } else {
                self.shiftClock.text = "No Timesheet"
                let time = self.timeFormatter?.string(from: Date())
                let dayTime = self.dayFormatter?.string(from: Date())
                self.clock.text = String(format: "%@ - %@", time!, dayTime!)
            }
            
            if self.peoplePanGesture?.state == .possible {
                if self.fabState != System.shared.state {
                    self.prepareFab()
                    
                    self.fab.alpha = self.shouldFabBeVisible() == true ? 1.0 : 0.0
                }
            }
        }
    }
    
    
    @objc func userSubscriptionNotification(_ notification: NSNotification) {
        
        guard App.shared.isLoaded == true, let userInfo = notification.userInfo as? JSON,
            let userId = userInfo["user"] as? String,
            let subscription = Subscriptions.shared.get(userId: userId)
        else {
            return
        }
        
        if let coordinate = subscription.coordinate {
            if let annotation = subscription.annotation {
                UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION * 2.0) {
                    annotation.coordinate = coordinate
                }
            } else {
                let matches = mapView.annotations.filter { (annote) -> Bool in
                    return annote is UserAnnotation && (annote as! UserAnnotation).subscription.user == userId
                }
                
                mapView.removeAnnotations(matches)
                
                subscription.annotation = UserAnnotation(subscription: subscription, coordinate: coordinate)
                mapView.addAnnotation(subscription.annotation!)
            }
        } else if let annotation = subscription.annotation {
            mapView.removeAnnotation(annotation)
            subscription.annotation = nil
        }
    }
    
    
    @objc func focusedEntryUpdated(_: NSNotification) {
        if focusedEntry.isSet() == true {
            showMapFocusButtons()
            
            menuButton.removeTargets()
            menuButton.styleTimeline(AssetManager.shared.arrowLeft)
            menuButton.addTarget(self, action: #selector(resetMap), for: .touchUpInside)
            
            let maxIndex = sheet!.entries.count
            let newIndex = sheet!.entries.count - focusedEntry!.index!
            
            let entry = sheet!.entries[self.focusedEntry!.index!]!
            
            if let annotation = entry.annotation {
                if annotation is EntryClusterAnnotation {
                    deselectAllAnnotations(true, annotation)
                    self.mapView.selectAnnotation(annotation, animated: true)
                    (self.mapView.view(for: annotation) as? EntryClusterAnnotationView)?.customCalloutView?.scrollTo(entry.clusterIndex)
                } else {
                    deselectAllAnnotations(true, annotation)
                    self.mapView.selectAnnotation(annotation, animated: true)
                }
            } else {
                deselectAllAnnotations()
            }
            
            focusMap(entry: entry)
            highlightMap(entry: entry)
            showFocusedEntryCenterView(index: newIndex, maxIndex: maxIndex)
            
            
            if self.selectedTab == TimelineNavTab.Status {
                self.reloadTableView()
            } else {
                self.selectedTab = TimelineNavTab.Status
            }
            
            if self.peopleVisible != true {
                self.peoplePressed()
            }
        }
    }
    
    
    @objc func rawLocationUpdated(_: NSNotification) {
        
        if let location = LocationManager.shared.currentLocation {
            if (Date().timeIntervalSince(location.timestamp) > 120) {
                self.gpsStrengthButton.styleTimeline(AssetManager.shared.gpsNone)
            } else if location.horizontalAccuracy < 29 {
                self.gpsStrengthButton.styleTimeline(AssetManager.shared.gpsGood)
            } else if location.horizontalAccuracy < 101 {
                self.gpsStrengthButton.styleTimeline(AssetManager.shared.gpsFair)
            } else {
                self.gpsStrengthButton.styleTimeline(AssetManager.shared.gpsPoor)
            }
        } else {
            self.gpsStrengthButton.styleTimeline(AssetManager.shared.gpsNone)
        }
        
        guard System.shared.state == .Traveling, let location = LocationManager.shared.currentLocation, let color = DeviceUser.shared.sheet?.entries.latest?.overlayColor else {
            return
        }
        
        if ActivityManager.shared.available {
            if ActivityManager.shared.recentlyDriving {
                let previousCoordinate = previousRawLocation?.coordinate ?? DeviceUser.shared.sheet?.entries.latest?.breadcrumbs.coordinates.last
                
                let array: [CLLocationCoordinate2D] = [previousCoordinate ?? location.coordinate, location.coordinate]
                let lineOverlay = Polyline(coordinates: array, count: array.count)
                lineOverlay.color = color
                mapView.add(lineOverlay)
                
                previousRawLocation = location
            }
        } else {
            let previousCoordinate = previousRawLocation?.coordinate ?? DeviceUser.shared.sheet?.entries.latest?.breadcrumbs.coordinates.last
            
            let array: [CLLocationCoordinate2D] = [previousCoordinate ?? location.coordinate, location.coordinate]
            let lineOverlay = Polyline(coordinates: array, count: array.count)
            lineOverlay.color = color
            mapView.add(lineOverlay)
            
            previousRawLocation = location
        }
    }
    
    
    @objc func gpsUpdated() {
        DispatchQueue.main.async {
            switch LocationManager.shared.gpsSetting {
            case .Off:
                self.gpsStatusTextView.text = "GPS Off"
                self.gpsStrengthButton.styleTimeline(AssetManager.shared.gpsNone)
                break
            case .High:
                self.gpsStatusTextView.text = "GPS in High Accuracy Mode"
                break
            case .Low:
                self.gpsStatusTextView.text = "GPS in Energy Saver Mode"
                break
            default:
                break
            }
        }
    }
    
    
    @objc func debounceUpdated(_ notification: NSNotification) {
        DispatchQueue.main.async {
            guard let data = notification.userInfo as? JSON, let debounceType = data["debounceType"] as? DebounceType else {
                self.dismissTravelingAlert()
                self.dismissCheckInAlert()
                return
            }
            
            if debounceType == DebounceType.ClockIn {
                self.showCheckInAlert()
            } else if debounceType == DebounceType.Travel {
                self.showTravelingAlert()
            } else {
                self.dismissCheckInAlert()
                self.dismissTravelingAlert()
            }
        }
    }
    
    
    @objc func crumbsUpdated(_: NSNotification) {
        _ = gpsStrengthPhantomImageView.layer.addPulse { pulse in
            pulse.borderColors = [UIColor.darkGray.cgColor, UIColor.darkGray.cgColor]
            pulse.backgroundColors = colorsWithOpacity([UIColor.darkGray.cgColor, UIColor.darkGray.cgColor], 0.45)
            pulse.path = UIBezierPath(ovalIn: self.gpsStrengthPhantomImageView.bounds).cgPath
            pulse.transformBefore = CATransform3DMakeScale(0.1, 0.1, 0.1)
            pulse.transformAfter = CATransform3DMakeScale(1.2, 1.2, 1.2
            )
            pulse.duration = 1.5
            pulse.repeatDelay = 0.5
            pulse.lineWidth = 0.0
        }
        
        // Traveling uses special function
        guard System.shared.state != .Traveling, let entry = self.sheet?.entries.latest else { return }
        
        let breadcrumbs = entry.breadcrumbs.newBreadcrumbs
        var array = [CLLocationCoordinate2D]()
        
        for breadcrumb in breadcrumbs {
            guard let location = breadcrumb.coordinate else { continue }
            array.append(location)
        }
        
        let lineOverlay = MKPolyline(coordinates: array, count: array.count)
        mapView.add(lineOverlay)
    }
    
    
    @objc func badgeValueUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo as? JSON, let count = data["count"] as? Int else {
            self.messageIndicator.alpha = 0.0
            return
        }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION, animations: {
                if count > 0 {
                    self.messageIndicator.alpha = 1.0
                } else {
                    self.messageIndicator.alpha = 0.0
                }
            })
        }
    }
    
    @objc func mapViewRegionChanged(_ notification: NSNotification) {
        DispatchQueue.main.async {
            switch self.mapView.userTrackingMode {
            case .none:
                self.centerMapButton.setImage(AssetManager.shared.centerMap, for: UIControlState.normal)
                break
            case .follow:
                self.centerMapButton.setImage(AssetManager.shared.centerMapFilled, for: UIControlState.normal)
                break
            case .followWithHeading:
                self.centerMapButton.setImage(AssetManager.shared.centerMapOriented, for: UIControlState.normal)
                break
            }
        }
    }
    
    
    @objc func focusUserNotification(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as? JSON,
            let userId = userInfo["user"] as? String
            else {
                return
        }
        
        if let subscription = Subscriptions.shared.get(userId: userId) {
            if let annotation = subscription.annotation {
                mapView.showAnnotations([annotation], animated: true)
            } else if let coordinate = subscription.coordinate {
                subscription.annotation = UserAnnotation(subscription: subscription, coordinate: coordinate)
                mapView.addAnnotation(subscription.annotation!)
            }
        } else {
            let matches = mapView.annotations.filter({ (annotation) -> Bool in
                return annotation is UserAnnotation
            })
            
            for match in matches {
                if (match as! UserAnnotation).subscription.user == userId {
                    mapView.removeAnnotation(match)
                    return
                }
            }
        }
    }
    
    @objc func focusLocationNotification(_ notification: NSNotification) {
        guard   let userInfo = notification.userInfo as? JSON,
                let location = userInfo["location"] as? Location
        else {
                return
        }
        
        focusMap(location: location)
    }
    
    
    @objc func modelUpdated(_ notification: NSNotification) {
        
        guard App.shared.isLoaded == true else {
            return
        }
        
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate, App.shared.isLoaded == true else {
            return
        }
        
        DispatchQueue.main.async {
            self.resetTabs()
        }
        
        if update.model is Location {
            prepareMap()
        }
        
        if update.type == ModelType.Sheet {
            
            if update.action == .Submit {
                DispatchQueue.main.async {
                    PKHUD.success()
                }
            }
            
            prepareMap()
            prepareFab()
        }
        
        if update.type == ModelType.Sheet, update.model == nil {
            self.closeInfo(self)
            self.resetTabs()
            self.prepareMap()
            self.prepareFab()
        }
        
        if update.model is Entry, let _entry = update.model as? Entry, _entry.sheet?.id == self.sheet?.id {
            
            let index = self.focusedEntry.index ?? 0
            let maxIndex = self.sheet?.entries.count ?? 0
            let indexString = String(format: "%i of %i", arguments: [index, maxIndex])
            self.indexLabel.text = indexString
            
            prepareMap()
            
            if update.action == .Create, let entry = self.sheet?.entries[_entry.id], let activity = entry.activity {
                
                if self.focusedEntry.isSet() == true {
                    if let focusedIndexEntryId = self.sheet?.entries[self.focusedEntry.index]?.id {
                        if focusedIndexEntryId != self.focusedEntry.entryId {
                            self.focusedEntry.index = self.sheet?.entries.index(id: self.focusedEntry.entryId)
                        }
                    }
                }else if activity.traveling == true {
                    self.centerMapButton.setImage(AssetManager.shared.centerMapFilled, for: UIControlState.normal)
                    self.mapView.setUserTrackingMode(.follow, animated: true)
                } else if activity.breaking == false {
                    self.mapView.userTrackingMode = .none
                    self.focusMap(entry: entry)
                }
            }
            
            if selectedTab == .Status {
                delay(0.1) {
                    self.reloadTableView()
                    if self.peopleVisible == true, self.selectedTab == .Status {
                        self.updatePeopleViewHeight()
                    }
                }
            }
        }
    }
    
    
    // MARK: - Keyboard Notification Handlers
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        guard self.peopleVisible == true else {
            self.view.endEditing(true)
            return
        }
        
        self.fab.alpha = 0.0
    }
    
    @objc func keyboardDidShow(_ notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            self.fab.alpha = 0.0
            
            UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight + 10.0, 0)
            }
        }
    }
    
    @objc func keyboardWillHide(notification _: NSNotification) {
        
        UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION, delay: 0.0, options: [], animations: {
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.peopleViewHeightConstraintOriginal + 10.0, 0)
        }, completion: nil)
        
        UIView.animate(withDuration: 1.0, delay: 1.0, options: [], animations: {
            if self.shouldFabBeVisible() { self.fab.alpha = 1.0 }
        }, completion: nil)
    }
}

// MARK: - Timeline Alert Handlers

typealias TimelineAlertHandlers = Timeline
extension TimelineAlertHandlers {
    @objc func showCheckInAlert() {
        shouldShowCheckInAlert = true
        checkInAlertViewBottomContsraint.constant = 0
        fab.alpha = 0.0
        peopleViewPulloutView.alpha = 0.0
    }

    @objc func showTravelingAlert() {
        shouldShowTravelingAlert = true
        travelingAlertViewBottomContraint.constant = 0
        fab.alpha = 0.0
        peopleViewPulloutView.alpha = 0.0
    }

    @objc func dismissCheckInAlert() {
        shouldShowCheckInAlert = false
        checkInAlertViewBottomContsraint.constant = -300
        self.fab.alpha = self.shouldFabBeVisible() == true ? 1.0 : 0.0
        peopleViewPulloutView.alpha = 1.0
    }

    @objc func dismissTravelingAlert() {
        shouldShowTravelingAlert = false
        travelingAlertViewBottomContraint.constant = -300
        self.fab.alpha = self.shouldFabBeVisible() == true ? 1.0 : 0.0
        peopleViewPulloutView.alpha = 1.0
    }

    @objc func hideCheckInAlert() {
        checkInAlertViewBottomContsraint.constant = -300
        self.fab.alpha = self.shouldFabBeVisible() == true ? 1.0 : 0.0
        peopleViewPulloutView.alpha = 1.0
    }

    @objc func hideTravelingAlert() {
        travelingAlertViewBottomContraint.constant = -300
        self.fab.alpha = self.shouldFabBeVisible() == true ? 1.0 : 0.0
        peopleViewPulloutView.alpha = 1.0
    }
}

// MARK: - Timeline Theme Functions

typealias TimelineThemeSupport = Timeline
extension TimelineThemeSupport: ThemeSupportedProtocol {
    func initializeThemeObjects() {
        view.backgroundColor = UIColor.black

        peopleView.backgroundColor = UIColor.clear
        statusView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        settingsView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        navigationView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        mapButtonsView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        mapFocusButtonsView.backgroundColor = Theme.shared.active.primaryBackgroundColor

        views.removeAll()
        views.insert(mapButtonsView, at: 0)
        views.insert(mapFocusButtonsView, at: 0)
        views.insert(navigationView, at: 0)
        views.insert(settingsView, at: 0)
        views.insert(statusView, at: 0)
        views.insert(peopleView, at: 0)

        shiftClock.textColor = Theme.shared.active.primaryFontColor
        indexLabel.textColor = Theme.shared.active.primaryFontColor
        mapSegmentLabel.textColor = Theme.shared.active.primaryFontColor
        trafficSwitchLabel.textColor = Theme.shared.active.primaryFontColor
        gpsSwitchLabel.textColor = Theme.shared.active.primaryFontColor
        breadcrumbsSwitchLabel.textColor = Theme.shared.active.primaryFontColor
        toleranceSliderLabel.textColor = Theme.shared.active.primaryFontColor
        toleranceValueLabel.textColor = Theme.shared.active.primaryFontColor
        userAnnotationLabel.textColor = Theme.shared.active.primaryFontColor
        mapAnnotationLabel.textColor = Theme.shared.active.primaryFontColor
        

        primaryLabels.removeAll()
        primaryLabels.insert(userAnnotationLabel, at: 0)
        primaryLabels.insert(mapAnnotationLabel, at: 0)
        primaryLabels.insert(toleranceSliderLabel, at: 0)
        primaryLabels.insert(toleranceValueLabel, at: 0)
        primaryLabels.insert(breadcrumbsSwitchLabel, at: 0)
        primaryLabels.insert(gpsSwitchLabel, at: 0)
        primaryLabels.insert(trafficSwitchLabel, at: 0)
        primaryLabels.insert(mapSegmentLabel, at: 0)
        primaryLabels.insert(indexLabel, at: 0)
        primaryLabels.insert(shiftClock, at: 0)

        clock.textColor = Theme.shared.active.secondaryFontColor
        dayClock.textColor = Theme.shared.active.secondaryFontColor

        secondaryLabels.removeAll()
        secondaryLabels.insert(dayClock, at: 0)
        secondaryLabels.insert(clock, at: 0)

        alternativeLabels.removeAll()

        switches.removeAll()
        switches.append(crumbSwitch)
        switches.append(gpsSwitch)
        switches.append(trafficSwitch)
        switches.append(userAnnotationSwitch)
        switches.append(mapAnnotationSwitch)

        crumbSwitch.thumbTintColor = Theme.shared.active.secondaryBackgroundColor
        crumbSwitch.tintColor = Theme.shared.active.secondaryBackgroundColor
        gpsSwitch.thumbTintColor = Theme.shared.active.secondaryBackgroundColor
        gpsSwitch.tintColor = Theme.shared.active.secondaryBackgroundColor
        trafficSwitch.thumbTintColor = Theme.shared.active.secondaryBackgroundColor
        trafficSwitch.tintColor = Theme.shared.active.secondaryBackgroundColor
        userAnnotationSwitch.thumbTintColor = Theme.shared.active.secondaryBackgroundColor
        userAnnotationSwitch.tintColor = Theme.shared.active.secondaryBackgroundColor
        mapAnnotationSwitch.thumbTintColor = Theme.shared.active.secondaryBackgroundColor
        mapAnnotationSwitch.tintColor = Theme.shared.active.secondaryBackgroundColor
        

        mapButtonsPulloutImage.image = mapButtonsPulloutImage.image?.withRenderingMode(.alwaysTemplate)
        mapFocusButtonsPulloutImage.image = mapFocusButtonsPulloutImage.image?.withRenderingMode(.alwaysTemplate)
        peopleViewPulloutImage.image = peopleViewPulloutImage.image?.withRenderingMode(.alwaysTemplate)

        settingsButton.imageView?.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        mapSpanButton.imageView?.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        centerMapButton.imageView?.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        lockButton.imageView?.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)

        gpsStatusTextView.textColor = Theme.shared.active.secondaryFontColor
        breadcrumbsTextView.textColor = Theme.shared.active.secondaryFontColor
        toleranceTextView.textColor = Theme.shared.active.secondaryFontColor
        userAnnotationTextView.textColor = Theme.shared.active.secondaryFontColor
        mapAnnotationTextView.textColor = Theme.shared.active.secondaryFontColor
        toleranceSlider.thumbTintColor = Theme.shared.active.secondaryBackgroundColor

        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.tableHeaderView?.backgroundColor = Theme.shared.active.primaryBackgroundColor

        fab.buttonImage = AssetManager.shared.compose
        fab.tintColor = UIColor.white
        fab.plusColor = UIColor.white
        fab.itemImageColor = UIColor.white
        fab.buttonColor = Color.blue.darken3
        fab.openAnimationType = .pop
        fab.isUserInteractionEnabled = true
        fab.hasShadow = true
        fab.alpha = 1.0

        for label in primaryLabels {
            label.autoResize()
        }

        for label in secondaryLabels {
            label.autoResize()
        }

        for label in alternativeLabels {
            label.autoResize()
        }
        
        // TODO: - Temp until Apple bug fix !!!
        
        if Device.osType == .iOS12 {
            DeviceSettings.shared.mapType = .standard
            mapTypeSegment.isEnabled = false
        }
        
        
        let type = DeviceSettings.shared.mapType
        
        if type == .standard {
            mapTypeSegment.selectedSegmentIndex = 0
        } else if type == .satelliteFlyover {
            mapTypeSegment.selectedSegmentIndex = 1
        } else if type == .hybridFlyover {
            mapTypeSegment.selectedSegmentIndex = 2
        }
        
        let index = self.focusedEntry.index ?? 0
        let maxIndex = self.sheet?.entries.count ?? 0
        let indexString = String(format: "%i of %i", arguments: [index, maxIndex])
        self.indexLabel.text = indexString
        
        Theme.shared.theme_changed.observe(self, selector: #selector(themeUpdated))
    }

    @objc func applyTheme() {
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.tableHeaderView?.backgroundColor = Theme.shared.active.primaryBackgroundColor

        if App.shared.isLoaded == true {
            prepareMap()
        }

        for view in views {
            view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        }

        for label in primaryLabels {
            label.textColor = Theme.shared.active.primaryFontColor
        }

        for label in secondaryLabels {
            label.textColor = Theme.shared.active.secondaryFontColor
        }

        for label in alternativeLabels {
            label.textColor = Theme.shared.active.alternativeFontColor
        }

        for swtch in switches {
            self.styleSwitch(swtch)
        }

        settingsButton.imageView?.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        mapSpanButton.imageView?.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        centerMapButton.imageView?.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        lockButton.imageView?.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
    }
    
    
    func setMapType(_ type: MKMapType) {
        
        if type == .standard {
            mapTypeSegment.selectedSegmentIndex = 0
        } else if type == .satelliteFlyover {
            mapTypeSegment.selectedSegmentIndex = 1
        } else if type == .hybridFlyover {
            mapTypeSegment.selectedSegmentIndex = 2
        }
        
        UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION, animations: {
            self.mapView.alpha = 0.0
        }) { _ in
            
            DeviceSettings.shared.mapType = type
            self.mapView.mapType = type
            self.prepareMap()
            
            UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
                
                if type != .standard {
                    self.logo.image = AssetManager.shared.launchLogo?.withRenderingMode(.alwaysTemplate)
                    self.logo.tintColor = UIColor.white.withAlphaComponent(0.9)
                } else {
                    self.logo.image = AssetManager.shared.launchLogo
                }
                
                self.setPulloutsTintColor()
                
                self.mapView.alpha = 1.0
            }
        }
    }

    
    func setPulloutsTintColor() {
        
        var color: UIColor!
        
        if self.mapView.mapType != .standard {
            color = UIColor(hex: "EBEBEB")?.withAlphaComponent(0.8)
        } else {
            color = Theme.shared.active.placeholderColor.withAlphaComponent(0.8)
        }
        
        mapButtonsPulloutImage.tintColor = color
        mapFocusButtonsPulloutImage.tintColor = color
        peopleViewPulloutImage.tintColor = color
    }
    
    func initializeButtons() {
        // Navigation View
        menuButton.styleTimeline(AssetManager.shared.menu)
        gpsStrengthButton.styleTimeline(AssetManager.shared.gpsNone)
        messageButton.styleTimeline(AssetManager.shared.message)
        cameraButton.styleTimeline(AssetManager.shared.camera)
        gpsStrengthButton.imageEdgeInsets = UIEdgeInsetsMake(12.5, 2.5, 12.5, 2.5)
        messageButton.imageEdgeInsets = UIEdgeInsetsMake(10.0, 7.5, 10.0, 7.5)
        
        // Map Buttons View
        settingsButton.styleTimeline(AssetManager.shared.settings)
        mapSpanButton.styleTimeline(AssetManager.shared.mapSpan)
        centerMapButton.styleTimeline(AssetManager.shared.centerMap)
        lockButton.styleTimeline(AssetManager.shared.lock)
        
        lockButton.imageEdgeInsets = UIEdgeInsetsMake(7.5, 12.5, 7.5, 12.5)
        
        // Map Focus Buttons View
        rightButton.styleTimeline(AssetManager.shared.arrowRight)
        leftButton.styleTimeline(AssetManager.shared.arrowLeft)
    }
    
    func setLock(locked: Bool, alert: Bool = false) {
        lockButton.styleTimeline(locked == false ? AssetManager.shared.unlock : AssetManager.shared.lock)
        lockButton.removeTargets()
        lockButton.addTarget(self, action: locked == false ? #selector(lockButtonPressed) : #selector(unlockButtonPressed), for: UIControlEvents.touchUpInside)
        
        if alert == true {
            switch locked {
            case false:
                Notifications.scheduleSilentNotification(title: "Location Hold Disabled", body: "Timeline will now generate entries.", identifier: "StateLockDisable")
            case true:
                Notifications.scheduleSilentNotification(title: "Location Hold Enabled", body: "Timeline will not generate any new entries while lock is enabled.", identifier: "StateLockDisable")
            }
        }
    }
    
    @objc func themeUpdated(_ notification: NSNotification) {
        guard let animated = notification.userInfo?["animated"] as? Bool, animated == true else {
            applyTheme()
            return
        }
        
        UIView.animate(withDuration: 0.5) {
            self.applyTheme()
            self.view.setNeedsDisplay()
        }
    }
}

// MARK: - Timeline Settings

typealias TimelineSettingsInitializers = Timeline
extension TimelineSettingsInitializers {
    func initializeSettings() {

        trafficSwitch.setOn(DeviceSettings.shared.mapTrafficEnabled, animated: false)
        gpsSwitch.setOn(DeviceSettings.shared.autoMode, animated: false)
        crumbSwitch.setOn(DeviceSettings.shared.breadcrumbMode, animated: false)
        userAnnotationSwitch.setOn(DeviceSettings.shared.userAnnotationMode, animated: false)
        mapAnnotationSwitch.setOn(DeviceSettings.shared.mapAnnotations, animated: false)
        toleranceValueLabel.text = String(format: "+%0.0f%%", arguments: [DeviceSettings.shared.accuracyBoost])
        toleranceSlider.setValue(Float(DeviceSettings.shared.accuracyBoost), animated: false)
        
        mapView.showsTraffic = DeviceSettings.shared.mapTrafficEnabled
    }
}

// MARK: - Timeline Styling Functions

typealias TimelineStylingInitializers = Timeline
extension TimelineStylingInitializers {
    func initializeFonts() {
        // Set dynamic font sizes
        let fontSize: CGFloat = baseFontSize

        settingsTitle.font = settingsTitle.font.withSize(fontSize + titleFontDifference)
        mapSegmentLabel.font = mapSegmentLabel.font.withSize(fontSize - 2.0)
        trafficSwitchLabel.font = trafficSwitchLabel.font.withSize(fontSize - 2.0)
        gpsSwitchLabel.font = gpsSwitchLabel.font.withSize(fontSize - 2.0)
        userAnnotationLabel.font = userAnnotationLabel.font.withSize(fontSize - 2.0)
        breadcrumbsSwitchLabel.font = breadcrumbsSwitchLabel.font.withSize(fontSize - 2.0)
        toleranceSliderLabel.font = toleranceSliderLabel.font.withSize(fontSize - 2.0)
        toleranceValueLabel.font = toleranceValueLabel.font.withSize(fontSize - 2.0)
        mapAnnotationLabel.font = mapAnnotationLabel.font.withSize(fontSize - 2.0)

        if Device.phoneType == .iPhone5 {
            clock.font = clock.font.withSize(clock.font.pointSize - 1.0)
            shiftClock.font = shiftClock.font.withSize(shiftClock.font.pointSize - 2.0)
        }

        // Style segment font
        DispatchQueue.main.async { [weak self] in
            let font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: fontSize - 6.0)
            self?.mapTypeSegment.setTitleTextAttributes([NSAttributedStringKey.font: font!], for: .normal)
        }

        travelAlertLine1.font = travelAlertLine1.font.withSize(fontSize + alertFontSizeDifference)
        travelAlertLine1.autoResize()
        travelAlertLine2.font = travelAlertLine2.font.withSize(fontSize + alertFontSizeDifference)

        checkInAlertLine1.font = checkInAlertLine1.font.withSize(fontSize + alertFontSizeDifference)
        checkInAlertLine1.autoResize()
        checkInAlertLine2.font = checkInAlertLine2.font.withSize(fontSize + alertFontSizeDifference)
    }

    func initializeFormatters() {
        // Setup formatters
        clockFormatter = DateFormatter()
        timeFormatter = DateFormatter()
        dayFormatter = DateFormatter()
        clockFormatter?.dateFormat = "h:mm:ss a"
        timeFormatter?.dateFormat = "h:mm a"
        dayFormatter?.dateFormat = "E d"
    }
    
    func initializeInitialConstraints() {
        
        statusViewHeightConstraint.constant = Device.hasNotch == true ? statusViewHeightConstraint.constant : statusViewHeightConstraint.constant - TIMELINE_STATUS_VIEW_HEIGHT_DIFFERENCE
        
        // Set original constraint values
        mapButtonsLeadingConstraintOriginal = mapButtonsLeadingConstraint.constant
        mapFocusButtonsTrailingConstraintOriginal = mapFocusButtonsTrailingConstraint.constant
        navigationViewTopConstraintOriginal = navigationViewTopConstraint.constant
        statusViewHeightConstraintOriginal = statusViewHeightConstraint.constant
        peopleViewBottomConstraintOriginal = peopleViewBottomConstraint.constant
        peopleViewHeightConstraintOriginal = peopleViewHeightConstraint.constant
        
    }
    
    func initializeTimelineForPresentation() {
        
        largeLogo.alpha = 0.0
        loadingLabel.alpha = 0.0
        loadingLabel.autoResize()
        mapButtonsPulloutView.alpha = 0.0
        peopleViewPulloutView.alpha = 0.0
        mapFocusButtonsPulloutView.alpha = 0.0
        fab.alpha = 0.0
        logo.alpha = 0.0
        
        navigationViewTopConstraint.constant = -150
        statusViewHeightConstraint.constant = 0.0
        logo.image = AssetManager.shared.launchLogo?.withRenderingMode(.alwaysTemplate)
        logo.tintColor = UIColor.white.withAlphaComponent(0.9)
        
        mapView.showsUserLocation = true
        navigationDrawerController?.isEnabled = false
        mapView.mapType = .satelliteFlyover
        
        hideMapFocusButtons(0.0)
        hideMapButtons(0.0)
    }

    func touchupStyling() {
        mapView.layoutMargins = UIEdgeInsetsMake(80, 80, 80, 80)
        
        trafficSwitch.corner = trafficSwitch.layer.height / 2
        crumbSwitch.corner = crumbSwitch.layer.height / 2
        gpsSwitch.corner = gpsSwitch.layer.height / 2
        userAnnotationSwitch.corner = userAnnotationSwitch.layer.height / 2
        mapAnnotationSwitch.corner = mapAnnotationSwitch.layer.height / 2
        peopleView.shadowOpacity = 0.0
        
        tableView.corner = peopleView.cornerRadius
        
        arrowViewCenterView.height = 0.0
        
        setLock(locked: LocationManager.shared.getStateHoldValue(), alert: false)
    }
}

// MARK: - Timeline Gesture Recognizers

typealias TimelineGestureInitializers = Timeline
extension TimelineGestureInitializers {
    func initializeGestures() {

        tabStatusFlatButton.addTarget(self, action: #selector(navTabPressed), for: .touchUpInside)
        tabStatusFlatButton.addTarget(tabStatusView, action: #selector(tabStatusView.touchAnimation), for: .touchUpInside)
        tabLocationsFlatButton.addTarget(self, action: #selector(navTabPressed), for: .touchUpInside)
        tabLocationsFlatButton.addTarget(tabLocationsView, action: #selector(tabLocationsView.touchAnimation), for: .touchUpInside)
        tabPeopleFlatButton.addTarget(self, action: #selector(navTabPressed), for: .touchUpInside)
        tabPeopleFlatButton.addTarget(tabPeopleView, action: #selector(tabPeopleView.touchAnimation), for: .touchUpInside)
        
        menuButton.addTarget(self, action: #selector(menuPressed), for: .touchUpInside)
        gpsStrengthButton.addTarget(self, action: #selector(gpsStrengthButtonPressed), for: .touchUpInside)
        messageButton.addTarget(self, action: #selector(messageButtonPressed), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraButtonPressed), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)
        mapSpanButton.addTarget(self, action: #selector(mapSpanButtonPressed), for: .touchUpInside)
        centerMapButton.addTarget(self, action: #selector(centerMapButtonPressed), for: .touchUpInside)
        checkInAlertButton.addTarget(self, action: #selector(checkInAlertButtonPressed), for: .touchUpInside)
        travelAlertButton.addTarget(self, action: #selector(travelingAlertButtonPressed), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(leftButtonPressed), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonPressed), for: .touchUpInside)
        
        gpsSwitch.addTarget(self, action: #selector(gpsSwitchChanged), for: UIControlEvents.valueChanged)
        crumbSwitch.addTarget(self, action: #selector(crumbSwitchChanged), for: UIControlEvents.valueChanged)
        trafficSwitch.addTarget(self, action: #selector(trafficSwitchChanged), for: .valueChanged)
        toleranceSlider.addTarget(self, action: #selector(toleranceSliderChanged), for: UIControlEvents.valueChanged)
        mapTypeSegment.addTarget(self, action: #selector(mapTypeSegmentChanged), for: .valueChanged)
        userAnnotationSwitch.addTarget(self, action: #selector(userAnnotationSwitchChanged), for: .valueChanged)
        mapAnnotationSwitch.addTarget(self, action: #selector(mapAnnotationSwitchChanged), for: .valueChanged)
        
        mapButtonsPulloutImage.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(mapButtonsPulloutImagePanGestureController)))
        mapButtonsPulloutImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapButtonsPulloutImagePressed)))
        mapButtonsPulloutImage.isUserInteractionEnabled = true
        
        mapFocusButtonsPulloutImage.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(mapFocusButtonsPulloutImagePanGestureController)))
        mapFocusButtonsPulloutImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapFocusButtonsPulloutImagePressed)))
        mapFocusButtonsPulloutImage.isUserInteractionEnabled = true
        
        peoplePanGesture = UIPanGestureRecognizer(target: self, action: #selector(peoplePanGestureController))
        peopleViewPulloutView.addGestureRecognizer(peoplePanGesture!)
        
        peopleViewPulloutImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(peoplePulloutImagePressed)))
        peopleViewPulloutImage.isUserInteractionEnabled = true
        
        mapGesture = UITapGestureRecognizer(target: self, action: #selector(hideControls))
        mapGesture?.numberOfTouchesRequired = 3
        mapView.addGestureRecognizer(mapGesture!)
        
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(mapLongPressed)))
        
        /*
        let gestureUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp))
        gestureUp.direction = .up
        statusView.addGestureRecognizer(gestureUp)
        */
        
        
        let gestureDown = UISwipeGestureRecognizer(target: self, action: #selector(swipeDown))
        gestureDown.direction = .down
        settingsView.addGestureRecognizer(gestureDown)
        
        
        mapSettingsArrowView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(settingsPanGestureController)))
        
        fab.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFab)))
        fab.isUserInteractionEnabled = true
        
        overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeInfoWithBump)))
        overlayView.isUserInteractionEnabled = true
        
        mapSettingsArrowView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeInfoWithBump)))
        
        tableViewSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeInfoWithBump))
        tableViewSwipeGesture?.direction = .down
        peopleView.addGestureRecognizer(tableViewSwipeGesture!)
        tableViewSwipeGesture?.isEnabled = false
    }

    @objc func peoplePulloutImagePressed(_: UITapGestureRecognizer) {
        peopleViewPulloutImage.touchAnimation()

        if peopleVisible == true {
            closeInfo(self)
        } else {
            selectedTab = System.shared.state == .Off ? backupTab : defaultTab
            peoplePressed()

            peopleViewPulloutImage.image = AssetManager.shared.pulloutDown
        }
    }
    
    @objc func lockButtonPressed() {
        lockButton.touchAnimation()
        
        LocationManager.shared.holdState(true)
        
        setLock(locked: true, alert: true)
    }
    
    @objc func unlockButtonPressed() {
        lockButton.touchAnimation()
        
        LocationManager.shared.holdState(false)
        
        setLock(locked: false, alert: true)
    }

    @objc func mapLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            Generator.confirm()

            focusMap()
            sender.isEnabled = false

            delay(0.3, closure: {
                sender.isEnabled = true
            })
        }
    }
    
    
    @objc func checkInAlertButtonPressed(_ sender : UIButton) {
        sender.touchAnimation()
        
        shouldShowCheckInAlert = false
        
        LocationManager.shared.resetDebounce()
        
        NotificationManager.shared.create_entry.post()
    }
    
    @objc func travelingAlertButtonPressed(_ sender: UIButton) {
        sender.touchAnimation()
        
        shouldShowTravelingAlert = false
        
        LocationManager.shared.resetDebounce()
        
        NotificationManager.shared.create_traveling_entry.post()
    }


    @objc func mapSpanButtonPressed(_: Any) {
        
        focusMap(sheet: sheet)
    }
    

    @objc func centerMapButtonPressed(_: Any) {

        switch mapView.userTrackingMode {
        case .none:
            centerMapButton.setImage(AssetManager.shared.centerMapFilled, for: UIControlState.normal)
            mapView.setUserTrackingMode(.follow, animated: true)
            break
        case .follow:
            centerMapButton.setImage(AssetManager.shared.centerMapOriented, for: UIControlState.normal)
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            break
        case .followWithHeading:
            centerMapButton.setImage(AssetManager.shared.centerMap, for: UIControlState.normal)
            mapView.setUserTrackingMode(.none, animated: false)
            break
        }
    }


    @objc func peoplePanGestureController(_ sender: UIPanGestureRecognizer) {
        // Animate the panel.
        switch sender.state {
        case .began:
            if peopleVisible == false {
                guard sender.translation(in: view).y <= 0 else {
                    sender.isEnabled = false
                    delay(0.1) { sender.isEnabled = true }
                    return
                }
                
                fab.close()
                fab.alpha = 0.0
                
                selectedTab = System.shared.state == .Off ? backupTab : defaultTab
                
                Generator.bump()
                
                UIView.animate(withDuration: 0.1) {
                    self.peopleView.shadowOpacity = 0.5
                }
            }

            originalPeopleViewHeight = peopleViewHeightConstraint.constant
            
            break
        case .changed:
            let translationY = -sender.translation(in: view).y
            let target: CGFloat = originalPeopleViewHeight + translationY

            let modifiedTarget = originalPeopleViewHeight < 150.0 ? 150.0 + translationY : target

            fab.alpha = 0.0

            if modifiedTarget < 150.0 {
                sender.isEnabled = false

                closeInfoWithBump()
                delay(0.25, closure: { sender.isEnabled = true })
                return
            }
            
            let maxHeight: CGFloat = min(self.maxTableViewHeight, ((UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale) - (navigationView.frame.maxY + 30.0)))

            peopleViewHeightConstraint.constant = min(target, maxHeight)

            UIView.animate(withDuration: 0.1, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)

            if target >= maxHeight {
                sender.isEnabled = false
                Generator.confirm()

                UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
                    self.peopleViewPulloutImage.image = AssetManager.shared.pulloutDown
                }

                delay(0.2, closure: { sender.isEnabled = true })

            } else {
                UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
                    self.overlayView.alpha = 0.0
                    self.peopleViewPulloutImage.image = AssetManager.shared.pullout
                }
            }

        case .ended, .cancelled, .failed:
            peopleViewHeightConstraint.constant = peopleView.height
            break
        case .possible:
            break
        }
    }
    
    
    @objc func settingsPanGestureController(_ sender: UIPanGestureRecognizer) {
        // Animate the panel.
        switch sender.state {
        case .began:
            
            originalSettingsViewBottomConstraint = mapSettingsBottomConstraint.constant
            let translationY = -sender.translation(in: view).y
            let target: CGFloat = originalSettingsViewBottomConstraint + translationY
            
            if target > 0 {
                mapSettingsBottomConstraint.constant = 0
                sender.isEnabled = false
                Generator.confirm()
                
                delay(0.2, closure: { sender.isEnabled = true })
                
            } else {
                mapSettingsBottomConstraint.constant = target
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
            break
        case .changed:
            let translationY = -sender.translation(in: view).y
            let target: CGFloat = originalSettingsViewBottomConstraint + translationY
            
            if target < -100 {
                sender.isEnabled = false
                
                closeInfoWithBump()
                delay(0.25, closure: { sender.isEnabled = true })
                return
            } else {
        
                if target > 0 {
                    mapSettingsBottomConstraint.constant = 0
                    sender.isEnabled = false
                    Generator.confirm()
                    
                    delay(0.2, closure: { sender.isEnabled = true })
                    
                } else {
                    mapSettingsBottomConstraint.constant = target
                    
                    UIView.animate(withDuration: 0.1, animations: {
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
            
        case .ended, .cancelled, .failed:
                
            break
        case .possible:
            break
        }
    }
    
    @objc func trafficSwitchChanged(_: Any) {
        DeviceSettings.shared.mapTrafficEnabled = trafficSwitch.isOn
        
        if trafficSwitch.isOn == true { mapView.showsTraffic = true } else { mapView.showsTraffic = false }
    }
    
    @objc func mapTypeSegmentChanged(_ segment: UISegmentedControl) {
        Generator.bump()
        
        if segment.selectedSegmentIndex == 0 {
            setMapType(MKMapType.standard)
        } else if segment.selectedSegmentIndex == 1 {
            setMapType(MKMapType.satelliteFlyover)
        } else if segment.selectedSegmentIndex == 2 {
            setMapType(MKMapType.hybridFlyover)
        }
    }
    
    @objc func mapAnnotationSwitchChanged(_ : Any) {
        DeviceSettings.shared.mapAnnotations = mapAnnotationSwitch.isOn
        
        prepareMap()
    }
    
    @objc func userAnnotationSwitchChanged(_ : Any) {
        
        DeviceSettings.shared.userAnnotationMode = userAnnotationSwitch.isOn
        
        if userAnnotationSwitch.isOn {
            PKHUD.loading()
            Subscriptions.shared.subscribeAll { (success) in
                guard success == true else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
            }
        } else {
            PKHUD.loading()
            Subscriptions.shared.unsubscribeAll { (success) in
                guard success == true else {
                    PKHUD.failure()
                    return
                }
                
                PKHUD.success()
            }
        }
    }
    
    
    
    @objc func navTabPressed(_ sender: FlatButton) {
        let tab = TimelineNavTab(rawValue: sender.tag)
        
        for gesture in tableView.gestureRecognizers ?? [] {
            if gesture is UITapGestureRecognizer {
                tableView.removeGestureRecognizer(gesture)
            }
        }
        
        if tab == self.selectedTab, self.peopleVisible == true {
            self.closeInfoWithBump()
        } else if tab == .Status && System.shared.state == .Off {
            self.closeInfoWithBump()
        } else {
            if self.selectedTab == .People, self.filtering == true  {
                self.searchController.searchBar.text = ""
                self.filtering = false
            }
            
            self.selectedTab = tab
            self.peoplePressed()
        }
    }
    
    @objc func leftButtonPressed(_ sender : FlatButton) {
        guard sheet != nil, sheet!.entries.count > 0 else {
            return
        }
        
        if focusedEntry.isSet() == true {
            let currentIndex = sheet!.entries.count - focusedEntry!.index! - 1
            let newIndex = currentIndex - 1
            if newIndex >= 0 {
                let focusedIndex = sheet!.entries.count - 1 - newIndex
                focusedEntry.set(focusedIndex)
            } else {
                focusedEntry.set(0)
            }
            
        } else {
            focusedEntry.set(0)
        }
    }
    
    @objc func rightButtonPressed(_ sender : FlatButton) {
        guard sheet != nil, sheet!.entries.count > 0 else {
            return
        }
        
        if focusedEntry.isSet() == true {
            let currentIndex = sheet!.entries.count - focusedEntry!.index! - 1
            let newIndex = currentIndex + 1
            let maxIndex = (sheet?.entries.count)! - 1
            if newIndex <= maxIndex {
                let focusedIndex = sheet!.entries.count - 1 - newIndex
                focusedEntry.set(focusedIndex)
            } else {
                focusedEntry.set(maxIndex)
            }
        } else {
            let newIndex = 0
            let maxIndex = (sheet?.entries.count)! - 1
            
            if newIndex <= maxIndex {
                let focusedIndex = sheet!.entries.count - 1 - newIndex
                focusedEntry.set(focusedIndex)
            }
        }
    }

    @objc func mapButtonsPulloutImagePressed(_: UITapGestureRecognizer) {
        mapButtonsPulloutImage.touchAnimation()

        if mapButtonsHidden == true {
            showMapButtons()
        } else {
            hideMapButtons()
        }
    }

    func showMapButtons(_ velocity: TimeInterval? = nil) {
        mapButtonsHidden = false

        mapButtonsLeadingConstraint.constant = mapButtonsLeadingConstraintOriginal!
        UIView.animate(withDuration: TimeInterval(velocity ?? DEFAULT_ANIMATION_DURATION),
                       animations: { [weak self] in
                           self?.view.layoutIfNeeded()
        })
    }

    func hideMapButtons(_ velocity: TimeInterval? = nil) {
        mapButtonsHidden = true

        mapButtonsLeadingConstraint.constant = mapButtonsLeadingConstraintOriginal - mapButtonsView.width - 12.5
        UIView.animate(withDuration: TimeInterval(velocity ?? DEFAULT_ANIMATION_DURATION),
                       animations: {
                           self.view.layoutIfNeeded()
        })
    }

    @objc func mapFocusButtonsPulloutImagePressed(_: UITapGestureRecognizer) {
        mapFocusButtonsPulloutImage.touchAnimation()

        if mapFocusButtonsHidden == true {
            showMapFocusButtons()
        } else {
            hideMapFocusButtons()
        }
    }

    func showMapFocusButtons(_ velocity: TimeInterval? = nil) {
        mapFocusButtonsHidden = false

        if self.focusedEntry.isSet() == false {
            let index = self.focusedEntry.index ?? 0
            let maxIndex = self.sheet?.entries.count ?? 0
            let indexString = String(format: "%i of %i", arguments: [index, maxIndex])
            self.indexLabel.text = indexString
        }
        
        mapFocusButtonsTrailingConstraint.constant = mapFocusButtonsTrailingConstraintOriginal
        UIView.animate(withDuration: TimeInterval(velocity ?? DEFAULT_ANIMATION_DURATION),
                       animations: {
                           self.view.layoutIfNeeded()

        })
    }

    func hideMapFocusButtons(_ velocity: TimeInterval? = nil) {
        mapFocusButtonsHidden = true

        mapFocusButtonsTrailingConstraint.constant = mapFocusButtonsTrailingConstraintOriginal - mapFocusButtonsView.width - 12.5
        UIView.animate(withDuration: TimeInterval(velocity ?? DEFAULT_ANIMATION_DURATION),
                       animations: {
                           self.view.layoutIfNeeded()
        })
    }

    @objc func mapFocusButtonsPulloutImagePanGestureController(_ sender: UIPanGestureRecognizer) {
        let v = mapFocusButtonsPulloutView!

        // Animate the panel.
        switch sender.state {
        case .began:
            break
        case .changed:
            let translationX = -sender.translation(in: v).x
            let overshoot = (mapFocusButtonsTrailingConstraint.constant + translationX) - mapFocusButtonsTrailingConstraintOriginal
            var target: CGFloat = min(mapFocusButtonsTrailingConstraint.constant + translationX, mapFocusButtonsTrailingConstraintOriginal)
            if overshoot > 0 {
                target += pow(overshoot, 0.66)
            }

            // let span = self.mapFocusButtonsTrailingConstraintOriginal - (self.mapFocusButtonsTrailingConstraintOriginal - self.mapFocusButtonsView.width - 12.5)
            // let alphaInset = max(1.0, (span - target) / span)
            // let alpha = 1.0 - 0.8 * alphaInset

            mapFocusButtonsTrailingConstraint.constant = target
            UIView.animate(withDuration: 0.1) {
                self.view.layoutIfNeeded()
                // self.mapFocusButtonsPulloutView.alpha = alpha
            }

        case .ended, .cancelled, .failed:
            // let p = sender.velocity(in: sender.view)
            // let x = p.x >= 1000 || p.x <= -1000 ? p.x : 0

            if mapFocusButtonsTrailingConstraint.constant >= mapFocusButtonsPanViewThreshold /* || x > 1000 */ {
                showMapFocusButtons()
            } else {
                hideMapFocusButtons()
            }
        case .possible:
            break
        }
    }

    @objc func mapButtonsPulloutImagePanGestureController(_ sender: UIPanGestureRecognizer) {
        let v = mapButtonsPulloutView!

        // Animate the panel.
        switch sender.state {
        case .began:
            break
        case .changed:
            let translationX = sender.translation(in: v).x

            let overshoot = (mapButtonsLeadingConstraint.constant + translationX) - mapButtonsLeadingConstraintOriginal
            var target: CGFloat = min(mapButtonsLeadingConstraint.constant + translationX, mapButtonsLeadingConstraintOriginal)
            if overshoot > 0 {
                target += pow(overshoot, 0.66)
            }

            // let span = self.mapButtonsLeadingConstraintOriginal - (self.mapButtonsLeadingConstraintOriginal - self.mapButtonsView.width - 12.5)
            // let alphaInset = max(1.0, (span - target) / span)
            // let alpha = 1.0 - 0.8 * alphaInset

            mapButtonsLeadingConstraint.constant = target

            UIView.animate(withDuration: 0.1) {
                self.view.layoutIfNeeded()
                // self.mapButtonsPulloutView.alpha = alpha
            }

        case .ended, .cancelled, .failed:
            // let p = sender.velocity(in: sender.view)
            // let x = p.x >= 1000 || p.x <= -1000 ? p.x : 0

            if mapButtonsLeadingConstraint.constant >= mapButtonsPanViewThreshold /* || x > 1000 */ {
                showMapButtons()
            } else {
                hideMapButtons()
            }
        case .possible:
            break
        }
    }
    
    @objc func settingsButtonPressed(_: Any) {
        
        if shouldShowCheckInAlert == true { hideCheckInAlert() }
        if shouldShowTravelingAlert == true { hideTravelingAlert() }
        
        
        statusViewHeightConstraint.constant = 0.0
        peopleViewHeightConstraint.constant = 0.0
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.overlayView.alpha = 0.5
            self.fab.alpha = 0.0
        }) { _ in
            self.settingsVisible = true
            UIView.animate(withDuration: 0.125, animations: {
                self.view.layoutIfNeeded()
            })
            
            UIView.animate(withDuration: 0.125) {
                self.settingsButton.transform = self.settingsButton.transform.rotated(by: -0.9999 * CGFloat.pi / 2.0)
                self.settingsButton.layoutIfNeeded()
            }
        }
    }

    @objc func messageButtonPressed() {
        
        let destination = UIStoryboard.Chat(identifier: "ViewChats") as! ViewChats
        destination.quickAccessed = true
        
        delay(0.2) {
            Presenter.push(destination, animated: true)
        }
    }

    @objc func swipeUp(_ sender: UISwipeGestureRecognizer) {

        guard self.peopleVisible == false else { return }
        
        selectedTab = System.shared.state == .Off ? backupTab : defaultTab
        
        Generator.bump()
        
        self.peoplePressed()
    }
    
    @objc func swipeDown(_: UISwipeGestureRecognizer) {

        closeInfoWithBump()
    }


    @objc func cameraButtonPressed() {
        
        let camera = Camera(source: self)

        camera.PresentPhotoInput(target: self, canEdit: false)
    }

    @objc func closeInfoWithBump() {
        
        Generator.bump()

        closeInfo(self)
    }

    @objc func gpsStrengthButtonPressed(_: Any) {
        
        LocationManager.shared.postLocationToAPI(true)
    }

    @objc func peoplePressed() {
        
        if selectedTab == nil { selectedTab = System.shared.state == .Off ? backupTab : defaultTab }
        if selectedTab == .Status, System.shared.state == .Off { return }

        fab.alpha = 0.0
        self.peopleVisible = true
        UIView.animate(withDuration: self.selectedTab == .People ? 0.125 : 0.2, animations: {
            self.view.layoutIfNeeded()
            self.updatePeopleViewHeight()
            self.peopleView.shadowOpacity = 0.5
            self.overlayView.alpha = 0.0
            self.fab.close()
            if self.peoplePanGesture?.state == .possible {
                self.peopleViewPulloutImage.image = AssetManager.shared.pulloutDown
            }
        })
    }

    @objc func gpsSwitchChanged(_ sender: UISwitch) {
        Generator.bump()

        DeviceSettings.shared.autoMode = sender.isOn
        LocationManager.shared.isTrackingLocation = sender.isOn
    }

    @objc func crumbSwitchChanged(_ sender: UISwitch) {
        Generator.bump()

        DeviceSettings.shared.breadcrumbMode = sender.isOn
    }

    @objc func toleranceSliderChanged(_ sender: UISlider) {
        DeviceSettings.shared.accuracyBoost = Double(sender.value)
        toleranceValueLabel.text = String(format: "+%0.0f%%", arguments: [sender.value])
    }
    
    @objc func goUserProfile(_ sender: UITapGestureRecognizer) {
        Generator.bump()
        
        guard let tag = sender.view?.tag, tag >= 0 else {
            return
        }
        
        let user = Users.shared.items[tag]
        user.view()
        self.dismissSearchController(sender)
    }
}

// MARK: - Timeline Fab Functions

typealias TimelineFabButton = Timeline
extension TimelineFabButton: KCFloatingActionButtonDelegate, FloatyDelegate {
    @objc func toggleFab(_ sender: UITapGestureRecognizer) {
        if fab.closed == true {
            sender.view?.touchAnimation()
        } else {
            Generator.bump()
        }

        delay(fab.closed == true ? 0.2 : 0.0) {
            self.fab.toggle()
        }
    }

    @objc func prepareFab() {
        switch System.shared.state {
        case .Off:
            prepareFabOff()
            fabState = .Off
            break
        case .Break:
            prepareFabBreak()
            fabState = .Break
            break
        case .LoggedIn:
            prepareFabLoggedIn()
            fabState = .LoggedIn
            break
        case .Traveling:
            prepareFabTraveling()
            fabState = .Traveling
            break
        case .Empty:
            prepareFabEmpty()
            fabState = .Empty
            break
        default:
            prepareFabOff()
            fabState = .Error
            break
        }

        DispatchQueue.main.async { [weak self] in
            guard let _self = self else {
                return
            }

            for item in _self.fab.items {
                let font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 13.5)
                item.titleLabel.font = font
                item.titleLabel.textAlignment = .right
                item.isUserInteractionEnabled = true
            }
        }
    }

    func prepareFabOff() {
        fab.clear()
        
        fab.addItem(item: FloatyItem.timesheetItem(target: self, action: #selector(createTimesheet), addShortcut: true))
    }

    func prepareFabBreak() {
        fab.clear()

        fab.addItem(item: FloatyItem.entryItem(target: self, action: #selector(manualEntryCreate), addShortcut: true))
        fab.addItem(item: FloatyItem.travelItem(target: self, action: #selector(createTravelingEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.endBreakItem(target: self, action: #selector(endBreakEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.submitItem(target: self, action: #selector(submitTimeSheet), addShortcut: true))
    }

    func prepareFabLoggedIn() {
        fab.clear()
        
        fab.addItem(item: FloatyItem.entryItem(target: self, action: #selector(manualEntryCreate), addShortcut: true))
        fab.addItem(item: FloatyItem.travelItem(target: self, action: #selector(createTravelingEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.breakItem(target: self, action: #selector(createBreakEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.submitItem(target: self, action: #selector(submitTimeSheet), addShortcut: true))
    }

    func prepareFabTraveling() {
        fab.clear()
        
        fab.addItem(item: FloatyItem.entryItem(target: self, action: #selector(manualEntryCreate), addShortcut: true))
        fab.addItem(item: FloatyItem.breakItem(target: self, action: #selector(createBreakEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.submitItem(target: self, action: #selector(submitTimeSheet), addShortcut: true))
    }

    func prepareFabEmpty() {
        fab.clear()
        
        fab.addItem(item: FloatyItem.entryItem(target: self, action: #selector(manualEntryCreate), addShortcut: true))
        fab.addItem(item: FloatyItem.travelItem(target: self, action: #selector(createTravelingEntry), addShortcut: true))
        fab.addItem(item: FloatyItem.deleteItem(target: self, action: #selector(submitTimeSheet), addShortcut: true))
    }
    
    func shouldFabBeVisible() -> Bool {
        
        if App.shared.isLoaded == false {
            return false
        }
        
        if self.peopleVisible == true || self.settingsVisible == true || self.statusView.alpha == 0.0 || self.mapView.alpha != 1.0 {
            return false
        } else {
            return true
        }
    }
}

// MARK: - Timeline Table View

typealias TimelineUserTableView = Timeline
extension TimelineUserTableView: UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    func initializeTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        self.filtering = false
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsetsMake(0, 0, peopleViewHeightConstraintOriginal + 10.0, 0)
        tableView.showsVerticalScrollIndicator = false
        self.navigationController?.extendedLayoutIncludesOpaqueBars = true
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(closeInfo), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        styleSearchBar(searchController)
        
        //registerForPreviewing(with: self, sourceView: peopleView)

        // Timesheet Section

        EntriesCell.register(tableView)
        EntriesHeaderCell.register(tableView)

        // Location Section

        LocationHeaderCell.register(tableView)
        LocationsScrollCell.register(tableView)

        // People Section
        
        PeopleScrollCell.register(tableView)
        UserCell.register(tableView)
    }

    @objc func reloadTableView() {
        
        if self.selectedTab == .People {
            if tableView.tableHeaderView == nil {
                searchController.hidesNavigationBarDuringPresentation = false
                searchController.searchBar.delegate = self
                searchController.delegate = self
                tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: DEFAULT_SEARCHBAR_HEADER_HEIGHT))
                tableView.tableHeaderView?.corner = self.tableView.cornerRadius
                tableView.tableHeaderView?.clipsToBounds = true
                tableView.tableHeaderView?.addSubview(searchController.searchBar)
                tableView.tableHeaderView?.layoutSubviews()
                tableView.tableHeaderView?.sizeToFit()
                tableView.tableHeaderView?.layoutIfNeeded()
                searchController.searchBar.sizeToFit()
                searchController.searchBar.backgroundColor = Theme.shared.active.primaryBackgroundColor
                tableView.tableHeaderView?.backgroundColor = Theme.shared.active.primaryBackgroundColor
            }
            
            tableView.tableHeaderView?.height = DEFAULT_SEARCHBAR_HEADER_HEIGHT
            if searchController.searchBar.showsCancelButton == true { searchController.searchBar.setShowsCancelButton(false, animated: true) }
            tableView.isScrollEnabled = self.filtering
            tableViewSwipeGesture?.isEnabled =  !self.filtering
        } else if self.selectedTab == .Locations {
            tableView.tableHeaderView?.height = 0
            tableView.tableHeaderView = nil
            tableView.isScrollEnabled = false
            tableViewSwipeGesture?.isEnabled = true
        } else if self.selectedTab == .Status {
            tableView.tableHeaderView?.height = 0
            tableView.tableHeaderView = nil
            tableView.isScrollEnabled = true
            tableViewSwipeGesture?.isEnabled = false
        }
        
        if peopleViewHeightConstraint.constant > estimatedTableViewHeight {
            updatePeopleViewHeight()
        }
        
        tableView.reloadData()
    }

    func numberOfSections(in _: UITableView) -> Int {
        guard let tab = self.selectedTab else {
            return 1
        }

        switch tab {
        case .Status:
            let value = self.focusedEntry.entryId != nil ? 1 : 2
            return value
        case .Locations:
            return 1
        case .People:
            return 2
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tab = self.selectedTab else {
            return 1
        }

        switch tab {
        case .Status:
            switch section {
            case 0:
                let value = System.shared.state == SystemState.Off ? 0 : 1
                return value
            case 1:
                let value = (System.shared.state == SystemState.Off || System.shared.state == SystemState.Empty || self.focusedEntry.isFocused) ? 0 : sheet?.entries.count ?? 0
                return value
            default:
                return 0
            }
        case .Locations:
            switch section {
            case 0:
                return 1
            default:
                return 1
            }
        case .People:
            switch section {
            case 0:
                return self.filtering == true ? self.filteredUsers.count : 1
            case 1:
                return 1
            default:
                return 0
            }
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let tab = self.selectedTab else {
            return 0
        }

        switch tab {
        case .Status:
            switch indexPath.section {
            case 0:
                return EntriesHeaderCell.cellHeight
            default:
                return EntriesCell.cellHeight
            }
        case .Locations:
            switch indexPath.section {
            case 11:
                return LocationHeaderCell.cellHeight
            case 0:
                return LocationsScrollCell.cellHeight
            default:
                return 0
            }
        case .People:
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    return self.filtering == true ?  UserCell.cellHeight : DEFAULT_SEARCHBAR_HEADER_HEIGHT / 2.0
                default:
                    return UserCell.cellHeight
                }
            case 1:
                switch indexPath.row {
                case 0:
                    return self.filtering == true ? 0.0 : PeopleScrollCell.cellHeight
                default:
                    return 0
                }
            
            default:
                return 0
            }
        }
    }

    var estimatedTableViewHeight: CGFloat {
        guard let tab = self.selectedTab else {
            return 0
        }

        switch tab {
        case .People:
            return self.filtering == true ? UIScreen.main.bounds.height : DEFAULT_SEARCHBAR_HEADER_HEIGHT + (DEFAULT_SEARCHBAR_HEADER_HEIGHT / 2.0) + PeopleScrollCell.cellHeight
        case .Locations:
            return LocationsScrollCell.cellHeight
        case .Status:
            guard let sheet = self.sheet else { return 0 }
            
            if let _ = self.focusedEntry.entryId {
                return EntriesHeaderCell.cellHeight
            } else {
                return EntriesHeaderCell.cellHeight + CGFloat(self.focusedEntry.isFocused ? 0 : sheet.entries.count) * EntriesCell.cellHeight + 10
            }
        }
    }
    
    var maxTableViewHeight: CGFloat {
        let extra: CGFloat = estimatedTableViewHeight - tableView.contentSize.height - peopleViewBottomConstraintOriginal
        let target = max(min(peopleViewHeightConstraint.constant, tableView.contentSize.height), tableView.contentSize.height) + extra
        
        return target
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tab = self.selectedTab else {
            return UITableViewCell()
        }

        switch tab {
        case .Status:
            if indexPath.section == 0 {
                let cell = EntriesHeaderCell.loadNib(self.tableView)

                cell.populate(sheet)

                let tap = UITapGestureRecognizer(target: self, action: #selector(goBack))
                cell.arrowDownView!.addGestureRecognizer(tap)
                cell.arrowDownView!.isUserInteractionEnabled = true

                cell.selectionStyle = .none

                return cell
            } else if indexPath.section == 1, indexPath.row < sheet?.entries.count ?? 0 {
                let cell = EntriesCell.loadNib(tableView)

                cell.threeDTouchAvailable = false // self.is3DTouchAvailable()
                cell.populate(sheet, index: indexPath.row)
                
                return cell
            } else {
                let cell = UITableViewCell()
                cell.selectionStyle = .none
                return cell
            }
        case .Locations:
            switch indexPath.section {
            case 11:
                let cell = LocationHeaderCell.loadNib(tableView)

                if let location = self.mapView.userLocation.location ?? LocationManager.shared.currentLocation {
                    Locations.shared.sortByDistance(location)
                }
                
                cell.button.addTarget(self, action: #selector(createLocationButtonPressed), for: .touchUpInside)
                
                cell.populate()
                
                cell.selectionStyle = .none
                return cell
            case 0:
                let cell = LocationsScrollCell.loadNib(tableView)

                cell.label.text = ""
                cell.cleanse()
                cell.populate(3)
                cell.selectionStyle = .none

                return cell
            default:
                return UITableViewCell()
            }
        case .People:
            switch indexPath.section {
            case 0:
                
                guard self.filtering == false else {
                    
                    if indexPath.row < self.filteredUsers.count {
                        let cell = UserCell.loadNib(tableView)
                        cell.populate(self.filteredUsers[indexPath.row])
                        cell.tag = Users.shared.index(id: self.filteredUsers[indexPath.row].id) ?? -1
                        
                        cell.gestureRecognizers?.removeAll()
                        let tap = UITapGestureRecognizer(target: self, action: #selector(goUserProfile))
                        cell.addGestureRecognizer(tap)
                        
                        cell.selectionStyle = .none
                        return cell
                    } else {
                        return UITableViewCell()
                    }
                }
                
                let cell = UITableViewCell()
                cell.backgroundColor = Theme.shared.active.primaryBackgroundColor
                cell.selectionStyle = .none
                
                PeopleScrollCell.mode = Users.shared.active.count > 0 ? .Active : .All
                
                let control = BetterSegmentedControl(
                    frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.width, height: DEFAULT_SEARCHBAR_HEADER_HEIGHT / 2.0),
                    titles: ["Active", "All"],
                    index: UInt( PeopleScrollCell.mode.rawValue),
                    options: [.backgroundColor(Theme.shared.active.subHeaderBackgroundColor),
                              .titleColor(Theme.shared.active.subHeaderFontColor),
                              .indicatorViewBackgroundColor(Theme.shared.active.rootHeaderBackgroundColor),
                              .selectedTitleColor(Theme.shared.active.rootHeaderFontColor),
                              .titleFont(UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 14.0)!),
                              .selectedTitleFont(UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 14.0)!),
                              .cornerRadius(5.0),
                              .bouncesOnChange(true)]
                )
                
                control.addTarget(self, action: #selector(self.peopleModeSegmentDidChange), for: .valueChanged)
                cell.addSubview(control)
                control.sizeToFit()
                
                return cell
            case 1:
                switch indexPath.row {
                case 0:
                    guard self.filtering == false else {
                        return UITableViewCell()
                    }
                    
                    if PeopleScrollCell.shared == nil {
                        let cell = PeopleScrollCell.loadNib(tableView)
                        PeopleScrollCell.shared = cell
                        PeopleScrollCell.mode = .Active
                        PeopleScrollCell.shared?.label.text = ""
                        PeopleScrollCell.shared?.populate(3)
                        cell.selectionStyle = .none
                    } else {
                        PeopleScrollCell.shared?.cleanse()
                    }
                    
                    PeopleScrollCell.shared?.populate(3)
                    return PeopleScrollCell.shared!
                default:
                    return UITableViewCell()
                }
            default:
                let cell = UITableViewCell()
                cell.selectionStyle = .none
                return cell
            }
        }
    }

    @objc func createLocationButtonPressed(_ sender: FlatButton) {
        UIView.animateAndChain(withDuration: 0.1, delay: 0.0, options: [], animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: nil).animateAndChain(withDuration: 0.1, delay: 0.0, options: [], animations: {
            sender.transform = .identity
        }, completion: { _ in
            Location().create()
        })
    }
    
    @objc func peopleModeSegmentDidChange(_ sender: BetterSegmentedControl) {
        
        switch sender.index {
        case 0:
            PeopleScrollCell.mode = .Active
            break
        case 1:
            PeopleScrollCell.mode = .All
            break
        default:
            PeopleScrollCell.mode = .Nearby
            break
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tab = self.selectedTab else {
            return
        }

        switch tab {
        case .Status:
            if indexPath.section == 1 {
                guard let sheet = self.sheet, indexPath.row < sheet.entries.count else {
                    return
                }

                Generator.bump()

                let destination = UIStoryboard.Main(identifier: "EntryReview") as! EntryReview

                let entry = self.sheet!.entries[indexPath.row]

                destination.sheet = self.sheet
                destination.index = indexPath.row
                destination.entry = entry

                Presenter.push(destination, animated: true, completion: nil)
            }
        case .Locations:
            return
        case .People:
            return
        }
    }

    func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let tab = self.selectedTab else {
            return false
        }

        switch tab {
        case .Status:
            let value = indexPath.section == 1 ? true : false
            return value
        case .Locations:
            return false
        case .People:
            return false
        }
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let tab = self.selectedTab else {
            return []
        }

        switch tab {
        case .Status:
            guard indexPath.section == 1 else {
                return []
            }

            let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { _, _ in

                Generator.bump()

                PKHUD.loading()

                self.sheet?.entries.items[indexPath.row].delete({ success in
                    guard success == true else {
                        PKHUD.failure()
                        return
                    }

                    PKHUD.success()
                })
            })

            let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit", handler: { _, _ in

                Generator.bump()

                let destination = UIStoryboard.Main(identifier: "EntryEdit") as? EntryEdit

                destination?.sheet = self.sheet
                destination?.index = indexPath.row

                Presenter.push(destination!, animated: true, completion: nil)

            })

            let viewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Map", handler: { _, _ in
                
                self.closeInfoWithBump()

                self.focusedEntry.set(indexPath.row)

            })

            viewRowAction.backgroundColor = UIColor.blue.withAlphaComponent(0.75)
            editRowAction.backgroundColor = UIColor.gray.withAlphaComponent(0.75)
            deleteRowAction.backgroundColor = UIColor.red.withAlphaComponent(0.75)

            return [viewRowAction, editRowAction, deleteRowAction]
        case .Locations:
            return []
        case .People:
            return []
        }
    }

    func tableView(_: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt _: IndexPath) {
        if let value = cell as? EntriesCell {
            value.updates = false
        } else if let value = cell as? EntriesHeaderCell {
            value.updates = false
        } else if let value = cell as? PeopleScrollCell {
            value.cleanse()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let value = cell as? EntriesCell {
            value.updates = indexPath.row == 0
        } else if let value = cell as? EntriesHeaderCell {
            value.updates = true
        } else if let value = cell as? EntriesHeaderCell {
            value.updates = true
        }
    }
}


// MARK: - Timeline Search Controller

typealias TimelineSearchResults = Timeline
extension TimelineSearchResults {

    func updateSearchResults(for searchController: UISearchController) {
        
        guard self.filtering == true else {
            return
        }
        
        if let searchString = searchController.searchBar.text?.uppercased() {
            let searchArray = searchString.components(separatedBy: " ")
            if searchString.characters.count > 0 && Users.shared.items.count > 0 {
                filteredUsers = Users.shared.items.filter({ (item) -> Bool in
                    
                    var found: Int = 0
                    var compares: [String] = [String]()
                    
                    compares.append(item.userRole.rawValue.uppercased())
                    
                    if let stream = Stream.shared[item.id] {
                        compares.append("-ACTIVE")
                        
                        if let activity = stream.entry?.activity?.name {
                            compares.append(activity)
                        }
                        if let location = stream.entry?.location?.name {
                            compares.append(location)
                        }
                    } else {
                        compares.append("-FREE")
                    }
                    
                    for searchItem in searchArray {
                        
                        if searchItem == " " || searchItem == "" {
                            found += 1
                            continue
                        }
                        
                        for compare in compares {
                            if(compare.uppercased().contains(searchItem)) {
                                found += 1
                            }
                        }
                        
                        if item.firstName!.uppercased().contains(searchItem) || item.lastName!.uppercased().contains(searchItem) {
                            found += 1
                        }
                    }
                    
                    return found >= searchArray.count
                })
            } else {
                filteredUsers = Users.shared.items
            }
        }
        
        if filtering {
            self.reloadSearchResults()
        }
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    func reloadSearchResults() {
        self.tableView.reloadData()
    }


    func willPresentSearchController(_: UISearchController) {
        self.filtering = true
    }

    @objc func dismissSearchController(_ sender: UITapGestureRecognizer) {
        searchController.dismiss(animated: true, completion: nil)
    }

    func didPresentSearchController(_: UISearchController) {
        // foo
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        view.endEditing(true)
        
        DispatchQueue.main.async {
            self.tableView.setContentOffset(CGPoint(x: 0, y: -DEFAULT_SEARCHBAR_HEADER_HEIGHT), animated: false)
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: false)
        }
        
        DispatchQueue.main.async {
            self.filtering = false
        }
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        self.searchController.searchBar.text = ""
    }

    @objc func dismissSearch(_ sender:  UITapGestureRecognizer) {
        self.searchController.searchBar.text = ""
        searchController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Timeline Previewing Delegate

typealias TimelinePreviewingDelegate = Timeline
extension TimelinePreviewingDelegate: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if (System.shared.state == SystemState.Off) || (System.shared.state == SystemState.Empty) { return nil }
        guard selectedTab == .Status else { return nil }
        let point = location.bma_offsetBy(dx: 0, dy: 0)
        guard let indexPath = self.tableView.indexPathForRow(at: point) else { return nil }

        if indexPath.section != 1 { return nil }

        let index = indexPath.row

        let newPath = IndexPath(row: index, section: 1)

        guard let cell = self.tableView.cellForRow(at: newPath) else { return nil }

        guard let detailVC = UIStoryboard.Main(identifier: "EntryReview") as? EntryReview else { return nil }

        detailVC.entry = sheet!.entries[index]
        detailVC.sheet = sheet!
        detailVC.index = index

        detailVC.preferredContentSize = CGSize(width: 0.0, height: 670)

        previewingContext.sourceRect = cell.frame

        return detailVC
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        if let _ = touches.first, traitCollection.forceTouchCapability == .available {
            // foo
        }
    }

    func previewingContext(_: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
