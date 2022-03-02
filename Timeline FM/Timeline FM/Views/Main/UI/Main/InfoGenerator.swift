//
//  InfoGenerator.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/18/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import Material
import PKHUD
import ActionSheetPicker_3_0

enum MainSectionStyle: Int {
    case Default = -1
    case User = 1
    case Location = 2
    case Entry = 3
    case Schedule = 4
    case Sheet = 5
}

struct MainInfo {
    
    var label: String?
    var value: (() -> String?)?
    var updates: Bool = false
    var section: Bool = false
    
    init(label: String?, value: (()-> String?)?, updates: Bool = false, section: Bool = false) {
        self.label = label
        self.value = value
        self.updates = updates
        self.section = section
    }
}

struct MainAction {
    
    var icon: UIImage?
    var label: String?
    var button: String?
    var color: UIColor?
    var action: Enclosure?
    var subtitle: String?
    
    init(icon: UIImage?, label: String?, button: String?, color: UIColor?, subtitle: String?, action: Enclosure?) {
        self.icon = icon
        self.label = label
        self.button = button
        self.color = color
        self.subtitle = subtitle
        self.action = action
    }
}

class InfoGenerator {
    
    class var titles: [String] {
        return ["Info", "Actions"]
    }
    
    class func getInfo(section: MainSectionStyle) -> JSON {
        
        switch section {
            /*
        case .User:
        case .Location:
        case .Activity:
        case .Schedule:
        case Users:
        case .Organization:
        */
        case .Sheet:
            return generateSheetInfo()
        case .Entry:
            return generateEntryInfo()
        case .User:
            return generateUserInfo()
        case .Location:
            return generateLocationInfo()
        default:
            return [:]
        }
    }
    
    private class func generateEntryInfo() -> JSON {
        
        var sections = [[MainInfo]]()
        var actions = [MainAction]()
        
        let entry = DeviceUser.shared.sheet?.entries.latest
        
        if entry != nil {
            
            var section1 = [MainInfo]()
            
            // SECTION 1
            section1.append(MainInfo(label: "Entry Info", value: nil, updates: false, section: true))
            section1.append(MainInfo(label: "Activity", value: { () -> String? in
                return entry?.activity?.name
            }))
            section1.append(MainInfo(label: "Duration", value: { () -> String? in
                let seconds = DeviceUser.shared.sheet?.duration(index: 0) ?? 0
                return String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
            }, updates: true))
            
            if let date = entry?.start {
                section1.append(MainInfo(label: "Start", value: { () -> String? in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "LLL d, h:mm:ss a"
                    return String(format: "%@", formatter.string(from: date))
                }))
            }
            
            if entry?.activity?.traveling == true {
                section1.append(MainInfo(label: "Distance", value: { () -> String? in
                    if let distance = DeviceUser.shared.sheet?.entries.latest?.meters {
                        return String(format: "%0.1f mi", distance * CONVERSION_METERS_TO_MILES_MULTIPLIER)
                    } else {
                        return nil
                    }
                }, updates: true))
            } else {
                section1.append(MainInfo(label: "Paid", value: { () -> String? in
                    if DeviceUser.shared.sheet?.entries.latest?.paidTime == true {
                        return "Paid"
                    } else {
                        return "Unpaid"
                    }
                }, updates: false))
            }
            
            sections.append(section1)
            
            actions.append(MainAction(icon: AssetManager.shared.historyGlyph, label: "View Entry", button: "View", color: Theme.shared.active.alternateIconColor, subtitle: "Review Entry", action: {
                
                let destination = UIStoryboard.Main(identifier: "EntryReview") as? EntryReview
                
                destination?.sheet = DeviceUser.shared.sheet
                destination?.index = 0
                destination?.entry = DeviceUser.shared.sheet?.entries.latest
                destination?.mode = ViewingMode.Viewing
                
                Presenter.push(destination!, animated: true, completion: nil)
            }))
            
            actions.append(MainAction(icon: AssetManager.shared.cameraGlyph, label: "View Photos", button: "View", color: Theme.shared.active.alternateIconColor, subtitle: "View Entry Photos", action: {
                
                DeviceUser.shared.sheet?.entries.latest?.photos.view()
            }))
            
            actions.append(MainAction(icon: AssetManager.shared.editIconGlyph, label: "Edit Entry", button: "Edit", color: Color.green.darken3, subtitle: "Update Entry", action: {
                
                let destination = UIStoryboard.Main(identifier: "EntryEdit") as? EntryEdit
                
                destination?.sheet = DeviceUser.shared.sheet
                destination?.index = 0
                destination?.mode = ViewingMode.Editing
                
                Presenter.push(destination!, animated: true, completion: nil)
            }))
            
            actions.append(MainAction(icon: AssetManager.shared.deleteTrashGlyph, label: "Delete Entry", button: "Go", color: Color.red.darken3, subtitle: "Caution! This is not reversable", action: {
                
                guard let entry = entry else {
                    return
                }
                
                PKHUD.loading()
                
                Async.waterfall(nil, [entry.delete], end: { (error, _) in
                    guard error == nil else {
                        PKHUD.failure()
                        return
                    }
                    
                    PKHUD.success()
                })
            }))
        }
        
        var json = JSON()
        
        json["Sections"] = sections as JSONObject
        json["Actions"] = actions as JSONObject
        
        return json
        
    }
    
    class func generateInfo(location: Location?) -> JSON {
        
        guard let location = location else {
            return EMPTY_JSON
        }
        
        var section = [MainInfo]()
        
        //section.append(MainInfo(label: "Info", value: nil, updates: false, section: true))
        
        section.append(MainInfo(label: location.address!, value: nil))
        
        section.append(MainInfo(label: location.addressStringZip!, value: nil))
        
        let people = location.presentUsers()
        
        section.append(MainInfo(label: "People", value: { () -> String? in
            return String(format: "%i", people.count )
        }, updates: true))
        
        section.append(MainInfo(label: "Photos", value: { () -> String? in
            return String(format: "%i", location.photos.items.count )
        }, updates: true))
        
        if people.count > 0 {
            
            section.append(MainInfo(label: "People", value: nil, updates: false, section: true))
            
            for person in people {
                section.append(MainInfo(label: person.fullName, value: { () -> String? in
                    return person.userRole.rawValue.lowercased()
                }))
            }
        }
        
        var json = JSON()
        
        json["section"] = section as JSONObject
        
        return json
    }
    
    private class func generateLocationInfo() -> JSON {
        
        var sections = [[MainInfo]]()
        var actions = [MainAction]()
        
        if let location = Locations.shared[DeviceUser.shared.sheet?.entries.latest?.location?.id] {
            
            DispatchQueue.main.async {
                Async.waterfall(nil, [location.retrievePhotos], end: { _, _ in })
            }
            
            // SECTION 1
            var section1 = [MainInfo]()
            
            section1.append(MainInfo(label: "Location Info", value: nil, updates: false, section: true))
            section1.append(MainInfo(label: "Address 1", value: { () -> String? in
                return location.address
            }))
            section1.append(MainInfo(label: "Address 2", value: { () -> String? in
                return location.addressStringZip
            }))
            section1.append(MainInfo(label: "Photos", value: { () -> String? in
                return String(format: "%i", location.photos.items.count )
            }, updates: true))
            section1.append(MainInfo(label: "Zones", value: { () -> String? in
                return String(format: "%i", location.zones.count )
            }, updates: true))
            
            sections.append(section1)
            /*
            // SECTION 2
            var section2 = [MainInfo]()
            
            section2.append(MainInfo(label: "Slot Info", value: nil, updates: false, section: true))
            section2.append(MainInfo(label: "Available", value: { () -> String? in
                return String(format: "%i",  4)
            }))
            section2.append(MainInfo(label: "Filled", value: { () -> String? in
                return String(format: "%i", 3)
            }))
            section2.append(MainInfo(label: "Empty", value: { () -> String? in
                return String(format: "%i", 1)
            }))
            section2.append(MainInfo(label: "Next Scheduled", value: { () -> String? in
                return "1 Day (4)"
            }))
            
            sections.append(section2)
            */
            
            actions.append(MainAction(icon: AssetManager.shared.buildingGlyph, label: "View Location", button: "View", color: Theme.shared.active.alternateIconColor, subtitle: "Review Location", action: {
                
                location.view()
            }))
            
            actions.append(MainAction(icon: AssetManager.shared.cameraGlyph, label: "View Photos", button: "View", color: Theme.shared.active.alternateIconColor, subtitle: "View Location Photos", action: {
                
                location.photos.view()
            }))
            
            actions.append(MainAction(icon: DeviceSettings.shared.mapProgram == .apple ? AssetManager.shared.appleMapsGlyph : AssetManager.shared.googleMapsGlyph, label: "Get Directions", button: "Get", color: Color.lime.darken3, subtitle: DeviceSettings.shared.mapProgram == .apple ? "Apple Maps" : "Google Maps", action: {
                if DeviceSettings.shared.mapProgram == .apple {
                    location.coordinate?.appleMaps(name: location.name)
                } else {
                    location.coordinate?.googleMaps()
                }
            }))
            
            actions.append(MainAction(icon: AssetManager.shared.editIconGlyph, label: "Edit Location", button: "Edit", color: Color.green.darken3, subtitle: "Update Location", action: {
                
                location.edit()
            }))
            
            actions.append(MainAction(icon: AssetManager.shared.geoFenceGlyph, label: "Edit Boundary", button: "Edit", color: Color.green.darken3, subtitle: "Update Location Boundary", action: {
                
                let destination = UIStoryboard.Location(identifier: "CreateBoundary") as! CreateBoundary
                
                destination.location = nil
                destination.updateId = location.id
                destination.mode = .Editing
                
                Presenter.push(destination, animated: true, completion: nil)
            }))
            
            
            actions.append(MainAction(icon: AssetManager.shared.zoneGlyph, label: "Create Zone", button: "Add", color: Color.blue.darken3, subtitle: "Add New Zone to Location",  action: {
                
                let destination = UIStoryboard.Location(identifier: "LocationAddZone") as! LocationAddZone
                destination.location = location
                
                Presenter.push(destination)
            }))
            
        } else if let placemark = LocationManager.shared.latestPlacemark {
            
            var number: String = ""
            if let subThoroughfare = placemark.subThoroughfare {
                number = String(format: "%@ ", subThoroughfare)
            }
            
            let addr1 = String(format: "%@%@", number, placemark.thoroughfare ?? "")
            let addr2 = String(format: "%@, %@ %@", placemark.locality ?? "", placemark.administrativeArea ?? "", placemark.postalCode ?? "")
            
            // SECTION 1
            var section1 = [MainInfo]()
            
            section1.append(MainInfo(label: "Location Info", value: nil, updates: false, section: true))
            section1.append(MainInfo(label: "Address 1", value: { () -> String? in
                return addr1
            }, updates: true))
            section1.append(MainInfo(label: "Address 2", value: { () -> String? in
                return addr2
            }, updates: true))
            
            if let closest = Locations.shared.closest(placemark.location) {
            
                section1.append(MainInfo(label: "Closest Location", value: { () -> String? in
                    return closest.name
                }))
                
                if let location = closest.location, let here = LocationManager.shared.currentLocation {
                    section1.append(MainInfo(label: "Distance", value: { () -> String? in
                        return String(format: "%0.1f mi", here.distance(from: location) * CONVERSION_METERS_TO_MILES_MULTIPLIER)
                    }, updates: true))
                }
            }
            
            sections.append(section1)
        }
        
        
        actions.append(MainAction(icon: AssetManager.shared.userLocationFilledGlyph, label: "Create Location", button: "Add", color: Color.blue.darken3, subtitle: "Add New Location", action: {
            
            let location: Location = Location()
            location.create()
        }))
        
        var json = JSON()
        
        json["Sections"] = sections as JSONObject
        json["Actions"] = actions as JSONObject
        
        return json
    }
    
    private class func generateSheetInfo() -> JSON {
        
        var sections = [[MainInfo]]()
        var actions = [MainAction]()
        
        if let sheet = DeviceUser.shared.sheet {
            
            // SECTION 1
            var section1 = [MainInfo]()
            
            section1.append(MainInfo(label: "Shift Info", value: nil, updates: false, section: true))
            
            if let date = sheet.date {
                section1.append(MainInfo(label: "Start", value: { () -> String? in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "LLL d, h:mm:ss a"
                    return String(format: "%@", formatter.string(from: date))
                }))
            }
            section1.append(MainInfo(label: "Paid Time", value: { () -> String? in
                let seconds = sheet.paidSeconds
                return String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
            }, updates: true))
            section1.append(MainInfo(label: "Break Time", value: { () -> String? in
                let seconds = sheet.unpaidSeconds
                return String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
            }, updates: true))
            section1.append(MainInfo(label: "Miles", value: { () -> String? in
                return String(format: "%0.1f", sheet.distance * CONVERSION_METERS_TO_MILES_MULTIPLIER)
            }, updates: true))
            
            sections.append(section1)
            
            // SECTION 2
            var section2 = [MainInfo]()
            
            section2.append(MainInfo(label: "Additional Info", value: nil, updates: false, section: true))
            
            section2.append(MainInfo(label: "Entries", value: { () -> String? in
                return String(format: "%i", sheet.entries.count)
            }))
            section2.append(MainInfo(label: "Breaks", value: { () -> String? in
                
                let matches = sheet.entries.items.filter({ (entry) -> Bool in
                    return entry.activity?.name ?? "" == "Break"
                })
                return String(format: "%i", matches.count)
            }))
            section2.append(MainInfo(label: "Photos", value: { () -> String? in
                
                var count: Int = 0
                for entry in sheet.entries.items {
                    count += entry.photos.count
                }
                
                return String(format: "%i", count)
            }, updates: true))
            section2.append(MainInfo(label: "Total Time", value: { () -> String? in
                let seconds = sheet.totalSeconds
                return String(format: "%.0fh %0.fm %.0fs", arguments: [clockHours(seconds), clockMinutes(seconds), clockSeconds(seconds)])
            }, updates: true))
            
            sections.append(section2)
            
            actions.append(MainAction(icon: AssetManager.shared.mapWaypointGlyph, label: "View on Map", button: "View", color: Theme.shared.active.alternateIconColor, subtitle: "Review Timesheet", action: {
                
                let sections = Navigator.shared.sections.filter({ (section) -> Bool in
                    return section.title == Timeline.section
                })
                
                if sections.count == 1 {
                    Navigator.shared.goTo(section: sections[0])
                }
            }))
            
            actions.append(MainAction(icon: AssetManager.shared.submitGlyph, label: "Submit Timesheet", button: "Go", color: Color.orange.darken3, subtitle: "Complete Timesheet", action: {
                
                guard let sheet = DeviceUser.shared.sheet else {
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
                    
                    let matches = Main.sections.filter({ (section) -> Bool in
                        return section.style == MainSectionStyle.Sheet
                    })
                    
                    if let section = matches.first {
                        
                        let picker = ActionSheetDatePicker(title: NSLocalizedString("TimelineViewController_SelectTimesheetEndTime", comment: ""), datePickerMode: UIDatePickerMode.dateAndTime, selectedDate: maximum, minimumDate: minimum, maximumDate: maximum, target: InfoGenerator.self, action: #selector(InfoGenerator.commitTimesheet(_:)), cancelAction: nil, origin: section)
                        
                        picker?.maximumDate = maximum
                        picker?.minimumDate = minimum
                        
                        UIViewController().styleActionSheetDatePicker(picker)
                        
                        picker?.show()
                    }
                    
                    
                }
            }))
        }
        
        
        var json = JSON()
        
        json["Sections"] = sections as JSONObject
        json["Actions"] = actions as JSONObject
        
        return json
    }
    
    private class func generateUserInfo() -> JSON {
        
        var sections = [[MainInfo]]()
        var actions = [MainAction]()
        
        // SECTION 1
        var section1 = [MainInfo]()
        section1.append(MainInfo(label: "User Info", value: nil, updates: false, section: true))
        section1.append(MainInfo(label: "Name", value: { () -> String? in
            return DeviceUser.shared.user?.fullName
        }))
        section1.append(MainInfo(label: "Phone", value: { () -> String? in
            return DeviceUser.shared.user?.readablePhoneNumber
        }))
        section1.append(MainInfo(label: "Role", value: { () -> String? in
            return DeviceUser.shared.user?.userRole.rawValue
        }))
        section1.append(MainInfo(label: "Photos", value: { () -> String? in
            return String(format: "%i", DeviceUser.shared.user?.photos.items.count ?? 0)
        }))
        
        sections.append(section1)
        
        // SECTION 2
        var section2 = [MainInfo]()
        
        section2.append(MainInfo(label: "Lifetime Stats", value: nil, updates: false, section: true))
        section2.append(MainInfo(label: "Shifts", value: { () -> String? in
            return String(format: "%i", DeviceUser.shared.user?.statistics?.shifts ?? 0)
        }))
        section2.append(MainInfo(label: "Hours", value: { () -> String? in
            return String(format: "%0.1f hours", DeviceUser.shared.user?.statistics?.hours ?? 0 )
        }))
        section2.append(MainInfo(label: "Miles", value: { () -> String? in
            return String(format: "%0.1f mi", (DeviceUser.shared.user?.statistics?.distance ?? 0) * CONVERSION_METERS_TO_MILES_MULTIPLIER)
        }))
        
        // TODO: Add in weight
        /*
        section2.append(MainInfo(label: "Weight", value: { () -> String? in
            return String(format: "%i", 0)
        }))
        */
        
        sections.append(section2)
        
        
        actions.append(MainAction(icon: AssetManager.shared.profileGlyph, label: "View Profile", button: "View", color: Theme.shared.active.alternateIconColor, subtitle: "Review Your Profile", action: {
            
            DeviceUser.shared.user?.view()
        }))
        
        actions.append(MainAction(icon: AssetManager.shared.cameraGlyph, label: "View Photos", button: "View", color: Theme.shared.active.alternateIconColor, subtitle: "View Your Photos", action: {
            
            DeviceUser.shared.user?.photos.view()
        }))
        
        actions.append(MainAction(icon: DeviceUser.shared.user?.profilePicture, label: "Update Picture", button: "Edit", color: Theme.shared.active.placeholderColor, subtitle: "Update Profile Picture", action: {
            
            PKHUD.loading()
            
            guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                PKHUD.failure()
                return
            }
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = UIApplication.shared.keyWindow?.visibleViewController as? UIImagePickerControllerDelegate as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            
            Presenter.present(imagePicker, animated: true, completion: {
                PKHUD.success()
            })
        }))
        
        // TODO: Add in schedules again
        /*
        actions.append(MainAction(icon: AssetManager.shared.calendarGlyph, label: "Update Schedule", button: "Edit", color: Theme.shared.active.placeholderColor, subtitle: "Automate Timesheets",  action: {
            
            let sections = Navigator.shared.sections.filter({ (section) -> Bool in
                return section.title == SchedulerController.section
            })
            
            if sections.count == 1 {
               Navigator.shared.goTo(section: sections[0])
            }
        }))
        */
        
        actions.append(MainAction(icon: AssetManager.shared.contactFilledGlyph, label: "Create User", button: "Add", color: Color.blue.darken3, subtitle: "Add New User to Org", action: {
            
            let user: User = User()
            user.create()
        }))
        
        var json = JSON()
        
        json["Sections"] = sections as JSONObject
        json["Actions"] = actions as JSONObject
        
        return json
    }
    
    
    @objc static func commitTimesheet(_ date: Date) {
        let userInfo: [AnyHashable: Any] = ["end": date as Any]
        
        NotificationManager.shared.submit_timesheet.post(userInfo)
    }
    
}


