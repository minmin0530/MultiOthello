//
//  LoginNameViewController.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2022/01/10.
//

import UIKit
import RealmSwift

class LoginNameViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        let realm = try! Realm()
        let account: Results<Account> = realm.objects(Account.self)

        if account.count >= 1 {
            DispatchQueue.main.async {
                let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
                nextVC.modalPresentationStyle = .fullScreen
                self.present(nextVC, animated: true, completion: nil)
            }
        }
    }
    @IBAction func decideButtonTapped(_ sender: Any) {
        let serverRequest: ServerRequest = ServerRequest()
        serverRequest.sendServerRequest(
            urlString: "https://multi-othello.com/confirmAccountName",
            params: [
                "name": self.nameTextField.text!
            ],
            completion: self.confirmAccountName(data:))
    }
    func confirmAccountName(data: Data?) {
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
            DispatchQueue.main.async {
                let docs : Bool = (json as! NSDictionary)["result"] as! Bool
                if docs {
                    let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginPasswordViewController") as! LoginPasswordViewController
                    nextVC.configure(userName: self.nameTextField.text!)
                    nextVC.modalPresentationStyle = .fullScreen
                    self.present(nextVC, animated: true, completion: nil)

                } else {
                    print("false")
                }
            }
        } catch {
            print ("json error")
            return
        }
    }
}
