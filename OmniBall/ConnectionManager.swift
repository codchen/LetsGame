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
    let maxPlayer = 3
    
    var browser : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID: MCPeerID!
    
    // peerID maps to its playerID
    var peersInGame: Dictionary<MCPeerID, Int> = Dictionary<MCPeerID, Int>()
    var controller: ViewController!
    var randomNumber: UInt32!
    var gameState: GameState = .WaitingForMatch
    var receivedAllRandomNumber: Bool = false
    var randomNumbers = Array<UInt32>()
    var playerID: UInt16 = 0   // the player ID of current player
    
    
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
    
    func generateRandomNumber(){
        randomNumber = arc4random()
        gameState = .WaitingForRandomNumber
        randomNumbers.append(randomNumber)
        println("My Random Number is \(randomNumber)")
        sendRandomNumber(randomNumber)
    }
    
    func sendRandomNumber(number: UInt32){
        var message = MessageRandomNumber(message: Message(messageType: MessageType.RandomNumber), number: number)
        let data = NSData(bytes: &message, length: sizeof(MessageRandomNumber))
        sendData(data, reliable: true)
    }
    
    func sendMove(x: Float, y: Float, dx: Float, dy: Float, count: UInt32, index: UInt16, dt: NSTimeInterval){
        var message = MessageMove(message: Message(messageType: MessageType.Move), x: x, y: y,
            dx: dx, dy: dy, count: count, index: index, dt: dt)
        let data = NSData(bytes: &message, length: sizeof(MessageMove))
        sendData(data, reliable: false)
    }
    
    func sendGameStart(){
        var message = MessageGameStart(message: Message(messageType: MessageType.GameStart), playerID: playerID)
        println("My playerID is \(playerID)")
        let data = NSData(bytes: &message, length: sizeof(MessageGameStart))
        sendData(data, reliable: true)
    }
    
    func sendCaptured(index: UInt16, time: NSTimeInterval, count: UInt32){
        var message = MessageCapture(message: Message(messageType: MessageType.Capture), index: index, time: time, count: count)
        let data = NSData(bytes: &message, length: sizeof(MessageCapture))
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
            controller.updatePeerPos(messageMove, peerPlayerID: peersInGame[peerID]!)
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
            
        } else if message.messageType == MessageType.Dead{
            let messageDead = UnsafePointer<MessageDead>(data.bytes).memory
            controller.updatePeerDeath(messageDead, peerPlayerID: peersInGame[peerID]!)
            
        } else if message.messageType == MessageType.Capture {
			let messageCapture = UnsafePointer<MessageCapture>(data.bytes).memory
            controller.updateCaptured(messageCapture, peerPlayerID: peersInGame[peerID]!)
        } else if message.messageType == MessageType.GameOver {
            peersInGame.removeValueForKey(peerID)
            if peersInGame.count == 0 {
            	controller.gameOver()
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

    }
    
}
