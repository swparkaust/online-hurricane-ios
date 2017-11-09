//
//  Card.swift
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2014. 8. 31..
//  Copyright (c) 2014년 Ryuhyun Factory. All rights reserved.
//

import Foundation
import SpriteKit

class Card : SKSpriteNode {
    
    let frontTexture :SKTexture
    let backTexture :SKTexture
    var largeTexture :SKTexture?
    let largeTextureFilename :String
    var faceUp = true
    var enlarged = false
    var savedPosition = CGPointZero
    weak var gameScene :GameScene? {
        return scene as? GameScene
    }
    
    init(imageNamed: String) {
        
        // initialize properties
        backTexture = SKTexture(imageNamed: "card_back.png")
        
        frontTexture = SKTexture(imageNamed: "\(imageNamed).png")
        largeTextureFilename = "\(imageNamed)_large.png"
        
        // call designated initializer on super
        super.init(texture: frontTexture, color: nil, size: frontTexture.size())
        
        
        // set properties defined in super
        userInteractionEnabled = true
        
        self.texture = self.backTexture
        if let damageLabel = self.childNodeWithName("damageLabel") {
            damageLabel.hidden = true
        }
        self.faceUp = false
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Touch Handlers
    
    override func touchesBegan(touches: (Set<NSObject>!), withEvent event: (UIEvent!)) {
        savedPosition = position
        
        for touch in touches {
            if gameScene?.match == nil || gameScene?.match?.state.value != MatchStateActive.value { return }
            
            if enlarged {
                runAction(SKAction.playSoundFileNamed("wood-hit.caf", waitForCompletion: false))
                
                NetworkController.sharedInstance().sendDidSlap()
                
                return
            }
            
            if gameScene!.myPlayerIndex == -1 || gameScene!.currentPlayerIndex != gameScene!.myPlayerIndex { return }
            
            zPosition = 15
            let pickup = SKAction.playSoundFileNamed("PlayingCards_Pickup_0\(Int(arc4random_uniform(4)+1)).caf", waitForCompletion: true)
            let liftUp = SKAction.scaleTo(1.2, duration: 0.2)
            let pickAndUp = SKAction.group([pickup, liftUp])
            runAction(pickAndUp)
            
            let wiggleIn = SKAction.scaleXTo(1.0, duration: 0.2)
            let wiggleOut = SKAction.scaleXTo(1.2, duration: 0.2)
            let wiggle = SKAction.sequence([wiggleIn, wiggleOut])
            let wiggleRepeat = SKAction.repeatActionForever(wiggle)
            
            runAction(wiggleRepeat, withKey: "wiggle")
            
            removeActionForKey("jump")
        }
    }
    
    override func touchesMoved(touches: (Set<NSObject>!), withEvent event: (UIEvent!)) {
        if gameScene?.match == nil || gameScene?.match?.state.value != MatchStateActive.value { return }
        
        if gameScene!.myPlayerIndex == -1 || gameScene!.currentPlayerIndex != gameScene!.myPlayerIndex { return }
        
        if enlarged { return }
        
        for touch in touches {
            let location = (touch as! UITouch).locationInNode(scene)
            position = location
        }
    }
    
    override func touchesEnded(touches: (Set<NSObject>!), withEvent event: (UIEvent!)) {
        if gameScene?.match == nil || gameScene?.match?.state.value != MatchStateActive.value { return }
        
        if gameScene!.myPlayerIndex == -1 || gameScene!.currentPlayerIndex != gameScene!.myPlayerIndex { return }
        
        if enlarged { return }
        
        for touch in touches {
            zPosition = 25
            
            let dropDown = SKAction.scaleTo(1.0, duration: 0.2)
            runAction(dropDown)
            
            removeActionForKey("wiggle")
            
            let location = (touch as! UITouch).locationInNode(scene)
            if gameScene!.rect.contains(location) {
                NetworkController.sharedInstance().sendTurnedCard()
            } else {
                let slide = SKAction.moveTo(savedPosition, duration: 0.3)
                runAction(slide)
            }
        }
    }
    
    //MARK: Card Actions
    func flip() {
        let firstHalfFlip = SKAction.scaleXTo(0.0, duration: 0.4)
        let secondHalfFlip = SKAction.scaleXTo(1.0, duration: 0.4)
        
        setScale(1.0)
        
        if faceUp {
            runAction(firstHalfFlip) {
                self.texture = self.backTexture
                if let damageLabel = self.childNodeWithName("damageLabel") {
                    damageLabel.hidden = true
                }
                self.faceUp = false
                self.runAction(secondHalfFlip)
            }
        } else {
            runAction(firstHalfFlip) {
                self.texture = self.frontTexture
                if let damageLabel = self.childNodeWithName("damageLabel") {
                    damageLabel.hidden = false
                }
                self.faceUp = true
                self.runAction(secondHalfFlip)
            }
        }
    }
    
    func enlarge() {
        if enlarged {
            let slide = SKAction.moveTo(savedPosition, duration: 0.3)
            let scaleDown = SKAction.scaleTo(1.0, duration: 0.3)
            runAction(SKAction.group([slide, scaleDown])) {
                self.enlarged = false
                self.zPosition = 0
            }
        } else {
            enlarged = true
            savedPosition = position
            
            if (largeTexture != nil) {
                texture = largeTexture
            } else {
                largeTexture = SKTexture(imageNamed: largeTextureFilename)
                texture = largeTexture
            }
            
            zPosition = 20
            
            let newPosition = CGPointMake(CGRectGetMidX((parent as! SKScene).frame), CGRectGetMidY((parent as! SKScene).frame))
            removeAllActions()
            
            let slide = SKAction.moveTo(newPosition, duration: 0.3)
            let scaleUp = SKAction.scaleTo(4.2, duration: 0.3)
            runAction(SKAction.group([slide, scaleUp]))
        }
    }
    
    func flipAndEnlarge() {
        let firstHalfFlip = SKAction.scaleYTo(0.0, duration: 0.2)
        let secondHalfFlip = SKAction.scaleYTo(4.2, duration: 0.2)
        
        setScale(1.0)
        
        if enlarged {
            let slide = SKAction.moveTo(savedPosition, duration: 0.3)
            let scaleDown = SKAction.scaleTo(1.0, duration: 0.3)
            runAction(firstHalfFlip) {
                self.texture = self.backTexture
                if let damageLabel = self.childNodeWithName("damageLabel") {
                    damageLabel.hidden = true
                }
                self.faceUp = false
                self.runAction(SKAction.group([secondHalfFlip, slide, scaleDown])) {
                    self.enlarged = false
                    self.zPosition = 0
                }
            }
        } else {
            enlarged = true
            savedPosition = position
            
            zPosition = 20
            
            let newPosition = CGPointMake(CGRectGetMidX((parent as! SKScene).frame), CGRectGetMidY((parent as! SKScene).frame))
            removeAllActions()
            
            let slide = SKAction.moveTo(newPosition, duration: 0.2)
            let scaleUp = SKAction.scaleTo(4.2, duration: 0.2)
            runAction(firstHalfFlip) {
                self.texture = self.frontTexture
                if let damageLabel = self.childNodeWithName("damageLabel") {
                    damageLabel.hidden = false
                }
                self.faceUp = true
                if (self.largeTexture != nil) {
                    self.texture = self.largeTexture
                } else {
                    self.largeTexture = SKTexture(imageNamed: self.largeTextureFilename)
                    self.texture = self.largeTexture
                }
                self.runAction(SKAction.group([secondHalfFlip, slide, scaleUp]))
            }
        }
    }
}
