//
//  TableListViewController.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2022/01/03.
//

import UIKit

class Table {
    var dateTime: String = ""
    var maxNumber: Int = 0
}

class TableListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var tableList: [Table] = []
    @IBOutlet weak private var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(onRefresh(_:)), for: .valueChanged)

        getTableList()
    }

    @objc private func onRefresh(_ sender: AnyObject) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.getTableList()
            self?.tableView.refreshControl?.endRefreshing()
        }
    }

    func tableViewReload(data: Data?) {
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
            DispatchQueue.main.async {
                let docs : NSArray = (json as! NSDictionary)["tableList"] as! NSArray
                self.tableList = []
                for doc in docs {
                    let table = Table()
                    table.dateTime = (doc as! NSDictionary)["datetime"] as! String
                    table.maxNumber = (doc as! NSDictionary)["maxnumber"] as! Int
                    self.tableList.append(table)
                }
            }
        } catch {
            print ("json error")
            return
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }

    }
    func getTableList() {
        let serverRequest: ServerRequest = ServerRequest()
        serverRequest.sendServerGetRequest(
            urlString: "https://multi-othello.com/getTableList",
            completion: self.tableViewReload)
    }
}

extension TableListViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "TableView", for: indexPath) as! TableViewCell
        // カスタムセルにRealmの情報を反映
        cell.configure(dateTime: tableList[indexPath.row].dateTime, maxNumber: tableList[indexPath.row].maxNumber)
        return cell
    }

//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
//                   forRowAt indexPath: IndexPath) {
////        deleteTodoItem(at: indexPath.row)
//    }
}
