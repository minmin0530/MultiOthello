//
//  GameScene.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2021/12/21.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var labels: [SKLabelNode] = []
    private var boards: [[SKShapeNode]] = [[]]
    private var boardsColorNumber: [[Int]] = [[]]
    private let COLORS: [UIColor] = [
        UIColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), // red
        UIColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0), // green
        UIColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), // blue
        UIColor.init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0), // yellow
        UIColor.init(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0), // purple
        UIColor.init(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0), // cyan
        UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0), // black
        UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)  // white
    ]
    private var turn: Int = 0
    private var points: [Int] = []
    override func didMove(to view: SKView) {

        let BOARD_SIZE: CGFloat = self.frame.width / 8
        let LINE_WIDTH: CGFloat = 4
        for x in 0...7 {
            var row: [SKShapeNode] = []
            var boardsColorNumberRow: [Int] = []
            for y in 0...7 {
                let board: SKShapeNode = SKShapeNode(rect: CGRect(x: CGFloat(x) * BOARD_SIZE - self.frame.width / 2, y: CGFloat(y) * BOARD_SIZE - self.frame.width / 2, width: BOARD_SIZE, height: BOARD_SIZE))
                board.fillColor = UIColor.init(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
                board.strokeColor = .black
                board.lineWidth = LINE_WIDTH
                addChild(board)
                row.append(board)
                boardsColorNumberRow.append(-1)
            }
            boards.append(row)
            boardsColorNumber.append(boardsColorNumberRow)
        }


        for i in 0...7 {
            points.append(0)
            let label: SKLabelNode = SKLabelNode(text: "●12345678901234567890")
            label.position.x = -self.frame.width / 2 + label.frame.width / 2
            label.position.y = self.frame.height / 2 - CGFloat(i * 35) - 35
            label.fontColor = COLORS[i]
            labels.append(label)
            addChild(label)
        }

    }
    
    
    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.green
//            self.addChild(n)
//        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.blue
//            self.addChild(n)
//        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.red
//            self.addChild(n)
//        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
        
//        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
        let location = touches.first!.location(in: self)
        guard let node = atPoint(location) as? SKShapeNode else {
            return
        }
        var y = 0
        for_i : for boardRow in boards {
            var x = 0
            for board in boardRow {
                if node == board {
                    board.fillColor = COLORS[turn]
                    boardsColorNumber[y][x] = turn
                    turn += 1
                    if turn > 7 {
                        turn = 0
                    }
                    break for_i
                }
                x += 1
            }
            y += 1
        }

        for t in 0...7 {
            points[t] = 0
            for boardRow2 in boardsColorNumber {
                for board2 in boardRow2 {
                    if board2 == t {
                        points[t] += 1
                    }
                }
            }
            labels[t].text = "●" + String(points[t])
        }


    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
