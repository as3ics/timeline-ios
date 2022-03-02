//
//  SystemMessage.swift
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

class SystemMessageModel: ChatItemProtocol {
    let uid: String
    let type: String = SystemMessageModel.chatItemType
    let message: String
    let date: Date

    static var chatItemType: ChatItemType {
        return "SystemMessageModel"
    }

    init(uid: String, message: String, date: Date) {
        self.message = message
        self.uid = uid
        self.date = date
    }
}

class SystemMessagePresenterBuilder: ChatItemPresenterBuilderProtocol {
    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem is SystemMessageModel
    }

    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        assert(canHandleChatItem(chatItem))
        return SystemMessagePresenter(systemMessageModel: chatItem as! SystemMessageModel)
    }

    var presenterType: ChatItemPresenterProtocol.Type {
        return SystemMessagePresenter.self
    }
}

class SystemMessagePresenter: ChatItemPresenterProtocol {
    let systemMessageModel: SystemMessageModel
    init(systemMessageModel: SystemMessageModel) {
        self.systemMessageModel = systemMessageModel
    }

    private static let cellReuseIdentifier = SystemMessageCollectionViewCell.self.description()

    static func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(SystemMessageCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
    }

    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: SystemMessagePresenter.cellReuseIdentifier, for: indexPath)
    }

    func configureCell(_ cell: UICollectionViewCell, decorationAttributes _: ChatItemDecorationAttributesProtocol?) {
        guard let systemMessageCell = cell as? SystemMessageCollectionViewCell else {
            assert(false, "expecting status cell")
            return
        }

        systemMessageCell.text = systemMessageModel.message
    }

    var canCalculateHeightInBackground: Bool {
        return true
    }

    func heightForCell(maximumWidth _: CGFloat, decorationAttributes _: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 24
    }
}

class SystemMessageCollectionViewCell: UICollectionViewCell {
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
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .center
        label.textColor = UIColor.black
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
        label.bounds.size = label.sizeThatFits(contentView.bounds.size)
        label.center = contentView.center
    }
}
