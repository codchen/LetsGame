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
    
    var browser : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID: MCPeerID!
    var peersInGame: [MCPeerID] = []
    var controller: ViewController!
    var randomNumber: UInt32!
    var gameState: GameState = GameState.WaitingForStart
    var playerID: Int = 0   // the player ID of current player
    
    
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
    }
    
//    func generateRandomNumber(){
//        self.randomNumber = arc4random()
//        gameState = GameState.WaitingForMatch
//    }
    
    func sendMove(x: Float, y: Float, dx: Float, dy: Float, count: UInt32, index: UInt16, dt: NSTimeInterval){
        var message = MessageMove(message: Message(messageType: MessageType.Move), x: x, y: y,
            dx: dx, dy: dy, count: count, index: index, dt: dt)
        let data = NSData(bytes: &message, length: sizeof(MessageMove))
        sendData(data)
    }
    
    func sendDrop(bornPosX: Float, bornPosY: Float) {
    	var message = MessageDrop(message: Message(messageType: MessageType.Drop), bornPosX: bornPosX, bornPosY: bornPosY)
        let data = NSData(bytes: &message, length: sizeof(MessageDrop))
        sendData(data)
    }
    
    func sendGameStart(){
        var message = MessageGameStart(message: Message(messageType: MessageType.GameStart))
        let data = NSData(bytes: &message, length: sizeof(MessageGameStart))
        sendData(data)
    }
    
    func sendDeath(index: Int){
        var message = MessageDead(message: Message(messageType: MessageType.Dead), index: index)
        let data = NSData(bytes: &message, length: sizeof(MessageDead))
        sendData(data)
    }
    
    func sendGameOver(){
        var message = MessageGameOver(message: Message(messageType: MessageType.GameOver))
        let data = NSData(bytes: &message, length: sizeof(MessageGameOver))
        sendData(data)
    }
    
//    func sendRawData(dx: Float, dy: Float){
//        var message = MessageRawData(message: Message(messageType: MessageType.RawData), dx: dx, dy: dy)
//        let data = NSData(bytes: &message, length: sizeof(MessageRawData))
//        sendToHost(data)
//    }
//
//    func sendDataTo(data: NSData, peer: MCPeerID){
//        var error : NSError?
//        if session.connectedPeers.count != 0 {
//            let success = session.sendData(data, toPeers: [peer], withMode: MCSessionSendDataMode.Reliable, error: &error)
//            
//            if !success {
//                if let error = error {
//                    println("Error sending data:\(error.localizedDescription)")
//                }
//            }
//        }
//    }
    
//    func sendToHost(data: NSData){
//        var error: NSError?
//        if hostID.count > 0{
//            let success = session.sendData(data, toPeers: hostID, withMode: MCSessionSendDataMode.Unreliable, error: &error)
//            
//            if !success{
//                if let error = error{
//                    println("Error sending data:\(error.localizedDescription)")
//
//                }
//            }
//        }
//    }
    
    func sendData(data: NSData){
        
        var error : NSError?
        if session.connectedPeers.count != 0 {
            let success = session.sendData(data, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Unreliable, error: &error)
        
            if !success {
                if let error = error {
            		println("Error sending data:\(error.localizedDescription)")
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
            controller.updatePeerPos(messageMove, peer: peerID)
        } else if message.messageType == MessageType.GameStart {
            if gameState != GameState.InGame {
                playerID++
            }
            peersInGame.append(peerID)
        } else if message.messageType == MessageType.Dead{
            let messageDead = UnsafePointer<MessageDead>(data.bytes).memory
            controller.updatePeerDeath(messageDead)
        } else if message.messageType == MessageType.GameOver {
            peersInGame.removeAll(keepCapacity: false)
            controller.gameOver()
        }
//        else if message.messageType == MessageType.Drop {
//            let messageDrop = UnsafePointer<MessageDrop>(data.bytes).memory
//            controller.updatePeerDrop(messageDrop, peer: peerID)
//        } else if message.messageType == MessageType.AddScore {
//            let messageAddScore = UnsafePointer<MessageAddScore>(data.bytes).memory
//            controller.addScore(messageAddScore)
//        }

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

    }
    
}
