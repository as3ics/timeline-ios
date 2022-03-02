//
//  PeopleCardCollectionCell.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 7/6/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Cards
import UIKit

class PeopleCardCollectionCell: UITableViewCell, NibProtocol, CardDelegate, UIScrollViewDelegate {
    typealias Item = PeopleCardCollectionCell

    static var reuseIdentifier: String = "PeopleCardCollectionCell"

    static var cellHeight: CGFloat = 200

    @IBOutlet var cardGroup: CardGroup!
    @IBOutlet var scrollView: UIScrollView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        // view.addSubview(card)
    }

    func populate(_ _parent: UIViewController) {
        // Do any additional setup after loading the view.

        // Aspect Ratio of 5:6 is preferred

        cardGroup.backgroundColor = ThemeManager.shared.theme.primaryBackgroundColor
        cardGroup.shadowBlur = 5
        cardGroup.cardRadius = 0
        cardGroup.cornerRadius = 0
        scrollView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear

        let _inset: CGFloat = 10.0
        let _width: CGFloat = (UIScreen.main.bounds.width - (4 * _inset)) / 3.0
        let _height: CGFloat = 120.0

        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 140)

        var i: CGFloat = -1.0

        i += 1.0
        let card1 = CardHighlight(frame: CGRect(x: i * _inset + (_inset / 2) + i * _width, y: 180.0 - _height, width: _width, height: _height))
        card1.backgroundColor = UIColor(red: 0, green: 94 / 255, blue: 112 / 255, alpha: 1)
        let user1 = Users.shared.users[0]
        card1.icon = user1.avatar?.image ?? UIImage(named: "avatar")
        card1.title = String(format: "%@ %@", user1.firstName!, user1.lastName!)
        card1.itemTitle = "Union at Dearborn"
        card1.itemSubtitle = ""
        card1.textColor = UIColor.white
        card1.delegate = self
        card1.hasParallax = true
        let cardContentVC1 = UIStoryboard.Main(identifier: "CardContent")
        card1.shouldPresent(cardContentVC1, from: _parent)
        scrollView.addSubview(card1)

        i += 1.0
        let card2 = CardHighlight(frame: CGRect(x: i * _inset + (_inset / 2) + i * _width, y: 180.0 - _height, width: _width, height: _height))
        card2.backgroundColor = UIColor(red: 94 / 255, green: 112 / 255, blue: 0, alpha: 1)
        let user2 = Users.shared.users[1]
        card2.icon = user2.avatar?.image ?? UIImage(named: "avatar")
        card2.title = String(format: "%@ %@", user2.firstName!, user2.lastName!)
        card2.itemTitle = "Doormont High"
        card2.itemSubtitle = ""
        card2.textColor = UIColor.white
        card2.delegate = self
        card2.hasParallax = true
        let cardContentVC2 = UIStoryboard.Main(identifier: "CardContent")
        card2.shouldPresent(cardContentVC2, from: _parent)
        scrollView.addSubview(card2)

        i += 1.0
        let card3 = CardHighlight(frame: CGRect(x: i * _inset + (_inset / 2) + i * _width, y: 180.0 - _height, width: _width, height: _height))
        card3.backgroundColor = UIColor(red: 112 / 255, green: 0, blue: 94 / 255, alpha: 1)
        let user3 = Users.shared.users[2]
        card3.icon = user3.avatar?.image ?? UIImage(named: "avatar")
        card3.title = String(format: "%@ %@", user3.firstName!, user3.lastName!)
        card3.itemTitle = "Doormont High"
        card3.itemSubtitle = ""
        card3.textColor = UIColor.white
        card3.delegate = self
        card3.hasParallax = true
        let cardContentVC3 = UIStoryboard.Main(identifier: "CardContent")
        card3.shouldPresent(cardContentVC3, from: _parent)
        scrollView.addSubview(card3)

        i += 1.0
        let card4 = CardHighlight(frame: CGRect(x: i * _inset + (_inset / 2) + i * _width, y: 180.0 - _height, width: _width, height: _height))
        card4.backgroundColor = UIColor(red: 112 / 255, green: 0, blue: 94 / 255, alpha: 1)
        let user4 = Users.shared.users[3]
        card4.icon = user4.avatar?.image ?? UIImage(named: "avatar")
        card4.title = String(format: "%@ %@", user4.firstName!, user4.lastName!)
        card4.itemTitle = "Doormont High"
        card4.itemSubtitle = ""
        card4.textColor = UIColor.white
        card4.delegate = self
        card4.hasParallax = true
        let cardContentVC4 = UIStoryboard.Main(identifier: "CardContent")
        card4.shouldPresent(cardContentVC4, from: _parent)
        scrollView.addSubview(card4)

        i += 1.0
        let card5 = CardHighlight(frame: CGRect(x: i * _inset + (_inset / 2) + i * _width, y: 180.0 - _height, width: _width, height: _height))
        card5.backgroundColor = UIColor(red: 112 / 255, green: 0, blue: 94 / 255, alpha: 1)
        let user5 = Users.shared.users[4]
        card5.icon = user5.avatar?.image ?? UIImage(named: "avatar")
        card5.title = String(format: "%@ %@", user5.firstName!, user5.lastName!)
        card5.itemTitle = "Doormont High"
        card5.itemSubtitle = ""
        card5.textColor = UIColor.white
        card5.delegate = self
        card5.hasParallax = true
        let cardContentVC5 = UIStoryboard.Main(identifier: "CardContent")
        card5.shouldPresent(cardContentVC5, from: _parent)
        scrollView.addSubview(card5)

        i += 1.0
        let card6 = CardHighlight(frame: CGRect(x: i * _inset + (_inset / 2) + i * _width, y: 180.0 - _height, width: _width, height: _height))
        card6.backgroundColor = UIColor(red: 112 / 255, green: 0, blue: 94 / 255, alpha: 1)
        let user6 = Users.shared.users[5]
        card6.icon = user6.avatar?.image ?? UIImage(named: "avatar")
        card6.title = String(format: "%@ %@", user6.firstName!, user6.lastName!)
        card6.itemTitle = "Doormont High"
        card6.itemSubtitle = ""
        card6.textColor = UIColor.white
        card6.delegate = self
        card6.hasParallax = true
        let cardContentVC6 = UIStoryboard.Main(identifier: "CardContent")
        card6.shouldPresent(cardContentVC6, from: _parent)
        scrollView.addSubview(card6)

        i += 1.0
        let card7 = CardHighlight(frame: CGRect(x: i * _inset + (_inset / 2) + i * _width, y: 180.0 - _height, width: _width, height: _height))
        card7.backgroundColor = UIColor(red: 112 / 255, green: 0, blue: 94 / 255, alpha: 1)
        let user7 = Users.shared.users[2]
        card7.icon = user7.avatar?.image ?? UIImage(named: "avatar")
        card7.title = String(format: "%@ %@", user7.firstName!, user7.lastName!)
        card7.itemTitle = "Doormont High"
        card7.itemSubtitle = ""
        card7.textColor = UIColor.white
        card7.delegate = self
        card7.hasParallax = true
        let cardContentVC7 = UIStoryboard.Main(identifier: "CardContent")
        card7.shouldPresent(cardContentVC7, from: _parent)
        scrollView.addSubview(card7)

        scrollView.delegate = self
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 140)
        scrollView.isPagingEnabled = true

        scrollView.contentSize = scrollView.contentSize.applying(CGAffineTransform(scaleX: 910.0 / CGFloat(scrollView.contentSize.width), y: 0))
        scrollView.layoutIfNeeded()
    }

    func cardDidTapInside(card: Card) {
        UIView.animate(withDuration: 0.25) {
            card.alpha = 0.0
        }
    }

    func cardDidCloseDetailView(card: Card) {
        card.alpha = 1.0
    }

    func cardHighlightDidTapButton(card _: CardHighlight, button _: UIButton) {
        print("foo")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
