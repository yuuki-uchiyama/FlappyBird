//
//  GameScene.swift
//  FlappyBird
//
//  Created by 内山由基 on 2018/06/05.
//  Copyright © 2018年 yuuki uchiyama. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var itemNode: SKNode!
    var bird: SKSpriteNode!
    
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let wallScoreCategory: UInt32 = 1 << 3
    let itemScoreCategory: UInt32 = 1 << 4
    
    //難易度調整の為のプロパティ
    var adjustment = 1.00
    var adjustBirdFly = 1.00
    var amountOfChange1 = 1.00
    var amountOfChange2 = 1.00

    var bestScore = 0
    var score = 0
    var itemScore = 0
    var wallScore = 0
    var itemScoreLabelNode: SKLabelNode!
    var scoreLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //効果音
    let birdFlapSound = SKAction.playSoundFileNamed("birdflap.mp3", waitForCompletion: false)
    let wallCrashSound = SKAction.playSoundFileNamed("wallcrash.mp3", waitForCompletion: false)
    let chickCatchSound = SKAction.playSoundFileNamed("chickcatch.mp3", waitForCompletion: false)
    
    var rollNumber = 0
    
    override func didMove(to view: SKView) {
        
        //後で色々変えてみる
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        bestScore = userDefaults.integer(forKey: "BEST")
        setupScoreLabel()
    }
    
    func setupScoreLabel(){
        score = 0
        itemScore = 0
        
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "BEST Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
    }
    
    //地面の画像・動作
    func setupGround(){
        //画像読み込み
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        //frameを満たすために何枚のgroundTextureが必要か計算（iPhoneのサイズによって異なるため）。　＋動かすために2枚多くする
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        //地面を動かすアクション（最初は右側に配置　→ 左（マイナス方向へ）へゆっくり画像一つ分動かす　→ 一瞬で元の位置に　→ 繰り返し）
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0 , duration: 5.0)
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        //上のneedNumberで計算した枚数分画像を作成し、並べる
        for i in 0..<needNumber{
        //画像をスプライトに
        let groundSprite = SKSpriteNode(texture: groundTexture)
        
        //位置の決定
        groundSprite.position = CGPoint(
            x: groundTexture.size().width * (CGFloat(i) + 0.5),
            y: groundTexture.size().height * 0.5
        )
        //実装
            groundSprite.run(repeatScrollGround)
            
            groundSprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            groundSprite.physicsBody?.categoryBitMask = groundCategory
            groundSprite.physicsBody?.isDynamic = false
            
            scrollNode.addChild(groundSprite)
        }
    }
    
    //雲の画像・動作
    func setupCloud(){
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        //雲を動かすアクション（最初は右側に配置　→ 左（マイナス方向へ）へゆっくり画像一つ分動かす　→ 一瞬で元の位置に　→ 繰り返し）
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0 , duration: 20.0)
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //上のneedNumberで計算した枚数分画像を作成し、並べる
        for i in 0..<needCloudNumber{
            //画像をスプライトに
            let cloudSprite = SKSpriteNode(texture: cloudTexture)
            cloudSprite.zPosition = -100
            
            //位置の決定：y軸（高さ）を上にするため、Viewの高さ–画像の高さと設定
            cloudSprite.position = CGPoint(
                x: cloudTexture.size().width * (CGFloat(i) + 0.5),
                y: self.size.height - cloudTexture.size().height * 0.5
            )
            //実装
            cloudSprite.run(repeatScrollCloud)
            scrollNode.addChild(cloudSprite)
        }
    }
    
    func setupWall(){
        
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        let moveWall = SKAction.moveBy(x: -movingDistance , y: 0 , duration: 4.0)
        let removeWall = SKAction.removeFromParent()
        
        let wallAnimation = SKAction.repeatForever(SKAction.sequence([moveWall, removeWall]))
        
        let createWallAnimation = SKAction.run({
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0
            
            let center_y = self.frame.size.height / 2 //高さの中心
            let random_y_range = self.frame.size.height / 4 //下壁の高さをランダムに動かす範囲・・・フレームの高さの１/４
            //下壁の位置の高さ・・・中心　– 壁の高さの半分　– ランダムに動かす範囲の半分　＝　ランダムの範囲が中心から半分ずつになる
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 - random_y_range / 2)
            
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            let slit_length = self.frame.size.height / 5
            
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            wall.addChild(upper)
            
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.isDynamic = false
            upper.physicsBody?.isDynamic = false
            
            let wallScoreNode = SKNode()
            wallScoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            wallScoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            wallScoreNode.physicsBody?.isDynamic = false
            wallScoreNode.physicsBody?.categoryBitMask = self.wallScoreCategory
            wallScoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(wallScoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupItem(){// https://rakugakiicon.com/
        //画像をテクスチャに変換
        let itemTexture = SKTexture(imageNamed: "chick")
        itemTexture.filteringMode = .linear
        
        //アイテムの出現位置（高さ）の範囲設定
        let item_center_y = self.frame.size.height / 2
        let item_random_y_range = self.frame.size.height / 3
        let item_random_x_range = self.frame.size.width / 3
        let under_item_lowest_y = UInt32( item_center_y - item_random_y_range / 2)
        
        //アイテムの移動設定
        let itemMovingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
        let moveItem = SKAction.moveBy(x: -itemMovingDistance * 1.5 , y: 0 , duration: 4.0 * 1.5)
        let removeItem = SKAction.removeFromParent()
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        

        
        //アイテムを作る設定
        let createItemAnimation = SKAction.run({
                let itemRandomNumber = arc4random_uniform(4)
                print(itemRandomNumber)
                if itemRandomNumber == 0{
                    let item_random_y = arc4random_uniform( UInt32(item_random_y_range) )
                    let item_random_x = arc4random_uniform(UInt32(item_random_x_range))
                    let itemAppearPoint = CGFloat(under_item_lowest_y + item_random_y)
                    let itemSprite = SKSpriteNode(texture: itemTexture)

                    itemSprite.position = CGPoint(x: itemMovingDistance + CGFloat(item_random_x), y:itemAppearPoint)
                    itemSprite.zPosition = -60
                    
                    itemSprite.physicsBody = SKPhysicsBody(circleOfRadius: itemSprite.size.height / 2.0)
                    itemSprite.physicsBody?.isDynamic = false
                    itemSprite.physicsBody?.categoryBitMask = self.itemScoreCategory
                    itemSprite.physicsBody?.contactTestBitMask = self.birdCategory
                    
                    itemSprite.run(itemAnimation)
                    self.itemNode.addChild(itemSprite)//error
                }
            
        })
            
            
        let itemBeforeWait = SKAction.wait(forDuration: 0.2)
        let itemAfterWait = SKAction.wait(forDuration: 1.8)
 
            let repeatForeverItem = SKAction.repeatForever(SKAction.sequence([itemBeforeWait, createItemAnimation, itemAfterWait]))
        
        itemNode.run(repeatForeverItem)
    }
    
    func setupBird(){
        //鳥の画像(飛んでいるように見せるため、2つの画像を使用)
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        //二つの画像を０.２秒感覚で入れ替え
        let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        bird.run(flap)
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            self.run(birdFlapSound)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15 * adjustBirdFly))
        }else if bird.speed == 0{
            restart()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if scrollNode.speed <= 0{
            return
        }
        
        if (contact.bodyA.categoryBitMask) == wallScoreCategory || (contact.bodyB.categoryBitMask) == wallScoreCategory{
            wallScore += 1
            score = wallScore + itemScore
            scoreLabelNode.text = "Score:\(score)"
            if wallScore % 3 == 0{
                print("speed up")
                amountOfChange2 = amountOfChange1 * 0.9
                adjustment += amountOfChange1 - amountOfChange2
                adjustBirdFly += (amountOfChange1 - amountOfChange2) / 2
                amountOfChange1 = amountOfChange2
                speedAdjust()
            }
            if score > bestScore{
                bestScore = score
                bestScoreLabelNode.text = "BEST Score:\(bestScore)"
                userDefaults.set(bestScore, forKey:"BEST")
                userDefaults.synchronize()
            }
        }else if (contact.bodyA.categoryBitMask) == itemScoreCategory || (contact.bodyB.categoryBitMask) == itemScoreCategory{
            self.run(chickCatchSound)
            itemScore += 1
            itemScoreLabelNode.text = "ItemScore:\(itemScore)"
            score = wallScore + itemScore
            scoreLabelNode.text = "Score:\(score)"
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore{
                bestScore = score
                bestScoreLabelNode.text = "BEST Score:\(bestScore)"
                userDefaults.set(bestScore, forKey:"BEST")
                userDefaults.synchronize()
            }
            
            if contact.bodyA.categoryBitMask == itemScoreCategory{
                contact.bodyA.node?.removeFromParent()
            }else{
                contact.bodyB.node?.removeFromParent()
            }
        }else if contact.bodyA.categoryBitMask == wallCategory || contact.bodyB.categoryBitMask == wallCategory{
                self.run(wallCrashSound)
            print("gameover")
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            if rollNumber == 0 {
                rollNumber = 1
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
            }
            }
        
    }
    
    func speedAdjust(){
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0 * adjustment)
        
        let wallSpeedAdjust = SKAction.speed(to: CGFloat(adjustment) , duration: 0.5)

        scrollNode.run(wallSpeedAdjust)
    }
    
    func restart(){
        wallScore = 0
        itemScore = 0
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        rollNumber = 0
        
        adjustment = 1.00
        adjustBirdFly = 1.00
        amountOfChange1 = 1.00
        amountOfChange2 = 1.00
        speedAdjust()
        
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }

}
    


