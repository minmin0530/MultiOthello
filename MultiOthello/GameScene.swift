//
//  GameScene.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2021/12/21.
//

import SocketIO
import SpriteKit
import GameplayKit
import RealmSwift
import SwiftUI

enum PuttablePieceResult {
    case pass
    case puttable
    case canNutPut
}

struct CustomData : SocketData {
    let id: String
    let x: Int
    let y: Int
    let turn: Int
    func socketRepresentation() -> SocketData {
        return ["id": id, "x": x, "y": y, "turn": turn]
    }
}
struct JoinData : SocketData {
    let tableid: String
    let name: String
    let userid: String
    func socketRepresentation() -> SocketData {
        return ["tableid": tableid, "name": name, "userid": userid]
    }
}
struct GameStartData : SocketData {
    let tableid: String
    func socketRepresentation() -> SocketData {
        return ["tableid": tableid]
    }
}
struct GameFinishData : SocketData {
    let tableid: String
    func socketRepresentation() -> SocketData {
        return ["tableid": tableid]
    }
}
class GameScene: SKScene {
    private let EMPTY_AREA = -1
    private let PUTTABLE_AREA = 777
    private var playerMaxNumber: Int?
    private var myTurn: Int?
    private var myName: String?
    private var tableID: String?
    private let manager = SocketManager(socketURL: URL(string:"https://multi-othello.com/")!, config: [.log(true), .compress])
    private var socket : SocketIOClient!
    private var dataList : NSArray! = []
    private var putData : NSArray! = []
    private var joinData : NSArray! = []
    private var gameStartData : NSArray! = []
    private var isPassTurn: Bool = false
    private var isGameFinish: Bool = false
    private var isGameStart: Bool = false
    private var isGameButtonActive: Bool = false
    private var waitGameButton: SKSpriteNode = SKSpriteNode(imageNamed: "waitGame")
    private var gameStartButton: SKSpriteNode = SKSpriteNode(imageNamed: "gameStart")
    private var gameFinishButton: SKSpriteNode = SKSpriteNode(imageNamed: "gameFinish")
    private var passTurnButton: SKSpriteNode = SKSpriteNode(imageNamed: "pass")
    private var labels: [SKLabelNode] = []
    private var boards: [[SKShapeNode]] = []
    private var boardsColorNumber: [[Int]] = []
    private var boardsCount: Int = 0
    private let COLORS: [UIColor] = [
        UIColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), // red
        UIColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0), // green
        UIColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), // blue
        UIColor.init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0), // yellow
        UIColor.init(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0), // purple
        UIColor.init(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0), // cyan
        UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0), // black
        UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), // white
        UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0), // gray
    ]
    private var turn: Int = 0
    private var points: [Int] = []
    private var gameClosure: (() -> Void)?
    func configure(tableID: String, closure: @escaping (() -> Void) ) {
        self.tableID = tableID
        gameClosure = closure
    }
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
        passTurnButton.isHidden = true
        addChild(passTurnButton)


        socket = manager.defaultSocket

        socket.on(clientEvent: .connect){ data, ack in
            print("socket connected!")
            let realm = try! Realm()
            let account: Results<Account> = realm.objects(Account.self)

            if account.count >= 1 {
                self.myName = account[0].name
                self.socket.emit("join", JoinData(tableid: self.tableID!, name: account[0].name, userid: account[0].userid))
            }
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
                self.putData = json as NSArray
            } catch {
                print("#####error")
                return
            }
        }

        socket.on("join"){data, ack in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                self.joinData = json as NSArray
            } catch {
                print("#####error")
                return
            }
        }
        socket.on("gameStart"){data, ack in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                self.gameStartData = json as NSArray
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

        if atPoint(location) == gameFinishButton {
            gameFinishButton.isHidden = true
            socket.emit("gameFinish", GameFinishData(tableid: self.tableID!))
//            self.view!.window!.rootViewController?.performSegue(withIdentifier: "presentSecond", sender: nil)
//            DispatchQueue.main.async {
            self.socket.emit("disconnect")

            gameClosure!()
//            let parentVC = self.view!.parentViewController() as! GameViewController
//            let nextVC = parentVC.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
//
//            let tableListView = nextVC.viewControllers?[1] as! TableListViewController
//            tableListView.getTableList()
//            nextVC.selectedViewController = tableListView
//            nextVC.modalPresentationStyle = .fullScreen
//            parentVC.present(nextVC, animated: true, completion: {
//                self.socket.emit("disconnect")
//                self.view?.presentScene(nil)
//            } )

//
//
//            nextVC.modalPresentationStyle = .fullScreen
//            nextVC.configure(tableID: id!)
//            parentVC.present(nextVC, animated: true, completion: nil)
//
//                if let theViewController = self.viewController { // Optional Bindingを採用。
//                    theViewController.performSegue(withIdentifier: "TabBarController", sender: self)
//                } else {
//                    print("Property viewController is nil") // viewControllerに、なにも代入されていなかったら、こちらが実行。
//                }
//                let UINavigationController = self.view!.window!.rootViewController?.tabBarController!.viewControllers?[1]
//                let tableListView = self.view!.window!.rootViewController?.tabBarController!.viewControllers?[1] as! TableListViewController
//                tableListView.getTableList()
//                self.view!.window!.rootViewController?.tabBarController!.selectedViewController = UINavigationController
//            }

            return
        }

        if atPoint(location) == gameStartButton {
            isGameStart = true
            gameStartButton.isHidden = true
            socket.emit("gameStart", GameStartData(tableid: self.tableID!))
            return
        }

        guard let node = atPoint(location) as? SKShapeNode else {
            return
        }

        if isGameStart == false {
            return
        }

        if myTurn == (turn % playerMaxNumber!) {
            var y = 0
            for_i : for boardRow in boards {
                var x = 0
                for board in boardRow {
                    if node == board {
                        // 空地ではない場合、処理を抜ける
                        if boardsColorNumber[y][x] != PUTTABLE_AREA &&
                            (turn >= (playerMaxNumber! * 2)) {
                            break for_i
                        }
//                        if totalCount >= playerMaxNumber! * 2 && canIPutAPiece(x: x, y: y, turn: turn) == .canNutPut {
//                            break for_i
//                        }

                        for yy in 0...7 {
                            for xx in 0...7 {
                                if boardsColorNumber[yy][xx] == PUTTABLE_AREA {
                                    boardsColorNumber[yy][xx] = EMPTY_AREA
                                }
                            }
                        }

                        boards[y][x].fillColor = COLORS[turn % playerMaxNumber!]
                        boardsColorNumber[y][x] = turn % playerMaxNumber!


                        socket.emit("put", CustomData(id: self.tableID!, x: x, y: y, turn: turn))

//                        turn += 1
                        break for_i
                    }
                    x += 1
                }
                y += 1
            }

//            fillColorBoards()
//            pointsLabel()
        }
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
        for yy in 0...7 {
            for xx in 0...7 {
                if boardsColorNumber[yy][xx] == PUTTABLE_AREA {
                    boardsColorNumber[yy][xx] = EMPTY_AREA
                }
            }
        }
        for yy in 0...7 {
            for xx in 0...7 {
                if boardsColorNumber[yy][xx] == PUTTABLE_AREA || boardsColorNumber[yy][xx] == EMPTY_AREA {
                    boards[yy][xx].fillColor = UIColor.init(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
                }
            }
        }
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

    func whereCanIPutAPiece(t: Int) {
        let turn = t % playerMaxNumber!
        for yy in 0...7 {
            for xx in 2...7 {
                if boardsColorNumber[yy][xx] == turn {
                    var xxxx = 0
                    for xxx in 1...xx {
                        if boardsColorNumber[yy][xx - xxx] != EMPTY_AREA &&
                           boardsColorNumber[yy][xx - xxx] != turn &&
                           boardsColorNumber[yy][xx - xxx] != PUTTABLE_AREA {
                            xxxx = xxx
                        } else {
                            break
                        }
                    }
                    if xxxx >= 1 && xxxx < xx && boardsColorNumber[yy][xx - xxxx - 1] == EMPTY_AREA {
                        boardsColorNumber[yy][xx - xxxx - 1] = PUTTABLE_AREA
                        break
                    }
                }
            }
            for xx in 0...5 {
                if boardsColorNumber[yy][xx] == turn && xx < 6 {
                    var xxxx = 0
                    for xxx in (xx + 1)...6 {
                        if boardsColorNumber[yy][xxx] != EMPTY_AREA &&
                           boardsColorNumber[yy][xxx] != turn &&
                           boardsColorNumber[yy][xxx] != PUTTABLE_AREA {
                            xxxx = xxx
                        } else {
                            break
                        }
                    }
                    if xxxx >= 1 && boardsColorNumber[yy][xxxx + 1] == EMPTY_AREA {
                        boardsColorNumber[yy][xxxx + 1] = PUTTABLE_AREA
                        break
                    }
                }
            }
        }
        for xx in 0...7 {
            for yy in 2...7 {
                if boardsColorNumber[yy][xx] == turn {
                    var yyyy = 0
                    for yyy in 1...yy {
                        if boardsColorNumber[yy - yyy][xx] != EMPTY_AREA &&
                           boardsColorNumber[yy - yyy][xx] != turn &&
                           boardsColorNumber[yy - yyy][xx] != PUTTABLE_AREA {
                            yyyy = yyy
                        } else {
                            break
                        }
                    }
                    if yyyy >= 1 && yyyy < yy && boardsColorNumber[yy - yyyy - 1][xx] == EMPTY_AREA {
                        boardsColorNumber[yy - yyyy - 1][xx] = PUTTABLE_AREA
                        break
                    }
                }
            }
            for yy in 0...5 {
                if boardsColorNumber[yy][xx] == turn && yy < 6 {
                    var yyyy = 0
                    for yyy in (yy + 1)...6 {
                        if boardsColorNumber[yyy][xx] != EMPTY_AREA &&
                           boardsColorNumber[yyy][xx] != turn &&
                           boardsColorNumber[yyy][xx] != PUTTABLE_AREA {
                            yyyy = yyy
                        } else {
                            break
                        }
                    }
                    if yyyy >= 1 && boardsColorNumber[yyyy + 1][xx] == EMPTY_AREA {
                        boardsColorNumber[yyyy + 1][xx] = PUTTABLE_AREA
                        break
                    }
                }
            }
        }
        for xx in 0...7 {
            for yy in 0...7 {

                    if boardsColorNumber[yy][xx] == turn {
                        var zzzz = 0
                        for zzz in 1...7 {
                            if yy >= zzz && xx >= zzz &&
                               boardsColorNumber[yy - zzz][xx - zzz] != EMPTY_AREA &&
                               boardsColorNumber[yy - zzz][xx - zzz] != turn &&
                               boardsColorNumber[yy - zzz][xx - zzz] != PUTTABLE_AREA {
                                zzzz = zzz
                            } else {
                                break
                            }
                        }
                        if zzzz >= 1 && yy > zzzz && xx > zzzz && boardsColorNumber[yy - zzzz - 1][xx - zzzz - 1] == EMPTY_AREA {
                            boardsColorNumber[yy - zzzz - 1][xx - zzzz - 1] = PUTTABLE_AREA
//                            break
                        }
                    }
            }
        }
        for xx in 0...7 {
            for yy in 0...7 {

                    if boardsColorNumber[yy][xx] == turn {
                        var zzzz = 0
                        for zzz in 1...6 {
                            if yy + zzz <= 7 && xx + zzz <= 7 &&
                               boardsColorNumber[yy + zzz][xx + zzz] != EMPTY_AREA &&
                               boardsColorNumber[yy + zzz][xx + zzz] != turn &&
                               boardsColorNumber[yy + zzz][xx + zzz] != PUTTABLE_AREA {
                                zzzz = zzz
                            } else {
                                break
                            }
                        }
                        if zzzz >= 1 && yy + zzzz < 7 && xx + zzzz < 7 && boardsColorNumber[yy + zzzz + 1][xx + zzzz + 1] == EMPTY_AREA {
                            boardsColorNumber[yy + zzzz + 1][xx + zzzz + 1] = PUTTABLE_AREA
//                            break
                        }
                    }
            }
        }
        for xx in 0...7 {
            for yy in 0...7 {

                if boardsColorNumber[yy][xx] == turn {
                    var zzzz = 0
                    for zzz in 1...6 {
                        if yy + zzz <= 7 && xx >= zzz &&
                           boardsColorNumber[yy + zzz][xx - zzz] != EMPTY_AREA &&
                           boardsColorNumber[yy + zzz][xx - zzz] != turn &&
                           boardsColorNumber[yy + zzz][xx - zzz] != PUTTABLE_AREA {
                            zzzz = zzz
                        } else {
                            break
                        }
                    }
                    if zzzz >= 1 && yy + zzzz < 7 && xx > zzzz && boardsColorNumber[yy + zzzz + 1][xx - zzzz - 1] == EMPTY_AREA {
                        boardsColorNumber[yy + zzzz + 1][xx - zzzz - 1] = PUTTABLE_AREA
//                            break
                    }
                }
            }
        }
        for xx in 0...7 {
            for yy in 0...7 {

                if boardsColorNumber[yy][xx] == turn {
                    var zzzz = 0
                    for zzz in 1...6 {
                        if xx + zzz <= 7 && yy >= zzz &&
                           boardsColorNumber[yy - zzz][xx + zzz] != EMPTY_AREA &&
                           boardsColorNumber[yy - zzz][xx + zzz] != turn &&
                           boardsColorNumber[yy - zzz][xx + zzz] != PUTTABLE_AREA {
                            zzzz = zzz
                        } else {
                            break
                        }
                    }
                    if zzzz >= 1 && xx + zzzz < 7 && yy > zzzz && boardsColorNumber[yy - zzzz - 1][xx + zzzz + 1] == EMPTY_AREA {
                        boardsColorNumber[yy - zzzz - 1][xx + zzzz + 1] = PUTTABLE_AREA
//                            break
                    }
                }
            }
        }
    }
    func canIPutAPiece(x: Int, y: Int, t: Int) -> PuttablePieceResult {
        if boardsColorNumber[y][x] == PUTTABLE_AREA {
            return .puttable
        } else {
            return .canNutPut
        }
    }
    func reversi(x: Int, y: Int, t: Int) {
        let turn = t % playerMaxNumber!
        for_xx: for xx in 0...x {
            if boardsColorNumber[y][xx] == turn && (xx + 1) < x {
                for xxx in (xx + 1)...(x - 1) {
                    if boardsColorNumber[y][xxx] == EMPTY_AREA {
                        break for_xx
                    }
                    if boardsColorNumber[y][xxx] == turn {
                        continue for_xx
                    }
                }
                for xxx in xx...x {
                    boardsColorNumber[y][xxx] = turn
                }
                break
            }
        }
        if x < 7 {
            for_xx : for xx in (x + 1)...7 {
                if boardsColorNumber[y][xx] == turn && (x + 1) < xx {
                    for xxx in (x + 1)...(xx - 1) {
                        if boardsColorNumber[y][xxx] == EMPTY_AREA {
                            break for_xx
                        }
                        if boardsColorNumber[y][xxx] == turn {
                            continue for_xx
                        }
                    }
                    for xxx in x...xx {
                        boardsColorNumber[y][xxx] = turn
                    }
                    break
                }
            }
        }

        for_yy: for yy in 0...y {
            if boardsColorNumber[yy][x] == turn && (yy + 1) < y {
                for yyy in (yy + 1)...(y - 1) {
                    if boardsColorNumber[yyy][x] == EMPTY_AREA {
                        break for_yy
                    }
                    if boardsColorNumber[yyy][x] == turn {
                        continue for_yy
                    }
                }

                for yyy in yy...y {
                    boardsColorNumber[yyy][x] = turn
                }
                break
            }
        }
        if y < 7 {
            for_yy: for yy in (y + 1)...7 {
                if boardsColorNumber[yy][x] == turn && (y + 1) < yy {
                    for yyy in (y + 1)...(yy - 1) {
                        if boardsColorNumber[yyy][x] == EMPTY_AREA {
                            break for_yy
                        }
                        if boardsColorNumber[yyy][x] == turn {
                            continue for_yy
                        }
                    }
                    for yyy in y...yy {
                        boardsColorNumber[yyy][x] = turn
                    }
                    break
                }
            }
        }

        for_zz: for zz in 1...7 {
            if x + zz <= 7 && y + zz <= 7 && boardsColorNumber[y + zz][x + zz] == turn && zz > 1 {
                for zzz in 1...(zz - 1) {
                    if boardsColorNumber[y + zzz][x + zzz] == EMPTY_AREA {
                        break for_zz
                    }
                    if boardsColorNumber[y + zzz][x + zzz] == turn {
                        continue for_zz
                    }
                }
                for zzz in 0...zz {
                    boardsColorNumber[y + zzz][x + zzz] = turn
                }
                break
            }
        }
        for_zz: for zz in 1...7 {
            if x - zz >= 0 && y - zz >= 0 && boardsColorNumber[y - zz][x - zz] == turn && zz > 1 {
                for zzz in 1...(zz - 1) {
                    if boardsColorNumber[y - zzz][x - zzz] == EMPTY_AREA {
                        break for_zz
                    }
                    if boardsColorNumber[y - zzz][x - zzz] == turn {
                        continue for_zz
                    }
                }
                for zzz in 1...(zz - 1) {
                    boardsColorNumber[y - zzz][x - zzz] = turn
                }
                break
            }
        }

        for_zz: for zz in 1...7 {
            if x + zz <= 7 && y - zz >= 0 && boardsColorNumber[y - zz][x + zz] == turn && zz > 1 {
                for zzz in 1...(zz - 1) {
                    if boardsColorNumber[y - zzz][x + zzz] == EMPTY_AREA {
                        break for_zz
                    }
                    if boardsColorNumber[y - zzz][x + zzz] == turn {
                        continue for_zz
                    }
                }
                for zzz in 0...zz {
                    boardsColorNumber[y - zzz][x + zzz] = turn
                }
                break
            }
        }
        for_zz: for zz in 1...7 {
            if x - zz >= 0 && y + zz <= 7 && boardsColorNumber[y + zz][x - zz] == turn && zz > 1 {
                for zzz in 1...(zz - 1) {
                    if boardsColorNumber[y + zzz][x - zzz] == EMPTY_AREA {
                        break for_zz
                    }
                    if boardsColorNumber[y + zzz][x - zzz] == turn {
                        continue for_zz
                    }
                }
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
//        labels[0].text = "@@@@@"
//        var i = 0
//        for doc in dataList {
//            if ( (doc as! NSDictionary)["x"] as! Double) > 0 {
//                for t in 0...7 {
//                    labels[t].text = "●Success!!"
//                }
//
//            }
////            ( (doc as! NSDictionary)["y"] as! Double)
////            squres[i].fillColor = UIColor.init(
////                red: (doc as! NSDictionary)["r"] as! CGFloat / 255.0,
////                green: (doc as! NSDictionary)["g"] as! CGFloat / 255.0,
////                blue: (doc as! NSDictionary)["b"] as! CGFloat / 255.0,
////                alpha: 1.0)
//            i += 1
//        }

        guard let joinData = joinData else { return }
        for doc in joinData {
            let owner: String = ( (doc as! NSDictionary)["ownername"] as! String)

            if isGameButtonActive == false {
                isGameButtonActive = true
                if owner == myName {
                    addChild(gameStartButton)
                } else {
                    addChild(waitGameButton)
                }
            }
            var i = 0
            let players: NSArray = ( (doc as! NSDictionary)["players"] as! NSArray)
            for player in players {
                let name: String = ( (player as! NSDictionary)["name"] as! String)
                labels[i].text = "●" + name
                if name == myName {
                    myTurn = i
                }
                i += 1
                playerMaxNumber = i
            }
        }

        guard let gameStartData = gameStartData else { return }
        for doc in gameStartData {
            let gameStartTableId: String = ( (doc as! NSDictionary)["tableid"] as! String)

            isGameStart = true
            waitGameButton.isHidden = true

        }


        guard let putData = putData else { return }
        for doc in putData {
            for yy in 0...7 {
                for xx in 0...7 {
                    if boardsColorNumber[yy][xx] == PUTTABLE_AREA {
                        boardsColorNumber[yy][xx] = EMPTY_AREA
                    }
                }
            }

            let x: Int = ( (doc as! NSDictionary)["x"] as! Int)
            let y: Int = ( (doc as! NSDictionary)["y"] as! Int)
            let t: Int = ( (doc as! NSDictionary)["turn"] as! Int)
            if t >= 63 && isGameFinish == false {
                isGameFinish = true
                addChild(gameFinishButton)
            }
            if (x == -1 && y == -1) == false {

                boards[y][x].fillColor = COLORS[t % playerMaxNumber!]
                boardsColorNumber[y][x] = t % playerMaxNumber!
                reversi(x: x, y: y, t: t)
                turn = t + 1
                fillColorBoards()
                pointsLabel()

                if (turn % playerMaxNumber!) == myTurn && turn >= playerMaxNumber! * 2 {
                    whereCanIPutAPiece(t: turn)

                    var isPass: Bool = true
                    for yy in 0...7 {
                        for xx in 0...7 {
                            if boardsColorNumber[yy][xx] == PUTTABLE_AREA {
                                isPass = false
                                boards[yy][xx].fillColor = COLORS[8]
                            }
                        }
                    }
                    if isPass {
                        socket.emit("put", CustomData(id: self.tableID!, x: -1, y: -1, turn: turn))
                        passTurnButton.isHidden = false
                        fillColorBoards()
                        pointsLabel()
                    } else {
                        passTurnButton.isHidden = true
                    }
                }
            } else {
                turn += 1
                if (turn % playerMaxNumber!) == myTurn {
                    whereCanIPutAPiece(t: turn)
                    for yy in 0...7 {
                        for xx in 0...7 {
                            if boardsColorNumber[yy][xx] == PUTTABLE_AREA {
                                boards[yy][xx].fillColor = COLORS[8]
                            }
                        }
                    }
                }
            }
            self.putData = nil
            break
        }
    }
}
