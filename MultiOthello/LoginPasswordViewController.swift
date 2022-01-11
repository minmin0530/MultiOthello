//
//  LoginPasswordViewController.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2022/01/10.
//

import UIKit
import RealmSwift

class LoginPasswordViewController: UIViewController {
    var userName: String?

    @IBOutlet weak var password: UITextField!

    @IBOutlet weak var confirmPassword: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    func configure(userName: String) {
        self.userName = userName
    }
    @IBAction func decideButtonTapped(_ sender: Any) {
        if password.text?.isEmpty == false {
            if password.text == confirmPassword.text {
                let serverRequest: ServerRequest = ServerRequest()
                serverRequest.sendServerRequest(
                    urlString: "https://multi-othello.com/createAccount",
                    params: [
                        "name": self.userName!,
                        "password": self.password.text!
                    ],
                    completion: self.createAccount(data:))
            }
        }
    }

    func createAccount(data: Data?) {
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
            DispatchQueue.main.async {
                let userid : String = (json as! NSDictionary)["userid"] as! String
                let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as! TabBarController


                let realm = try! Realm()

                let account = Account()
                account.userid = userid
                account.name = self.userName!
                account.password = self.password.text!
                try! realm.write {
                    realm.add(account)
                }


                nextVC.modalPresentationStyle = .fullScreen
                self.present(nextVC, animated: true, completion: nil)
            }
        } catch {
            print ("json error")
            return
        }
    }
}
