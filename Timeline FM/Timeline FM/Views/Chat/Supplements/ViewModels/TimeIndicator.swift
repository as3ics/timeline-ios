//
//  TimeIndicator.swift
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

class TimeSeparatorModel: ChatItemProtocol {
    let uid: String
    let type: String = TimeSeparatorModel.chatItemType
    let date: String

    static var chatItemType: ChatItemType {
        return "TimeSeparatorModel"
    }

    init(uid: String, date: String) {
        self.date = date
        self.uid = uid
    }
}

extension Date {
    // Have a time stamp formatter to avoid keep creating new ones. This improves performance
    private static let weekdayAndDateStampDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "EEEE, MMM dd yyyy" // "Monday, Mar 7 2016"
        return dateFormatter
    }()

    func toWeekDayAndDateString() -> String {
        return Date.weekdayAndDateStampDateFormatter.string(from: self)
    }
}

class TimeSeparatorPresenterBuilder: ChatItemPresenterBuilderProtocol {
    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem is TimeSeparatorModel
    }

    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        assert(canHandleChatItem(chatItem))
        return TimeSeparatorPresenter(timeSeparatorModel: chatItem as! TimeSeparatorModel)
    }

    var presenterType: ChatItemPresenterProtocol.Type {
        return TimeSeparatorPresenter.self
    }
}

class TimeSeparatorPresenter: ChatItemPresenterProtocol {
    let timeSeparatorModel: TimeSeparatorModel
    init(timeSeparatorModel: TimeSeparatorModel) {
        self.timeSeparatorModel = timeSeparatorModel
    }

    private static let cellReuseIdentifier = TimeSeparatorCollectionViewCell.self.description()

    static func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(TimeSeparatorCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
    }

    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: TimeSeparatorPresenter.cellReuseIdentifier, for: indexPath)
    }

    func configureCell(_ cell: UICollectionViewCell, decorationAttributes _: ChatItemDecorationAttributesProtocol?) {
        guard let timeSeparatorCell = cell as? TimeSeparatorCollectionViewCell else {
            assert(false, "expecting status cell")
            return
        }

        timeSeparatorCell.text = timeSeparatorModel.date
    }

    var canCalculateHeightInBackground: Bool {
        return true
    }

    func heightForCell(maximumWidth _: CGFloat, decorationAttributes _: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 24
    }
}

class TimeSeparatorCollectionViewCell: UICollectionViewCell {
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
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = UIColor.gray
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
