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
    var controller: ViewController!
    
    enum MessageType: Int {
        case GameInit, Move, GameOver, Drop
    }
    
    struct Message {
        let messageType: MessageType
    }
    
    struct MessageMove {
        let message: Message
        let dx: Float
        let dy: Float
        let posX: Float
        let posY: Float
        let rotate: Float
        let dt: Float
    }
    
    struct MessageGameOver {
        let message: Message
    }
    
    struct MessageDrop {
        let message: Message
        let bornPosX: Float
        let bornPosY: Float
        
    }
    
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
    
    func sendMove(dx: Float, dy: Float, posX: Float, posY: Float, rotate: Float, dt: Float){
        var message = MessageMove(message: Message(messageType: MessageType.Move), dx: dx, dy: dy,
            posX: posX, posY: posY, rotate: rotate, dt: dt)
        let data = NSData(bytes: &message, length: sizeof(MessageMove))
        sendData(data)
        
    }
    
    func sendDrop(bornPosX: Float, bornPosY: Float) {
    	var message = MessageDrop(message: Message(messageType: MessageType.Drop), bornPosX: bornPosX, bornPosY: bornPosY)
        let data = NSData(bytes: &message, length: sizeof(MessageDrop))
        sendData(data)
    }
    
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
            // Called when a peer sends an NSData to us
        var message = UnsafePointer<Message>(data.bytes).memory
        
        if message.messageType == MessageType.Move {
            let messageMove = UnsafePointer<MessageMove>(data.bytes).memory
            controller.updatePeerPos(messageMove, peer: peerID)
        } else if message.messageType == MessageType.Drop {
            let messageDrop = UnsafePointer<MessageDrop>(data.bytes).memory
            controller.updatePeerDrop(messageDrop, peer: peerID)
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
