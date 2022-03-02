//
//  Fab.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/13/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import Floaty
import Material

extension Floaty {
    func clear(shortcuts: Bool = true) {
        for item in self.items {
            self.removeItem(item: item)
        }
        
        if shortcuts {
            UIApplication.shared.shortcutItems?.removeAll()
        }
    }
}

extension FloatyItem {
    
    static func travelItem(target: Any?, action: Selector?, addShortcut: Bool = false) -> FloatyItem {
        let item = FloatyItem()
        item.icon = AssetManager.shared.car
        item.iconTintColor = Color.blue.darken3
        item.title = "Travel"
        item.addGestureRecognizer(UITapGestureRecognizer(target: item, action: #selector(item.touchAnimation)))
        item.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
        
        if addShortcut == true {
            let createTravelShortcut = UIMutableApplicationShortcutItem(type: ShortcutIdentifier.Travel.rawValue, localizedTitle: "Travel", localizedSubtitle: "Create traveling entry", icon: UIApplicationShortcutIcon(type: .location), userInfo: EMPTY_JSON)
            UIApplication.shared.shortcutItems?.append(createTravelShortcut)
        }
        
        return item
    }
    
    static func breakItem(target: Any?, action: Selector?, addShortcut: Bool = false) -> FloatyItem {
        let item = FloatyItem()
        item.title = NSLocalizedString("TimelineViewController_FAB_StartBreak", comment: "")
        item.icon = AssetManager.shared.breakShortcut
        item.iconTintColor = Color.deepOrange.darken3
        item.addGestureRecognizer(UITapGestureRecognizer(target: item, action: #selector(item.touchAnimation)))
        item.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
    
        if addShortcut == true {
            let createBreakShortcut = UIMutableApplicationShortcutItem(type: ShortcutIdentifier.Break.rawValue, localizedTitle: "Start Break", localizedSubtitle: "Go on break", icon: UIApplicationShortcutIcon(type: .time), userInfo: EMPTY_JSON)
            UIApplication.shared.shortcutItems?.append(createBreakShortcut)
        }
    
        return item
    }
    
    static func submitItem(target: Any?, action: Selector?, addShortcut: Bool = false) -> FloatyItem {
        let item = FloatyItem()
        item.title = NSLocalizedString("TimelineViewController_FAB_SubmitTimesheet", comment: "")
        item.icon = AssetManager.shared.timeCard
        item.iconTintColor = UIColor.black
        item.addGestureRecognizer(UITapGestureRecognizer(target: item, action: #selector(item.touchAnimation)))
        item.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
    
        if addShortcut == true {
            let submitTimesheetShortcut = UIMutableApplicationShortcutItem(type: ShortcutIdentifier.SubmitTimeSheet.rawValue, localizedTitle: "Submit Timesheet", localizedSubtitle: "Submit your current timesheet", icon: UIApplicationShortcutIcon(type: .date), userInfo: EMPTY_JSON)
            UIApplication.shared.shortcutItems?.append(submitTimesheetShortcut)
        }
    
        return item
    }
    
    static func deleteItem(target: Any?, action: Selector?, addShortcut: Bool = false) -> FloatyItem {
        let item = FloatyItem()
        item.title = "Cancel Timesheet"
        item.icon = AssetManager.shared.deleteTrash
        item.iconTintColor = UIColor.black
        item.addGestureRecognizer(UITapGestureRecognizer(target: item, action: #selector(item.touchAnimation)))
        item.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
        
        if addShortcut == true {
            let submitTimesheetShortcut = UIMutableApplicationShortcutItem(type: ShortcutIdentifier.SubmitTimeSheet.rawValue, localizedTitle: "Cancel Timesheet", localizedSubtitle: "Cancel current timesheet", icon: UIApplicationShortcutIcon(type: .prohibit), userInfo: EMPTY_JSON)
            UIApplication.shared.shortcutItems?.append(submitTimesheetShortcut)
        }
        
        return item
    }
    
    static func entryItem(target: Any?, action: Selector?, addShortcut: Bool = false) -> FloatyItem {
        let item = FloatyItem()
        item.title = NSLocalizedString("TimelineViewController_FAB_AddEntry", comment: "")
        item.icon = AssetManager.shared.date
        item.iconTintColor = Color.green.darken3
        item.addGestureRecognizer(UITapGestureRecognizer(target: item, action: #selector(item.touchAnimation)))
        item.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
    
        if addShortcut == true {
            let createTimeEntryShortcut = UIMutableApplicationShortcutItem(type: ShortcutIdentifier.AddEntry.rawValue, localizedTitle: "Add Entry", localizedSubtitle: "Create a new entry", icon: UIApplicationShortcutIcon(type: .markLocation), userInfo: EMPTY_JSON)
            UIApplication.shared.shortcutItems?.append(createTimeEntryShortcut)
        }
    
        return item
    }
    
    static func timesheetItem(target: Any?, action: Selector?, addShortcut: Bool = false) -> FloatyItem {
        let item = FloatyItem()
        item.title = NSLocalizedString("TimelineViewController_FAB_CreateTimesheet", comment: "")
        item.icon = AssetManager.shared.timeCard
        item.iconTintColor = UIColor.black
        item.addGestureRecognizer(UITapGestureRecognizer(target: item, action: #selector(item.touchAnimation)))
        item.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
    
        if addShortcut == true {
            let createTimeSheetShortcut = UIMutableApplicationShortcutItem(type: ShortcutIdentifier.CreateTimeSheet.rawValue, localizedTitle: "Create Timesheet", localizedSubtitle: "Start a new timesheet", icon: UIApplicationShortcutIcon(type: .date), userInfo: EMPTY_JSON)
            UIApplication.shared.shortcutItems?.append(createTimeSheetShortcut)
        }
    
        return item
    }
    
    static func endBreakItem(target: Any?, action: Selector?, addShortcut: Bool = false) -> FloatyItem {
        let item = FloatyItem()
        item.title = NSLocalizedString("TimelineViewController_FAB_EndBreak", comment: "")
        item.icon = AssetManager.shared.breakShortcut
        item.iconTintColor = Color.deepOrange.darken3
        item.addGestureRecognizer(UITapGestureRecognizer(target: item, action: #selector(item.touchAnimation)))
        item.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
        
        if addShortcut == true {
            let createEndBreakShortcut = UIMutableApplicationShortcutItem(type: ShortcutIdentifier.EndBreak.rawValue, localizedTitle: "End Break", localizedSubtitle: "Come off break", icon: UIApplicationShortcutIcon(type: .time), userInfo: EMPTY_JSON)
            UIApplication.shared.shortcutItems?.append(createEndBreakShortcut)
        }
        
        return item
    }
    
    static func downloadTimesheet(target: Any?, action: Selector?) -> FloatyItem {
        let item = FloatyItem()
        item.title = "Load Timesheet"
        item.icon = AssetManager.shared.download
        item.iconTintColor = Color.blue.base
        item.addGestureRecognizer(UITapGestureRecognizer(target: item, action: #selector(item.touchAnimation)))
        item.addGestureRecognizer(UITapGestureRecognizer(target: target, action: action))
        
        return item
    }
}
