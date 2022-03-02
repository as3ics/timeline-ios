//
//  Types_Local.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 9/14/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation

// LocationManager.swift

enum GPSSetting {
    case Undetermined
    case Off
    case High
    case Low
}

enum DebounceType {
    case ClockIn
    case Travel
    case Processing
}

// Global State Machine
enum SystemState {
    case Traveling
    case Empty
    case LoggedIn
    case Break
    case Off
    case Error
}

// Sytem Errors

enum SystemErrors: Error {
    case AuthError
    case APIError
    case PretenseError
}

extension SystemErrors: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .AuthError:
            return NSLocalizedString("Authorization Not Complete", comment: "")
        case .APIError:
            return NSLocalizedString("API Request Failed", comment: "")
        case .PretenseError:
            return NSLocalizedString("Some pre-condition has not been met", comment: "")
        }
    }
}


// for 3d touch

enum ShortcutIdentifier: String {
    case CreateTimeSheet = "com.timelinefm.shortcut.createTimeSheet"
    case Travel = "com.timelinefm.shortcut.travel"
    case QuickAddEntry = "com.timelinefm.shortcut.quickAddEntry"
    case Break = "com.timelinefm.shortcut.break"
    case EndBreak = "com.timelinefm.shortcut.endBreak"
    case SubmitTimeSheet = "com.timelinefm.shortcut.submitTimeSheet"
    case AddEntry = "com.timelinefm.shortcut.addEntry"
}
