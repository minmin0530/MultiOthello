//
//  GameViewController.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2021/12/21.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    var tableID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = GameScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFit
                scene.configure(tableID: self.tableID!, closure: {
                    let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
                    let tableListView = nextVC.viewControllers?[1] as! TableListViewController
                    tableListView.getTableList()
                    nextVC.selectedViewController = tableListView
                    nextVC.modalPresentationStyle = .fullScreen
                    self.present(nextVC, animated: true, completion: {
                        view.presentScene(nil)
                    })
                })
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    func configure(tableID: String) {
        self.tableID = tableID
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
