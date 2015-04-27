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

class ConnectionManager: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {
    
    var serviceType = "LetsGame"
    var maxPlayer: Int!
    var connectedPeer = 0
    
    var advertiser: MCNearbyServiceAdvertiser!
    var browser: MCNearbyServiceBrowser!
    var session : MCSession!
    var peerID: MCPeerID!
    var invitedPeers: [MCPeerID] = []
    var connectingPeers: [MCPeerID] = []

    var me: Peer!
    struct PeersInGame {
        var peers: [Peer] = []
//        var maxPlayer: Int = 3
        var numOfPlayers = 0		// num of players entered the game, will stay unchanged
        var numOfRandomNumber = 0
        var numOfDelta = 1
        
        mutating func addPeer(peer: Peer) {
            peers.append(peer)
        }
        mutating func addPeer(peerID: MCPeerID) {
            peers.append(Peer(peerID: peerID))
        }
        
        mutating func removePeer(peer: Peer) {
            var removeIdx = 0
            for var i = 0; i < peers.count; ++i {
                if peers[i].peerID.isEqual(peer.peerID) {
                    removeIdx = i
                    break
                }
            }
            peers.removeAtIndex(removeIdx)
        }
        
        func hasPeer(peerID: MCPeerID) -> Bool{
            for peer in peers {
                if peer.peerID == peerID {
                    return true
                }
            }
            return false
        }
        
        func getNumPlayers() -> Int {
            return peers.count
        }
        
        func getPeer(playerID: UInt16) -> Peer? {
            for peer in peers {
                if peer.playerID == playerID {
                    return peer
                }
            }
            return nil
        }
        
        func getPeer(peerID: MCPeerID) -> Peer? {
            for peer in peers {
                if peer.peerID == peerID {
                    return peer
                }
            }
            return nil
        }
        
        func getPeerName(playerID: UInt16) -> String {
            if let peer = getPeer(playerID) {
                return peer.peerID.displayName
            }
            return ""
        }
        
        func getScore(playerID: UInt16) -> Int {
            if let peer = getPeer(playerID) {
                return peer.score
            }
            return 0
        }
        
        func getMaxScore() -> Int {
            var maxScore = 0
            for peer in peers {
                if peer.score > maxScore {
                    maxScore = peer.score
                }
            }
            return maxScore
        }
        
        func getDelta(playerID: Int) -> Double {
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
            numOfDelta = 1
        }
        
       func receivedAllRandomNumbers() -> Bool {
            if numOfRandomNumber == getNumPlayers() {
                return true
            } else {
                return false
            }
        }
        
        func receivedAllDelta() -> Bool {
            if numOfDelta == getNumPlayers() {
                return true
            } else {
                return false
            }
        }
        
        func hasAllPlayers() -> Bool {
            if getNumPlayers() == numOfPlayers {
                return true
            } else {
                return false
            }
        }
        
        func printRandomNumbers() {
            for peer in peers {
                println(peer.randomNumber)
            }
        }
    }
    var peersInGame: PeersInGame!
    var controller: GameViewController!
    var diffController: DifficultyController!
    var gameState: GameState = .WaitingForStart
    var gameMode: GameMode = .None
    var receivedAllRandomNumber: Bool = false
    
    // reconcil data info
    var latency: NSTimeInterval!
    var maxLevel: Int = 4
    var gameStartMsgCnt: Int = 0
    
    
    init(pNum: Int) {
        super.init()
        // Do any additional setup after loading the view, typically from a nib.
        if NSUserDefaults.standardUserDefaults().dataForKey("peerID") == nil {
            self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
            NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(self.peerID), forKey: "peerID")
        } else {
            self.peerID = NSKeyedUnarchiver.unarchiveObjectWithData(NSUserDefaults.standardUserDefaults().dataForKey("peerID")!) as MCPeerID
        }
        self.maxPlayer = pNum
        self.serviceType = self.serviceType + String(self.maxPlayer)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        // create the browser viewcontroller with a unique service name
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.advertiser.delegate = self
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        self.browser.delegate = self
		self.startConnecting()
        peersInGame = PeersInGame()
//        peersInGame.maxPlayer = maxPlayer
        self.me = Peer(peerID: self.peerID)
        self.peersInGame.addPeer(me)
    }
    
    func getConnectedMessage() -> String {
        if peersInGame.peers.count == 1 {
            return "Not connected to anyone yet!"
        }
        var result = "Connected peers:"
        for peer in peersInGame.peers {
            if peer.getName() != me.getName() {
                result = result + "\t\t" + peer.getName()
            }
        }
        return result
    }
    
    func getConnectionPrompt() -> String {
        if maxPlayer == 1 {
            return "Single mode"
        }
        if (maxPlayer - peersInGame.peers.count) == 0 {
            return ""
        }
        if (maxPlayer - peersInGame.peers.count) == 1 {
            return "Need to connect to 1 more peer!"
        }
        else {
            return "Need to connect to \(maxPlayer - peersInGame.peers.count) more peers!"
        }
    }
    
    func generateRandomNumber(){
        peersInGame.setRandomNumber(me.peerID, number: arc4random())
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
        let data = NSData(bytes: &message, length: sizeof(MessageGameStart))
        for peer in peersInGame.peers {
            if peer.playerID == 0 {
                sendDataTo(data, peerID: peer.peerID, reliable: true)
                break
            }
        }

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
    
//    func sendExit(){
//        var message = MessageExit(message: Message(messageType: MessageType.Exit))
//        let data = NSData(bytes: &message, length: sizeof(MessageExit))
//        sendData(data, reliable: true)
//    }
    
    func sendChooseGameMode() {
        var message = MessageChooseGameMode(message: Message(messageType: MessageType.ChooseGameMode), numConnectedPeers: UInt16(peersInGame.getNumPlayers()))
        let data = NSData(bytes: &message, length: sizeof(MessageChooseGameMode))
        sendData(data, reliable: true)
    }
    
    func sendForceExitSession(peer: MCPeerID) {
        var message = MessageForceExitSession(message: Message(messageType: MessageType.ForceExitSession))
        let data = NSData(bytes: &message, length: sizeof(MessageForceExitSession))
        sendDataTo(data, peerID: peer, reliable: true)
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
        if !peersInGame.hasAllPlayers() {
            peersInGame.numOfRandomNumber = 0
        }
        peersInGame.clearGameData()
    }
    
    func exitGame() {
        session.disconnect()
        gameState = .WaitingForStart
        controller.setHostUI(isHost: true, isConnecting: false)
        invitedPeers = []
        peersInGame = PeersInGame()
        me = Peer(peerID: self.peerID)
        peersInGame.addPeer(me)
//        peersInGame.maxPlayer = maxPlayer
        controller.currentLevel = 0
        startConnecting()
    }
    
    func readyToChooseGameMode() {
        gameState = .InLevelViewController
        stopConnecting()
        peersInGame.numOfPlayers = peersInGame.getNumPlayers()
        sendChooseGameMode()
    }
    
    func startConnecting() {
        println("[START CONN]")
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func stopConnecting() {
        println("[STOP CONN]")
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
    
    func readyToSendFirstTrip(){
        if peersInGame.hasAllPlayers() {
            for peer in peersInGame.peers {
                if peer.playerID > me.playerID {
                    sendFirstTrip(peer.peerID)
                }
            }
        }
    }
    
    func determineHost() {
        stopConnecting()	// will restart connecting when finishing randomnumber exchange
        println("[SET HOSTUI] false true")
        controller.setHostUI(isHost: false, isConnecting: true)
        generateRandomNumber()
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!,
        withContext context: NSData!, invitationHandler: ((Bool,
        MCSession!) -> Void)!) {
            println("[INVITATION FROM] \(peerID.displayName)")
            if gameState == .InLevelViewController {
                invitationHandler(false, session)
            } else {
                controller.setHostUI(isHost: false, isConnecting: true)
                invitationHandler(true, session)
            }
    }
    
    func hasInvitedPeer(peerID: MCPeerID) -> Bool{
        for id in invitedPeers {
            if id == peerID {
                return true
            }
        }
        return false
    }
    
    func browser(browser: MCNearbyServiceBrowser!,
        foundPeer peerID: MCPeerID!,
        withDiscoveryInfo info: [NSObject : AnyObject]!) {
            println("[FOUND] \(peerID.displayName)")
            if !hasInvitedPeer(peerID) {
                println("[INVITE] \(peerID.displayName)")
                browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 10)
                invitedPeers.append(peerID)
                NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "deleteFromInvited:", userInfo: peerID, repeats: false)
            }
            
            
    }
    
    func deleteFromInvited(timer: NSTimer) {
        println("[TIME OUT]")
        let peerID = timer.userInfo as MCPeerID
		deleteFromInvited(peerID)
    }
    
    func deleteFromInvited(peerID: MCPeerID) {
        if !peersInGame.hasPeer(peerID) && !invitedPeers.isEmpty{
            var idx2remove = 0
            for var i = 0; i < invitedPeers.count; ++i {
                if invitedPeers[i] == peerID {
                    idx2remove = i
                    break
                }
            }
            invitedPeers.removeAtIndex(idx2remove)
        }
    }
    
    func browser(browser: MCNearbyServiceBrowser!,
        lostPeer peerID: MCPeerID!) {
            
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!,
        fromPeer peerID: MCPeerID!)  {
            
        var message = UnsafePointer<Message>(data.bytes).memory
        
        if message.messageType == MessageType.Move {
            let messageMove = UnsafePointer<MessageMove>(data.bytes).memory
            if let peer = peersInGame.getPeer(peerID) {
                controller.updatePeerPos(messageMove, peerPlayerID: Int(peer.playerID))
            }
        } else if message.messageType == MessageType.RandomNumber {
            let messageRandomNumber = UnsafePointer<MessageRandomNumber>(data.bytes).memory
            println("[RANDOM NUM] \(peerID.displayName): \(messageRandomNumber.number)")
            peersInGame.setRandomNumber(peerID, number: messageRandomNumber.number)
            if peersInGame.receivedAllRandomNumbers(){
                println("[ALL RANDOM NUM] \(peersInGame.getNumPlayers())")
                let sortedPeers: NSMutableArray = NSMutableArray(array: peersInGame.peers)
                let sortByRandomNumber = NSSortDescriptor(key: "randomNumber", ascending: false)
                let sortDescriptors = [sortByRandomNumber]
                sortedPeers.sortUsingDescriptors(sortDescriptors)
                peersInGame.peers = NSArray(array: sortedPeers) as [Peer]
                for var i = 0; i < peersInGame.getNumPlayers(); ++i {
                    peersInGame.peers[i].playerID = UInt16(i)
                    if (i == 0) {
                        println("[ADD LBLHOST] \(peersInGame.peers[i].getName())")
                        self.controller.addHostLabel(self.peersInGame.peers[i].getName())
                    }
                }
                
               	if me.playerID != 0 {
                    println("[SET HOSTUI] false, false")
                    self.controller.setHostUI(isHost: false, isConnecting: false)
//                	sendGameReady()
                } else {
                    println("[SET HOSTUI] true, false")
                    self.controller.setHostUI(isHost: true, isConnecting: false)
                    if peersInGame.getNumPlayers() < maxPlayer {
                        startConnecting()
                    }
                }
                
//                gameState = .WaitingForStart
                diffController = nil
            }
//        } else if message.messageType == MessageType.GameReady {
//            gameStartMsgCnt++
//            println("[GAME READY] \(peerID.displayName) \(peersInGame.getNumPlayers())")
//            if gameStartMsgCnt == peersInGame.getNumPlayers() - 1 {
//                self.controller.setHostUI(isHost: true, isConnecting: false)
//                if gameStartMsgCnt < maxPlayer {
//                    startConnecting()
//                }
//            	gameStartMsgCnt = 0
//            }
        } else if message.messageType == MessageType.GameStart {
            let messageGameStart = UnsafePointer<MessageGameStart>(data.bytes).memory
            println("Received game start")
            let mode = GameMode(rawValue: Int(messageGameStart.gameMode))
            if mode != GameMode.None {
                self.gameMode = mode!
            }
            readyToSendFirstTrip()
        } else if message.messageType == MessageType.FirstTrip{
            let messageFirstTrip = UnsafePointer<MessageFirstTrip>(data.bytes).memory
            let delta = NSDate().timeIntervalSince1970 - messageFirstTrip.time
            println("Received First Trip from \(peerID.displayName)")
            println("1st Trip: time \(messageFirstTrip.time), delta \(delta)")
            sendSecondTrip(delta, peer: peerID)
            
        } else if message.messageType == MessageType.SecondTrip {
            let messageSecondTrip = UnsafePointer<MessageSecondTrip>(data.bytes).memory
            latency = (messageSecondTrip.delta + NSDate().timeIntervalSince1970 - messageSecondTrip.time) / 2.0
            let calculatedDelta = messageSecondTrip.delta - latency
            peersInGame.setDelta(peerID, delta: calculatedDelta)
            println("Received Second Trip from \(peerID.displayName)")
            println("2nd Trip: time \(messageSecondTrip.time), delta \(messageSecondTrip.delta)")
            println("Calculated delta: \(messageSecondTrip.delta - latency), latency: \(latency)")
            sendThirdTrip(calculatedDelta, peer: peerID)
            if (peersInGame.receivedAllDelta()) {
                if diffController != nil {
                    diffController.transitToInstruction()
                }
                else{
                    controller.transitToInstruction()
                }
            }
            
        } else if message.messageType == MessageType.ThirdTrip {
            let messageThirdTrip = UnsafePointer<MessageThirdTrip>(data.bytes).memory
            let calculatedDelta = messageThirdTrip.delta * -1.0
            peersInGame.setDelta(peerID, delta: calculatedDelta)
            println("Received Third Trip from \(peerID.displayName)")
            println("3rd Trip: delta \(messageThirdTrip.delta)")
            if (peersInGame.receivedAllDelta()) {
                if diffController != nil {
                    diffController.transitToInstruction()
                }
                else{
                    controller.transitToInstruction()
                }
            }
            
        } else if message.messageType == MessageType.Dead{
            let messageDead = UnsafePointer<MessageDead>(data.bytes).memory
            if let peer = peersInGame.getPeer(peerID){
            	controller.updatePeerDeath(messageDead, peerPlayerID: Int(peer.playerID))
                peersInGame.increaseScore(peer.playerID)
            }
        } else if message.messageType == MessageType.Destination {
			let messageDestination = UnsafePointer<MessageDestination>(data.bytes).memory
            controller.updateDestination(messageDestination)
        
        } else if message.messageType == MessageType.GameOver {
            controller.gameOver()
        } else if message.messageType == MessageType.NeutralInfo{
            let messageNeutral = UnsafePointer<MessageNeutralInfo>(data.bytes).memory
            if let peer = peersInGame.getPeer(peerID){
                controller.updateNeutralInfo(messageNeutral, peerPlayerID: Int(peer.playerID))
            }
        } else if message.messageType == MessageType.Pause {
            let messagePause = UnsafePointer<MessagePause>(data.bytes).memory
            controller.pause()
        } else if message.messageType == MessageType.Reborn {
            let messageReborn = UnsafePointer<MessageReborn>(data.bytes).memory
            if let peer = peersInGame.getPeer(peerID){
                controller.updateReborn(messageReborn, peerPlayerID: Int(peer.playerID))
            }
//        } else if message.messageType == MessageType.Exit {
//            if let peer = peersInGame.getPeer(peerID){
//                peersInGame.removePeer(peer)
//            }
        } else if message.messageType == MessageType.ChooseGameMode {
            let messageChooseGameMode = UnsafePointer<MessageChooseGameMode>(data.bytes).memory
            let numConnectedPeers = messageChooseGameMode.numConnectedPeers
            gameState = .InLevelViewController
            peersInGame.numOfPlayers = Int(numConnectedPeers)	// set numOfPlayersEnterGame
            stopConnecting()
            if peersInGame.getNumPlayers() > Int(numConnectedPeers) {
                for peer in peersInGame.peers {
                    if !peer.peerID.isEqual(peerID) && !peer.peerID.isEqual(me.peerID) {
                        sendForceExitSession(peer.peerID)
                        peersInGame.removePeer(peer)
                        break
                    }
                }
            }
        } else if message.messageType == MessageType.ForceExitSession {
        	session.disconnect()
        }
    }
    
    // The following methods do nothing, but the MCSessionDelegate protocol
    // requires that we implement them.
    func session(session: MCSession!,
        didStartReceivingResourceWithName resourceName: String!,
        fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!)  {
            
            // Called when a peer starts sending a file to us
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!)  {
            // Called when a file has finished transferring from another peer
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!,
        withName streamName: String!, fromPeer peerID: MCPeerID!)  {
            // Called when a peer establishes a stream with us
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!,
        didChangeState state: MCSessionState)  {
            //stopConnecting()
            println("[numConnectedPeers]: \(session.connectedPeers.count)")
            dispatch_async(dispatch_get_main_queue()) {
                switch self.session.connectedPeers.count {
                case 0:
                    self.controller.player2.text = ""
                    self.controller.player3.text = ""
                case 1:
                    let peer1 = self.session.connectedPeers[0] as MCPeerID
                    self.controller.player2.text = peer1.displayName
                    self.controller.player3.text = ""
                case 2:
                    let peer1 = self.session.connectedPeers[0] as MCPeerID
                    let peer2 = self.session.connectedPeers[1] as MCPeerID
                    self.controller.player2.text = peer1.displayName
                    self.controller.player3.text = peer2.displayName
                default:
                    break
                }
            }
            
            if state == MCSessionState.Connected {
                
                println("[CONNECTED] \(peerID.displayName)")
                determineHost()
                
                if !peersInGame.hasPeer(peerID) {
                    println("add: "+peerID.displayName)
                    let peer = Peer(peerID: peerID)
                    peersInGame.addPeer(peer)
                }
                println("\(peersInGame.getNumPlayers())")
                if peersInGame.getNumPlayers() == maxPlayer{
                    var alert = UIAlertController(title: "Connection Complete", message: "You have connected to maximum number of players!", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    controller.presentViewController(alert, animated: true, completion: nil)
                }
            }
            else if state == MCSessionState.NotConnected {
                println("[LOST CONNECTION] \(invitedPeers.count) "+peerID.displayName)
                
                if let peer = peersInGame.getPeer(peerID) {
                    var alert = UIAlertController(title: "Lost Connection", message: "Lost connection with " + peerID.displayName, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    if diffController != nil {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.diffController.presentViewController(alert, animated: true, completion: nil)
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.controller.presentViewController(alert, animated: true, completion: nil)
                        }
                    }
                    self.controller.deletePlayerLabel(peerID.displayName)
                    // when host exit in level view controller
                    if peer.playerID == 0 && gameState == .InLevelViewController {
                        gameState = .WaitingForStart
                    }
                    peersInGame.removePeer(peer)
                    println("[REMOVED] "+peerID.displayName)
                    deleteFromInvited(peerID)
                    peersInGame.numOfDelta = 1
                    peersInGame.numOfRandomNumber = 0
                    for peer in peersInGame.peers {
                        peer.randomNumber = 0
                    }
                    self.controller.playBtn.layer.removeAllAnimations()
                    
                    if gameState == .WaitingForStart {
                        if peersInGame.getNumPlayers() == 1 {
                            controller.setHostUI(isHost: true, isConnecting: false)
                            controller.addHostLabel(me.getName())
                            me.playerID = 0
                            startConnecting()
                        } else {
                            determineHost()
                        }
                    }
                } else {	// in case initial connection with someone failed
                    if me.playerID == 0 {
                        controller.setHostUI(isHost: true, isConnecting: false)
                        controller.addHostLabel(me.getName())
                    } else {
                        controller.setHostUI(isHost: false, isConnecting: false)
                    }
                }
            }
            else if state == MCSessionState.Connecting {
                println("[CONNECTING] \(peerID.displayName)")
                if gameState == .InLevelViewController {
                    println("[CONNECTION CANCELED]")
                    session.cancelConnectPeer(peerID)
                }
            }
    }
    
}
