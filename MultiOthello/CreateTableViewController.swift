//
//  CreateTableViewController.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2022/01/03.
//

import UIKit
import RealmSwift

class CreateTableViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak private var pickerView: UIPickerView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var tableNameTextField: UITextField!
    private var maxNumber: Int = 3
    private let dataList = [ "3", "4", "5", "6", "7" ]
    override func viewDidLoad() {
        super.viewDidLoad()

        pickerView.dataSource = self
        pickerView.delegate = self
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataList.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataList[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        maxNumber = row + 3
    }
    @IBAction func createTableButtonTapped(_ sender: Any) {
        let realm = try! Realm()
        let account: Results<Account> = realm.objects(Account.self)

        let serverRequest: ServerRequest = ServerRequest()
        serverRequest.sendServerRequest(
            urlString: "https://multi-othello.com/createTable",
            params: [
                "datetime": self.datePicker.date.toStringWithCurrentLocale(),
                "maxnumber": self.maxNumber,
                "tablename": self.tableNameTextField.text!,
                "ownerid": account[0].userid,
                "ownername": account[0].name
            ],
            completion: self.sceneChange(data:))
    }

    func sceneChange(data: Data) {
        DispatchQueue.main.async {
            let UINavigationController = self.tabBarController?.viewControllers?[1]
            let tableListView = self.tabBarController?.viewControllers?[1] as! TableListViewController
            tableListView.getTableList()
            self.tabBarController?.selectedViewController = UINavigationController
        }
    }
}

extension Date {
    func toStringWithCurrentLocale() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: self)
    }
}
