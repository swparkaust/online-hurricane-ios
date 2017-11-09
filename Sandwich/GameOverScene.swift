import Foundation
import SpriteKit

class GameOverScene: SKScene {
    
    init(size: CGSize, won:Bool) {
        
        super.init(size: size)
        
        backgroundColor = SKColor.whiteColor()
        
        var message = won ? "You win!" : "You lose!"
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Light")
        label.text = message
        label.fontSize = 87
        label.fontColor = SKColor.blackColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(3.0),
            SKAction.runBlock() {
                NetworkController.sharedInstance().sendRestartMatch()
                
                let reveal = SKTransition.flipHorizontalWithDuration(0.5)
//                let scene = GameScene(size: size)
                if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
                    /* Set the scale mode to scale to fit the window */
                    scene.scaleMode = .AspectFill
                    scene.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                    
                    self.view?.presentScene(scene, transition:reveal)
                }
            }
        ]))
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}