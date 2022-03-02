//
//  Daemon.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/24/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import UserNotifications
import CoreLocation

class DaemonTask {
    var executable: (() -> Void)?
    var interval: Int?
    var offset: Int = 0
    var name: String?
    var timestamp: Date?
    var description: String?
    var running: Bool = false
}

class Daemon {
    static let shared = Daemon()

    internal var timer: Timer?
    var start: Date?
    var tasks = [DaemonTask]()

    func initialize() {
        tasks.removeAll()
    }

    subscript(name: String?) -> DaemonTask? {
        guard let taskName = name else {
            return nil
        }

        var value: DaemonTask?
        for task in tasks {
            if task.name == taskName {
                value = task
                break
            }
        }

        return value
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func addTask(task: DaemonTask) {
        for previousTask in tasks {
            if task.name! == previousTask.name! {
                previousTask.running = true
                return
            }
        }

        task.running = false
        tasks.append(task)
    }

    func removeTask(name: String) {
        var i: Int = 0
        for previousTask in tasks {
            if previousTask.name! == name {
                tasks.remove(at: i)
                return
            }
            i = i + 1
        }
    }

    func stopTask(name: String?) {
        guard let name = name else {
            return
        }

        for task in tasks {
            if let taskName = task.name, name == taskName {
                task.running = false
                break
            }
        }
    }

    func startTask(name: String?) {
        guard let name = name else {
            return
        }

        for task in tasks {
            if let taskName = task.name, name == taskName {
                task.running = true
                break
            }
        }
    }

    @objc func fire() {
        timer?.invalidate()
        timer = nil

        start = Date()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(execute), userInfo: nil, repeats: true)
    }

    @objc func stop() {
        timer?.invalidate()
        timer = nil
    }

    @objc internal func execute() {
        guard let startTime = self.start else {
            return
        }

        let time = Int(floor(Date().timeIntervalSince1970 - startTime.timeIntervalSince1970))

        for task in tasks {
            if let interval = task.interval, (time + task.offset) % interval == 0, task.running == true, let executable = task.executable {
                task.timestamp = Date()

                DispatchQueue.main.async {
                    executable()
                }
            }
        }
    }
}
