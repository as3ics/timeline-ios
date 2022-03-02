//
//  MainSectionActionItem.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 10/18/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit
import Material

class MainSectionActionItem: UIView, NibProtocol, ThemeSupportedProtocol {

    
    typealias Item = MainSectionActionItem
    static var reuseIdentifier: String = "MainSectionActionItem"
    static var size: CGSize {
        return CGSize(width: 100, height: 90)
    }
    
    var index: Int = -1
    
    var colors: [UIColor] = [Color.blue.darken3, Color.red.darken3, Color.green.darken3]
    var action: Enclosure?
    
    @IBOutlet var card: CardHighlight!
    
    func populate(action: MainAction?) {
        guard let action = action else {
            return
        }
        
        self.card.icon = action.icon
        self.card.buttonText = action.button ?? "Go"
        self.card.tintColor = Theme.shared.active.alternateIconColor
        self.card.title = action.label ?? ""
        self.card.itemSubtitle = action.subtitle ?? ""
        self.card.backgroundColor = action.color ?? Color.blue.base
        self.action = action.action
        self.card.action = action.action
        self.card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(execute)))
    }
    
    @objc func execute(_ sender: Any?) {
        
        if let tap = sender as? UITapGestureRecognizer, let view = tap.view {
            view.touchAnimation()
        }
        
        delay(0.1) {
            self.action?()
        }
    }

    func applyTheme() {
        
    }
    
}

