//
//  GameScene.swift
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2014. 8. 31..
//  Copyright (c) 2014년 Ryuhyun Factory. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, NetworkControllerDelegate, GKGameCenterControllerDelegate, UITextFieldDelegate {

    var table:SKSpriteNode!
    var deckCard:Card?
    var deckCardBack:Card?
    var pile = [Card]()
    var rankNames:[String]
    var suitNames:[String]
    let rect: CGRect
    var myPlayerIndex:Int
    var currentPlayerIndex:Int
    var debugLabel:SKLabelNode!
    var match:Match?
    var playerLabels:[SKLabelNode] = [SKLabelNode]()
    var scoreLabels:[SKLabelNode] = [SKLabelNode]()
    var topBar:SKSpriteNode?
    var cancelButton:RFButton?
    var textField:UITextField?
    var currentKeyboardHeight: CGFloat! = 0.0
    var mySprite:SKSpriteNode?
    var playButton:RFButton?
    var leaderboardButton:RFButton?
    var helpButton:RFButton?
    var titleShown:Bool
    var score:Int64
    
    required init?(coder aDecoder: NSCoder) {
        // initialize properties
        rankNames = ["ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king"]
        suitNames = ["clubs", "diamonds", "hearts", "spades"]
        rect = CGRect(x: 0.0, y: 153.0, width: 768.0, height: 871.0)
        myPlayerIndex = -1
        currentPlayerIndex = -1
        titleShown = false
        score = 0
        
        // call designated initializer on super
        super.init(coder: aDecoder)
    }

    override func didMoveToView(view: SKView) {
        table = SKSpriteNode(imageNamed:"bg_board.png")
        table.zPosition = -10
        table.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        self.addChild(table)
        
        debugLabel = SKLabelNode(fontNamed:"HelveticaNeue-Light")
        debugLabel.fontSize = 32;
        debugLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(debugLabel)
        
        NetworkController.sharedInstance().authenticateLocalUser()
        
        NetworkController.sharedInstance().delegate = self
        stateChanged(NetworkController.sharedInstance().state)
    }
    
    func newDamageLabel() -> SKLabelNode {
        let damageLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        damageLabel.name = "damageLabel"
        damageLabel.fontSize = 12
        damageLabel.fontColor = UIColor(red: 0.47, green: 0.0, blue: 0.0, alpha: 1.0)
        damageLabel.text = "0"
        damageLabel.position = CGPointMake(25, 40)
        
        return damageLabel
    }
    
    func newOutlineTextLabel(myText:String, color:SKColor = SKColor.blackColor()) -> SKLabelNode {
        let textLabel = SKLabelNode(fontNamed:"HelveticaNeue-Light")
        textLabel.fontSize = 32;
        textLabel.fontColor = SKColor.whiteColor()
        textLabel.text = myText
        textLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        
        let outlineLabel1 = SKLabelNode(fontNamed:"HelveticaNeue-Light")
        outlineLabel1.fontSize = 32;
        outlineLabel1.fontColor = color
        outlineLabel1.text = myText
        outlineLabel1.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        outlineLabel1.zPosition = textLabel.zPosition - 1
        outlineLabel1.position = CGPoint(x:-1, y:0);
        
        textLabel.addChild(outlineLabel1)
        
        let outlineLabel2 = SKLabelNode(fontNamed:"HelveticaNeue-Light")
        outlineLabel2.fontSize = 32;
        outlineLabel2.fontColor = color
        outlineLabel2.text = myText
        outlineLabel2.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        outlineLabel2.zPosition = textLabel.zPosition - 1
        outlineLabel2.position = CGPoint(x:0, y:1);
        
        textLabel.addChild(outlineLabel2)
        
        let outlineLabel3 = SKLabelNode(fontNamed:"HelveticaNeue-Light")
        outlineLabel3.fontSize = 32;
        outlineLabel3.fontColor = color
        outlineLabel3.text = myText
        outlineLabel3.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        outlineLabel3.zPosition = textLabel.zPosition - 1
        outlineLabel3.position = CGPoint(x:0, y:-1);
        
        textLabel.addChild(outlineLabel3)
        
        let outlineLabel4 = SKLabelNode(fontNamed:"HelveticaNeue-Light")
        outlineLabel4.fontSize = 32;
        outlineLabel4.fontColor = color
        outlineLabel4.text = myText
        outlineLabel4.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        outlineLabel4.zPosition = textLabel.zPosition - 1
        outlineLabel4.position = CGPoint(x:1, y:0);
        
        textLabel.addChild(outlineLabel4)
        
        return textLabel
    }
    
    func writeChat(string:String, color:UIColor = UIColor.grayColor()) {
        let textLabel = newOutlineTextLabel(string, color: color)
        textLabel.position = convertPointFromView(CGPointMake(8, textField!.frame.origin.y))
        textLabel.zPosition = 101
        
        let newPosition = CGPointMake(textLabel.position.x, self.size.height + textLabel.frame.size.height/2)
        let slide = SKAction.moveTo(newPosition, duration: 10.0)
        let remove = SKAction.removeFromParent()
        
        textLabel.runAction(SKAction.sequence([slide, remove]))
        
        self.addChild(textLabel)
    }
    
    func calculateZIndexesForCards() {
        if let deckCard = deckCard {
            deckCard.zPosition = 52
        }
        
        for i in 0..<pile.count {
            pile[i].zPosition = CGFloat(i)
        }
    }
    
    func findMatch() {
        runAction(SKAction.playSoundFileNamed("affirm.caf", waitForCompletion: false))
        
        let delegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        NetworkController.sharedInstance().findMatchWithMinPlayers(2, maxPlayers: 4, viewController: delegate.window!.rootViewController)
    }
    
    func showLeaderboard() {
        runAction(SKAction.playSoundFileNamed("affirm.caf", waitForCompletion: false))
        
        showLeaderboardAndAchievements(true)
    }
    
    func showHelp() {
        runAction(SKAction.playSoundFileNamed("affirm.caf", waitForCompletion: false))
        
        ModalAlert.Tell("Swipe up the stack to play.\nTap the matching pair to win cards.\nWin all the cards.", onScene: self, okBlock: { () -> Void in
            self.runAction(SKAction.playSoundFileNamed("affirm.caf", waitForCompletion: false))
        })
    }
    
    func quitMatch() {
        runAction(SKAction.playSoundFileNamed("affirm.caf", waitForCompletion: false))
        
        ModalAlert.Ask("End Game?\nThis will terminate the game for all other players.", onScene: self, yesBlock: { () -> Void in
            self.runAction(SKAction.playSoundFileNamed("affirm.caf", waitForCompletion: false))
            
            NetworkController.sharedInstance().sendQuitMatch()
            }) { () -> Void in
                self.runAction(SKAction.playSoundFileNamed("affirm.caf", waitForCompletion: false))
        }
    }
    
    func reportScore() {
        var leaderBoard = GKLeaderboard()
        leaderBoard.identifier = NetworkController.sharedInstance().leaderboardIdentifier
        leaderBoard.timeScope = GKLeaderboardTimeScope.AllTime
        leaderBoard.range = NSMakeRange(1, 1)
        
        leaderBoard.loadScoresWithCompletionHandler({ (scores: [AnyObject]!, error: NSError!) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                var localScore:GKScore? = leaderBoard.localPlayerScore
                let newValue:Int64 = {
                    if let localScore = localScore {
                        return localScore.value + self.score
                    } else {
                        return self.score
                    }
                }()
                localScore = GKScore(leaderboardIdentifier: NetworkController.sharedInstance().leaderboardIdentifier)
                localScore!.value = newValue
                
                GKScore.reportScores([localScore!], withCompletionHandler: { (error: NSError!) -> Void in
                    if (error != nil) {
                        println("\(error.localizedDescription)")
                    }
                })
            })
        })
    }
    
    func showLeaderboardAndAchievements(shouldShowLeaderboard: Bool) {
        var gcViewController = GKGameCenterViewController()
        
        gcViewController.gameCenterDelegate = self
        
        if shouldShowLeaderboard {
            gcViewController.viewState = GKGameCenterViewControllerState.Leaderboards
            gcViewController.leaderboardIdentifier = NetworkController.sharedInstance().leaderboardIdentifier
        } else {
            gcViewController.viewState = GKGameCenterViewControllerState.Achievements
        }
        
        let delegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        delegate.window!.rootViewController?.presentViewController(gcViewController, animated: true, completion: nil)
    }
    
    func fieldRect() -> CGRect {
        let fWidth:CGFloat = self.view!.frame.size.width
        let fHeight:CGFloat = 31
        let fX:CGFloat = 0
        let fY:CGFloat = self.view!.frame.size.height - fHeight
        return CGRectMake(fX, fY, fWidth, fHeight)
    }
    
    func processReturn() {
        if let textField = textField {
            textField.resignFirstResponder()
            if !textField.text.isEmpty {
                NetworkController.sharedInstance().sendChat(textField.text)
                textField.text = ""
            }
        }
    }
    
    func isCorrectTypeOfString(str:NSString) -> Bool {
//        let notLetters:NSCharacterSet = NSCharacterSet.letterCharacterSet().invertedSet
//        if str.rangeOfCharacterFromSet(notLetters).location == NSNotFound {
            return true
//        }
//        return false
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize =  (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
                let deltaHeight:CGFloat = keyboardSize.height - currentKeyboardHeight
                self.animateTextField(true, deltaHeight: deltaHeight)
                currentKeyboardHeight = keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize =  (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
                self.animateTextField(false, deltaHeight: keyboardSize.height)
                currentKeyboardHeight = 0.0
            }
        }
    }
    
    func animateTextField(up: Bool, deltaHeight: CGFloat) {
        var movement = (up ? -deltaHeight : deltaHeight)
        
        UIView.animateWithDuration(0.3, animations: {
                self.view!.frame = CGRectOffset(self.view!.frame, 0, movement)
        })
    }
    
    func stateChanged(state: NetworkState) {
        switch state.value {
        case NetworkStateNotAvailable.value:
            debugLabel.text = "Not Available"
        case NetworkStatePendingAuthentication.value:
            debugLabel.text = "Pending Authentication"
        case NetworkStateAuthenticated.value:
            debugLabel.text = "Authenticated"
        case NetworkStateConnectingToServer.value:
            debugLabel.text = "Connecting to Server"
        case NetworkStateConnected.value:
            debugLabel.text = "Connected"
        case NetworkStatePendingMatchStatus.value:
            debugLabel.text = "Pending Match Status"
        case NetworkStateReceivedMatchStatus.value:
            debugLabel.text = "Received Match Status"
        case NetworkStatePendingMatch.value:
            debugLabel.text = "Pending Match"
        case NetworkStateMatchActive.value:
            debugLabel.text = "Match Active"
        case NetworkStatePendingMatchStart.value:
            debugLabel.text = "Pending Start"
        default:
            break
        }
    }
    
    func setNotInMatch() {
        debugLabel.hidden = true
        
        if myPlayerIndex != -1 {
            myPlayerIndex = -1
            
            if let deckCard = deckCard {
                if let deckCardBack = deckCardBack {
                    deckCard.removeFromParent()
                    deckCardBack.removeFromParent()
                }
            }
            
            for playerLabel in playerLabels {
                playerLabel.removeFromParent()
            }
            playerLabels.removeAll()
            
            for scoreLabel in scoreLabels {
                scoreLabel.removeFromParent()
            }
            scoreLabels.removeAll()
            
            if let topBar = topBar {
                topBar.removeFromParent()
            }
            
            if let cancelButton = cancelButton {
                cancelButton.removeFromParent()
            }
            
            if let textField = textField {
                textField.removeFromSuperview()
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
            
            table.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
            
            for card in pile {
                card.removeFromParent()
            }
            pile.removeAll()
            
            ModalAlert.Tell("You were disconnected from the game.", onScene: self, okBlock: { () -> Void in
                self.runAction(SKAction.playSoundFileNamed("affirm.caf", waitForCompletion: false))
            })
        }
        
        if !titleShown {
            mySprite = SKSpriteNode(imageNamed:"onlinesandwiches_logo_small")
            
            mySprite!.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
            
            self.addChild(mySprite!)
            
            playButton = RFButton(defaultButtonImage: "play_button", activeButtonImage: "play_button_active", buttonAction: findMatch)
            playButton!.position = CGPointMake(CGRectGetMidX(self.frame), 78)
            addChild(playButton!)
            
            leaderboardButton = RFButton(defaultButtonImage: "leaderboard_button", activeButtonImage: "leaderboard_button_active", buttonAction: showLeaderboard)
            leaderboardButton!.position = CGPointMake(192, 78)
            addChild(leaderboardButton!)
            
            helpButton = RFButton(defaultButtonImage: "help_button", activeButtonImage: "help_button_active", buttonAction: showHelp)
            helpButton!.position = CGPointMake(576, 78)
            addChild(helpButton!)
            
            NSNotificationCenter.defaultCenter().postNotificationName("showiAdBanner", object: nil)
            
            titleShown = true
        }
    }
    
    func matchStarted(theMatch: Match!) {
        
        debugLabel.hidden = true
        
        if titleShown {
            if let mySprite = mySprite {
                if let playButton = playButton {
                    if let leaderboardButton = leaderboardButton {
                        if let helpButton = helpButton {
                            mySprite.removeFromParent()
                            playButton.removeFromParent()
                            leaderboardButton.removeFromParent()
                            helpButton.removeFromParent()
                        }
                    }
                }
            }
            NSNotificationCenter.defaultCenter().postNotificationName("hideiAdBanner", object: nil)
            titleShown = false
        }
        
        match = theMatch
        
        if myPlayerIndex == -1 {
            if let players = match?.players {
                for i in 0..<players.count {
                    if players[i].playerId == GKLocalPlayer.localPlayer().playerID {
                        myPlayerIndex = i
                        break
                    }
                }
            }
            
            var myPlayer: Player = match?.players[myPlayerIndex] as! Player
            
            topBar = SKSpriteNode(imageNamed:"top_bar")
            
            topBar!.position = CGPoint(x:CGRectGetMidX(self.frame), y:965);
            
            self.addChild(topBar!)
            
            for playerLabel in playerLabels {
                playerLabel.removeFromParent()
            }
            playerLabels.removeAll()
            for scoreLabel in scoreLabels {
                scoreLabel.removeFromParent()
            }
            scoreLabels.removeAll()
            if let players = match?.players {
                for i in 0..<players.count {
                    let playerLabel = SKLabelNode(fontNamed:"HelveticaNeue-Light")
                    playerLabel.text = players[i].alias;
                    playerLabel.fontSize = 28;
                    playerLabel.fontColor = SKColor.blackColor()
                    playerLabel.position = CGPoint(x:256 + 128 * i, y:921);
                    
                    playerLabels.append(playerLabel)
                    
                    self.addChild(playerLabel)
                    
                    let scoreLabel = SKLabelNode(fontNamed:"HelveticaNeue-UltraLight")
                    scoreLabel.text = toString((players[i] as! Player).score);
                    scoreLabel.fontSize = 64;
                    scoreLabel.fontColor = SKColor.blackColor()
                    scoreLabel.position = CGPoint(x:256 + 128 * i, y:967);
                    
                    scoreLabels.append(scoreLabel)
                    
                    self.addChild(scoreLabel)
                }
            }
            
            cancelButton = RFButton(defaultButtonImage: "cancel_button", activeButtonImage: "cancel_button_active", buttonAction: quitMatch)
            cancelButton!.xScale = 0.5
            cancelButton!.yScale = 0.5
            cancelButton!.position = CGPointMake(128, 969)
            addChild(cancelButton!)
            
            textField = UITextField(frame: fieldRect())
            textField!.borderStyle = UITextBorderStyle.RoundedRect
            textField!.textColor = UIColor.blackColor()
            textField!.font = UIFont.systemFontOfSize(16.0)
            textField!.backgroundColor = UIColor.whiteColor()
            textField!.autocorrectionType = UITextAutocorrectionType.Default
            textField!.keyboardType = UIKeyboardType.Default
            textField!.clearButtonMode = UITextFieldViewMode.WhileEditing
            textField!.delegate = self
            textField!.placeholder = "Tap here to chat"
            textField!.returnKeyType = UIReturnKeyType.Send
            self.view?.addSubview(textField!)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
            
            table.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) + convertPointFromView(textField!.frame.origin).y)
            
            deckCardBack = Card(imageNamed: "card_back")
            deckCardBack!.position = CGPointMake(384, 78 + convertPointFromView(textField!.frame.origin).y)
            deckCardBack!.userInteractionEnabled = false
            addChild(deckCardBack!)
            
//            if let myDeck = myPlayer.deck as NSArray as? [[String:Int]] {
//                for cardDict in myDeck {
//                    let rank = cardDict["rank"]
//                    let suit = cardDict["suit"]
                    deckCard = Card(imageNamed: "card_back")
                    deckCard!.position = CGPointMake(384, 78 + convertPointFromView(textField!.frame.origin).y)
                    addChild(deckCard!)
            
//                    card.addChild(newDamageLabel())
//                }
//            }
    
            score = Int64(myPlayer.score)
        }
    }
    
    func activatePlayer(playerIndex: UInt8) {
        currentPlayerIndex = Int(playerIndex)
        
        if currentPlayerIndex == myPlayerIndex {
            let dropHeight:CGFloat = 100.0
            
            let bounceFactor: CGFloat = 0.5
            let riseAction = SKAction.moveByX(0, y: dropHeight, duration: 0.3)
            let dropAction = SKAction.moveByX(0, y: -dropHeight, duration: 0.3)
            let bounce = SKAction.sequence([SKAction.moveByX(0, y: dropHeight*bounceFactor, duration: 0.1),
                SKAction.moveByX(0, y: -dropHeight*bounceFactor, duration: 0.1),
                SKAction.moveByX(0, y: dropHeight*bounceFactor/2, duration: 0.1),
                SKAction.moveByX(0, y: -dropHeight*bounceFactor/2, duration: 0.1)])
            let wait = SKAction.waitForDuration(1.0)
            let jump = SKAction.sequence([riseAction, SKAction.group([dropAction, bounce]), wait])
            let jumpRepeat = SKAction.repeatActionForever(jump)
            
            if let deckCard = deckCard {
                deckCard.runAction(jumpRepeat, withKey: "jump")
            }
        } else {
            if let deckCard = deckCard {
                deckCard.removeActionForKey("jump")
            }
        }
    }
    
    func player(playerIndex: UInt8, turnedCardWithRank rank: Int32, suit: Int32, playerScore: Int32) {
        if Int(playerIndex) == myPlayerIndex {
            if let deckCard = deckCard {
                deckCard.position = CGPointMake(384, 78 + convertPointFromView(textField!.frame.origin).y)
            }
        }
        
        if Int(playerIndex) == myPlayerIndex {
            if let deckCard = deckCard {
                if let deckCardBack = deckCardBack {
                    switch playerScore {
                    case 0:
                        deckCard.hidden = true
                        deckCardBack.hidden = true
                    case 1:
                        deckCard.hidden = false
                        deckCardBack.hidden = true
                    default:
                        deckCard.hidden = false
                        deckCardBack.hidden = false
                    }
                }
            }
        }
        
        let card = Card(imageNamed: "\(rankNames[Int(rank)])_of_\(suitNames[Int(suit)])")
        let newPosition = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        card.position = newPosition
        pile.append(card)
        addChild(card)
        
        card.flipAndEnlarge()
        
        runAction(SKAction.playSoundFileNamed("PlayingCards_DealFlip_0\(Int(arc4random_uniform(7)+1)).caf", waitForCompletion: false))
        
        if Int(playerIndex) == myPlayerIndex {
            let damageLabel = newDamageLabel()
            damageLabel.text = "-\(score - Int64(playerScore))"
            damageLabel.fontSize = 32;
            damageLabel.fontColor = UIColor(red: 1, green: 0.231, blue: 0.188, alpha: 1)
            damageLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:512);
            damageLabel.zPosition = 100
            
            let newPosition = CGPointMake(CGRectGetMidX(self.frame), self.size.height + damageLabel.frame.size.height/2)
            let slide = SKAction.moveTo(newPosition, duration: 3.0)
            let remove = SKAction.removeFromParent()
            
            damageLabel.runAction(SKAction.sequence([slide, remove]))
            
            self.addChild(damageLabel)
            
            score = Int64(playerScore)
        }
        scoreLabels[Int(playerIndex)].text = toString(playerScore)
        
        calculateZIndexesForCards()
    }
    
    func playerClaimedPile(playerIndex: UInt8, playerScore: Int32) {
        if Int(playerIndex) == myPlayerIndex {
            if let deckCard = deckCard {
                if let deckCardBack = deckCardBack {
                    switch playerScore {
                    case 0:
                        deckCard.hidden = true
                        deckCardBack.hidden = true
                    case 1:
                        deckCard.hidden = false
                        deckCardBack.hidden = true
                    default:
                        deckCard.hidden = false
                        deckCardBack.hidden = false
                    }
                }
            }
        }
        
        for card in pile {
            let flipAndEnlarge = SKAction.runBlock(card.flipAndEnlarge)
            let delay = SKAction.waitForDuration(0.5)
            let newPosition: CGPoint = {
                if Int(playerIndex) == self.myPlayerIndex {
                    return CGPointMake(384, 78 + self.convertPointFromView(self.textField!.frame.origin).y)
                } else {
                    return CGPointMake(384, self.size.height + card.size.height/2)
                }
            }()
            let slide = SKAction.moveTo(newPosition, duration: 0.3)
            let remove = SKAction.removeFromParent()
            card.runAction(SKAction.sequence([flipAndEnlarge, delay, slide, remove]))
        }
        pile.removeAll()
        
        runAction(SKAction.playSoundFileNamed("PlayingCards_Slide_0\(Int(arc4random_uniform(4)+1)).caf", waitForCompletion: false))
        
        if Int(playerIndex) == myPlayerIndex {
            let damageLabel = newDamageLabel()
            damageLabel.text = "+\(Int64(playerScore) - score)"
            damageLabel.fontSize = 32;
            damageLabel.fontColor = UIColor(red: 0.298, green: 0.851, blue: 0.392, alpha: 1)
            damageLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:512);
            damageLabel.zPosition = 100
            
            let newPosition = CGPointMake(CGRectGetMidX(self.frame), self.size.height + damageLabel.frame.size.height/2)
            let slide = SKAction.moveTo(newPosition, duration: 3.0)
            let remove = SKAction.removeFromParent()
            
            damageLabel.runAction(SKAction.sequence([slide, remove]))
            
            self.addChild(damageLabel)
            
            score = Int64(playerScore)
        }
        scoreLabels[Int(playerIndex)].text = toString(playerScore)
        
        if let players = match?.players {
            writeChat("\(players[Int(playerIndex)].alias) wins cards", color: UIColor(red: 1, green: 0.8, blue: 0, alpha: 1))
        }
        
        calculateZIndexesForCards()
    }
    
    func player(playerIndex: UInt8, discardedCardWithRank rank: Int32, suit: Int32, playerScore: Int32) {
        if Int(playerIndex) == myPlayerIndex {
            if let deckCard = deckCard {
                if let deckCardBack = deckCardBack {
                    switch playerScore {
                    case 0:
                        deckCard.hidden = true
                        deckCardBack.hidden = true
                    case 1:
                        deckCard.hidden = false
                        deckCardBack.hidden = true
                    default:
                        deckCard.hidden = false
                        deckCardBack.hidden = false
                    }
                }
            }
        }
        
        let card = Card(imageNamed: "\(rankNames[Int(rank)])_of_\(suitNames[Int(suit)])")
        let newPosition: CGPoint = {
            if Int(playerIndex) == self.myPlayerIndex {
                return CGPointMake(384, 78 + self.convertPointFromView(self.textField!.frame.origin).y)
            } else {
                return CGPointMake(384, self.size.height + card.size.height/2)
            }
            }()
        card.position = newPosition
        pile.insert(card, atIndex: 0)
        addChild(card)
        
        card.flipAndEnlarge()
        
        runAction(SKAction.playSoundFileNamed("PlayingCards_DealFlip_0\(Int(arc4random_uniform(7)+1)).caf", waitForCompletion: false))
        
        if Int(playerIndex) == myPlayerIndex {
            let damageLabel = newDamageLabel()
            damageLabel.text = "-\(score - Int64(playerScore))"
            damageLabel.fontSize = 32;
            damageLabel.fontColor = UIColor(red: 1, green: 0.231, blue: 0.188, alpha: 1)
            damageLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:512);
            damageLabel.zPosition = 100
            
            let newPosition = CGPointMake(CGRectGetMidX(self.frame), self.size.height + damageLabel.frame.size.height/2)
            let slide = SKAction.moveTo(newPosition, duration: 3.0)
            let remove = SKAction.removeFromParent()
            
            damageLabel.runAction(SKAction.sequence([slide, remove]))
            
            self.addChild(damageLabel)
            
            score = Int64(playerScore)
        }
        scoreLabels[Int(playerIndex)].text = toString(playerScore)
        
        writeChat("No match!", color: UIColor(red: 1, green: 0.8, blue: 0, alpha: 1))
        
        calculateZIndexesForCards()
    }
    
    func gameOver(winnerIndex: UInt8, winnerScore: Int32) {
        match?.state = MatchStateGameOver
        if Int(winnerIndex) == myPlayerIndex {
            score = Int64(winnerScore)
        }
        reportScore()
        if let textField = textField {
            textField.removeFromSuperview()
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if Int(winnerIndex) == myPlayerIndex {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            /* Set the scale mode to scale to fit the window */
            gameOverScene.scaleMode = .AspectFill
            gameOverScene.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
            self.view?.presentScene(gameOverScene, transition: reveal)
        } else {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            /* Set the scale mode to scale to fit the window */
            gameOverScene.scaleMode = .AspectFill
            gameOverScene.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func chat(text: String!) {
        writeChat(text, color: UIColor.grayColor())
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        processReturn()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if isCorrectTypeOfString(string) {
            return true
        }
        return false
    }
}
