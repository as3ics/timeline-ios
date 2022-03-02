//
//  About.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/6/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Material
import PKHUD
import UIKit
import CoreLocation
import StoreKit

class About: UIViewController, UITableViewDelegate, UITableViewDataSource, ThemeSupportedProtocol {
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
        tableView.delegate = self

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        StandardDismissCell.register(tableView)
        SettingsBasicCell.register(tableView)
        SettingsOrgCodeCell.register(tableView)
        StandardDescriptionCell.register(tableView)

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 9
    }

    /* Zach - This is where you setup the details for each activity entry in a timesheet */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row

        if index == 0 {
            let cell = StandardDismissCell.loadNib(tableView)

            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goBack)))
            cell.isUserInteractionEnabled = true

            cell.selectionStyle = .none
            return cell
        } else if index == 1 {
            let cell = SettingsBasicCell.loadNib(tableView)

            cell.icon.image = UIImage(named: "privacy")
            cell.label.text = NSLocalizedString("SettingsViewController_PrivacyPolicy", comment: "")

            cell.selectionStyle = .none
            return cell
        } else if index == 2 {
            let cell = SettingsBasicCell.loadNib(tableView)
            cell.icon.image = UIImage(named: "terms")
            cell.label.text = NSLocalizedString("SettingsViewController_TermsAndConditions", comment: "")

            cell.selectionStyle = .none
            return cell
        } else if index == 3 {
            let cell = SettingsBasicCell.loadNib(tableView)

            cell.icon.image = UIImage(named: "rating")
            cell.label.text = "Review Us!"

            cell.selectionStyle = .none
            return cell
        } else if index == 4 {
            let cell = SettingsBasicCell.loadNib(tableView)

            cell.icon.image = UIImage(named: "icon-help")
            cell.label.text = "Help"

            cell.selectionStyle = .none
            return cell
        } else if index == 5 {
            let cell = SettingsOrgCodeCell.loadNib(tableView)

            cell.humanIdLabel.text = DeviceUser.shared.user!.registrationCode

            cell.selectionStyle = .none
            return cell
        } else if index == 6 {
            let cell = StandardDescriptionCell.loadNib(tableView)

            cell.content.text = NSLocalizedString("SettingsViewController_OrgIdDescription", comment: "")
            cell.content.backgroundColor = UIColor.clear

            cell.selectionStyle = .none
            return cell
        } else if index == 7 {
            let cell = SettingsOrgCodeCell.loadNib(tableView)
            
            cell.icon.image = AssetManager.shared.feedback
            cell.icon.tintColor = Theme.shared.active.alternateIconColor
            
            cell.titleLabel.text = "Contact:"
            cell.humanIdLabel.text = "developer@timelinefm.com"
            
            cell.selectionStyle = .none
            return cell
        } else if index == 8 {
            let cell = StandardDescriptionCell.loadNib(tableView)
            
            cell.content.text = "At Timeline we are always open to feedback, positive and negative. If you have something to say, new features to request, or are having issues with the application please don't hesitate to reach out to our team."
            cell.content.backgroundColor = UIColor.clear
            
            cell.selectionStyle = .none
            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            External.shared.showPrivacy()
        } else if indexPath.row == 2 {
            External.shared.showTerms()
        } else if indexPath.row == 3 {
            External.shared.requestReview()
        } else if indexPath.row == 4 {
            PKHUD.message(text: "Coming Soon!")
            PKHUD.hide(delay: DEFAULT_PKHUD_TEXT_TIMEOUT)
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 20
        case 8:
            return 90
        default:
            return 60
        }
    }
    
    @objc func applyTheme() {
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
