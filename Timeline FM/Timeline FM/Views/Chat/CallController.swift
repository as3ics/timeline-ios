//
//  CallController.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/7/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit
/*
 class CallController: UIViewController, SINCallDelegate {

 @IBOutlet var usernameLabel: UILabel!
 @IBOutlet var statusLabel: UILabel!
 @IBOutlet var profilePicture: UIImageView!
 @IBOutlet var answerButton: UIImageView!
 @IBOutlet var ignoreButton: UIImageView!
 @IBOutlet var hangupButton: UIImageView!

 var durationTimer: Timer! = nil
 var _call: SINCall!

 var callAnswered: Bool = false

 let appDelegate = UIApplication.shared.delegate as! AppDelegate

 override func viewDidLoad() {
 super.viewDidLoad()

 self.profilePicture.cornerRadius = self.profilePicture.frame.height / 2

 self.hangupButton.alpha = 0.0

 let tap1 = UITapGestureRecognizer(target: self, action: #selector(ignoreButtonPressed(_:)))
 ignoreButton.addGestureRecognizer(tap1)
 ignoreButton.isUserInteractionEnabled = true

 let tap2 = UITapGestureRecognizer(target: self, action: #selector(answerButtonPressed(_:)))
 answerButton.addGestureRecognizer(tap2)
 answerButton.isUserInteractionEnabled = true

 let tap3 = UITapGestureRecognizer(target: self, action: #selector(hangupButtonPressed(_:)))
 hangupButton.addGestureRecognizer(tap3)
 hangupButton.isUserInteractionEnabled = true

 _call.delegate = self

 if _call.direction == SINCallDirection.incoming {
 setCallStatusText(text: "")
 showButtons()

 audioController().startPlayingSoundFile(self.pathForSound(soundName: "incoming"), loop: true)
 } else {
 callAnswered = true
 setCallStatusText(text: "Calling...")
 showButtons()
 }
 // Do any additional setup after loading the view.
 }

 override func viewWillAppear(_ animated: Bool) {
 self.usernameLabel.text = "Unknown"

 let id = _call.remoteUserId

 if let name = deviceUser.users?.callerId(id: id!)
 {
 self.usernameLabel.text = name
 }
 }

 func audioController() -> SINAudioController {

 return appDelegate._client.audioController()
 }

 func setCall(call: SINCall) {
 _call = call
 _call.delegate = self
 }

 override func didReceiveMemoryWarning() {
 super.didReceiveMemoryWarning()
 // Dispose of any resources that can be recreated.
 }

 @IBAction func ignoreButtonPressed(_ sender: Any)
 {
 print("Ignore Button Pressed")

 _call.hangup()

 if(self.navigationController != nil)
 {
 self.navigationController?.popViewController(animated: true)
 }
 else
 {
 self.dismiss(animated: true, completion: nil)
 }
 }

 @IBAction func answerButtonPressed(_ sender: Any)
 {
 print("Answer Button Pressed")
 callAnswered = true
 showButtons()
 audioController().stopPlayingSoundFile()
 _call.answer()
 }

 func callDidProgress(_ call: SINCall!) {

 setCallStatusText(text: "Ringing...")
 audioController().startPlayingSoundFile(pathForSound(soundName: "ringback"), loop: true)

 }

 func callDidEstablish(_ call: SINCall!) {
 startCallDurationTimer()

 print("Sinch Call Established")

 showButtons()
 audioController().stopPlayingSoundFile()

 }

 func callDidEnd(_ call: SINCall!) {
 print("Sinch Call Ended")
 audioController().stopPlayingSoundFile()
 stopCallDurationTimer()

 if(self.navigationController != nil)
 {
 self.navigationController?.popViewController(animated: true)
 }
 else
 {
 self.dismiss(animated: true, completion: nil)
 }
 }

 @IBAction func hangupButtonPressed(_ sender: Any)
 {
 print("Hangup Button Pressed")
 _call.hangup()

 if(self.navigationController != nil)
 {
 self.navigationController?.popViewController(animated: true)
 }
 else
 {
 self.dismiss(animated: true, completion: nil)
 }

 }

 func setCallStatusText(text: String)
 {
 statusLabel.text = text
 }

 func showButtons() {
 if callAnswered == true {
 ignoreButton.alpha = 0.0
 hangupButton.alpha = 1.0
 answerButton.alpha = 0.0
 }
 else
 {
 ignoreButton.alpha = 1.0
 hangupButton.alpha = 0.0
 answerButton.alpha = 1.0
 }
 }

 func pathForSound(soundName: String) -> String {
 return Bundle.main.path(forResource: soundName, ofType: "wav")!
 }

 @objc func onDurationTimer() {
 let duration = Date().timeIntervalSince(_call.details.establishedTime)

 updateTimerLabel(seconds: Int(duration))
 }

 func updateTimerLabel(seconds: Int)
 {
 let min = String(format: "%02d", (seconds / 60))
 let sec = String(format: "%02d", (seconds % 60))

 setCallStatusText(text: "\(min) : \(sec)")

 }

 func startCallDurationTimer() {
 self.durationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.onDurationTimer), userInfo: nil, repeats: true)

 }

 func stopCallDurationTimer() {
 if durationTimer != nil {
 durationTimer.invalidate()
 durationTimer = nil
 }
 }

 deinit {
 NotificationCenter.default.removeObserver(self)
 }

 }

 */
