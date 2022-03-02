//
//  MainSectionTableView.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/18/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class MainSectionTableView: UIView, NibProtocol, ThemeSupportedProtocol, UITableViewDelegate, UITableViewDataSource {
    
    typealias Item = MainSectionTableView
    static var reuseIdentifier: String = "MainSectionTableView"

    
    @IBOutlet var tableView: UITableView!
    
    var section = [MainInfo]()
    var updates = [IndexPath]()
    
    var timer_1000ms: Timer?
    
    var update: Bool = false {
        willSet {
            guard newValue != update else {
                return
            }
            
            if newValue == false {
                timer_1000ms?.invalidate()
                timer_1000ms = nil
            } else if newValue == true, timer_1000ms == nil {
                timer_1000ms = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
                    
                    print("Timer - Main Section Table View")
                    
                    self.applyUpdates()
                })
                
                timer_1000ms?.fire()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.alwaysBounceHorizontal = false
        tableView.isScrollEnabled = false
        
        MainHeaderCell.register(tableView)
        MainValueCell.register(tableView)
        
    }
    
    func populate(section: [MainInfo]) {
        self.section.removeAll()
        self.section.append(contentsOf: section)
        self.tableView.sizeToFit()
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MainValueCell.cellHeight
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard indexPath.row < self.section.count else {
            let cell = UITableViewCell.defaultCell()
            cell.backgroundColor = Theme.shared.active.primaryBackgroundColor
            cell.selectionStyle = .none
            return cell
        }
        
        let info = self.section[indexPath.row]
        
        switch info.section {
        case true:
            let cell = MainHeaderCell.loadNib(tableView)
            cell.title.text = info.label
            cell.selectionStyle = .none
            return cell
        case false:
            let cell = MainValueCell.loadNib(tableView)
            cell.title.text = info.label
            cell.value.text = info.value?()
            cell.selectionStyle = .none
            
            if info.updates == true {
                let matches = updates.filter { (path) -> Bool in
                    return path.row == indexPath.row
                }
                
                if matches.count == 0 {
                    updates.append(indexPath)
                }
            }
            
            return cell
        }
    }
    
    func setIndex(_ index: Int, of: Int) {
        guard let header = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? MainHeaderCell else {
            return
        }
        
        header.setIndex(index, of: of)
    }
    
    @objc func applyUpdates() {
        
        self.tableView.reloadRows(at: updates, with: .none)
        
    }
    
    func applyTheme() {
        tableView.backgroundColor = Theme.shared.active.primaryBackgroundColor
        self.backgroundColor = Theme.shared.active.primaryBackgroundColor
    }
    
    deinit {
        timer_1000ms?.invalidate()
        timer_1000ms = nil
        updates.removeAll()
        NotificationCenter.default.removeObserver(self)
    }

}


