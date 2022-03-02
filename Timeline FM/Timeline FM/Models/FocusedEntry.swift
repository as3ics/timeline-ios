//
//  FocusedEntry.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/12/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation

var _focusedEntry = FocusedEntry()
var _historyFocusedEntry = FocusedEntry()

class FocusedEntry {
    var isFocused: Bool! = false
    var index: Int?
    var entryId: String?
    weak var sheet: Sheet?
    
    init() {
        sheet = nil
        index = nil
        entryId = nil
        isFocused = false
    }
    
    func set(_ index: Int) {
        DispatchQueue.main.async {
            if let sheet = self.sheet, let entries = sheet.entries {
                if index < entries.count {
                    self.isFocused = true
                    self.index = index
                    self.entryId = entries[index]?.id
                    
                    NotificationManager.shared.focues_entry_updated.post()
                }
            }
        }
    }
    
    func clear() {
        isFocused = false
        index = nil
        entryId = nil
    }
    
    func isSet() -> Bool! {
        return (isFocused == true)
    }
}
