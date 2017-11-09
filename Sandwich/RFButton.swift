//
//  RFButton.swift
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2015. 3. 19..
//  Copyright (c) 2015년 Ryuhyun Factory. All rights reserved.
//

import SpriteKit

class RFButton: SKNode {
    var defaultButton: SKSpriteNode
    var activeButton: SKSpriteNode
    var action: () -> Void
    
    init(defaultButtonImage: String, activeButtonImage: String, buttonAction: () -> Void) {
        defaultButton = SKSpriteNode(imageNamed: defaultButtonImage)
        activeButton = SKSpriteNode(imageNamed: activeButtonImage)
        activeButton.hidden = true
        action = buttonAction
        
        super.init()
        
        userInteractionEnabled = true
        addChild(defaultButton)
        addChild(activeButton)
    }
    
    /**
        Required so XCode doesn't throw warnings
    */
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        activeButton.hidden = false
        defaultButton.hidden = true
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            var location: CGPoint = touch.locationInNode(self)
            
            if defaultButton.containsPoint(location) {
                activeButton.hidden = false
                defaultButton.hidden = true
            } else {
                activeButton.hidden = true
                defaultButton.hidden = false
            }
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            var location: CGPoint = touch.locationInNode(self)
            
            if defaultButton.containsPoint(location) {
                action()
            }
            
            activeButton.hidden = true
            defaultButton.hidden = false
        }
    }
}
