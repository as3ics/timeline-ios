//
//  NameIndicator.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/2/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Chatto
import ChattoAdditions
import Foundation
import UIKit
import CoreLocation

class NameViewModel: ChatItemProtocol {
    let uid: String
    let type: String = NameViewModel.chatItemType
    let name: String
    let date: Date

    static var chatItemType: ChatItemType {
        return "NameViewModel"
    }

    init(uid: String, name: String, date: Date) {
        self.name = name
        self.uid = uid
        self.date = date
    }
}

class NameViewPresenterBuilder: ChatItemPresenterBuilderProtocol {
    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem is NameViewModel
    }

    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        assert(canHandleChatItem(chatItem))
        return NameViewPresenter(nameViewModel: chatItem as! NameViewModel)
    }

    var presenterType: ChatItemPresenterProtocol.Type {
        return NameViewPresenter.self
    }
}

class NameViewPresenter: ChatItemPresenterProtocol {
    let nameViewModel: NameViewModel
    init(nameViewModel: NameViewModel) {
        self.nameViewModel = nameViewModel
    }

    private static let cellReuseIdentifier = NameCollectionViewCell.self.description()

    static func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(NameCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
    }

    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: NameViewPresenter.cellReuseIdentifier, for: indexPath)
    }

    func configureCell(_ cell: UICollectionViewCell, decorationAttributes _: ChatItemDecorationAttributesProtocol?) {
        guard let nameViewCell = cell as? NameCollectionViewCell else {
            assert(false, "expecting name cell")
            return
        }

        nameViewCell.text = nameViewModel.name
    }

    var canCalculateHeightInBackground: Bool {
        return true
    }

    func heightForCell(maximumWidth _: CGFloat, decorationAttributes _: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 24
    }
}

class NameCollectionViewCell: UICollectionViewCell {
    private let label: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        label.font = UIFont.systemFont(ofSize: 9)
        label.textAlignment = .left
        // let insets = UIEdgeInsetsMake(0, 20, 0, 0)
        // self.label.layoutEdgeInsets = insets
        label.textColor = UIColor.darkGray
        contentView.addSubview(label)
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
        label.bounds.size = CGSize(width: 200.0, height: 10.0)
        label.center = CGPoint(x: contentView.center.x - 25.0, y: contentView.center.y)
    }
}
