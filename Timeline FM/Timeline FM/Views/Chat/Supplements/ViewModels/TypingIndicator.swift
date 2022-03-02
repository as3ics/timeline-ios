//
//  TypingIndicator.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/2/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Chatto
import ChattoAdditions
import Foundation
import Material
import UIKit
import CoreLocation

class TypingModel: ChatItemProtocol {
    let uid: String
    let type: String = TypingModel.chatItemType
    var users = [User]()
    let date: Date

    static var chatItemType: ChatItemType {
        return "TypingModel"
    }

    init(uid: String, users: [User], date: Date) {
        self.users.removeAll()
        for user in users {
            self.users.append(user)
        }
        self.uid = uid
        self.date = date
    }
}

class TypingPresenterBuilder: ChatItemPresenterBuilderProtocol {
    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem is TypingModel
    }

    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        assert(canHandleChatItem(chatItem))
        return TypingPresenter(typingModel: chatItem as! TypingModel)
    }

    var presenterType: ChatItemPresenterProtocol.Type {
        return TypingPresenter.self
    }
}

class TypingPresenter: ChatItemPresenterProtocol {
    let typingModel: TypingModel
    init(typingModel: TypingModel) {
        self.typingModel = typingModel
    }

    private static let cellReuseIdentifier = TypingCollectionViewCell.self.description()

    static func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(TypingCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
    }

    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: TypingPresenter.cellReuseIdentifier, for: indexPath)
    }

    func configureCell(_ cell: UICollectionViewCell, decorationAttributes _: ChatItemDecorationAttributesProtocol?) {
        guard let typingCell = cell as? TypingCollectionViewCell else {
            assert(false, "expecting receipt cell")
            return
        }

        var message: String = ""
        if typingModel.users.count == 1 {
            message = "\(typingModel.users[0].firstName!) \(typingModel.users[0].lastName!)"
        } else {
            message = "\(typingModel.users.count) users are typing"
        }

        typingCell.text = message
    }

    var canCalculateHeightInBackground: Bool {
        return true
    }

    func heightForCell(maximumWidth _: CGFloat, decorationAttributes _: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 50
    }
}

class TypingCollectionViewCell: UICollectionViewCell {
    private let label: UILabel = UILabel()
    private var image: UIImageView = UIImageView()

    var images = [UIImageView]()
    var i: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        label.font = UIFont.boldSystemFont(ofSize: 9.0)
        label.textAlignment = .left
        label.baselineAdjustment = .alignBaselines
        label.textColor = UIColor.lightGray
        label.alpha = 0.95

        image.contentMode = .scaleAspectFit
        image.backgroundColor = UIColor.clear
        image.alpha = 0.95

        images.removeAll()

        images.append(UIImageView(image: UIImage(named: "typing-1")))
        images.append(UIImageView(image: UIImage(named: "typing-2")))
        images.append(UIImageView(image: UIImage(named: "typing-3")))
        images.append(UIImageView(image: UIImage(named: "typing-4")))
        images.append(UIImageView(image: UIImage(named: "typing-5")))
        images.append(UIImageView(image: UIImage(named: "typing-6")))

        image.image = images[0].image

        contentView.addSubview(label)
        contentView.addSubview(image)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in

            UIView.animate(withDuration: 0.25, animations: {
                self.image.image = self.images[self.i].image
            })

            self.i = self.i + 1
            if self.i >= self.images.count {
                self.i = 0
            }
        }

        timer.fire()
    }

    var text: String = "" {
        didSet {
            if oldValue != text {
                self.setTextOnLabel(text)
            }
        }
    }

    private func setTextOnLabel(_ text: String) {
        label.text = text

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        image.bounds.size = CGSize(width: 80.0, height: 40.0)
        image.center = CGPoint(x: 40.0, y: contentView.center.y - 5)

        label.bounds.size = CGSize(width: 200.0, height: 20.0)
        label.center = CGPoint(x: 127.5, y: contentView.center.y + 17.0)

        // self.label.bounds.size = self.label.sizeThatFits(self.contentView.bounds.size)
        // self.label.center = self.contentView.center
    }
}
