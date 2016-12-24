//
//  GameScene.swift
//  NinjaIntro
//
//  Created by Aditya Batura on 25/9/16.
//  Copyright (c) 2016 Aditya Batura. All rights reserved.
//

import SpriteKit

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1       // 1
    static let Projectile: UInt32 = 0b10      // 2
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self/length()
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "player")
    var monstersDestroyed = 0
    let myLabel = SKLabelNode(fontNamed:"Chalkduster")
    let myclock = SKLabelNode(fontNamed: "Futura")
    var timer = 60
    
    override func didMove(to view: SKView) {
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
        
        //countdown timer
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GameScene.countdown), userInfo: nil, repeats: true)
        updateclock()
        myclock.fontSize = 45
        myclock.position = CGPoint(x:size.width * 0.6, y:size.height * 0.8)
        myclock.fontColor = UIColor.black
        
        /* Setup your scene here */
        changeMyLabelText()
        myLabel.fontSize = 45
        myLabel.position = CGPoint(x:size.width * 0.8, y:size.height * 0.8)
        myLabel.fontColor = UIColor.black
//        UIColor(red:0.26, green:0.26, blue:0.26, alpha:1.0)
        backgroundColor = UIColor(red:0.26, green:0.26, blue:0.26, alpha:1.0)
        
        
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        self.addChild(myLabel)
        self.addChild(player)
        self.addChild(myclock)
        
        player.run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(addMonster),SKAction.wait(forDuration: 1.0)])
            ))
        
        
        //set gravity and contacts delegate when collision is made
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       /* Called when a touch begins */
        
        for touch in touches {
            let location = touch.location(in: self)
            
            //*****************//
            
            // 1- initialise projectile
            let projectile = SKSpriteNode(imageNamed: "projectile")
            run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
            
            //2 - set projectile starting point
            projectile.position = player.position
            
            //3 - calculate offset
            let offset = location - projectile.position
            
            // 4 - Bail out if you are shooting down or backwards
            if (offset.x < 0) { return }
            
            // 5 - OK to add now - you've double checked position
            self.addChild(projectile)
            
            //Physics body smaller than projectile
            projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
            
            //projectile will not be controlled by physics body, it will be coded
            projectile.physicsBody?.isDynamic = true
            
            //category as described by the 32bit integer
            projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
            
            //collide with what
            projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
            
            // take no action when collide, they will go through each other
            projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
            
            // use this cuz the bodies are moving fast. In case it doesn't get detected
            projectile.physicsBody?.usesPreciseCollisionDetection = true
            
            // 6 - Get the direction of where to shoot
            let direction = offset.normalized()
            
            // 7 - Make it shoot far enough to be guaranteed off screen
            let shootAmount = direction * 1000
            
            // 8 - Add the shoot amount to the current position
            let realDest = shootAmount + projectile.position
            
            // 9 - Create the actions
            let actionMove = SKAction.move(to: realDest, duration: 2.0)
            let actionMoveDone = SKAction.removeFromParent()
            projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
            
            //*****************//
            
            let sprite = SKSpriteNode(imageNamed:"Spaceship")
            
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            sprite.position = location
            
            let action = SKAction.rotate(byAngle: CGFloat(M_PI), duration:1)
            
            sprite.run(SKAction.repeatForever(action))
            
//            self.addChild(sprite)
        }
    }
   
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
    }
    
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        
        // Create sprite
        let monster = SKSpriteNode(imageNamed: "monster")
        
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        // Add the monster to the scene
        addChild(monster)
        
        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Create the actions
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        monster.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        // Create a physics body, a rectangle of the size of the monster
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
        
        // Physics engine will not control the body, it will be controlled by the code
        monster.physicsBody?.isDynamic = true
        
        
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        
    }
    
    
    func projectileDidCollideWithMonster(_ projectile:SKSpriteNode, monster:SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        monstersDestroyed += 1
        changeMyLabelText()
        if (monstersDestroyed > 30) {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
            // why no projectile
            projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode,monster: secondBody.node as! SKSpriteNode)
        }
        
    }
    
    func changeMyLabelText(){
        myLabel.text = "Score: \(monstersDestroyed)"
    }
    
    func updateclock() {
        myclock.text = String(timer)
//        myclock.text = String(format: "%.2f",timer)
    }
    
    func countdown() {
        if timer > 0 {
            timer = timer - 1
            updateclock()
        }
        else{
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
}
