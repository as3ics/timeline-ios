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
    var arrowLeft: UIImage?
    var arrowRight: UIImage?
    var avatar: UIImage?
    var breakIcon: UIImage?
    var breakShortcut: UIImage?
    var building: UIImage?
    var calendar: UIImage?
    var call: UIImage?
    var cancel: UIImage?
    var car: UIImage?
    var camera: UIImage?
    var cancelCircle: UIImage?
    var cancelSquare: UIImage?
    var centerMap: UIImage?
    var centerMapFilled: UIImage?
    var centerMapOriented: UIImage?
    var clear: UIImage?
    var clock: UIImage?
    var compose: UIImage?
    var composeMessage: UIImage?
    var database: UIImage?
    var date: UIImage?
    var deleteDatabase: UIImage?
    var deleteTrash: UIImage?
    var directions: UIImage?
    var done: UIImage?
    var edit: UIImage?
    var end: UIImage?
    var favorited: UIImage?
    var feedback: UIImage?
    var googleMaps: UIImage?
    var gpsFair: UIImage?
    var gpsPoor: UIImage?
    var gpsNone: UIImage?
    var gpsGood: UIImage?
    var iconAuto: UIImage?
    var iconCrumbs: UIImage?
    var iconEdited: UIImage?
    var iconPhotos: UIImage?
    var iconUnpaid: UIImage?
    var info: UIImage?
    var iPhone: UIImage?
    var language: UIImage?
    var launchLogo: UIImage?
    var locate: UIImage?
    var locationGlobe: UIImage?
    var lock: UIImage?
    var mapSpan: UIImage?
    var menu: UIImage?
    var message: UIImage?
    var onboarding: UIImage?
    var password: UIImage?
    var photo: UIImage?
    var photos: UIImage?
    var plus: UIImage?
    var profile: UIImage?
    var pullout: UIImage?
    var pulloutDown: UIImage?
    var save: UIImage?
    var settings: UIImage?
    var settingsFilled: UIImage?
    var shield: UIImage?
    var start: UIImage?
    var submit: UIImage?
    var timesheet: UIImage?
    var timesheetGlyph: UIImage?
    var touchId: UIImage?
    var track: UIImage?
    var unfavorited: UIImage?
    var unlock: UIImage?
    var uploadCloud: UIImage?
    
    func initialize() {
        self.activity = UIImage(named: "work-filled")?.withRenderingMode(.alwaysTemplate)
        self.activityGlyph = UIImage(named: "work-filled-glyph")?.withRenderingMode(.alwaysTemplate)
        self.add = UIImage(named: "add")?.withRenderingMode(.alwaysTemplate)
        self.annotation = UIImage(named: "ndp-icon")?.withRenderingMode(.alwaysTemplate)
        self.appleMaps = UIImage(named: "apple-maps-filled")?.withRenderingMode(.alwaysTemplate)
        self.arrowLeft = UIImage(named: "arrow-left")?.withRenderingMode(.alwaysTemplate)
        self.arrowRight = UIImage(named: "arrow-right")?.withRenderingMode(.alwaysTemplate)
        self.avatar = UIImage(named: "avatar")
        self.breakIcon = UIImage(named: "icon-break")
        self.breakShortcut = UIImage(named: "break")
        self.building = UIImage(named: "bulding")?.withRenderingMode(.alwaysTemplate)
        self.calendar = UIImage(named: "calendar")
        self.call = UIImage(named: "phone-blue")?.withRenderingMode(.alwaysTemplate)
        self.camera = UIImage(named: "camera")
        self.cancel = UIImage(named: "cancel")?.withRenderingMode(.alwaysTemplate)
        self.cancelCircle = UIImage(named: "cancel-circle")?.withRenderingMode(.alwaysTemplate)
        self.cancelSquare = UIImage(named: "cancel-square")?.withRenderingMode(.alwaysTemplate)
        self.car = UIImage(named: "car")
        self.centerMap = UIImage(named: "location")?.withRenderingMode(.alwaysTemplate)
        self.centerMapFilled = UIImage(named: "location-filled")?.withRenderingMode(.alwaysTemplate)
        self.centerMapOriented = UIImage(named: "location-oriented")?.withRenderingMode(.alwaysTemplate)
        self.clear = UIImage(named: "clear")
        self.clock = UIImage(named: "clock-filled")?.withRenderingMode(.alwaysTemplate)
        self.compose = UIImage(named: "compose")?.withRenderingMode(.alwaysTemplate)
        self.composeMessage = UIImage(named: "compose-message")?.withRenderingMode(.alwaysTemplate)
        self.database = UIImage(named: "database")?.withRenderingMode(.alwaysTemplate)
        self.date = UIImage(named: "date")
        self.deleteDatabase = UIImage(named: "delete-database")?.withRenderingMode(.alwaysTemplate)
        self.deleteTrash = UIImage(named: "delete-trash")?.withRenderingMode(.alwaysTemplate)
        self.directions = UIImage(named: "directions")?.withRenderingMode(.alwaysTemplate)
        self.done = UIImage(named: "done")?.withRenderingMode(.alwaysTemplate)
        self.edit = UIImage(named: "edit")?.withRenderingMode(.alwaysTemplate)
        self.end = UIImage(named: "finish")?.withRenderingMode(.alwaysTemplate)
        self.favorited = UIImage(named: "bookmark-filled")?.withRenderingMode(.alwaysTemplate)
        self.feedback = UIImage(named: "feedback")?.withRenderingMode(.alwaysTemplate)
        self.gpsPoor = UIImage(named: "gps-poor")
        self.gpsFair = UIImage(named: "gps-fair")
        self.gpsNone = UIImage(named: "gps-none")
        self.gpsGood = UIImage(named: "gps-good")
        self.googleMaps = UIImage(named: "google-maps-filled")?.withRenderingMode(.alwaysTemplate)
        self.iconAuto = UIImage(named: "icon-auto")
        self.iconCrumbs = UIImage(named: "icon-crumbs")
        self.iconEdited = UIImage(named: "icon-edited")
        self.iconPhotos = UIImage(named: "icon-photos")
        self.iconUnpaid = UIImage(named: "icon-unpaid")
        self.info = UIImage(named: "info")?.withRenderingMode(.alwaysTemplate)
        self.iPhone = UIImage(named: "iPhone")?.withRenderingMode(.alwaysTemplate)
        self.language = UIImage(named: "language")?.withRenderingMode(.alwaysTemplate)
        self.launchLogo = UIImage(named: "launch-logo")
        self.locate = UIImage(named: "place-marker-filled")?.withRenderingMode(.alwaysTemplate)
        self.locationGlobe = UIImage(named: "location-globe")?.withRenderingMode(.alwaysTemplate)
        self.lock = UIImage(named: "lock")?.withRenderingMode(.alwaysTemplate)
        self.mapSpan = UIImage(named: "map-span")?.withRenderingMode(.alwaysTemplate)
        self.message = UIImage(named: "message")?.withRenderingMode(.alwaysTemplate)
        self.menu = UIImage(named: "menu")?.withRenderingMode(.alwaysTemplate)
        self.onboarding = UIImage(named: "onboarding")?.withRenderingMode(.alwaysTemplate)
        self.password = UIImage(named: "password")?.withRenderingMode(.alwaysTemplate)
        self.photo = UIImage(named: "photo")?.withRenderingMode(.alwaysTemplate)
        self.photos = UIImage(named: "photos")?.withRenderingMode(.alwaysTemplate)
        self.plus = UIImage(named: "plus")?.withRenderingMode(.alwaysTemplate)
        self.profile = UIImage(named: "profile")?.withRenderingMode(.alwaysTemplate)
        self.pullout = UIImage(named: "pullout")?.withRenderingMode(.alwaysTemplate)
        self.pulloutDown = UIImage(named: "pullout-down")?.withRenderingMode(.alwaysTemplate)
        self.save = UIImage(named: "save")?.withRenderingMode(.alwaysTemplate)
        self.settings = UIImage(named: "settings")?.withRenderingMode(.alwaysTemplate)
        self.settingsFilled = UIImage(named: "settings-filled")?.withRenderingMode(.alwaysTemplate)
        self.shield = UIImage(named: "shield")?.withRenderingMode(.alwaysTemplate)
        self.start = UIImage(named: "start")?.withRenderingMode(.alwaysTemplate)
        self.submit = UIImage(named: "submit")
        self.timesheet = UIImage(named: "timesheet")
        self.timesheetGlyph = UIImage(named: "timesheet-glyph")?.withRenderingMode(.alwaysTemplate)
        self.touchId = UIImage(named: "touch-id")?.withRenderingMode(.alwaysTemplate)
        self.track = UIImage(named: "track-blue")?.withRenderingMode(.alwaysTemplate)
        self.unfavorited = UIImage(named: "bookmark")?.withRenderingMode(.alwaysTemplate)
        self.unlock = UIImage(named: "unlock")?.withRenderingMode(.alwaysTemplate)
        self.uploadCloud = UIImage(named: "upload-cloud")?.withRenderingMode(.alwaysTemplate)
    }
}
