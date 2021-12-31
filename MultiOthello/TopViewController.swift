//
//  TopViewController.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2021/12/31.
//

import UIKit

class TopViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.isHidden = true
        dismiss(animated: false, completion: nil)
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: false, completion: nil)
    }
}
