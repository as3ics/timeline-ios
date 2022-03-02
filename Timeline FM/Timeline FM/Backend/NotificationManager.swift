//
//  Notifications.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import UIKit

class NotificationManager {
    
    static let shared = NotificationManager()

    let gps_sensitivity_updated = Notification.Name(rawValue: "gps_sensitivity_updated_notification")
    fileprivate let gps_sensitivity_updated_notification: Notification

    let new_current_location = Notification.Name(rawValue: "new_current_location_notification")
    fileprivate let new_current_location_notification: Notification

    let new_latest_location = Notification.Name(rawValue: "new_latest_location_notification")
    fileprivate let new_latest_location_notification: Notification

    let new_latest_placemark = Notification.Name(rawValue: "new_latest_placemark_notification")
    fileprivate let new_latest_placemark_notification: Notification

    let new_breadcrumb = Notification.Name(rawValue: "new_breadcrumb_notification")
    fileprivate let new_breadcrumb_notification: Notification

    let create_entry = Notification.Name(rawValue: "create_entry_notification")
    fileprivate let create_entry_notification: Notification

    let create_traveling_entry = Notification.Name(rawValue: "create_traveling_entry_notification")
    fileprivate let create_traveling_entry_notification: Notification

    let create_break_entry = Notification.Name(rawValue: "create_break_entry_notification")
    fileprivate let create_break_entry_notification: Notification

    let come_off_break = Notification.Name(rawValue: "come_off_break_notification")
    fileprivate let come_off_break_notification: Notification

    let create_timesheet = Notification.Name(rawValue: "create_timesheet_notification")
    fileprivate let create_timesheet_notification: Notification

    let submit_timesheet = Notification.Name(rawValue: "submit_timesheet_notification")
    fileprivate let submit_timesheet_notification: Notification

    let location_manager_debouncing = Notification.Name(rawValue: "location_manager_debouncing_notification")
    fileprivate let location_manager_debouncing_notification: Notification

    let focues_entry_updated = Notification.Name(rawValue: "focues_entry_updated_notification")
    fileprivate let focues_entry_updated_notification: Notification

    let new_api_diagnostic = Notification.Name(rawValue: "new_api_diagnostic_notification")
    fileprivate let new_api_diagnostic_notification: Notification

    let should_open_diagnostics = Notification.Name(rawValue: "should_open_diagnostics_notification")
    fileprivate let should_open_diagnostics_notification: Notification

    let chat_photo_selected = Notification.Name(rawValue: "chat_photo_selected_notification")
    fileprivate let chat_photo_selected_notification: Notification

    let chat_item_status_update = Notification.Name(rawValue: "chat_item_status_update_notification")
    fileprivate let chat_item_status_update_notification: Notification

    let chat_new_message = Notification.Name(rawValue: "chat_new_message_notification")
    fileprivate let chat_new_message_notification: Notification
    
    let chat_users_reloaded = Notification.Name(rawValue: "chat_users_reloaded_notification")
    fileprivate let chat_users_reloaded_notification: Notification
    
    let user_avatar_retrieved = Notification.Name(rawValue: "user_avatar_retrieved_notification")
    fileprivate let user_avatar_retrieved_notification: Notification

    let location_snapshot_retrieved = Notification.Name(rawValue: "location_snapshot_retrieved_notification")
    fileprivate let location_snapshot_retrieved_notification: Notification
    
    let user_subscription_updated = Notification.Name(rawValue: "user_subscription_updated_notification")
    fileprivate let user_subscription_updated_notification: Notification
    
    let messages_retrieved = Notification.Name(rawValue: "messages_retrieved_notification")
    fileprivate let messages_retrieved_notification: Notification
    
    let user_stream_updated = Notification.Name(rawValue: "user_stream_updated_notification")
    fileprivate let user_stream_updated_notification: Notification
    
    let map_view_region_changed = Notification.Name(rawValue: "map_view_region_changed")
    fileprivate let map_view_region_changed_notification: Notification
    
    let map_focus_location = Notification.Name(rawValue: "map_focus_location_notification")
    fileprivate let map_focus_location_notification: Notification
    
    let notifications_registered = Notification.Name(rawValue: "notifications_registered_notification")
    fileprivate let notifications_registered_notification: Notification
    
    let location_zone_selected = Notification.Name(rawValue: "location_zone_selected_notification")
    fileprivate let location_zone_selected_notification: Notification
    
    init() {
        
        map_focus_location_notification = Notification(name: map_focus_location)
        user_avatar_retrieved_notification = Notification(name: user_avatar_retrieved)
        gps_sensitivity_updated_notification = Notification(name: gps_sensitivity_updated)
        new_current_location_notification = Notification(name: new_current_location)
        new_latest_location_notification = Notification(name: new_latest_location)
        new_latest_placemark_notification = Notification(name: new_latest_placemark)
        new_breadcrumb_notification = Notification(name: new_breadcrumb)
        create_entry_notification = Notification(name: create_entry)
        create_traveling_entry_notification = Notification(name: create_traveling_entry)
        create_break_entry_notification = Notification(name: create_break_entry)
        come_off_break_notification = Notification(name: come_off_break)
        create_timesheet_notification = Notification(name: create_timesheet)
        submit_timesheet_notification = Notification(name: submit_timesheet)
        location_manager_debouncing_notification = Notification(name: location_manager_debouncing)
        focues_entry_updated_notification = Notification(name: focues_entry_updated)
        new_api_diagnostic_notification = Notification(name: new_api_diagnostic)
        should_open_diagnostics_notification = Notification(name: should_open_diagnostics)
        chat_photo_selected_notification = Notification(name: chat_photo_selected)
        chat_item_status_update_notification = Notification(name: chat_item_status_update)
        chat_new_message_notification = Notification(name: chat_new_message)
        user_subscription_updated_notification = Notification(name: user_subscription_updated)
        messages_retrieved_notification = Notification(name: messages_retrieved)
        location_snapshot_retrieved_notification = Notification(name: location_snapshot_retrieved)
        user_stream_updated_notification = Notification(name: user_stream_updated)
        chat_users_reloaded_notification = Notification(name: chat_users_reloaded)
        map_view_region_changed_notification = Notification(name: map_view_region_changed)
        notifications_registered_notification = Notification(name: notifications_registered)
        location_zone_selected_notification = Notification(name: location_zone_selected)
        
        chat_new_message.observe(self, selector: #selector(updateBadge))
    }


    @objc func alertAutoTravelEntryMade() {
        Notifications.shared.scheduleNotification(title: NSLocalizedString("LocationUpdate_TravelingEntryAlert_Title", comment: ""), body: NSLocalizedString("LocationUpdate_TravelingEntryAlert_Body", comment: ""), identifier: "AutoTravelEntryCreated")
    }

    @objc func alertAutoEntryMade() {
        Notifications.shared.scheduleNotification(title: NSLocalizedString("LocationUpdate_NewEntryAlert_Title", comment: ""), body: NSLocalizedString("LocationUpdate_NewEntryAlert_Body", comment: ""), identifier: "AutoEntryCreated")
    }
    
    @objc func updateBadge(_ notification: NSNotification) {
        Notifications.shared.updateBadge()
    }
}

