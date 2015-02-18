//
//  GameScene.swift
//  TestForCollision
//
//  Created by Xiaoyu Chen on 2/2/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import SpriteKit
import MultipeerConnectivity
import CoreMotion

struct nodeInfo {
    var x: CGFloat
    var y: CGFloat
    var dx: CGFloat
    var dy: CGFloat
    var dt: CGFloat
    var index: UInt16
}

struct Opponent {
    var nodes: [SKSpriteNode]
    var updated: [Bool]
    var info: [nodeInfo]
    var color: PlayerColors
    var lastCount: UInt32
    var deleteIndex: Int
}

enum PlayerColors: Int{
    case Green = 0, Red, Yellow, Blue
}

enum ScrollDirection: Int{
    case up = 0, down, left, right
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var margin: CGFloat!
    var scrollDirection: ScrollDirection!
    var scrolling = false
    var anchorPointVel = CGVector(dx: 0, dy: 0)
    var scrollingFrameDuration = CGFloat(30)
    
    var subscene_index = 1
    let subscene_count_horizontal = 2
    let subscene_count_vertical = 2
    
    var myNodes: [SKSpriteNode] = []
    var selected: Bool = false
    var locked: Bool = false
    var selectedNode: SKSpriteNode!
    var launchTime: NSDate!
    var launchPoint: CGPoint!
    
//    var opponents: [SKSpriteNode] = []
//    var opponentsUpdated: [Bool] = []
//    var opponentsInfo: [nodeInfo] = []
//    var count: UInt16 = 0
//    var opponentDeleteIndex = -1
    
    // Opponents Setting
    var opponents: Dictionary<Int, Opponent> = Dictionary<Int, Opponent>()
    
    var myDeadNodes: [Int] = []
    
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    var currentTime: NSDate!
    
    var c: UInt32 = 0
//    var lastCount: UInt32 = 0
    
    //node info
//    var currentInfo: nodeInfo!
    var offset: CGFloat!
    
    //physics constants
    let maxSpeed = 600
    
    //hard coded!!
    let latency = 0.17
    
    var playerColor: PlayerColors!
    var gameOver: Bool = false
    
    
    func setUpPlayerColors(playerColor: PlayerColors, playerID: Int) {
        switch playerColor {
        case .Green:
            setUpPlayers("node1", playerID: playerID)
        case .Red:
                setUpPlayers("node2", playerID: playerID)
        case .Yellow:
                setUpPlayers("node3", playerID: playerID)
        default:
            println("error in setup player color")
        }
    }
    
    func setUpPlayers(spriteName: String, playerID: Int){
        var node1: SKSpriteNode!
        var count: UInt16 = 0
        enumerateChildNodesWithName(spriteName){node, _ in
            node1 = node as SKSpriteNode
            node1.physicsBody = SKPhysicsBody(circleOfRadius: node1.size.width / 2 - 10)
            node1.physicsBody?.linearDamping = 0
            node1.physicsBody?.restitution = 1
            if playerID != self.connection.playerID {
                self.opponents[playerID]?.nodes.append(node1)
                self.opponents[playerID]?.updated.append(false)
                self.opponents[playerID]?.info.append(nodeInfo(x: node1.position.x, y: node1.position.y, dx: 0, dy: 0, dt: 0, index: count))
                count++
                
            } else {
                self.myNodes.append(node1)
            }
        }
    }
    
    func getPlayerImageName(playerColor: PlayerColors, isSelected: Bool) -> String {
        if !isSelected {
            switch playerColor {
            case .Green:
                return "80x80_green_ball"
            case .Red:
                return "80x80_red_ball"
            case .Yellow:
                return "80x80_yellow_ball"
            case .Blue:
                return "80x80_blue_ball"
            }
        } else {
            switch playerColor {
            case .Green:
                return "80x80_green"
            case .Red:
                return "80x80_red"
            case .Yellow:
                return "80x80_blue"
            case .Blue:
                return "80x80_blue_ball"
            }
        }
    }
    
    override func didMoveToView(view: SKView) {
        
        connection.gameState = .InGame
        
        size = CGSize(width: 1024, height: 768)
        
        playerColor = PlayerColors(rawValue: connection.playerID)
        setUpPlayerColors(playerColor, playerID: connection.playerID)
        println("playerID is \(connection.playerID)")
        
        for var index = 0; index < connection.maxPlayer; ++index {
            if connection.playerID != index {
                let color = PlayerColors(rawValue: index)
                opponents[index] = Opponent(nodes: [SKSpriteNode](), updated: [Bool](), info: [nodeInfo](), color: color!, lastCount: UInt32(0), deleteIndex: -1)
                setUpPlayerColors(color!, playerID: index)
            }
        }
        
        /* Setup your scene here */

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
    }
    
    func randomPos() -> CGPoint{
        return CGPoint(x: CGFloat.random(min: 200, max: size.width - 200), y: CGFloat.random(min: 0 + 200, max: size.height - 2 * margin - 200))
    }
    
    func closeEnough(point1: CGPoint, point2: CGPoint) -> Bool{
        offset = point1.distanceTo(point2)
        if offset >= 10{
            return false
        }
        return true
    }
    
    func update_peer_dead_reckoning(){
        for (id, var player) in opponents{
            
            let currentOppNodes = player.nodes
            
            for var index = 0; index < player.updated.count; ++index {
                if player.updated[index] == true {
                    
                    let currentNodeInfo = player.info[index]
                    
                    if closeEnough(CGPoint(x: currentNodeInfo.x, y: currentNodeInfo.y), point2: currentOppNodes[index].position) == true {
                        currentOppNodes[index].physicsBody!.velocity = CGVector(dx: currentNodeInfo.dx, dy: currentNodeInfo.dy)
                    }
                    else {
                        currentOppNodes[index].physicsBody!.velocity = CGVector(dx: currentNodeInfo.dx + (currentNodeInfo.x - currentOppNodes[index].position.x), dy: currentNodeInfo.dy + (currentNodeInfo.y - currentOppNodes[index].position.y))
                    }
                    
                    player.updated[index] = false
                }

            }
            opponents[id] = player
        }
    }
    
    func deleteMyNode(index: Int){
        myNodes[index].removeFromParent()
        myNodes.removeAtIndex(index)
        sendDead(index)
    }
    
    func deleteOpponent(playerID: Int, index: Int){
        opponents[playerID]?.nodes[index].removeFromParent()
        opponents[playerID]?.nodes.removeAtIndex(index)
        opponents[playerID]?.info.removeAtIndex(index)
        opponents[playerID]?.updated.removeAtIndex(index)
    }
    
    func withinBorder(pos: CGPoint) -> Bool{
        if pos.x < 0 || pos.x > size.width * 2 || pos.y < margin || pos.y > 2 * size.height - margin{
            return false
        }
        return true
    }
    
    override func update(currentTime: CFTimeInterval) {
        
        if !gameOver {
            checkGameOver()
        }
        
        for var index = 0; index < self.myNodes.count; ++index{
            if withinBorder(myNodes[index].position) == false{
                self.myDeadNodes.insert(index, atIndex: 0)
            }
        }
        for index in self.myDeadNodes{
            self.deleteMyNode(index)
        }
        
        self.myDeadNodes = []
        
        for (id, var opponent) in opponents {
            if opponent.deleteIndex != -1 {
                deleteOpponent(id, index: opponent.deleteIndex)
                opponent.deleteIndex = -1
                opponents[id] = opponent
            }
        }
        moveAnchor()
    }
    
    override func didEvaluateActions() {
        update_peer_dead_reckoning()
    }
    
    override func didSimulatePhysics() {
        sendMove()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        //node1.physicsBody?.applyForce(CGVector(dx: -50, dy: 0))
        if locked == false{
            let touch = touches.anyObject() as UITouch
            let loc = touch.locationInNode(self)
            if selected == false{
                for node in myNodes{
                    if node.containsPoint(loc){
                        selectedNode = node
                        selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(playerColor, isSelected: true))
                        selected = true
                        break
                    }
                }
                if selected == false && scrolling == false{
                    if loc.y > (-anchorPoint.y * size.height + size.height - 150){
                        scrollDirection = ScrollDirection(rawValue: 0)
                    }
                    else if loc.y < (-anchorPoint.y * size.height + 150){
                        scrollDirection = ScrollDirection(rawValue: 1)
                    }
                    else if loc.x < (-anchorPoint.x * size.width + 150){
                        scrollDirection = ScrollDirection(rawValue: 2)
                    }
                    else if loc.x > (-anchorPoint.x * size.width + size.width - 150){
                        scrollDirection = ScrollDirection(rawValue: 3)
                    }
                    println("\(loc.x), \(loc.y), \(anchorPoint.x), \(anchorPoint.y)\n")
                    
                }
            }
            else {
                launchPoint = loc
                launchTime = NSDate()
            }
        }
    }

    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        if selected == true && launchTime != nil && launchPoint != nil{
            let now = NSDate()
            let offset: CGPoint = (loc - launchPoint) / CGFloat(now.timeIntervalSinceDate(launchTime!))
            selectedNode.physicsBody?.velocity = CGVector(dx: offset.x / 1.5, dy: offset.y / 1.5)
            selected = false
            selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(self.playerColor, isSelected: false))
            selectedNode = nil
            launchTime = nil
            launchPoint = nil
            sendMove()
        }
        else if scrollDirection != nil{
            switch scrollDirection!{
            case .up:
                if (loc.y < -anchorPoint.y * size.height + size.height - 250) && subscene_index != 3 && subscene_index != 4{
                    scroll(scrollDirection)
                }
            case .down:
                if (loc.y > -anchorPoint.y * size.height + 250) && subscene_index != 1 && subscene_index != 2{
                    scroll(scrollDirection)
                }
            case .left:
                if (loc.x > -anchorPoint.x * size.width + 250) && subscene_index != 1 && subscene_index != 3{
                    scroll(scrollDirection)
                }
            case .right:
                if (loc.x < -anchorPoint.x * size.width + size.width - 250) && subscene_index != 2 && subscene_index != 4{
                    scroll(scrollDirection)
                }
            default:
                println("error scrolling")
            }
        }
    }
    
    func scroll(direction: ScrollDirection){
        switch direction{
        case .up:
            anchorPointVel.dy = -CGFloat(1) / scrollingFrameDuration
        case .down:
            anchorPointVel.dy = CGFloat(1) / scrollingFrameDuration
        case .left:
            anchorPointVel.dx = CGFloat(1) / scrollingFrameDuration
        case .right:
            anchorPointVel.dx = -CGFloat(1) / scrollingFrameDuration
        default:
            println("error")
        }
        scrolling = true
        changeAnchor()
    }
    
    func moveAnchor(){
        if (scrollingFrameDuration > 0) && scrolling == true{
            anchorPoint.x += anchorPointVel.dx
            anchorPoint.y += anchorPointVel.dy
            scrollingFrameDuration--
        }
        else if scrolling == true{
            anchorPointVel = CGVector(dx: 0, dy: 0)
            anchorPoint = CGPoint(x: CGFloat(-(subscene_index - 1) % subscene_count_horizontal), y: CGFloat(-(subscene_index - 1) / subscene_count_vertical))
            scrolling = false
            scrollingFrameDuration = CGFloat(30)
            scrollDirection = nil
        }
    }
    
    func changeAnchor(){
        switch scrollDirection!{
        case .up:
            subscene_index += 2
        case .down:
            subscene_index -= 2
        case .left:
            subscene_index -= 1
        case .right:
            subscene_index += 1
        default:
            println("error")
        }
    }
    
    func deletePeerBalls(message: MessageDead, peerPlayerID: Int) {
        opponents[peerPlayerID]?.deleteIndex = message.index
    }
    
    func checkGameOver() {
        if myNodes.count == 0 {
            gameOver = true
            connection.sendGameOver()
            gameOver(won: false)
        }
    }
    
    func gameOver(#won: Bool) {
        connection.gameState = .Done
        connection.playerID = 0
        connection.randomNumbers.removeAll(keepCapacity: true)
        connection.receivedAllRandomNumber = false
        let gameOverScene = GameOverScene(size: size, won: won)
        gameOverScene.scaleMode = scaleMode
        gameOverScene.controller = connection.controller
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        view?.presentScene(gameOverScene, transition: reveal)
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        self.currentTime = NSDate()
        var player = opponents[peerPlayerID]
        if (message.count > player?.lastCount){
            player?.lastCount = message.count
            player?.info[Int(message.index)] = nodeInfo(x: CGFloat(message.x), y: CGFloat(message.y), dx: CGFloat(message.dx), dy: CGFloat(message.dy), dt: CGFloat(message.dt), index: message.index)
            player?.updated[Int(message.index)] = true
        }
        opponents[peerPlayerID] = player
    }
    
    func sendDead(index: Int){
        println("I'm dead")
        connection.sendDeath(index)
    }
    
    func sendMove(){
        for var index = 0; index < self.myNodes.count; ++index{
            connection.sendMove(Float(myNodes[index].position.x), y: Float(myNodes[index].position.y), dx: Float(myNodes[index].physicsBody!.velocity.dx), dy: Float(myNodes[index].physicsBody!.velocity.dy), count: c, index: UInt16(index), dt: NSDate().timeIntervalSince1970)
                c++
        }
    }
    
    override func className() -> String{
        return "GameScene"
    }
}
