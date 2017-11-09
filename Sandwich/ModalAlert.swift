//
//  ModalAlert.swift
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2015. 4. 5..
//  Copyright (c) 2015년 Ryuhyun Factory. All rights reserved.
//

import Foundation
import SpriteKit

class CoverNode: SKSpriteNode {
    
    init() {
        super.init(texture: nil, color: SKColor(red: 0, green: 0, blue: 0, alpha: 0.7), size: CGSizeMake(768, 1024))
        userInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ModalAlert {
    
    private struct Static {
        static let kDialogName = "dialogBox"
        static let kAnimationTime = 0.4
        static let kDialogImg = "dialogBox.png"
        static let kOkButtonImg = "ok_button"
        static let kCancelButtonImg = "cancel_button"
        static let kFontName = "HelveticaNeue-Light"
    }
    
    class func CloseAlert(alertDialog: SKSpriteNode!, onCoverNode coverNode: SKSpriteNode!, executingBlock block: (() -> Void)?) {
        alertDialog.runAction(SKAction.scaleTo(0, duration: Static.kAnimationTime))
        
        coverNode.runAction(SKAction.sequence([
            SKAction.fadeAlphaTo(0, duration: Static.kAnimationTime),
            SKAction.runBlock({ () -> Void in
                coverNode.removeFromParent()
                if (block != nil) { block!() }
            })
            ]))
    }
    
    class func ShowAlert(message: String, onScene scene: SKScene!, withOpt1 opt1Name: String, withOpt1Block opt1Block: () -> Void, andOpt2 opt2Name: String?, withOpt2Block opt2Block: (() -> Void)?) {
        var coverNode = CoverNode()
        coverNode.zPosition = CGFloat(Int.max)
        coverNode.position = CGPointMake(CGRectGetMidX(scene.frame), CGRectGetMidY(scene.frame))
        scene.addChild(coverNode)
        coverNode.runAction(SKAction.fadeAlphaTo(80, duration: Static.kAnimationTime))
        
        var dialog = SKSpriteNode(imageNamed: Static.kDialogImg)
        dialog.name = Static.kDialogName
        dialog.position = CGPointMake(0, 0)
        dialog.alpha = 0.85
        
        let msgSize:CGSize = CGSizeMake(dialog.frame.size.width * 0.9, dialog.frame.size.height * 0.55)
        let fontSize:CGFloat = 32
        
        let dialogMsg = DSMultilineLabelNode(fontNamed:Static.kFontName)
        dialogMsg.text = message
        dialogMsg.fontSize = fontSize
        dialogMsg.fontColor = SKColor.blackColor()
        dialogMsg.position = CGPoint(x:0, y:dialog.frame.size.height * 0.2);
        dialogMsg.paragraphWidth = msgSize.width
        dialog.addChild(dialogMsg)
        
        var opt1Button: RFButton = RFButton(defaultButtonImage: opt1Name, activeButtonImage: opt1Name + "_active") { () -> Void in
            self.CloseAlert(dialog, onCoverNode: coverNode, executingBlock: opt1Block)
        }
        opt1Button.position = CGPointMake(((opt2Name != nil) ? dialog.frame.size.width * -0.23 : 0), opt1Button.defaultButton.frame.size.height * 0.6 - dialog.frame.size.height/2)
        dialog.addChild(opt1Button)
        
        var opt2Button:RFButton? = nil
        if (opt2Name != nil) {
            opt2Button = RFButton(defaultButtonImage: opt2Name!, activeButtonImage: opt2Name! + "_active") { () -> Void in
                self.CloseAlert(dialog, onCoverNode: coverNode, executingBlock: opt2Block)
            }
            opt2Button!.position = CGPointMake(dialog.frame.size.width * 0.23, opt1Button.defaultButton.frame.size.height * 0.6 - dialog.frame.size.height/2)
            dialog.addChild(opt2Button!)
        }
        
        coverNode.addChild(dialog)
        
        dialog.setScale(0)
        dialog.runAction(SKEase.ScaleToWithNode(dialog, easeFunction: CurveType.Back, mode: EasingMode.EaseOut, time: Static.kAnimationTime, toValue: 1.0))
    }
    
    class func Ask(question: String, onScene scene: SKScene!, yesBlock: () -> Void, noBlock: () -> Void) {
        ShowAlert(question, onScene: scene, withOpt1: Static.kOkButtonImg, withOpt1Block: yesBlock, andOpt2: Static.kCancelButtonImg, withOpt2Block: noBlock)
    }
    
    class func Confirm(question: String, onScene scene: SKScene!, okBlock: () -> Void, cancelBlock: () -> Void) {
        ShowAlert(question, onScene: scene, withOpt1: Static.kOkButtonImg, withOpt1Block: okBlock, andOpt2: Static.kCancelButtonImg, withOpt2Block: cancelBlock)
    }
    
    class func Tell(statement: String, onScene scene: SKScene!, okBlock: () -> Void) {
        ShowAlert(statement, onScene: scene, withOpt1: Static.kOkButtonImg, withOpt1Block: okBlock, andOpt2: nil, withOpt2Block: nil)
    }
}
