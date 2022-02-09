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
    @IBOutlet weak var tableNameLabel: UILabel!
    private var id: String?
    func configure(dateTime: String, maxNumber: Int, tableName: String, id: String) {
        self.id = id
        self.dateTimeLabel.text = dateTime
        self.maxNumberLabel.text = String(maxNumber) + "人"
        if tableName == "" {
            self.tableNameLabel.text = "no name"
        } else {
            self.tableNameLabel.text = tableName
        }
    }
    @IBAction func joinButtonTapped(_ sender: Any) {
        let parentVC = self.parentViewController() as! TableListViewController
        let nextVC = parentVC.storyboard?.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
        nextVC.modalPresentationStyle = .fullScreen
        nextVC.configure(tableID: id!)
        parentVC.present(nextVC, animated: true, completion: nil)
    }
}
