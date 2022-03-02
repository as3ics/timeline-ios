//
//  TimesheetHistoryViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/18/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import MapKit
import PKHUD
import UIKit
import CoreLocation
import Material


// MARK: - HistoryTimesheetController

class HistoryTimesheetController: ViewController, CLLocationManagerDelegate, MapViewProtocol, MKMapViewDelegate  {
    
    @IBOutlet var mapView: MapView!

    var sheet: Sheet!
    weak var focusedEntry: FocusedEntry! = _focusedEntry
    
    // MARK: - History MapFocusButtonsView Section Outlets
    
    @IBOutlet var mapFocusButtonsView: UIView!
    @IBOutlet var indexLabel: UILabel!
    @IBOutlet var arrowViewCenterView: UIView!
    @IBOutlet var leftButton: FlatButton!
    @IBOutlet var rightButton: FlatButton!
    @IBOutlet var mapFocusButtonsPulloutView: UIView!
    @IBOutlet var mapFocusButtonsPulloutImage: UIImageView!
    
    fileprivate var mapFocusButtonsHidden: Bool = false
    
    // MARK: - History PeopleView Section Outlets
    
    @IBOutlet var peopleView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var peopleViewPulloutView: UIView!
    @IBOutlet var peopleViewPulloutImage: UIImageView!
    
    
    // MARK: - History StatusView Section Outlets
    
    @IBOutlet var statusView: UIView!
    @IBOutlet var tabStatusView: UIView!
    @IBOutlet var tabStatusImage: UIImageView!
    @IBOutlet var tabStatusLabel: UILabel!
    @IBOutlet var tabStatusDownArrow: UIImageView!
    @IBOutlet var tabStatusFlatButton: FlatButton!
    
    // MARK: History Layout Constraints
    
    @IBOutlet var arrowViewCenterViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var peopleViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var peopleViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var mapFocusButtonsTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var statusViewHeightConstraint: NSLayoutConstraint!
    
    fileprivate var mapFocusButtonsTrailingConstraintOriginal: CGFloat = 0.0
    fileprivate var peopleViewBottomConstraintOriginal: CGFloat = 0.0
    fileprivate var peopleViewHeightConstraintOriginal: CGFloat = 0.0
    fileprivate var statusViewHeightConstraintOriginal: CGFloat = 0.0
    fileprivate var originalPeopleViewHeight: CGFloat = 0.0
    
    fileprivate var mapPadding: UIEdgeInsets?
    fileprivate let baseFontSize: CGFloat = 18.0
    fileprivate var peoplePanGesture: UIPanGestureRecognizer?
    fileprivate var mapFocusButtonsPanViewThreshold: CGFloat { return mapFocusButtonsTrailingConstraintOriginal - (mapFocusButtonsView.width / 2.0) - 12.5 }
    
    fileprivate var peopleVisible: Bool {
        get {
            return peopleViewHeightConstraint.constant != peopleViewHeightConstraintOriginal
        } set {
            peopleViewHeightConstraint.constant = newValue == false ? peopleViewHeightConstraintOriginal : maxTableViewHeight
            
            if newValue == false {
                self.resetTabs()
            } else {
                tabStatusImage.tintColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabStatusLabel.textColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
                tabStatusDownArrow.alpha = 1.0
            }
        }
    }
    
    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard self.sheet != nil else {
            goBack()
            return
        }
        
        mapView.delegate = mapView
        
        mapView.inputView?.masksToBounds = false
        mapView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 140, right: 10)
        mapView.showsUserLocation = false
        mapView.showsTraffic = false

        mapPadding = UIEdgeInsetsMake(40, 40, 130, 40)
        
        statusViewHeightConstraint.constant = Device.hasNotch == true ? statusViewHeightConstraint.constant : statusViewHeightConstraint.constant - TIMELINE_STATUS_VIEW_HEIGHT_DIFFERENCE
        
        // Set original constraint values
        mapFocusButtonsTrailingConstraintOriginal = mapFocusButtonsTrailingConstraint.constant
        statusViewHeightConstraintOriginal = statusViewHeightConstraint.constant
        peopleViewBottomConstraintOriginal = peopleViewBottomConstraint.constant
        peopleViewHeightConstraintOriginal = peopleViewHeightConstraint.constant
        
        initializeTableView()
        initializeNavTab()
        
        hideMapFocusButtons(0.0)
        
        PKHUD.loading()

        Async.waterfall(nil, [self.sheet.retrieve], end: { error, response in
            guard error == nil, let container = response as? JSON, let timesheet = container["model"] as? Sheet else {
                PKHUD.failure()
                self.goBack()
                return
            }
            
            self.sheet = timesheet
            
            Async.waterfall(nil, [self.sheet!.entries.retrieve], end: { error, _ in
                guard error == nil else {
                    PKHUD.failure()
                    self.goBack()
                    return
                }
                
                self.focusedEntry.sheet = self.sheet
                self.focusedEntry.clear()
                
                self.populateOverlays(locations: Locations.shared.items)
                self.populate(sheet: self.sheet)
                self.focusMap(sheet: self.sheet, animated: false, fade: true)
                
                self.reloadTableView()
                self.resetMap()
                self.showMapFocusButtons()
                
                PKHUD.success()
            })
        })
        
        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdated))
        NotificationManager.shared.focues_entry_updated.observe(self, selector: #selector(focusedEntryUpdated))
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationDrawerController?.isEnabled = true
    }
    
    override func setupNavBar() {
        if let date = self.sheet.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE LLLL d, YYYY"
            navBar?.title = formatter.string(from: date)
        } else {
            navBar?.title = "Past Timesheet"
        }
        
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = {
            self.goBack()
        }
        
        navBar?.rightImage = nil
    }
    
    override func goBack() {
        super.goBack()
        
        self.focusedEntry.sheet = nil
        self.focusedEntry.clear()
    }
    
    // MARK: - Other Functions
    
    @objc func focusedEntryUpdated(_: NSNotification) {
        if focusedEntry.isSet() == true {
            showMapFocusButtons()
            
            self.navBar?.leftButton.image = AssetManager.shared.arrowLeft
            self.navBar?.leftEnclosure = nil
            self.navBar?.leftEnclosure = {
                self.resetMap()
            }
            
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
            
            self.reloadTableView()
            
            if self.peopleVisible != true {
                self.peoplePressed()
            }
        } else {
            self.reloadTableView()
        }
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
    
    @objc func resetMap() {
        
        focusedEntry.clear()
        
        hideMapFocusButtons()
        closeFocusedEntryCenterView()
        deselectAllAnnotations()
        closeInfo(self)
        
        focusMap(sheet: sheet)
        unhighlightMap(sheet: sheet)
        tableView.reloadData()
        
        self.navBar?.leftButton.image = AssetManager.shared.arrowLeft
        self.navBar?.leftEnclosure = nil
        self.navBar?.leftEnclosure = {
            self.goBack()
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
    
    func closeFocusedEntryCenterView() {
        arrowViewCenterViewHeightConstraint.constant = 0.0
        UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION, animations: {
            self.view.layoutIfNeeded()
            
            let maxIndex = self.sheet?.entries.count ?? 0
            let indexString = String(format: "%i of %i", arguments: [0, maxIndex])
            self.indexLabel.text = indexString
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
    
    
    fileprivate func resetTabs() {

        tabStatusImage.tintColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        tabStatusLabel.textColor = Theme.shared.active.darkIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        tabStatusDownArrow.tintColor = Theme.shared.active.alternateIconColor.withAlphaComponent(TIMELINE_VIEW_BUTTON_ALPHA)
        tabStatusDownArrow.alpha = 0.0
    }
    
    var maxTableViewHeight: CGFloat {
        let extra: CGFloat = estimatedTableViewHeight - tableView.contentSize.height - peopleViewBottomConstraintOriginal
        let target = max(min(peopleViewHeightConstraint.constant, tableView.contentSize.height), tableView.contentSize.height) + extra
        
        return target
    }
    
    @objc func updatePeopleViewHeight() {
        
        guard peopleVisible == true else {
            return
        }
        
        let target = self.maxTableViewHeight
        
        if peopleViewHeightConstraint.constant != target {
            peopleViewHeightConstraint.constant = target
            
            UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    
    @objc func navTabPressed(_ sender: FlatButton) {
        
        if self.peopleVisible == true {
            self.closeInfoWithBump()
            self.tabStatusDownArrow.alpha = 0.0
        } else {
            self.peoplePressed()
            self.tabStatusDownArrow.alpha = 1.0
        }
    }
    
    
    @objc func peoplePulloutImagePressed(_: UITapGestureRecognizer) {
        peopleViewPulloutImage.touchAnimation()
        
        if peopleVisible == true {
            closeInfo(self)
        } else {
            peoplePressed()
            
            peopleViewPulloutImage.image = AssetManager.shared.pulloutDown
        }
    }
    
    
    @objc func peoplePressed() {
        
        self.peopleVisible = true
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.updatePeopleViewHeight()
            self.peopleView.shadowOpacity = 1.0
            if self.peoplePanGesture?.state == .possible {
                self.peopleViewPulloutImage.image = AssetManager.shared.pulloutDown
            }
        }) { _ in
            self.peopleViewHeightConstraint.constant = self.peopleView.height
            self.tableView.scrollRectToVisible(CGRect(x: 0, y: -DEFAULT_SEARCHBAR_HEADER_HEIGHT, width: 1, height: 1), animated: true)
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
            
            if modifiedTarget < 150.0 {
                sender.isEnabled = false
                
                closeInfoWithBump()
                delay(0.25, closure: { sender.isEnabled = true })
                return
            }
            
            peopleViewHeightConstraint.constant = min(target, self.estimatedTableViewHeight - peopleViewBottomConstraintOriginal)
            
            UIView.animate(withDuration: 0.1, animations: {
                self.view.layoutIfNeeded()
                //self.fab.layoutIfNeeded()
            }, completion: nil)
            
            if target > peopleViewHeightConstraint.constant + 10 || peopleView.height + 10 < peopleViewHeightConstraint.constant {
                sender.isEnabled = false
                Generator.confirm()
                
                UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
                    // self.overlayView.alpha = 0.5
                    self.peopleViewPulloutImage.image = AssetManager.shared.pulloutDown
                }
                
                delay(0.2, closure: { sender.isEnabled = true })
                
            } else {
                UIView.animate(withDuration: DEFAULT_ANIMATION_DURATION) {
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

    @objc func closeInfoWithBump() {
        Generator.bump()
        
        closeInfo(self)
    }
    
    
    @objc func closeInfo(_: Any) {
        
        tableView.refreshControl?.endRefreshing()
        
        if peopleVisible == true {
            peopleVisible = false
            self.peopleView.shadowOpacity = 0.0
            UIView.animate(withDuration: 0.15) {
                self.peopleViewPulloutImage.image = AssetManager.shared.pullout
                self.view.layoutIfNeeded()
            }
        }
        
        statusViewHeightConstraint.constant = statusViewHeightConstraintOriginal
        UIView.animate(withDuration: 0.15, animations: {
            self.view.layoutIfNeeded()

            self.peopleView.shadowOpacity = 0.0
        }, completion: nil)
    }
    
    
    var estimatedTableViewHeight: CGFloat {
        guard let sheet = self.sheet else { return 0 }
        
        if self.focusedEntry.isSet() == true {
            return EntriesHeaderCell.cellHeight
        } else {
            return EntriesHeaderCell.cellHeight + CGFloat(self.focusedEntry.isFocused ? 0 : sheet.entries.count) * EntriesCell.cellHeight + 10
        }
        
    }
    
    
    func initializeNavTab() {
        tabStatusImage.image = tabStatusImage.image?.withRenderingMode(.alwaysTemplate)
        tabStatusDownArrow.image = tabStatusDownArrow.image?.withRenderingMode(.alwaysTemplate)
        
        peopleVisible = false
    }
    
    @objc func modelUpdated(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate else {
            return
        }
        
        if update.model is Entry, let _entry = update.model as? Entry, _entry.sheet?.id == self.sheet?.id {
            
            let index = self.focusedEntry.index ?? 0
            let maxIndex = self.sheet?.entries.count ?? 0
            let indexString = String(format: "%i of %i", arguments: [index, maxIndex])
            self.indexLabel.text = indexString
            
            self.clearMap(all: true)
            self.populateOverlays(locations: Locations.shared.items)
            self.populate(sheet: self.sheet)
            self.focusMap(sheet: self.sheet)
            
            self.reloadTableView()
        }
    }

    
    @objc override func applyTheme() {
        super.applyTheme()
        
        peopleView.backgroundColor = UIColor.clear
        peopleView.shadowOpacity = 0.0
        statusView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        mapFocusButtonsView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        rightButton.styleTimeline(AssetManager.shared.arrowRight)
        leftButton.styleTimeline(AssetManager.shared.arrowLeft)
        
        mapFocusButtonsPulloutImage.tintColor = Theme.shared.active.placeholderColor.withAlphaComponent(0.8)
        
        indexLabel.textColor = Theme.shared.active.primaryFontColor
        
        tabStatusFlatButton.addTarget(self, action: #selector(navTabPressed), for: .touchUpInside)
        tabStatusFlatButton.addTarget(tabStatusView, action: #selector(tabStatusView.touchAnimation), for: .touchUpInside)
        
        peopleViewPulloutImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(peoplePulloutImagePressed)))
        peopleViewPulloutImage.tintColor = Theme.shared.active.placeholderColor.withAlphaComponent(0.8)
        peopleViewPulloutImage.isUserInteractionEnabled = true
        
        peoplePanGesture = UIPanGestureRecognizer(target: self, action: #selector(peoplePanGestureController))
        peopleViewPulloutView.addGestureRecognizer(peoplePanGesture!)
        
        leftButton.addTarget(self, action: #selector(leftButtonPressed), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonPressed), for: .touchUpInside)
        
        mapFocusButtonsPulloutImage.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(mapFocusButtonsPulloutImagePanGestureController)))
        mapFocusButtonsPulloutImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapFocusButtonsPulloutImagePressed)))
        mapFocusButtonsPulloutImage.isUserInteractionEnabled = true
        
        let index = self.focusedEntry.index ?? 0
        let maxIndex = self.sheet?.entries.count ?? 0
        let indexString = String(format: "%i of %i", arguments: [index, maxIndex])
        indexLabel.text = indexString
    }
    
    override func prepareForDeinit() {
        super.prepareForDeinit()
        
        self.clearMap(all: false)
        self.sheet?.entries.clearAnnotations()
        self.sheet?.cleanse()
    }
}


// MARK: - Timeline Table View

typealias HistoryUserTableView = HistoryTimesheetController
extension HistoryUserTableView: UITableViewDelegate, UITableViewDataSource {
    func initializeTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 50.0, 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = true
        
        self.navigationController?.extendedLayoutIncludesOpaqueBars = true
        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(closeInfo), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
        
        EntriesCell.register(tableView)
        EntriesHeaderCell.register(tableView)
    }
    
    @objc func reloadTableView() {
        
        tableView.reloadData()
        updatePeopleViewHeight()
    }
    
    func numberOfSections(in _: UITableView) -> Int {
        return 2
    }
    
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return self.focusedEntry.isFocused ? 0 : sheet?.entries.count ?? 0
        default:
            return 0
        }
    }
    
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return EntriesHeaderCell.cellHeight
        default:
            return EntriesCell.cellHeight
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            
            cell.updates = false
            return cell
        } else {
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            return cell
        }
    }
    
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    }
    
    func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard sheet.user == Auth.shared.id || System.shared.adminAccess else {
            return false
        }
        
        return indexPath.section == 1
    }
    
    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
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
    }
}

