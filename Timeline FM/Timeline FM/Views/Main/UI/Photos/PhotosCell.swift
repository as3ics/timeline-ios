//
//  PhotosCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/11/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import UIKit

class PhotosCell: UITableViewCell, NibProtocol, ThemeSupportedProtocol {
    typealias Item = PhotosCell
    static var reuseIdentifier: String = "PhotosCell"
    
    static let cellHeight: CGFloat = UIScreen.main.bounds.width / 3.0
    
    @IBOutlet var image1: UIImageView!
    @IBOutlet var image2: UIImageView!
    @IBOutlet var image3: UIImageView!
    //@IBOutlet var image4: UIImageView!
    
    @IBOutlet var activityIndicator1: UIActivityIndicatorView!
    @IBOutlet var activityIndicator2: UIActivityIndicatorView!
    @IBOutlet var activityIndicator3: UIActivityIndicatorView!
    //@IBOutlet var activityIndicator4: UIActivityIndicatorView!
    
    var indicators: [UIActivityIndicatorView] = [UIActivityIndicatorView]()
    var images: [UIImageView] = [UIImageView]()
    var photos: [Photo] = [Photo]()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        images.append(image1)
        images.append(image2)
        images.append(image3)
        //images.append(image4)
        
        indicators.append(activityIndicator1)
        indicators.append(activityIndicator2)
        indicators.append(activityIndicator3)
        //indicators.append(activityIndicator4)
        
        applyTheme()
        
        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func populate(photos: [Photo]) {
        
        for photo in photos {
            self.photos.append(photo)
        }
        
        for indicator in indicators {
            indicator.stopAnimating()
            indicator.alpha = 0.0
        }
        
        var i: Int = 0
        while i < self.photos.count {
            let photo = self.photos[i]
            let image = self.images[i]
            let indicator = self.indicators[i]
            
            image.tag = photo.index
            image.image = photo.placeholder
            
            if image.image == nil {
                indicator.startAnimating()
                indicator.alpha = 1.0
                
                
                let session = APIClient.shared.downloadSession
                
                Async.waterfall(session, [photo.downloadPlaceholder]) { (error, response) in
                    DispatchQueue.main.async {
                        image.image = photo.placeholder
                        indicator.stopAnimating()
                        indicator.alpha = 0.0
                    }
                }
                
                //self.photos[i].observePlaceholderUpdates = true
                //Notifications.shared.image_placeholder_retrieved.observe(self, selector: #selector(imagePlaceholderUpdated))
            }
            
            i = i + 1
        }
        
    }
    
    @objc func imagePlaceholderUpdated(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as? JSON, let photo = userInfo["photo"] as? Photo else {
            return
        }
        
        
        var i: Int = 0
        while i < self.photos.count {
            if self.photos[i].id == photo.id {
                DispatchQueue.main.async {
                    self.images[i].image = photo.placeholder
                    self.indicators[i].stopAnimating()
                    self.indicators[i].alpha = 0.0
                }
                break
            }
            i += 1
        }
        
        DispatchQueue.main.async {
            var emptyImages: Int = 0
            var j: Int = 0
            while j < self.photos.count {
                if self.images[j].image == nil {
                    emptyImages += 1
                }
                j += 1
            }
            
            if emptyImages == 0 {
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for image in images {
            image.image = nil
            
            for gesture in image.gestureRecognizers ?? [] {
                image.removeGestureRecognizer(gesture)
            }
        }
        
        for indicator in indicators {
            indicator.stopAnimating()
            indicator.alpha = 0.0
        }
        
        self.photos.removeAll()
    }
    
    @objc func applyTheme() {
        for image in images {
            image.borderColor = Theme.shared.active.primaryBackgroundColor
        }
    }
    
}
