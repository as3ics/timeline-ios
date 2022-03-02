//
//  StandardPhotoCell.swift
//  Timesheets
//
//  Created by Zachary DeGeorge on 3/23/18.
//  Copyright © 2018 Timeline Software, LLC. All rights reserved.
//

import UIKit

class StandardPhotoCell: UITableViewCell, UIScrollViewDelegate, ThemeSupportedProtocol, NibProtocol {
    typealias Item = StandardPhotoCell
    static var reuseIdentifier: String = "StandardPhotoCell"

    @IBOutlet var photo: UIImageView!
    @IBOutlet var scrollView: UIScrollView!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0

        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        applyTheme()

        Theme.shared.theme_changed.observe(self, selector: #selector(applyTheme))
    }

    func viewForZooming(in _: UIScrollView) -> UIView? {
        return photo
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func populate(_ image: UIImage?) {
        photo.image = image
    }

    @objc func applyTheme() {
        backgroundColor = Theme.shared.active.subHeaderBackgroundColor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
