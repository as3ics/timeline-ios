//
//  ChatInfo.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 6/5/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Material
import NYTPhotoViewer
import UIKit
import CoreLocation

// MARK: - ChatInfo

class ChatInfo: ViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!

    var chatroom: Chatroom?
    var selectedSegment: Int = 0

    var photoViewerCoordinator: PhotoViewerCoordinator?
    var nytPhotos = [NYTPhotoBox]()

    // MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none

        let refreshControl = UIRefreshControl()
        refreshControl.alpha = 0.0
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.addTarget(self, action: #selector(goBack), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl

        StandardTextFieldCell.register(tableView)
        StandardHeaderCell.register(tableView)
        SettingsSwitchCell.register(tableView)
        ChatInfoPhotoCell.register(tableView)
        ChatInfoUserCell.register(tableView)
        ChatInfoSegmentCell.register(tableView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func setupNavBar() {
        navBar?.title = "Details"
        
        navBar?.rightImage = AssetManager.shared.done
        navBar?.rightEnclosure = { self.goBack() }
        
        navBar?.leftImage = nil
    }
    
    // MARK: - UITableView Delegate and DataSource

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return chatroom!.chatUsers.count + 1
        case 1:
            return 2 //3
        case 2:
            switch selectedSegment {
            case 0:
                 return max(Int(ceil(Double(chatroom?.photos.items.count ?? 0) / 2.0)), 1)
            default:
                return 1
            }
        default:
            return 0
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                return 40
            default:
                return 60
            }
        case 1:
            return 45
        case 2:
            return 200
        default:
            return 0
        }
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = nil
                cell.title.text = "Users"
                
                cell.selectionStyle = .none
                
                return cell
            default:
                let cell = ChatInfoUserCell.loadNib(tableView)
                
                cell.populate(chatroom?.chatUsers[indexPath.row - 1]?.user)
                
                cell.tag = indexPath.row - 1
                cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goViewUserProfile)))
                
                cell.selectionStyle = .none
                return cell
            }
        case 1:
            switch indexPath.row {
            case 0:
                let cell = StandardHeaderCell.loadNib(tableView)
                
                cell.footer.text = nil
                cell.title.text = "Content"
                
                cell.selectionStyle = .none
                
                return cell
            case 100:
                let cell = SettingsSwitchCell.loadNib(tableView)
                
                cell.icon.image = UIImage(named: "alert-blue")
                cell.label.text = "Hide Alerts"
                cell.backgroundColor = Theme.shared.active.secondaryBackgroundColor
                
                cell.onSwitch.isOn = DeviceSettings.shared.getChatAlertSetting(chatroom!.id!)
                // cell.onSwitch.tintColor = Color.blue.lighten1
                cell.onSwitch.onTintColor = Color.blue.lighten1
                
                cell.onSwitch.addTarget(self, action: #selector(switchValueDidChange(_:)), for: UIControlEvents.valueChanged)
                
                cell.backgroundColor = UIColor.clear
                cell.selectionStyle = .none
                
                return cell
            case 1:
                let cell = ChatInfoSegmentCell.loadNib(tableView)
                
                cell.segment.addTarget(self, action: #selector(segmentValueDidChange(_:)), for: UIControlEvents.valueChanged)
                
                // cell.backgroundColor = UIColor(hex: "F0F0F7")?.withAlphaComponent(0.85)
                cell.selectionStyle = .none
                
                return cell
            default:
                return UITableViewCell.defaultCell()
            }
        case 2:
            switch selectedSegment {
            case 0:
                if chatroom?.photos.items.count == 0 {
                    let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
                    let cell = views![0] as! EmptyCell
                    
                    cell.backgroundColor = UIColor.clear
                    
                    cell.selectionStyle = .none
                    return cell
                    
                } else {
                    let base = indexPath.row * 2
                    
                    let cell = ChatInfoPhotoCell.loadNib(tableView)
                    
                    if base < chatroom!.photos.items.count {
                        cell.image1.image = chatroom?.photos.items[base].image
                        cell.image1.tag = base
                        
                        let tap = UITapGestureRecognizer(target: self, action: #selector(viewPhotos(_:)))
                        cell.image1.addGestureRecognizer(tap)
                        cell.image1.isUserInteractionEnabled = true
                    } else {
                        cell.image1.image = UIImage()
                    }
                    
                    if base + 1 < chatroom!.photos.items.count {
                        cell.image2.image = chatroom?.photos.items[base + 1].image
                        cell.image2.tag = base + 1
                        
                        let tap = UITapGestureRecognizer(target: self, action: #selector(viewPhotos(_:)))
                        cell.image2.addGestureRecognizer(tap)
                        cell.image2.isUserInteractionEnabled = true
                    } else {
                        cell.image2.image = UIImage()
                    }
                    
                    cell.selectionStyle = .none
                    
                    return cell
                }
            default:
                let views = Bundle.main.loadNibNamed("EmptyCell", owner: self, options: nil)
                let cell = views![0] as! EmptyCell
                
                cell.backgroundColor = UIColor.clear
                
                cell.selectionStyle = .none
                return cell
            }
        default:
            return UITableViewCell.defaultCell()
        }
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let returnedView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: 1.0)) // set these values as necessary
        returnedView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)

        return returnedView
    }

    func numberOfSections(in _: UITableView) -> Int {
        return 3
    }
    
    // MARK: - Other Functions

    @objc func switchValueDidChange(_ sender: UISwitch) {
        if sender.isOn == true {
            DeviceSettings.shared.setChatAlertSetting(chatroom!.id!, value: true)
        } else {
            DeviceSettings.shared.setChatAlertSetting(chatroom!.id!, value: false)
        }
    }

    @objc func segmentValueDidChange(_ sender: UISegmentedControl) {
        selectedSegment = sender.selectedSegmentIndex
        tableView.reloadSections([2], with: UITableViewRowAnimation.automatic)
    }

    @objc func goViewUserProfile(_ sender: UITapGestureRecognizer) {
        
        Generator.bump()
        
        guard let tag = sender.view?.tag, let user = Users.shared[self.chatroom?.chatUsers[tag]?.user?.id] else {
            return
        }
        
        user.view()
    }

    @objc override func applyTheme() {
        super.applyTheme()
        
        view.backgroundColor = Theme.shared.active.primaryBackgroundColor
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        navBar?.leftButton.tintColor = Theme.shared.active.alternativeFontColor
        navBar?.rightButton.tintColor = Theme.shared.active.alternativeFontColor
    }
}

extension ChatInfo: NYTPhotosViewControllerDelegate {
    
    @objc func viewPhotos(_ sender: Any?) {
        guard let sender = sender as? UITapGestureRecognizer, let tag = sender.view?.tag else {
            return
        }
        
        Generator.bump()
        
        nytPhotos.removeAll()
        for photo in chatroom?.photos.items ?? [] {
            
            if photo.nytPhoto.image == nil {
                photo.nytPhoto.image = photo.image
            }
            
            nytPhotos.append(photo.nytPhoto)
        }
        
        photoViewerCoordinator = PhotoViewerCoordinator(images: nytPhotos)
        
        DispatchQueue.main.async {
            Presenter.present(NYTPhotosViewController(dataSource: self.photoViewerCoordinator!, initialPhoto: self.nytPhotos[tag], delegate: self), animated: true, completion: nil)
        }
    }
    
    
    func photosViewController(_ photosViewController: NYTPhotosViewController, handleActionButtonTappedFor photo: NYTPhoto) -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad, let photoImage = photo.image else {
            return false
        }
        
        let shareActivityViewController = UIActivityViewController(activityItems: [photoImage], applicationActivities: nil)
        shareActivityViewController.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, _: [Any]?, _: Error?) in
            if completed {
                photosViewController.delegate?.photosViewController!(photosViewController, actionCompletedWithActivityType: activityType?.rawValue)
            }
        }
        
        shareActivityViewController.popoverPresentationController?.barButtonItem = photosViewController.rightBarButtonItem
        photosViewController.present(shareActivityViewController, animated: true, completion: nil)
        
        return true
    }
    
    func photosViewController(_ controller: NYTPhotosViewController, didNavigateTo nytPhoto: NYTPhoto, at index: UInt) {
        guard let nytPhotoBox = nytPhoto as? NYTPhotoBox else {
            return
        }
        
        if nytPhotoBox.image == nil {
            
            if let image = nytPhotoBox.info.photo.image {
                DispatchQueue.main.async {
                    nytPhotoBox.image = image
                    controller.display(nytPhotoBox, animated: true)
                }
            } else {
                Async.waterfall(APIClient.shared.downloadSession, [nytPhotoBox.info.photo.download], end: { _, _ in
                    DispatchQueue.main.async {
                        nytPhotoBox.image = nytPhotoBox.info.photo.image
                        controller.display(nytPhotoBox, animated: true)
                    }
                })
            }
        }
    }
    
    func photosViewControllerWillDismiss(_ photosViewController: NYTPhotosViewController) {
        Generator.confirm()
    }
}
