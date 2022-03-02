//
//  UIKitExtensions.swift
//  Timeline SDK
//
//  Created by Zachary DeGeorge on 6/29/18.
//  Copyright © 2018 Timeline Software LLC. All rights reserved.
//

import Foundation
import CoreLocation

/*

 var longPressStart: Date? = nil
 var timer: Timer?
 @objc func editTableview(_ sender: UILongPressGestureRecognizer) {

 if sender.state == .began {

 self.longPressStart = Date()
 let longPressTime = Date().timeIntervalSince(self.longPressStart!)
 let longPressMax = sender.minimumPressDuration
 let delta:CGFloat = CGFloat(longPressTime / longPressMax)
 let direction: Bool = self.tableView.isEditing == true ? false : true
 let startAngle: CGFloat = direction == false ? (-CGFloat(Double.pi/2) + CGFloat(Double.pi * 2)) : -CGFloat(Double.pi/2)
 let endAngle: CGFloat = direction == false ? startAngle - min((delta * CGFloat(Double.pi * 2)), CGFloat(Double.pi * 2) - 0.001): startAngle + (CGFloat(Double.pi * 2) * delta)
 let circlePath = UIBezierPath(arcCenter: sender.location(in: self.view), radius: 25.0, startAngle: startAngle, endAngle:  endAngle, clockwise: true)

 let shapeLayer = CAShapeLayer()
 shapeLayer.path = circlePath.cgPath

 //change the fill color
 shapeLayer.fillColor = UIColor.clear.cgColor
 //you can change the stroke color
 shapeLayer.strokeColor = direction == false ? Color.red.darken1.withAlphaComponent(0.33).cgColor : Color.blue.darken1.withAlphaComponent(0.33).cgColor
 //you can change the line width
 shapeLayer.lineWidth = 50.0

 self.view.layer.addSublayer(shapeLayer)

 self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { (timer) in
 if let circle = self.view.layer.sublayers?.last as? CAShapeLayer, let pressStart = self.longPressStart {
 let longPressTime = Date().timeIntervalSince(pressStart)
 let longPressMax = sender.minimumPressDuration
 let delta:CGFloat = CGFloat(longPressTime / longPressMax)
 let direction: Bool = self.tableView.isEditing == true ? false : true
 let startAngle: CGFloat = direction == false ? (-CGFloat(Double.pi/2) + CGFloat(Double.pi * 2)) : -CGFloat(Double.pi/2)
 let endAngle: CGFloat = direction == false ? startAngle - min((delta * CGFloat(Double.pi * 2)), CGFloat(Double.pi * 2) - 0.001): startAngle + (CGFloat(Double.pi * 2) * delta)
 let circlePath = UIBezierPath(arcCenter: sender.location(in: self.view), radius: 25.0, startAngle: startAngle, endAngle:  endAngle, clockwise: true)

 UIView.animate(withDuration: 0.02, animations: {
 if delta > 1.0 {
 circle.strokeColor = direction == false ? Color.red.darken1.withAlphaComponent(0.33).cgColor : Color.green.darken1.withAlphaComponent(0.33).cgColor
 } else {
 circle.strokeColor = direction == false ? Color.red.darken1.withAlphaComponent(0.33).cgColor : Color.blue.darken1.withAlphaComponent(0.33).cgColor
 }
 circle.path = circlePath.cgPath
 circle.layoutIfNeeded()
 })

 if delta > 1.0 {

 if self.view.layer.sublayers?.last is CAShapeLayer {
 let _ = self.view.layer.sublayers?.popLast()
 }

 self.timer?.invalidate()
 self.timer = nil
 self.longPressStart = nil

 if self.tableView.isEditing == false {
 self.tableView.setEditing(true, animated: false)
 } else {
 self.tableView.setEditing(false, animated: false)
 }
 }

 } else {
 self.timer?.invalidate()
 self.timer = nil
 }
 }

 timer?.fire()
 }

 if sender.state == .ended {

 if self.view.layer.sublayers?.last is CAShapeLayer {
 let _ = self.view.layer.sublayers?.popLast()
 }

 self.timer?.invalidate()
 self.timer = nil
 self.longPressStart = nil
 }
 }

 */
