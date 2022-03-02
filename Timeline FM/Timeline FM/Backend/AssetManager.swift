//
//  AssetManager.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/16/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation

class AssetManager {
    
    static var shared: AssetManager = AssetManager()
    
    var activity: UIImage?
    var activityGlyph: UIImage?
    var add: UIImage?
    var annotation: UIImage?
    var appleMaps: UIImage?
    var appleMapsGlyph: UIImage?
    var arrowLeft: UIImage?
    var arrowRight: UIImage?
    var avatar: UIImage?
    var breakIcon: UIImage?
    var breakShortcut: UIImage?
    var building: UIImage?
    var buildingGlyph: UIImage?
    var cafeGlyph: UIImage?
    var calendar: UIImage?
    var calendarGlyph: UIImage?
    var call: UIImage?
    var cancel: UIImage?
    var car: UIImage?
    var carGlyph: UIImage?
    var camera: UIImage?
    var cameraGlyph: UIImage?
    var cancelCircle: UIImage?
    var cancelSquare: UIImage?
    var centerMap: UIImage?
    var centerMapFilled: UIImage?
    var centerMapOriented: UIImage?
    var clear: UIImage?
    var clock: UIImage?
    var coin: UIImage?
    var commuting: UIImage?
    var companyGlyph: UIImage?
    var compose: UIImage?
    var composeMessage: UIImage?
    var contactFilledGlyph: UIImage?
    var dashboard: UIImage?
    var database: UIImage?
    var date: UIImage?
    var dayOff: UIImage?
    var delete: UIImage?
    var deleteDatabase: UIImage?
    var deleteTrash: UIImage?
    var deleteTrashGlyph: UIImage?
    var directions: UIImage?
    var done: UIImage?
    var download: UIImage?
    var edit: UIImage?
    var editIcon: UIImage?
    var editIconGlyph: UIImage?
    var emptyTimesheet: UIImage?
    var end: UIImage?
    var favorited: UIImage?
    var feedback: UIImage?
    var filter: UIImage?
    var geoFence: UIImage?
    var geoFenceGlyph: UIImage?
    var googleMaps: UIImage?
    var googleMapsGlyph: UIImage?
    var gpsFair: UIImage?
    var gpsPoor: UIImage?
    var gpsNone: UIImage?
    var gpsGood: UIImage?
    var history: UIImage?
    var historyGlyph: UIImage?
    var iconAuto: UIImage?
    var iconBreadcrumbs: UIImage?
    var iconEdited: UIImage?
    var iconPhotos: UIImage?
    var iconUnpaid: UIImage?
    var indicator: UIImage?
    var info: UIImage?
    var iPhone: UIImage?
    var language: UIImage?
    var launchLogo: UIImage?
    var locate: UIImage?
    var locationGlobe: UIImage?
    var locationGlyph: UIImage?
    var lock: UIImage?
    var mapSpan: UIImage?
    var mapWaypointGlyph: UIImage?
    var menu: UIImage?
    var message: UIImage?
    var noGpsGlyph: UIImage?
    var noTimesheet: UIImage?
    var ok: UIImage?
    var onboarding: UIImage?
    var password: UIImage?
    var photo: UIImage?
    var photos: UIImage?
    var photoStack: UIImage?
    var pictures: UIImage?
    var picturesFilled: UIImage?
    var place: UIImage?
    var plus: UIImage?
    var profile: UIImage?
    var profileGlyph: UIImage?
    var pullout: UIImage?
    var pulloutDown: UIImage?
    var reorder: UIImage?
    var save: UIImage?
    var scheduleClock: UIImage?
    var scheduleGlyph: UIImage?
    var search: UIImage?
    var select: UIImage?
    var settings: UIImage?
    var settingsFilled: UIImage?
    var shield: UIImage?
    var sms: UIImage?
    var start: UIImage?
    var steeringWheel: UIImage?
    var submit: UIImage?
    var submitGlyph: UIImage?
    var swipeLeft: UIImage?
    var swipeRight: UIImage?
    var thumbsUp: UIImage?
    var timeCard: UIImage?
    var timer: UIImage?
    var timesheet: UIImage?
    var timesheetGlyph: UIImage?
    var touchId: UIImage?
    var track: UIImage?
    var unfavorited: UIImage?
    var unlock: UIImage?
    var uploadCloud: UIImage?
    var userPhoto: UIImage?
    var userLocation: UIImage?
    var userLocationFilled: UIImage?
    var userLocationFilledGlyph: UIImage?
    var weightBonus: UIImage?
    var workersGlyph: UIImage?
    var zone: UIImage?
    var zoneGlyph: UIImage?
    
    func initialize() {
        
        Assets.shared.initialize()
        
        self.activity = UIImage(named: "work-filled")?.withRenderingMode(.alwaysTemplate)
        self.activityGlyph = UIImage(named: "work-filled-glyph")?.withRenderingMode(.alwaysTemplate)
        self.add = UIImage(named: "add")?.withRenderingMode(.alwaysTemplate)
        self.annotation = UIImage(named: "ndp-icon")?.withRenderingMode(.alwaysTemplate)
        self.appleMaps = UIImage(named: "apple-maps-filled")?.withRenderingMode(.alwaysTemplate)
        self.appleMapsGlyph = UIImage(named: "apple-maps-filled-glyph")?.withRenderingMode(.alwaysTemplate)
        self.arrowLeft = UIImage(named: "arrow-left")?.withRenderingMode(.alwaysTemplate)
        self.arrowRight = UIImage(named: "arrow-right")?.withRenderingMode(.alwaysTemplate)
        self.avatar = UIImage(named: "avatar")
        self.breakIcon = UIImage(named: "icon-break")
        self.breakShortcut = UIImage(named: "break")
        self.building = UIImage(named: "bulding")?.withRenderingMode(.alwaysTemplate)
        self.buildingGlyph = UIImage(named: "building-glyph")?.withRenderingMode(.alwaysTemplate)
        self.cafeGlyph = UIImage(named: "cafe-glyph")?.withRenderingMode(.alwaysTemplate)
        self.calendar = UIImage(named: "calendar")
        self.calendarGlyph = UIImage(named: "calendar-glyph")?.withRenderingMode(.alwaysTemplate)
        self.call = UIImage(named: "phone-blue")?.withRenderingMode(.alwaysTemplate)
        self.camera = UIImage(named: "camera")
        self.cameraGlyph = UIImage(named: "camera-glyph")?.withRenderingMode(.alwaysTemplate)
        self.cancel = UIImage(named: "cancel")?.withRenderingMode(.alwaysTemplate)
        self.cancelCircle = UIImage(named: "cancel-circle")?.withRenderingMode(.alwaysTemplate)
        self.cancelSquare = UIImage(named: "cancel-square")?.withRenderingMode(.alwaysTemplate)
        self.car = UIImage(named: "car")
        self.carGlyph = UIImage(named: "car-glyph")?.withRenderingMode(.alwaysTemplate)
        self.centerMap = UIImage(named: "location")?.withRenderingMode(.alwaysTemplate)
        self.centerMapFilled = UIImage(named: "location-filled")?.withRenderingMode(.alwaysTemplate)
        self.centerMapOriented = UIImage(named: "location-oriented")?.withRenderingMode(.alwaysTemplate)
        self.clock = UIImage(named: "clock-filled")?.withRenderingMode(.alwaysTemplate)
        self.coin = UIImage(named: "coin")?.withRenderingMode(.alwaysTemplate)
        self.commuting = UIImage(named: "commuting")
        self.companyGlyph = UIImage(named: "company")?.withRenderingMode(.alwaysTemplate)
        self.compose = UIImage(named: "compose")?.withRenderingMode(.alwaysTemplate)
        self.composeMessage = UIImage(named: "compose-message")?.withRenderingMode(.alwaysTemplate)
        self.contactFilledGlyph = UIImage(named: "contact-filled-glyph")?.withRenderingMode(.alwaysTemplate)
        self.dashboard = UIImage(named: "dashboard")?.withRenderingMode(.alwaysTemplate)
        self.database = UIImage(named: "database")?.withRenderingMode(.alwaysTemplate)
        self.date = UIImage(named: "date")
        self.dayOff = UIImage(named: "day-off-glyph")?.withRenderingMode(.alwaysTemplate)
        self.delete = UIImage(named: "Delete")
        self.deleteDatabase = UIImage(named: "delete-database")?.withRenderingMode(.alwaysTemplate)
        self.deleteTrash = UIImage(named: "delete-trash")?.withRenderingMode(.alwaysTemplate)
        self.deleteTrashGlyph = UIImage(named: "delete-trash-glyph")?.withRenderingMode(.alwaysTemplate)
        self.directions = UIImage(named: "directions")?.withRenderingMode(.alwaysTemplate)
        self.done = UIImage(named: "done")?.withRenderingMode(.alwaysTemplate)
        self.download = UIImage(named: "download")?.withRenderingMode(.alwaysTemplate)
        self.edit = UIImage(named: "edit")?.withRenderingMode(.alwaysTemplate)
        self.editIcon = UIImage(named: "edit-icon")?.withRenderingMode(.alwaysTemplate)
        self.editIconGlyph = UIImage(named: "edit-icon-glyph")?.withRenderingMode(.alwaysTemplate)
        self.emptyTimesheet = UIImage(named: "empty-timesheet")?.withRenderingMode(.alwaysTemplate)
        self.end = UIImage(named: "finish")?.withRenderingMode(.alwaysTemplate)
        self.favorited = UIImage(named: "bookmark-filled")?.withRenderingMode(.alwaysTemplate)
        self.feedback = UIImage(named: "feedback")?.withRenderingMode(.alwaysTemplate)
        self.filter = UIImage(named: "filter")?.withRenderingMode(.alwaysTemplate)
        self.geoFence = UIImage(named: "geo-fence")?.withRenderingMode(.alwaysTemplate)
        self.geoFenceGlyph = UIImage(named: "geo-fence-glyph")?.withRenderingMode(.alwaysTemplate)
        self.gpsPoor = UIImage(named: "gps-poor")
        self.gpsFair = UIImage(named: "gps-fair")
        self.gpsNone = UIImage(named: "gps-none")
        self.gpsGood = UIImage(named: "gps-good")
        self.googleMaps = UIImage(named: "google-maps-filled")?.withRenderingMode(.alwaysTemplate)
        self.googleMapsGlyph = UIImage(named: "google-maps-filled-glyph")?.withRenderingMode(.alwaysTemplate)
        self.history = UIImage(named: "history")?.withRenderingMode(.alwaysTemplate)
        self.historyGlyph = UIImage(named: "history-glyph")?.withRenderingMode(.alwaysTemplate)
        self.iconAuto = UIImage(named: "icon-auto")
        self.iconBreadcrumbs = UIImage(named: "icon-breadcrumbs")
        self.iconEdited = UIImage(named: "icon-edited")
        self.iconPhotos = UIImage(named: "icon-photos")
        self.iconUnpaid = UIImage(named: "icon-unpaid")
        self.indicator = UIImage(named: "indicator")
        self.info = UIImage(named: "info")?.withRenderingMode(.alwaysTemplate)
        self.iPhone = UIImage(named: "iPhone")?.withRenderingMode(.alwaysTemplate)
        self.language = UIImage(named: "language")?.withRenderingMode(.alwaysTemplate)
        self.launchLogo = UIImage(named: "launch-logo")
        self.locate = UIImage(named: "place-marker-filled")?.withRenderingMode(.alwaysTemplate)
        self.locationGlobe = UIImage(named: "location-globe")?.withRenderingMode(.alwaysTemplate)
        self.locationGlyph = UIImage(named: "location-glyph")?.withRenderingMode(.alwaysTemplate)
        self.lock = UIImage(named: "lock")?.withRenderingMode(.alwaysTemplate)
        self.mapSpan = UIImage(named: "map-span")?.withRenderingMode(.alwaysTemplate)
        self.mapWaypointGlyph = UIImage(named: "map-waypoint-glyph")?.withRenderingMode(.alwaysTemplate)
        self.message = UIImage(named: "message")?.withRenderingMode(.alwaysTemplate)
        self.menu = UIImage(named: "menu")?.withRenderingMode(.alwaysTemplate)
        self.noGpsGlyph = UIImage(named: "no-gps-glyph")?.withRenderingMode(.alwaysTemplate)
        self.noTimesheet = UIImage(named: "no-timesheet")?.withRenderingMode(.alwaysTemplate)
        self.ok = UIImage(named: "ok")
        self.onboarding = UIImage(named: "onboarding")?.withRenderingMode(.alwaysTemplate)
        self.password = UIImage(named: "password")?.withRenderingMode(.alwaysTemplate)
        self.photo = UIImage(named: "photo")?.withRenderingMode(.alwaysTemplate)
        self.photos = UIImage(named: "photos")?.withRenderingMode(.alwaysTemplate)
        self.photoStack = UIImage(named: "photo-stack")?.withRenderingMode(.alwaysTemplate)
        self.pictures = UIImage(named: "pictures")?.withRenderingMode(.alwaysTemplate)
        self.picturesFilled = UIImage(named: "pictures-filled")?.withRenderingMode(.alwaysTemplate)
        self.place = UIImage(named: "place")?.withRenderingMode(.alwaysTemplate)
        self.plus = UIImage(named: "plus")?.withRenderingMode(.alwaysTemplate)
        self.profile = UIImage(named: "profile")?.withRenderingMode(.alwaysTemplate)
        self.profileGlyph = UIImage(named: "profile-glyph")?.withRenderingMode(.alwaysTemplate)
        self.pullout = UIImage(named: "pullout")?.withRenderingMode(.alwaysTemplate)
        self.pulloutDown = UIImage(named: "pullout-down")?.withRenderingMode(.alwaysTemplate)
        self.reorder = UIImage(named: "reorder")?.withRenderingMode(.alwaysTemplate)
        self.save = UIImage(named: "save")?.withRenderingMode(.alwaysTemplate)
        self.scheduleClock = UIImage(named: "schedule-clock")?.withRenderingMode(.alwaysTemplate)
        self.scheduleGlyph = UIImage(named: "schedule-glyph")?.withRenderingMode(.alwaysTemplate)
        self.search = UIImage(named: "search")?.withRenderingMode(.alwaysTemplate)
        self.select = UIImage(named: "Select")
        self.settings = UIImage(named: "settings")?.withRenderingMode(.alwaysTemplate)
        self.settingsFilled = UIImage(named: "settings-filled")?.withRenderingMode(.alwaysTemplate)
        self.shield = UIImage(named: "shield")?.withRenderingMode(.alwaysTemplate)
        self.sms = UIImage(named: "sms")?.withRenderingMode(.alwaysTemplate)
        self.start = UIImage(named: "start")?.withRenderingMode(.alwaysTemplate)
        self.steeringWheel = UIImage(named: "steering-wheel")?.withRenderingMode(.alwaysTemplate)
        self.submit = UIImage(named: "submit")
        self.submitGlyph = UIImage(named: "submit-glyph")?.withRenderingMode(.alwaysTemplate)
        self.swipeLeft = UIImage(named: "swipe-left")?.withRenderingMode(.alwaysTemplate)
        self.swipeRight = UIImage(named: "swipe-right")?.withRenderingMode(.alwaysTemplate)
        self.thumbsUp = UIImage(named: "thumbs-up")?.withRenderingMode(.alwaysTemplate)
        self.timeCard = UIImage(named: "time-card")?.withRenderingMode(.alwaysTemplate)
        self.timer = UIImage(named: "timer")
        self.timesheet = UIImage(named: "timesheet")
        self.timesheetGlyph = UIImage(named: "timesheet-glyph")?.withRenderingMode(.alwaysTemplate)
        self.touchId = UIImage(named: "touch-id")?.withRenderingMode(.alwaysTemplate)
        self.track = UIImage(named: "track-blue")?.withRenderingMode(.alwaysTemplate)
        self.unfavorited = UIImage(named: "bookmark")?.withRenderingMode(.alwaysTemplate)
        self.unlock = UIImage(named: "unlock")?.withRenderingMode(.alwaysTemplate)
        self.uploadCloud = UIImage(named: "upload-cloud")?.withRenderingMode(.alwaysTemplate)
        self.userPhoto = UIImage(named: "user-photo")?.withRenderingMode(.alwaysTemplate)
        self.userLocation = UIImage(named: "user-location")?.withRenderingMode(.alwaysTemplate)
        self.userLocationFilled = UIImage(named: "user-location-filled")?.withRenderingMode(.alwaysTemplate)
        self.userLocationFilledGlyph = UIImage(named: "user-location-filled-glyph")?.withRenderingMode(.alwaysTemplate)
        self.weightBonus = UIImage(named: "weight-bonus")?.withRenderingMode(.alwaysTemplate)
        self.workersGlyph = UIImage(named: "workers-glyph")?.withRenderingMode(.alwaysTemplate)
        self.zone = UIImage(named: "zone")?.withRenderingMode(.alwaysTemplate)
        self.zoneGlyph = UIImage(named: "zone-glyph")?.withRenderingMode(.alwaysTemplate)
        
    }
}
