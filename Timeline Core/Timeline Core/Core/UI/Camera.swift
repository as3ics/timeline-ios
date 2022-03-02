//
//  Camera.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 4/7/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import Foundation
import MobileCoreServices
import UIKit
import CoreLocation

class Camera {
    var delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate

    init(source: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
        delegate = source
    }
    
    func PresentPhotoInput(target: UIViewController, canEdit: Bool = false) {
        
        let picker = UIAlertController(title: "Select Photo Source", message: "Would you like to take a new photo or add one from your photo library?", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        picker.addAction(UIAlertAction(title: "Camera", style: UIAlertActionStyle.default, handler: { (action) in
            self.PresentMultyCamera(target: target, canEdit: canEdit)
        }))
        
        picker.addAction(UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.default, handler: { (action) in
            self.PresentPhotoLibrary(target: target, canEdit: canEdit)
        }))
        
        picker.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: { (action) in
            // foo
        }))
        
        target.present(picker, animated: true)
        
    }

    func PresentPhotoLibrary(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) && !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.savedPhotosAlbum) {
            return
        }

        let type = kUTTypeImage as String
        let imagePicker = UIImagePickerController()

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary

            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                if (availableTypes as NSArray).contains(type) {
                    /* Set up defaults */
                    imagePicker.mediaTypes = [type]
                    imagePicker.allowsEditing = canEdit
                }
            }
        } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.sourceType = .savedPhotosAlbum

            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum) {
                if (availableTypes as NSArray).contains(type) {
                    imagePicker.mediaTypes = [type]
                }
            }
        } else {
            return
        }

        imagePicker.allowsEditing = canEdit
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil) // presents the imagepicker to the user

        return
    }

    func PresentMultyCamera(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            return
        }

        let type1 = kUTTypeImage as String
        //let type2 = kUTTypeMovie as String

        let imagePicker = UIImagePickerController()

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                if (availableTypes as NSArray).contains(type1) {
                    imagePicker.mediaTypes = [type1/*, type2*/]
                    imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                    imagePicker.showsCameraControls = true
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.rear
            } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.front
            }
        } else {
            // show alert, no camera available
            return
        }

        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil) // presents the imagepicker to the user
    }

    func PresentPhotoCamera(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            return
        }

        let type1 = kUTTypeImage as String

        let imagePicker = UIImagePickerController()

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                if (availableTypes as NSArray).contains(type1) {
                    imagePicker.mediaTypes = [type1]
                    imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.rear
            } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.front
            }
        } else {
            // show alert, no camera available
            return
        }

        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        App.shared.isAuthenticating = true
        target.present(imagePicker, animated: true, completion: nil) // presents the imagepicker to the user
    }

    // Video Camera
    func PresentVideoCamera(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            return
        }

        let type1 = kUTTypeMovie as String

        let imagePicker = UIImagePickerController()

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                if (availableTypes as NSArray).contains(type1) {
                    imagePicker.mediaTypes = [type1]
                    imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                    imagePicker.videoMaximumDuration = 15.0
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.rear
            } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.front
            }
        } else {
            // show alert, no camera available
            return
        }

        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil) // presents the imagepicker to the user
    }

    // video library
    func PresentVideoLibrary(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) && !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.savedPhotosAlbum) {
            return
        }

        let type = kUTTypeMovie as String
        let imagePicker = UIImagePickerController()

        imagePicker.videoMaximumDuration = 15.0

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary

            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                if (availableTypes as NSArray).contains(type) {
                    /* Set up defaults */
                    imagePicker.mediaTypes = [type]
                    imagePicker.allowsEditing = canEdit
                }
            }
        } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.sourceType = .savedPhotosAlbum

            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum) {
                if (availableTypes as NSArray).contains(type) {
                    imagePicker.mediaTypes = [type]
                }
            }
        } else {
            return
        }

        imagePicker.allowsEditing = canEdit
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil) // presents the imagepicker to the user

        return
    }
}
