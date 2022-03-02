//
//  SchedulerExecptionController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/26/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Material
import PKHUD
import UIKit
import CoreLocation

// MARK: - ViewActivities

class SchedulerOverrideController: ViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!

    var localDateFormatter = DateFormatter()
    var timeDateFormatter = DateFormatter()
    var smallDateFormatter = DateFormatter()

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.alpha = 0.5
        refreshControl.addTarget(self, action: #selector(reloadTableView), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        localDateFormatter.dateFormat = "LLL d, yyyy"
        timeDateFormatter.dateFormat = "h:mm a"
        smallDateFormatter.dateFormat = "LLL d"


        OverrideCell.register(tableView)

        Notifications.shared.model_updated.observe(self, selector: #selector(modelUpdatedNotification))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Overrides.shared.sort()
        tableView.reloadData()
    }
    
    override func setupNavBar() {
        navBar?.title = "Overrides"
        
        navBar?.leftImage = AssetManager.shared.menu
        navBar?.leftEnclosure = { self.menuPressed() }
        
        navBar?.rightImage = AssetManager.shared.plus
        navBar?.rightEnclosure = { self.goAddOverrideView() }
    }

    // MARK: - UITableView Delegate and DataSource

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = Overrides.shared.count

        if section > count {
            return 0
        } else {
            return 1
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        let count: Int = Overrides.shared.count
        return count + 1
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let count = Overrides.shared.count

        if count == 0 {
            return 200
        } else if indexPath.section < count {
            return 60
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let count = Overrides.shared.count
        if count == 0 {
            let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
            let cell = views![0] as! EmptyCell

            let tap = UITapGestureRecognizer(target: self, action: #selector(goAddOverrideView))
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
            cell.backgroundColor = UIColor.clear

            cell.selectionStyle = .none
            return cell
        } else if indexPath.section < count {
            let override = Overrides.shared.items[indexPath.section]

            let cell = OverrideCell.loadNib(tableView)

            cell.numberLabel.text = "\(indexPath.section + 1)"
            cell.titleLabel.text = override.title

            if override.doNotTrack == false {
                cell.typeLabel.text = "Modification"
                cell.typeLabel.textColor = Color.green.base
                cell.upperDateLabel.text = localDateFormatter.string(from: override.start!)

                let timeSpanString = String(format: "%@ - %@", arguments: [self.timeDateFormatter.string(from: override.start!), self.timeDateFormatter.string(from: override.end!)])
                cell.lowerDateLabel.text = timeSpanString
            } else {
                cell.typeLabel.text = "Time Off"
                cell.typeLabel.textColor = Color.red.base

                if override.multiDay == false {
                    cell.upperDateLabel.text = "Single Day"

                    cell.lowerDateLabel.text = localDateFormatter.string(from: override.start!)
                } else {
                    cell.upperDateLabel.text = "Multi Day"

                    let timeSpanString = String(format: "%@ - %@", arguments: [self.smallDateFormatter.string(from: override.start!), self.localDateFormatter.string(from: override.end!)])

                    cell.lowerDateLabel.text = timeSpanString
                }
            }
            
            cell.selectionStyle = .none
            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if Overrides.shared.count != 0 {
            return true
        } else {
            return false
        }
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { _, _ in

            Generator.bump()

            PKHUD.loading()

            Overrides.shared.items[indexPath.section].delete({ success in
                guard success == true else {
                    PKHUD.failure()
                    return
                }

                PKHUD.success()
            })
        })

        let editRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit", handler: { _, _ in

            Generator.bump()

            let destination = UIStoryboard.Schedule(identifier: "ScheduleViewOverrideController") as! ScheduleViewOverrideController

            destination.override = Overrides.shared.items[indexPath.section]

            Presenter.push(destination, animated: true, completion: nil)
        })

        editRowAction.backgroundColor = UIColor.gray
        deleteRowAction.backgroundColor = UIColor.red

        return [editRowAction, deleteRowAction]
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let count = Overrides.shared.count
        if indexPath.section < count {
            Generator.bump()

            let destination = UIStoryboard.Schedule(identifier: "ScheduleViewOverrideController") as! ScheduleViewOverrideController

            destination.override = Overrides.shared.items[indexPath.section]

            Presenter.push(destination, animated: true, completion: nil)
        }
    }

    // MARK: - Model Updater
    
    @objc func modelUpdatedNotification(_ notification: NSNotification) {
        guard let data = notification.userInfo, let update = data["update"] as? ModelUpdate else {
            return
        }
        
        if let _ = update.model as? Override {
            Overrides.shared.sort()
            tableView.reloadData()
        }
    }

    // MARK: - Other Functions
    
    @objc func reloadTableView() {
        tableView.refreshControl?.endRefreshing()
        Overrides.shared.sort()
        tableView.reloadData()
    }
    
    @objc func goAddOverrideView() {
        
        let destination = UIStoryboard.Schedule(identifier: "ScheduleAddOverrideController") as! ScheduleAddOverrideController
        
        Presenter.push(destination, animated: true, completion: nil)
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.tableHeaderView?.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }
}
