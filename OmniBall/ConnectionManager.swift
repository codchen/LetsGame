//
//  ConnectionManager.swift
//  try
//
//  Created by Jiafang Jiang on 1/18/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class ConnectionManager: NSObject, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    let serviceType = "LetsGame"
    let maxPlayer = 2
    var connectedPeer = 0
    
    var browser : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID: MCPeerID!
    
    // peerID maps to its playerID
    var peersInGame: Dictionary<MCPeerID, Int> = Dictionary<MCPeerID, Int>()
    var controller: GameViewController!
    var randomNumber: UInt32!
    var gameState: GameState = .WaitingForMatch
    var gameMode: GameMode = .None
    var receivedAllRandomNumber: Bool = false
    var randomNumbers = Array<UInt32>()
    var playerID: UInt16 = 0   // the player ID of current player
    
    // reconcil data info
    var latency: NSTimeInterval!
    var delta: Dictionary<Int, NSTimeInterval> = Dictionary<Int, NSTimeInterval>()
    var timeDifference: Dictionary<Int, Double> = Dictionary<Int, Double>()
    var scoreBoard: Dictionary<Int, Int> = Dictionary<Int, Int>()
    var maxLevel: Int = 5
    
    
    override init() {
        super.init()
        // Do any additional setup after loading the view, typically from a nib.
        self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        // create the browser viewcontroller with a unique service name
        self.browser = MCBrowserViewController(serviceType:serviceType,
            session:self.session)
        
        self.browser.delegate = self;
        
        self.assistant = MCAdvertiserAssistant(serviceType:serviceType,
            discoveryInfo:nil, session:self.session)
        
        // tell the assistant to start advertising our fabulous chat
        self.assistant.start()
        scoreBoard[0] = 0
    }
    
    func generateRandomNumber(){
        randomNumber = arc4random()
        gameState = .WaitingForRandomNumber
        randomNumbers.append(randomNumber)
        println("My Random Number is \(randomNumber)")
        sendRandomNumber(randomNumber)
    }
    
//    func transitToGame(gameMode: GameMode) {
//        
//        switch gameMode {
//        case .BattleArena:
//        	if playerID == 0 {
//            	controller.transitToBattleArena()
//            }
//        case .HiveMaze:
//            controller.transitToHiveMaze()
//        default:
//            return
//        }
//    }
    
    func sendRandomNumber(number: UInt32){
        var message = MessageRandomNumber(message: Message(messageType: MessageType.RandomNumber), number: number)
        let data = NSData(bytes: &message, length: sizeof(MessageRandomNumber))
        sendData(data, reliable: true)
    }
    
    func sendFirstTrip(peer: MCPeerID){
        var message = MessageFirstTrip(message: Message(messageType: MessageType.FirstTrip), time: NSDate().timeIntervalSince1970)
        let data = NSData(bytes: &message, length: sizeof(MessageFirstTrip))
        sendDataTo(data, peerID: peer, reliable: true)
    }
    
    func sendSecondTrip(delta: NSTimeInterval, peer: MCPeerID){
        var message = MessageSecondTrip(message: Message(messageType: MessageType.SecondTrip), time: NSDate().timeIntervalSince1970, delta: delta)
        let data = NSData(bytes: &message, length: sizeof(MessageSecondTrip))
        sendDataTo(data, peerID: peer, reliable: true)
    }
    
    func sendThirdTrip(delta: NSTimeInterval, peer: MCPeerID){
        var message = MessageThirdTrip(message: Message(messageType: MessageType.ThirdTrip), delta: delta)
        let data = NSData(bytes: &message, length: sizeof(MessageThirdTrip))
        sendDataTo(data, peerID: peer, reliable: true)
    }
    
    func sendMove(x: Float, y: Float, dx: Float, dy: Float, count: UInt32, index: UInt16, dt: NSTimeInterval, isSlave: Bool){
        var message = MessageMove(message: Message(messageType: MessageType.Move), x: x, y: y,
            dx: dx, dy: dy, count: count, index: index, dt: dt, isSlave: isSlave)
        let data = NSData(bytes: &message, length: sizeof(MessageMove))
        sendData(data, reliable: false)
    }
    
    func sendDestinationPos(x: Float, y: Float, rotate: Float, starX: Float, starY: Float){
        var message = MessageDestination(message: Message(messageType: MessageType.Destination), x: x, y: y, rotate: rotate, starX: starX, starY: starY)
        let data = NSData(bytes: &message, length: sizeof(MessageDestination))
        sendData(data, reliable: true)
    }
    
    func sendGameStart(){
        var message = MessageGameStart(message: Message(messageType: MessageType.GameStart), playerID: playerID, gameMode: UInt16(self.gameMode.rawValue))
        //println("My playerID is \(playerID)")
        let data = NSData(bytes: &message, length: sizeof(MessageGameStart))
        sendData(data, reliable: true)
    }
    
    func sendNeutralInfo(index: UInt16, id: UInt16, lastCaptured: Double){
        var message = MessageNeutralInfo(message: Message(messageType: MessageType.NeutralInfo), index: index, id: id, lastCaptured: lastCaptured)
        let data = NSData(bytes: &message, length: sizeof(MessageNeutralInfo))
        sendData(data, reliable: true)
    }
    
    func sendReborn(index: UInt16){
        var message = MessageReborn(message: Message(messageType: MessageType.Reborn), index: index)
        let data = NSData(bytes: &message, length: sizeof(MessageReborn))
        sendData(data, reliable: true)
    }
    
    func sendPause(){
        var message = MessagePause(message: Message(messageType: MessageType.Pause))
        let data = NSData(bytes: &message, length: sizeof(MessagePause))
        sendData(data, reliable: true)
    }
    
    func sendDeath(index: UInt16, count: UInt32){
        var message = MessageDead(message: Message(messageType: MessageType.Dead), index: index, count: count)
        let data = NSData(bytes: &message, length: sizeof(MessageDead))
        sendData(data, reliable: true)
    }
    
    func sendGameOver(){
        var message = MessageGameOver(message: Message(messageType: MessageType.GameOver))
        let data = NSData(bytes: &message, length: sizeof(MessageGameOver))
        sendData(data, reliable: true)
    }
    
    func sendDataTo(data: NSData, peerID: MCPeerID, reliable: Bool) {
        var error : NSError?
        var success: Bool!
        if session.connectedPeers.count != 0 {
            switch reliable {
            case true:
                success = session.sendData(data, toPeers: [peerID], withMode: MCSessionSendDataMode.Reliable, error: &error)
            default:
                success = session.sendData(data, toPeers: [peerID], withMode: MCSessionSendDataMode.Unreliable, error: &error)
            }
            
            if !success {
                if let error = error {
                    println("Error sending data:\(error.localizedDescription)")
                }
            }
        }
    }
    
    func sendData(data: NSData, reliable: Bool){
        
        var error : NSError?
        var success: Bool!
        if session.connectedPeers.count != 0 {
            switch reliable {
            case true:
                success = session.sendData(data, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: &error)
            default:
                success = session.sendData(data, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Unreliable, error: &error)
            }

            if !success {
                if let error = error {
            		println("Error sending data:\(error.localizedDescription)")
            	}
        	}
        }
    }
    
    func gameOver(){
        playerID = 0
        randomNumbers.removeAll(keepCapacity: false)
        receivedAllRandomNumber = false
        peersInGame.removeAll(keepCapacity: false)
        delta.removeAll(keepCapacity: false)
        scoreBoard.removeAll(keepCapacity: false)
    }
    
    func browserViewControllerDidFinish(
        browserViewController: MCBrowserViewController!)  {
            // Called when the browser view controller is dismissed (ie the Done
            // button was tapped)
            controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(
        browserViewController: MCBrowserViewController!)  {
            // Called when the browser view controller is cancelled
            
            controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!,
        fromPeer peerID: MCPeerID!)  {
            
        var message = UnsafePointer<Message>(data.bytes).memory
        
        if message.messageType == MessageType.Move {
            let messageMove = UnsafePointer<MessageMove>(data.bytes).memory
            if peersInGame[peerID] != nil{
            controller.updatePeerPos(messageMove, peerPlayerID: peersInGame[peerID]!)
            }
        } else if message.messageType == MessageType.RandomNumber {
            let messageRandomNumber = UnsafePointer<MessageRandomNumber>(data.bytes).memory
            randomNumbers.append(messageRandomNumber.number)
            
            if gameState == .WaitingForMatch {
                generateRandomNumber()
            }
            
            if randomNumbers.count == maxPlayer{
                receivedAllRandomNumber = true
            }
            
            if receivedAllRandomNumber {
                var allNumbers = Set<UInt32>()
                
                for number in randomNumbers {
                    allNumbers.insert(number)
                }
                if allNumbers.count == randomNumbers.count {
                    randomNumbers.sort {$0 > $1}
                    for var index = 0; index < randomNumbers.count; ++index {
                        if randomNumbers[index] == self.randomNumber {
                            playerID = UInt16(index)
                            scoreBoard[Int(playerID)] = 0
                            gameState = .WaitingForStart
                            sendGameStart()
                            self.assistant.stop()
                            break
                        }
                    }
                } else {
                    randomNumbers.removeAll(keepCapacity: true)
                    generateRandomNumber()
                    receivedAllRandomNumber = false
                }
            }
        } else if message.messageType == MessageType.GameStart {
            let messageGameStart = UnsafePointer<MessageGameStart>(data.bytes).memory
            peersInGame[peerID] = Int(messageGameStart.playerID)
            let mode = GameMode(rawValue: Int(messageGameStart.gameMode))
            if mode != GameMode.None {
                self.gameMode = mode!
            }
            scoreBoard[peersInGame[peerID]!] = 0
            if peersInGame.count == maxPlayer - 1 {
                for (peer, id) in peersInGame {
                    if id > Int(self.playerID) {
                        sendFirstTrip(peer)
                    }
                }
            }
        } else if message.messageType == MessageType.FirstTrip{
            let messageFirstTrip = UnsafePointer<MessageFirstTrip>(data.bytes).memory
            let delta = NSDate().timeIntervalSince1970 - messageFirstTrip.time
            println("Received First Trip from \(peerID.displayName)")
            println("1st Trip: time \(messageFirstTrip.time), delta \(delta)")
            sendSecondTrip(delta, peer: peerID)
            
        } else if message.messageType == MessageType.SecondTrip {
            let messageSecondTrip = UnsafePointer<MessageSecondTrip>(data.bytes).memory
            latency = (messageSecondTrip.delta + NSDate().timeIntervalSince1970 - messageSecondTrip.time) / 2.0
            delta[peersInGame[peerID]!] = messageSecondTrip.delta - latency
            println("Received Second Trip from \(peerID.displayName)")
            println("2nd Trip: time \(messageSecondTrip.time), delta \(messageSecondTrip.delta)")
            println("Calculated delta: \(messageSecondTrip.delta - latency), latency: \(latency)")
            sendThirdTrip(delta[peersInGame[peerID]!]!, peer: peerID)
            if (delta.count == maxPlayer - 1) {
//                transitToGame(self.gameMode)
                if controller.presentedViewController != nil{
                    controller.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
                }
                controller.transitToInstruction()
            }
            
        } else if message.messageType == MessageType.ThirdTrip {
            let messageThirdTrip = UnsafePointer<MessageThirdTrip>(data.bytes).memory
            delta[peersInGame[peerID]!] = messageThirdTrip.delta * -1.0
            println("Received Third Trip from \(peerID.displayName)")
            println("3rd Trip: delta \(messageThirdTrip.delta)")
            if (delta.count == maxPlayer - 1) {
//                transitToGame(self.gameMode)
                if controller.presentedViewController != nil{
                    controller.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
                }
                controller.transitToInstruction()
            }
            
        } else if message.messageType == MessageType.Dead{
            let messageDead = UnsafePointer<MessageDead>(data.bytes).memory
            if peersInGame[peerID] != nil{
            	controller.updatePeerDeath(messageDead, peerPlayerID: peersInGame[peerID]!)
                scoreBoard[peersInGame[peerID]!]!++
            }
        } else if message.messageType == MessageType.Destination {
			let messageDestination = UnsafePointer<MessageDestination>(data.bytes).memory
            controller.updateDestination(messageDestination)
        
        } else if message.messageType == MessageType.GameOver {
            controller.gameOver()
        } else if message.messageType == MessageType.NeutralInfo{
            let messageNeutral = UnsafePointer<MessageNeutralInfo>(data.bytes).memory
            if peersInGame[peerID] != nil{
                controller.updateNeutralInfo(messageNeutral, peerPlayerID: peersInGame[peerID]!)
            }
        } else if message.messageType == MessageType.Pause {
            let messagePause = UnsafePointer<MessagePause>(data.bytes).memory
            controller.pause()
        } else if message.messageType == MessageType.Reborn {
            let messageReborn = UnsafePointer<MessageReborn>(data.bytes).memory
            if peersInGame[peerID] != nil{
                controller.updateReborn(messageReborn, peerPlayerID: peersInGame[peerID]!)
            }
            }
    }
    
    // The following methods do nothing, but the MCSessionDelegate protocol
    // requires that we implement them.
    func session(session: MCSession!,
        didStartReceivingResourceWithName resourceName: String!,
        fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!)  {
            
            // Called when a peer starts sending a file to us
    }
    
    func session(session: MCSession!,
        didFinishReceivingResourceWithName resourceName: String!,
        fromPeer peerID: MCPeerID!,
        atURL localURL: NSURL!, withError error: NSError!)  {
            // Called when a file has finished transferring from another peer
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!,
        withName streamName: String!, fromPeer peerID: MCPeerID!)  {
            // Called when a peer establishes a stream with us
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!,
        didChangeState state: MCSessionState)  {
            // Called when a connected peer changes state (for example, goes offline)
            if state == MCSessionState.Connected {
                connectedPeer++
                if connectedPeer == maxPlayer - 1 {
                    controller.playBtn.enabled = true
                    controller.playBtn.setBackgroundImage(UIImage(named: "300x300_button_battle"), forState: UIControlState.Normal)
                    controller.playBtn.setBackgroundImage(UIImage(named: "300x300_button_battle"), forState: UIControlState.Selected)
                }
            }
            else if state == MCSessionState.NotConnected {
                if peersInGame[peerID] != nil{
                    connectedPeer--
                }
            }

    }
    
}
