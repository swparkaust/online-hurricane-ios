//
//  LogoScene.swift
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2/27/15.
//  Copyright (c) 2015 Ryuhyun Factory. All rights reserved.
//

import Foundation
import SpriteKit

class LogoScene: SKScene {
    init(size: CGSize, index: Int) {
        super.init(size: size)
        
        backgroundColor = SKColor.whiteColor()
        
        var name1 = "ryuhyunfactory_logo"
        var name2 = "onlinesandwiches_logo"
        var array:[String] = [name1, name2]
        var name = array[index]
        
        let logo = SKSpriteNode(imageNamed:name)
        logo.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(logo)
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(2.0),
            SKAction.runBlock() {
                if index < array.count - 1 {
                    let fade = SKTransition.fadeWithColor(SKColor.whiteColor(), duration: 1.0)
                    let logoScene = LogoScene(size: self.size, index: index + 1)
                    /* Set the scale mode to scale to fit the window */
                    logoScene.scaleMode = .AspectFill
                    logoScene.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                    self.view?.presentScene(logoScene, transition: fade)
                } else {
                    let fade = SKTransition.fadeWithColor(SKColor.whiteColor(), duration: 1.0)
                    if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
                        /* Set the scale mode to scale to fit the window */
                        scene.scaleMode = .AspectFill
                        scene.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                        
                        self.view?.presentScene(scene, transition:fade)
                    }
                }
            }
        ]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
