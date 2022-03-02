//
//  CreateActivityViewController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 11/7/17.
//  Copyright © 2017 Timeline Software, LLC. All rights reserved.
//

import PKHUD
import UIKit
import CoreLocation

// MARK: - ViewActivity

class ViewActivity: ViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    override var usesIQKeyboard: Bool {
        return true
    }

    var index: Int?
    var activity: Activity?

    var name: String = ""
    var notes: String = ""
    
    enum InputFieldTags: Int {
        case name = 1
        case notes = 2
    }
    
    // MARK: - UIViewController Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        hideKeyboardWhenTappedAround()

        StandardTextFieldCell.register(tableView)
        StandardHeaderCell.register(tableView)
        StandardTextViewCell.register(tableView)

        if mode != ViewingMode.Creating && index == nil {
            goBack()
        } else if let index = self.index, let activity = Activities.shared[index] {
            name = activity.name ?? ""
            notes = activity.notes ?? ""
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }
    
    override func setupNavBar() {
        navBar?.leftImage = AssetManager.shared.arrowLeft
        navBar?.leftEnclosure = { self.goBack() }
        
        setNavItems()
    }
    
    override func goBack() {
        if mode == ViewingMode.Editing {
            mode = ViewingMode.Viewing
            setNavItems()
            tableView.refreshControl?.endRefreshing()
            tableView.reloadData()
            return
        } else {
            tableView.refreshControl?.endRefreshing()
            super.goBack()
        }
    }

    func setNavItems() {
        if mode == ViewingMode.Editing {
            navBar?.title = "Edit Actitity"
        } else if mode == ViewingMode.Creating {
            navBar?.title = "Create Activity"
        } else if mode == ViewingMode.Viewing {
            navBar?.title = "View Activity"
        }

        if mode != ViewingMode.Creating {
            if Activities.shared[self.index!]?.restricted == false {
                if mode == ViewingMode.Editing {
                    navBar?.rightImage = AssetManager.shared.save
                    navBar?.rightEnclosure = {
                        self.save()
                    }
                } else if mode == ViewingMode.Viewing {
                    
                    if System.shared.adminAccess == true {
                        navBar?.rightImage = AssetManager.shared.edit
                        navBar?.rightEnclosure = { self.edit() }
                    } else {
                        navBar?.rightImage = nil
                    }
                }
            } else {
                navBar?.rightImage = nil
            }
        } else if mode == ViewingMode.Creating {
            navBar?.rightImage = AssetManager.shared.add
            navBar?.rightEnclosure = {
                self.create()
            }
        }

        applyTheme()
    }
    
    // MARK: - UITableView Delegate and DataSource
    
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 2
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 70
        } else if indexPath.section == 1 && indexPath.row == 1 {
            return 350
        } else {
            return 60
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Activity Name"

                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextFieldCell.loadNib(tableView)

                cell.label.text = "Activity"
                cell.contents.text = name
                cell.placeholder = "Enter Name"

                if mode == ViewingMode.Viewing {
                    cell.carrot.alpha = 0.0
                    cell.contents.textColor = Theme.shared.active.primaryFontColor
                    cell.contents.isEnabled = false
                } else {
                    cell.carrot.alpha = 1.0
                    cell.contents.isEnabled = true
                }

                cell.contents.tag = InputFieldTags.name.rawValue
                cell.contents.delegate = self

                cell.selectionStyle = .none
                return cell
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = StandardHeaderCell.loadNib(tableView)

                cell.footer.text = ""
                cell.title.text = "Activity Notes"

                cell.selectionStyle = .none

                return cell
            } else if indexPath.row == 1 {
                let cell = StandardTextViewCell.loadNib(tableView)

                cell.contents.text = notes

                if mode == ViewingMode.Viewing {
                    cell.contents.isEditable = false
                } else {
                    cell.contents.isEditable = true
                }

                cell.contents.tag = InputFieldTags.notes.rawValue
                cell.contents.delegate = self

                cell.selectionStyle = .none
                return cell
            }
        }

        return UITableViewCell()
    }
    
    // MARK: - UIText Delegate

    func textFieldDidEndEditing(_ textField: UITextField, reason _: UITextFieldDidEndEditingReason) {
        if textField.tag == InputFieldTags.name.rawValue {
            name = textField.text ?? ""
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.tag == InputFieldTags.notes.rawValue {
            notes = textView.text
        }
    }
    
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    // MARK: - Other Functions

    @objc func edit() {

        mode = ViewingMode.Editing
        setNavItems()
        tableView.reloadData()
    }

    @objc func create() {
        view.endEditing(true)

        guard name != "" else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Please enter name")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT)
            return
        }

        PKHUD.loading()

        if activity == nil {
            activity = Activity()
        }

        activity?.name = name
        activity?.notes = notes

        activity?.create({ success in

            guard success == true else {
                PKHUD.failure()
                return
            }

            PKHUD.success()
            
            if let navigationController = self.navigationController {
                navigationController.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }

    @objc func save() {
        view.endEditing(true)

        guard name != "" else {
            PKHUD.sharedHUD.contentView = PKHUDTextView(text: "Please enter name")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: DEFAULT_PKHUD_TEXT_TIMEOUT)
            return
        }

        guard let index = self.index, let activity = Activities.shared[index] else {
            return
        }

        PKHUD.loading()

        activity.name = name
        activity.notes = notes

        activity.update({ success in
            guard success == true else {
                PKHUD.failure()
                return
            }

            PKHUD.success()
            
            if let navigationController = self.navigationController {
                navigationController.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        tableView.backgroundColor = Theme.shared.active.subHeaderBackgroundColor
        
        if self.mode != ViewingMode.Viewing {
            navBar?.rightButton.tintColor = UIColor.red
        }
    }
}
