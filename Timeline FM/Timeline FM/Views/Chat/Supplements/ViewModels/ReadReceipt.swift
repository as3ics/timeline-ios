//
//  ReadReceipt.swift
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

class ReadReceiptModel: ChatItemProtocol {
    let uid: String
    let type: String = ReadReceiptModel.chatItemType
    let message: String
    let date: Date

    static var chatItemType: ChatItemType {
        return "ReadReceiptModel"
    }

    init(uid: String, message: String, date: Date) {
        self.message = message
        self.uid = uid
        self.date = date
    }
}

class ReadReceiptPresenterBuilder: ChatItemPresenterBuilderProtocol {
    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem is ReadReceiptModel
    }

    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        assert(canHandleChatItem(chatItem))
        return ReadReceiptPresenter(readReceiptModel: chatItem as! ReadReceiptModel)
    }

    var presenterType: ChatItemPresenterProtocol.Type {
        return ReadReceiptPresenter.self
    }
}

class ReadReceiptPresenter: ChatItemPresenterProtocol {
    let readReceiptModel: ReadReceiptModel
    init(readReceiptModel: ReadReceiptModel) {
        self.readReceiptModel = readReceiptModel
    }

    private static let cellReuseIdentifier = ReadReceiptCollectionViewCell.self.description()

    static func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(ReadReceiptCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
    }

    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: ReadReceiptPresenter.cellReuseIdentifier, for: indexPath)
    }

    func configureCell(_ cell: UICollectionViewCell, decorationAttributes _: ChatItemDecorationAttributesProtocol?) {
        guard let readReceiptCell = cell as? ReadReceiptCollectionViewCell else {
            assert(false, "expecting receipt cell")
            return
        }

        readReceiptCell.text = readReceiptModel.message
    }

    var canCalculateHeightInBackground: Bool {
        return true
    }

    func heightForCell(maximumWidth _: CGFloat, decorationAttributes _: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 14
    }
}

class ReadReceiptCollectionViewCell: UICollectionViewCell {
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
        label.font = UIFont.boldSystemFont(ofSize: 10.0)
        label.textAlignment = .right
        label.textColor = UIColor.lightGray
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
        label.center = CGPoint(x: contentView.width - 115.0, y: contentView.center.y)
        // self.label.bounds.size = self.label.sizeThatFits(self.contentView.bounds.size)
        // self.label.center = self.contentView.center
    }
}
