//
//  Navigator.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/28/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import Material
import PKHUD

protocol SidebarSectionProtocol {
    
    static var section: String { get }
}


final class NavigationSection {
    
    var title: String
    var type: Any.Type
    var index: Int
    var storyboard: UIStoryboard
    var identifier: String
    var icon: String
    var specialLoader: (() -> Void)?

    init(title: String,
         type: Any.Type,
         index: Int,
         storyboard: UIStoryboard,
         identifier: String,
         icon: String,
         specialLoader: (() -> Void)? = nil
    ) {
        self.title = title
        self.type = type
        self.index = index
        self.storyboard = storyboard
        self.identifier = identifier
        self.icon = icon
        self.specialLoader = specialLoader
    }
}

open class Navigator {
    
    static let shared: Navigator = Navigator()
    
    var sections = [NavigationSection]()
    var activeSection: NavigationSection?

    init() {
        var index = 0
        sections.append(NavigationSection(
            title: Main.section,
            type: type(of: Main.self),
            index: index,
            storyboard: UIStoryboard(name: "Main", bundle: Bundle.main),
            identifier: "Main",
            icon: "time-card",
            specialLoader: nil))
        
        /*
        index += 1
        
        sections.append(NavigationSection(
            title: Dashboard.section,
            type: type(of: Dashboard.self),
            index: index,
            storyboard: UIStoryboard(name: "Main", bundle: Bundle.main),
            identifier: "Dashboard",
            icon: "dashboard",
            specialLoader: nil))
        */
        
        index += 1
        
        sections.append(NavigationSection(
            title: Timeline.section,
            type: type(of: Timeline.self),
            index: index,
            storyboard: UIStoryboard(name: "Main", bundle: Bundle.main),
            identifier: "Timeline",
            icon: "map-waypoint",
            specialLoader: nil))
        
        index += 1
        sections.append(NavigationSection(
            title: ViewUsers.section,
            type: type(of: ViewUsers.self),
            index: index,
            storyboard: UIStoryboard(name: "User", bundle: Bundle.main),
            identifier: "ViewUsers",
            icon: "people-filled",
            specialLoader: nil))
        
        index += 1
        sections.append(NavigationSection(
            title: ViewLocations.section,
            type: type(of: ViewLocations.self),
            index: index,
            storyboard: UIStoryboard(name: "Location", bundle: Bundle.main),
            identifier: "ViewLocations",
            icon: "place-marker-filled",
            specialLoader: nil))
        
        index += 1
        sections.append(NavigationSection(
            title: ViewActivities.section,
            type: type(of: ViewActivities.self),
            index: index,
            storyboard: UIStoryboard(name: "Activity", bundle: Bundle.main),
            identifier: "ViewActivities",
            icon: "work-filled",
            specialLoader: nil))
        
        index += 1
        sections.append(NavigationSection(
            title: ViewHistory.section,
            type: type(of: ViewHistory.self),
            index: index,
            storyboard: UIStoryboard(name: "History", bundle: Bundle.main),
            identifier: "ViewHistory",
            icon: "history",
            specialLoader: nil))
        
        index += 1
        sections.append(NavigationSection(
            title: PhotosView.section,
            type: type(of: PhotosView.self),
            index: index,
            storyboard: UIStoryboard(name: "Main", bundle: Bundle.main),
            identifier: "PhotosView",
            icon: "pictures-filled",
            specialLoader: photosSpecialLoader))
        
        /*
        index += 1
        sections.append(NavigationSection(
            title: SchedulerController.section,
            type: type(of: SchedulerController.self),
            index: index,
            storyboard: UIStoryboard(name: "Schedule", bundle: Bundle.main),
            identifier: "SchedulerController",
            icon: "calendar",
            specialLoader: scheduleSpecialLoader))
        */
        
        index += 1
        sections.append(NavigationSection(
            title: ViewChats.section,
            type: type(of: ViewChats.self),
            index: index,
            storyboard: UIStoryboard(name: "Chat", bundle: Bundle.main),
            identifier: "ViewChats",
            icon: "message",
            specialLoader: nil))
        
        index += 1
        sections.append(NavigationSection(
            title: Settings.section,
            type: type(of: Settings.self),
            index: index,
            storyboard: UIStoryboard(name: "Main", bundle: Bundle.main),
            identifier: "Settings",
            icon: "settings-filled",
            specialLoader: nil))
        
        index += 1
        sections.append(NavigationSection(
            title: Login.section,
            type: type(of: Login.self),
            index: index,
            storyboard: UIStoryboard(name: "Main", bundle: Bundle.main),
            identifier: "Login",
            icon: "shutdown",
            specialLoader: logoutSpecialLoader))
    }
    
    func initialize() {
        
    }

    func index(title: String?) -> Int? {
        guard let title = title else {
            return nil
        }

        for section in sections {
            if section.title == title {
                return section.index
            }
        }

        return nil
    }

    func goTo(section: NavigationSection, options: UIWindow.TransitionOptions? = nil) {
        
        activeSection = section
        
        if let specialLoader = section.specialLoader {
            specialLoader()
            return
        }

        let destinationStoryboard = section.storyboard
        let destinationIdentifier = section.identifier
        let destination = destinationStoryboard.instantiateViewController(withIdentifier: destinationIdentifier)

        let navigation = UINavigationController(rootViewController: destination)
        navigation.isNavigationBarHidden = true

        setDestination(destination: navigation, options: options)
    }
    
    func setDestination(destination: UIViewController, options: UIWindow.TransitionOptions? = nil) {
        
        App.shared.cleanseUI()
        
        if let drawer = UIApplication.shared.keyWindow?.rootViewController?.navigationDrawerController {
            let sidebar = drawer.leftViewController as! Sidebar
            
            sidebar.activeIndex = activeSection?.index
            
            let drawer = NavigationDrawerController(rootViewController: destination, leftViewController: sidebar, rightViewController: nil)
            
            UIApplication.shared.keyWindow?.setRootViewController(drawer, options: options ?? UIWindow.TransitionOptions(direction: .toTop, style: .easeInOut))
            
        } else {
            let sidebar = UIStoryboard.Main(identifier: "Sidebar") as! Sidebar
            
            sidebar.activeIndex = activeSection?.index
            
            let drawer = NavigationDrawerController(rootViewController: destination, leftViewController: sidebar, rightViewController: nil)
            
            UIApplication.shared.keyWindow?.setRootViewController(drawer, options: options ?? UIWindow.TransitionOptions(direction: .toTop, style: .easeInOut))
        }
    }
}

extension Navigator {
    
    func photosSpecialLoader() {
        
        let destination = UIStoryboard.Main(identifier: "PhotosView") as! PhotosView
        
        destination.photos = Organization.shared.photos
        destination.title = Organization.shared.name
        
        PKHUD.loading()
        
        Async.waterfall(nil, [Organization.shared.retrievePhotos, Organization.shared.photos.retrieve]) { (_, _) in
            PKHUD.success()
            self.setDestination(destination: destination, options: nil)
        }
    }
    
    func scheduleSpecialLoader() {
        
        let viewControllerOne = UIStoryboard.Schedule(identifier: "SchedulerController")
        viewControllerOne.pageTabBarItem.title = "Schedule"
        viewControllerOne.pageTabBarItem.titleColor = Theme.shared.active.subHeaderFontColor
        viewControllerOne.pageTabBarItem.titleLabel?.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 14.0)
        
        let viewControllerTwo = UIStoryboard.Schedule(identifier: "SchedulerOverrideController")
        viewControllerTwo.pageTabBarItem.title = "Overrides"
        viewControllerTwo.pageTabBarItem.titleColor = Theme.shared.active.subHeaderFontColor
        viewControllerTwo.pageTabBarItem.titleLabel?.font = UIFont(name: DEFAULT_SYSTEM_FONT_NAME, size: 14.0)
        
        let destination = PageTabBarController(viewControllers: [viewControllerOne, viewControllerTwo])
        destination.pageTabBarAlignment = .bottom
        destination.pageTabBar.lineAlignment = .top
        destination.pageTabBar.height = 60
        destination.pageTabBar.lineColor = Theme.shared.active.rootHeaderBackgroundColor
        destination.pageTabBar.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        destination.isBounceEnabled = true
        
        destination.view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        setDestination(destination: destination)
    }
    
    func logoutSpecialLoader() {
        if let index = Navigator.shared.index(title: Login.section) {
            
            Auth.shared.flush()
            let section = Navigator.shared.sections[index]
            
            let destinationStoryboard = section.storyboard
            let destinationIdentifier = section.identifier
            let destination = destinationStoryboard.instantiateViewController(withIdentifier: destinationIdentifier)
            
            let navigation = UINavigationController(rootViewController: destination)
            navigation.isNavigationBarHidden = true
            
            setDestination(destination: navigation, options: nil)
        }
    }
}
