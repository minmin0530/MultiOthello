//
//  GameScene.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2021/12/21.
//

import SocketIO
import SpriteKit
import GameplayKit

struct CustomData : SocketData {
    let x: Int
    let y: Int
    let turn: Int
    func socketRepresentation() -> SocketData {
        return ["x": x, "y": y, "turn": turn]
    }
}

class GameScene: SKScene {

    private let manager = SocketManager(socketURL: URL(string:"https://multi-othello.com/")!, config: [.log(true), .compress])
    private var socket : SocketIOClient!
    private var dataList : NSArray! = []
    private var putData : NSArray! = []
    private var labels: [SKLabelNode] = []
    private var boards: [[SKShapeNode]] = []
    private var boardsColorNumber: [[Int]] = []
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
        for y in 0...7 {
            var row: [SKShapeNode] = []
            var boardsColorNumberRow: [Int] = []
            for x in 0...7 {
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


        socket = manager.defaultSocket

        socket.on(clientEvent: .connect){ data, ack in
            print("socket connected!")
        }

        socket.on(clientEvent: .disconnect){data, ack in
            print("socket disconnected!")
        }

        socket.on("drag"){data, ack in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                self.dataList = json[0] as? NSArray
            } catch {
                print("#####error")
                return
            }
        }

        socket.on("put"){data, ack in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                self.putData = json as? NSArray
            } catch {
                print("#####error")
                return
            }
        }

        socket.connect()

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
                    if boardsColorNumber[y][x] != -1 {
                        break for_i
                    }
                    board.fillColor = COLORS[turn]
                    boardsColorNumber[y][x] = turn


                    socket.emit("put", CustomData(x: x, y: y, turn: turn))
                    reversi(x: x, y: y, turn: turn)

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

        fillColorBoards()
        pointsLabel()
    }

    func pointsLabel() {
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
    func fillColorBoards() {
        for t in 0...7 {
            for yy in 0...7 {
                for xx in 0...7 {
                    if boardsColorNumber[yy][xx] == t {
                        boards[yy][xx].fillColor = COLORS[t]
                    }
                }
            }
        }
    }

    func reversi(x: Int, y: Int, turn: Int) {

        for xx in 0...x {
            if boardsColorNumber[y][xx] == turn {
                for xxx in xx...x {
                    boardsColorNumber[y][xxx] = turn
                }
                break
            }
        }
        if x < 7 {
            for xx in (x + 1)...7 {
                if boardsColorNumber[y][xx] == turn {
                    for xxx in x...xx {
                        boardsColorNumber[y][xxx] = turn
                    }
                    break
                }
            }
        }

        for yy in 0...y {
            if boardsColorNumber[yy][x] == turn {
                for yyy in yy...y {
                    boardsColorNumber[yyy][x] = turn
                }
                break
            }
        }
        if y < 7 {
            for yy in (y + 1)...7 {
                if boardsColorNumber[yy][x] == turn {
                    for yyy in y...yy {
                        boardsColorNumber[yyy][x] = turn
                    }
                    break
                }
            }
        }

        for zz in 1...7 {
            if x + zz <= 7 && y + zz <= 7 && boardsColorNumber[y + zz][x + zz] == turn {
                for zzz in 0...zz {
                    boardsColorNumber[y + zzz][x + zzz] = turn
                }
                break
            }
        }
        for zz in 1...7 {
            if x - zz >= 0 && y - zz >= 0 && boardsColorNumber[y - zz][x - zz] == turn {
                for zzz in 0...zz {
                    boardsColorNumber[y - zzz][x - zzz] = turn
                }
                break
            }
        }

        for zz in 1...7 {
            if x + zz <= 7 && y - zz >= 0 && boardsColorNumber[y - zz][x + zz] == turn {
                for zzz in 0...zz {
                    boardsColorNumber[y - zzz][x + zzz] = turn
                }
                break
            }
        }
        for zz in 1...7 {
            if x - zz >= 0 && y + zz <= 7 && boardsColorNumber[y + zz][x - zz] == turn {
                for zzz in 0...zz {
                    boardsColorNumber[y + zzz][x - zzz] = turn
                }
                break
            }
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
        labels[0].text = "@@@@@"
        var i = 0
        for doc in dataList {
            if ( (doc as! NSDictionary)["x"] as! Double) > 0 {
                for t in 0...7 {
                    labels[t].text = "●Success!!"
                }

            }
//            ( (doc as! NSDictionary)["y"] as! Double)
//            squres[i].fillColor = UIColor.init(
//                red: (doc as! NSDictionary)["r"] as! CGFloat / 255.0,
//                green: (doc as! NSDictionary)["g"] as! CGFloat / 255.0,
//                blue: (doc as! NSDictionary)["b"] as! CGFloat / 255.0,
//                alpha: 1.0)
            i += 1
        }

        guard let putData = putData else { return }
        for doc in putData {
            let x: Int = ( (doc as! NSDictionary)["x"] as! Int)
            let y: Int = ( (doc as! NSDictionary)["y"] as! Int)
            let t: Int = ( (doc as! NSDictionary)["turn"] as! Int)
            boards[y][x].fillColor = COLORS[t]
            boardsColorNumber[y][x] = t
            reversi(x: x, y: y, turn: t)

            turn = t + 1
            if turn > 7 {
                turn = 0
            }
            fillColorBoards()
            pointsLabel()
        }


    }
}
