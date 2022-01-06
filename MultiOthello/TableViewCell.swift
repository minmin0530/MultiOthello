//
//  TableViewCell.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2022/01/03.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var dateTimeLabel: UILabel!

    @IBOutlet weak var maxNumberLabel: UILabel!
    func configure(dateTime: String, maxNumber: Int) {
        self.dateTimeLabel.text = dateTime
        self.maxNumberLabel.text = String(maxNumber) + "人"
    }
}
