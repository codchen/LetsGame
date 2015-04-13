//
//  ConnectionManager.swift
//  try
//
//  Created by Jiafang Jiang on 1/18/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Peer: NSObject {
    var peerID: MCPeerID!
    var score: Int = 0
    var randomNumber: UInt32 = 0
    var playerID: UInt16 = 0
    var delta: Double = 0
    init(peerID: MCPeerID) {
        super.init()
        self.peerID = peerID
    }
    
    func getName() -> String {
        return peerID.displayName
    }
}

class ConnectionManager: NSObject, MCBrowserViewControllerDelegate, MCSessionDelegate {

    let serviceType = "LetsGame"
    let maxPlayer: Int = 3
//    var connectedPeer = 0
    var connectedPeerNames: [String] = []
    var _model2sceneAdptr: ModelToSceneAdapter = ModelToSceneAdapter()
    
    var browser : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID: MCPeerID!
    
    // peerID maps to its playerID
    var me: Peer!
    struct PeersInGame {
        var peers: [Peer] = []
        var maxPlayer: Int = 3
        var numOfRandomNumber = 0
        var numOfDelta = 1
        
        mutating func addPeer(peer: Peer) {
            peers.append(peer)
        }
        mutating func addPeer(peerID: MCPeerID) {
            peers.append(Peer(peerID: peerID))
        }
        
        mutating func getNumPlayers() -> Int {
            return peers.count
        }
        
        mutating func getPeer(playerID: UInt16) -> Peer? {
            for peer in peers {
                if peer.playerID == playerID {
                    return peer
                }
            }
            return nil
        }
        
        mutating func getPeer(peerID: MCPeerID) -> Peer? {
            for peer in peers {
                if peer.peerID == peerID {
                    return peer
                }
            }
            return nil
        }
        
        mutating func getPeerName(playerID: UInt16) -> String {
            if let peer = getPeer(playerID) {
                return peer.peerID.displayName
            }
            return ""
        }
        
        mutating func getScore(playerID: UInt16) -> Int {
            if let peer = getPeer(playerID) {
                return peer.score
            }
            return 0
        }
        
        mutating func getMaxScore() -> Int {
            var maxScore = 0
            for peer in peers {
                if peer.score > maxScore {
                    maxScore = peer.score
                }
            }
            return maxScore
        }
        
        mutating func getDelta(playerID: Int) -> Double {
            if let peer = getPeer(UInt16(playerID)) {
                return peer.delta
            }
            return 0
        }
        
        mutating func setRandomNumber(peerID: MCPeerID, number: UInt32) {
            if let peer = getPeer(peerID) {
                if peer.randomNumber == 0 {
                    numOfRandomNumber++
                }
                peer.randomNumber = number
            }
        }
        
        mutating func setDelta(peerID: MCPeerID, delta: Double) {
            if let peer = getPeer(peerID) {
                if peer.delta == 0 {
                    numOfDelta++
                }
                peer.delta = delta
            }
        }
        
        mutating func increaseScore(playerID: UInt16) {
            if let peer = getPeer(playerID) {
                peer.score++
            }
        }
        
        mutating func clearGameData() {
            for peer in peers {
                peer.randomNumber = 0
                peer.delta = 0
                peer.score = 0
            }
            numOfRandomNumber = 0
        }
        mutating func receivedAllRandomNumbers() -> Bool {
            if numOfRandomNumber == maxPlayer {
                return true
            } else {
                return false
            }
        }
        mutating func receivedAllDelta() -> Bool {
            if numOfDelta == maxPlayer {
                return true
            } else {
                return false
            }
        }
        mutating func hasAllPlayers() -> Bool {
            if getNumPlayers() == maxPlayer {
                return true
            } else {
                return false
            }
        }
    }
    var peersInGame: PeersInGame!
    
//    var peersInGame: Dictionary<MCPeerID, Int> = Dictionary<MCPeerID, Int>()
    var controller: GameViewController!
//    var randomNumber: UInt32!
    var gameState: GameState = .WaitingForMatch
    var gameMode: GameMode = .None
//    var receivedAllRandomNumber: Bool = false
//    var randomNumbers = Array<UInt32>()
//    var playerID: UInt16 = 0   // the player ID of current player
    
    // reconcil data info
//    var latency: NSTimeInterval!
//    var delta: Dictionary<Int, NSTimeInterval> = Dictionary<Int, NSTimeInterval>()
//    var timeDifference: Dictionary<Int, Double> = Dictionary<Int, Double>()
//    var scoreBoard: Dictionary<Int, Int> = Dictionary<Int, Int>()
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
        peersInGame = PeersInGame()
        peersInGame.maxPlayer = maxPlayer
        self.me = Peer(peerID: self.peerID)
        self.peersInGame.addPeer(me)
    }
    
    func getConnectedMessage() -> String {
        var result = "Connected peers:"
        for peer in peersInGame.peers {
            result = result + "\t\t" + peer.getName()
        }
        return result
    }
    
    func generateRandomNumber(){
        peersInGame.setRandomNumber(me.peerID, number: arc4random())
        gameState = .WaitingForRandomNumber
//        randomNumbers.append(randomNumber)
        println("My Random Number is \(me.randomNumber)")
        sendRandomNumber(me.randomNumber)
    }
    
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
        println("sent destination")
        sendData(data, reliable: true)
    }
    
    func sendGameStart(){
        var message = MessageGameStart(message: Message(messageType: MessageType.GameStart), gameMode: UInt16(self.gameMode.rawValue))
        println("send game start called")
        let data = NSData(bytes: &message, length: sizeof(MessageGameStart))
        sendData(data, reliable: true)
    }
    
    func sendGameReady(){
        var message = MessageReadyToGame(message: Message(messageType: MessageType.GameReady), playerID: me.playerID)
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
    
    func clearGameData(){
//        playerID = 0
//        randomNumbers.removeAll(keepCapacity: false)
        peersInGame.clearGameData()
//        receivedAllRandomNumber = false
//        peersInGame.removeAll(keepCapacity: false)
//        delta.removeAll(keepCapacity: false)
//        scoreBoard.removeAll(keepCapacity: false)
//        scoreBoard[Int(playerID)] = 0
    }
    
    func readyToSendFirstTrip(){
        println("in ready to send first trip")
        if peersInGame.peers.count == maxPlayer {
            println("transit to instr")
            dispatch_async(dispatch_get_main_queue()){
            	self.controller.transitToInstruction()
            }
            for peer in peersInGame.peers {
                if peer.playerID > me.playerID {
                    sendFirstTrip(peer.peerID)
                }
            }
        }
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
//            if peersInGame[peerID] != nil{
            if let peer = peersInGame.getPeer(peerID) {
                _model2sceneAdptr.updatePeerPos(messageMove, peerPlayerID: Int(peer.playerID))
            }

//            }
        } else if message.messageType == MessageType.RandomNumber {
            let messageRandomNumber = UnsafePointer<MessageRandomNumber>(data.bytes).memory
            peersInGame.setRandomNumber(peerID, number: messageRandomNumber.number)
//            randomNumbers.append(messageRandomNumber.number)
            
            if peersInGame.receivedAllRandomNumbers(){
//                receivedAllRandomNumber = true
                let sortedPeers: NSMutableArray = NSMutableArray(array: peersInGame.peers)
                let sortByRandomNumber = NSSortDescriptor(key: "randomNumber", ascending: false)
                let sortDescriptors = [sortByRandomNumber]
                sortedPeers.sortUsingDescriptors(sortDescriptors)
                peersInGame.peers = NSArray(array: sortedPeers) as! [Peer]
                for var i = 0; i < peersInGame.peers.count; ++i {
                    peersInGame.peers[i].playerID = UInt16(i)
                }
                gameState = .WaitingForReconcil
                sendGameReady()
                self.assistant.stop()
                
            }
            
        } else if message.messageType == MessageType.GameReady {
            let messageGameReady = UnsafePointer<MessageReadyToGame>(data.bytes).memory
//            peersInGame[peerID] = Int(messageGameReady.playerID)
//            scoreBoard[peersInGame[peerID]!] = 0
            if peersInGame.peers.count == maxPlayer {
                for peer in peersInGame.peers {
                    if peer.playerID == 0 {
                        controller.addHostLabel(peer.peerID.displayName)
                        if me.playerID == 0 {
                            dispatch_async(dispatch_get_main_queue()){
                                self.controller.playBtn.enabled = true
                            }
                        }
                        break
                    }
                }
            }
        } else if message.messageType == MessageType.GameStart {
            let messageGameStart = UnsafePointer<MessageGameStart>(data.bytes).memory
//            peersInGame[peerID] = Int(messageGameStart.playerID)
            println("Received game start")
            let mode = GameMode(rawValue: Int(messageGameStart.gameMode))
            if mode != GameMode.None {
                self.gameMode = mode!
            }
//            scoreBoard[peersInGame[peerID]!] = 0

            readyToSendFirstTrip()
        } else if message.messageType == MessageType.FirstTrip{
            let messageFirstTrip = UnsafePointer<MessageFirstTrip>(data.bytes).memory
            let delta = NSDate().timeIntervalSince1970 - messageFirstTrip.time
            println("Received First Trip from \(peerID.displayName)")
            println("1st Trip: time \(messageFirstTrip.time), delta \(delta)")
            sendSecondTrip(delta, peer: peerID)
            
        } else if message.messageType == MessageType.SecondTrip {
            let messageSecondTrip = UnsafePointer<MessageSecondTrip>(data.bytes).memory
            let latency = (messageSecondTrip.delta + NSDate().timeIntervalSince1970 - messageSecondTrip.time) / 2.0
            let calculatedDelta = messageSecondTrip.delta - latency
            peersInGame.setDelta(peerID, delta: calculatedDelta)
//            delta[peersInGame[peerID]!] = messageSecondTrip.delta - latency
            println("Received Second Trip from \(peerID.displayName)")
            println("2nd Trip: time \(messageSecondTrip.time), delta \(messageSecondTrip.delta)")
            println("Calculated delta: \(messageSecondTrip.delta - latency), latency: \(latency)")
            sendThirdTrip(calculatedDelta, peer: peerID)
            if (peersInGame.receivedAllDelta()) {
                if controller.presentedViewController != nil{
                    controller.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
                }
                gameState = .WaitingForStart
//                controller.transitToGame(gameMode, gameState: gameState)
                		// this is only valid for 0th player
            }
            
        } else if message.messageType == MessageType.ThirdTrip {
            let messageThirdTrip = UnsafePointer<MessageThirdTrip>(data.bytes).memory
            let calculatedDelta = messageThirdTrip.delta * -1.0
            peersInGame.setDelta(peerID, delta: calculatedDelta)
            println("Received Third Trip from \(peerID.displayName)")
            println("3rd Trip: delta \(messageThirdTrip.delta)")
            if (peersInGame.receivedAllDelta()) {
                if controller.presentedViewController != nil{
                    controller.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
                }
                gameState = .WaitingForStart
//                controller.transitToGame(gameMode, gameState: gameState)
//                controller.transitToInstruction()
            }
            
        } else if message.messageType == MessageType.Dead{
            let messageDead = UnsafePointer<MessageDead>(data.bytes).memory
//            if peersInGame[peerID] != nil{
            if let peer = peersInGame.getPeer(peerID) {
                _model2sceneAdptr.updatePeerDeath(messageDead, peerPlayerID: Int(peer.playerID))
                peersInGame.increaseScore(peer.playerID)
            }
//            	scoreBoard[peersInGame[peerID]!]!++
//            }
        } else if message.messageType == MessageType.Destination {
			let messageDestination = UnsafePointer<MessageDestination>(data.bytes).memory
            dispatch_async(dispatch_get_main_queue()) {
                self.controller.updateDestination(messageDestination)
            }
        
        } else if message.messageType == MessageType.GameOver {
            _model2sceneAdptr.gameOver()
        } else if message.messageType == MessageType.NeutralInfo{
            let messageNeutral = UnsafePointer<MessageNeutralInfo>(data.bytes).memory
//            if peersInGame[peerID] != nil{
            	if let peer = peersInGame.getPeer(peerID) {
					_model2sceneAdptr.updateNeutralInfo(messageNeutral, peerPlayerID: Int(peer.playerID))
            	}
            
//            }
        } else if message.messageType == MessageType.Pause {
            let messagePause = UnsafePointer<MessagePause>(data.bytes).memory
            _model2sceneAdptr.pause()
        } else if message.messageType == MessageType.Reborn {
            let messageReborn = UnsafePointer<MessageReborn>(data.bytes).memory
//            if peersInGame[peerID] != nil{
            if let peer = peersInGame.getPeer(peerID) {
            	_model2sceneAdptr.updateReborn(messageReborn, peerPlayerID: Int(peer.playerID))
            }

//            }
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
                let peer = Peer(peerID: peerID)
                peersInGame.addPeer(peer)
//                connectedPeer++
                connectedPeerNames.append(peer.getName())
                if peersInGame.hasAllPlayers(){
                    generateRandomNumber()
//                    controller.playBtn.enabled = true
                    dispatch_async(dispatch_get_main_queue()){
                        self.controller.connectedPeers.text = self.getConnectedMessage()
                        self.controller.connectPrompt.text = ""
                        self.controller.playBtn.setBackgroundImage(UIImage(named: "300x300_button_battle"), forState: UIControlState.Normal)
                        self.controller.playBtn.setBackgroundImage(UIImage(named: "300x300_button_battle"), forState: UIControlState.Selected)
                    }
                }
                else {
                    dispatch_async(dispatch_get_main_queue()){
                        self.controller.connectedPeers.text = self.getConnectedMessage()
                        self.controller.connectPrompt.text = "Need to connect to \(self.maxPlayer - self.peersInGame.getNumPlayers()) more peers!"
                    }

                }
            }
            else if state == MCSessionState.NotConnected {
                if gameState == .InGame {
                    var alert = UIAlertController(title: "Lost Connection", message: "Lost connection with " + peerID.displayName, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    controller.presentViewController(alert, animated: true, completion: nil)

                }
                if let peer = peersInGame.getPeer(peerID) {
                    connectedPeerNames = connectedPeerNames.filter({$0 != peer.getName()})
                    self.controller.connectedPeers.text = self.getConnectedMessage()
                    self.controller.connectPrompt.text = "Need to connect to \(self.maxPlayer - self.peersInGame.getNumPlayers()) more peers!"
                }
            }

    }
    
}
