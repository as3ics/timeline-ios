//
//  LocationObject.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/3/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import ActionSheetPicker_3_0
import CoreLocation
import Foundation
import MapKit
import Material
import BetterSegmentedControl
import PKHUD

class LocationObject: UIView, NibProtocol, ThemeSupportedProtocol, UITableViewDelegate, UITableViewDataSource {
    
    typealias Item = LocationObject
    static var reuseIdentifier: String = "LocationObject"
    static var size: CGSize {
        return CGSize(width: 300, height: 210)
    }
    
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var title: UILabel!

    @IBOutlet var viewButton: FlatButton!
    @IBOutlet var directionsButton: FlatButton!
    @IBOutlet var picturesButton: FlatButton!
    @IBOutlet var icon: UIImageView!
    
    var location: Location?
    var index: Int = -1
    
    var info: JSON? {
        didSet {
            if let infos = info?["section"] as? [MainInfo] {
                self.infos = infos
            } else {
                infos.removeAll()
            }
        }
    }
    
    var infos = [MainInfo]()

    override func awakeFromNib() {
        super.awakeFromNib()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        MainHeaderCell.register(tableView)
        MainValueCell.register(tableView)
        
        viewButton.addTarget(self, action: #selector(focus), for: .touchUpInside)
        directionsButton.addTarget(self, action: #selector(directions), for: .touchUpInside)
        picturesButton.addTarget(self, action: #selector(photos), for: .touchUpInside)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cardPressed)))

        applyTheme()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func populate(_ location: Location) {
        
        self.location = location
        self.title.text = location.name
        self.icon.image = location.dequeSnapshot()

        NotificationManager.shared.new_latest_location.observe(self, selector: #selector(refresh))
        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
        
        self.info = InfoGenerator.generateInfo(location: location)
        tableView.isScrollEnabled = infos.count > 4
        
        self.refresh()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infos.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MainValueCell.cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard indexPath.row < self.infos.count else {
            let cell = UITableViewCell.defaultCell()
            cell.backgroundColor = Theme.shared.active.primaryBackgroundColor
            cell.selectionStyle = .none
            return cell
        }
        
        let info = self.infos[indexPath.row]
        
        switch info.section {
        case true:
            let cell = MainHeaderCell.loadNib(tableView)
            cell.title.text = info.label
            cell.label.text = nil
            cell.selectionStyle = .none
            return cell
        case false:
            let cell = MainValueCell.loadNib(tableView)
            cell.title.text = info.label
            cell.value.text = info.value?()
            cell.selectionStyle = .none
            
            return cell
        }
    }
    
    @objc func cardPressed(_ sender: UITapGestureRecognizer) {
        sender.view?.touchAnimation()
        
        delay(0.2) {
            self.location?.view()
        }
    }
    
    @objc func focus() {
        delay(0.2) {
            NotificationManager.shared.map_focus_location.post(["location": self.location as JSONObject])
        }
    }
    
    @objc func photos() {
        
        guard let location = self.location else {
            return
        }
        
        delay(0.2) {
            
            PKHUD.loading()
            
            Async.waterfall(nil, [location.retrievePhotos], end: { _, _ in
                
                PKHUD.success()
                
                self.location?.photos.view()
            })
        }
    }

    @objc func directions() {
        delay(0.2) {
            if DeviceSettings.shared.mapProgram == MapProgram.apple {
                self.location?.coordinate?.appleMaps(name: self.location?.name)
            } else {
                self.location?.coordinate?.googleMaps()
            }
        }
    }

    @objc func refresh() {
        tableView.reloadSections([0], with: .none)
    }

    @objc func applyTheme() {
        
        tableView.corner = 7.5
        tableView.bounces = false
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        
        icon.circle = true
        icon.backgroundColor = UIColor.clear
        
        directionsButton.style(Color.blue.darken2, image: AssetManager.shared.googleMaps)
        viewButton.style(Color.blue.darken2, image: AssetManager.shared.centerMapFilled)
        picturesButton.style(Color.blue.darken2, image: AssetManager.shared.picturesFilled)
        
        
        directionsButton.corner = 7.5
        viewButton.corner = 7.5
        picturesButton.corner = 7.5
        
        
        /*
        directionsButton.circle = true
        viewButton.circle = true
        picturesButton.circle = true
        */
        
        self.backgroundColor = UIColor.clear
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
