//
//  SceneViewController.swift
//  AR-Table-Tennis
//
//  Created by Jack Carey on 12/9/17.
//  Copyright © 2017 Jack Carey. All rights reserved.
//

import UIKit
import SceneKit

class SceneViewController: UIViewController, SCNSceneRendererDelegate {
    
    var scnView: SCNView {
        return self.view as! SCNView
    }
    
    var scnScene: SCNScene!
    var mainCameraNode: SCNNode!
    
    var scrotum: SCNNode!
    
    func setupView(){
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = UIColor.darkGray
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
        scnView.isPlaying = true
    }
    
    func setupCamera(){
        mainCameraNode = SCNNode()
        mainCameraNode.camera = SCNCamera()
        mainCameraNode.position = SCNVector3(-1.5, 2, 2.5)
        mainCameraNode.eulerAngles = SCNVector3(.degToRad(-45), .degToRad(-30), 0)
        scnScene.rootNode.addChildNode(mainCameraNode)
        scnView.pointOfView = mainCameraNode
        
    }
    
    func addTable(){
        let cubeNode = SCNNode(geometry: SCNBox(width: 2.5, height: 0.3, length: 0.05, chamferRadius: 0))
        cubeNode.position = SCNVector3(0, 0.15, 0)
        cubeNode.geometry!.firstMaterial?.diffuse.contents = UIColor.red
        cubeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: cubeNode.geometry!, options: nil))
        
        let floorNode = SCNNode(geometry: SCNPlane(width: 2.5, height: 5))
        floorNode.eulerAngles = SCNVector3(.degToRad(-90), 0, 0)
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0, green: 0.4, blue: 0.9, alpha: 1)
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        
        scrotum = SCNNode()
        scrotum.position = SCNVector3(0,0,0)
        
        scnScene.rootNode.addChildNode(cubeNode)
        scnScene.rootNode.addChildNode(floorNode)
        scnScene.rootNode.addChildNode(scrotum)
    }
    
    func throwBall(){
        let ballNode = SCNNode(geometry: SCNSphere(radius: 0.04))
        ballNode.name = "ball"
        ballNode.position = SCNVector3(0, 1.5, 2.25)
        ballNode.geometry!.firstMaterial?.diffuse.contents = UIColor.green
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: ballNode.geometry!, options: nil))
        ballNode.physicsBody!.applyForce(SCNVector3(0, -5, -5), asImpulse: true)
        ballNode.physicsBody!.mass = 0.0027
        ballNode.physicsBody!.restitution = 0.9
        
        scrotum.addChildNode(ballNode)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        addTable()
        setupCamera()
        throwBall()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        throwBall()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        //clear balls
        for node in scrotum.childNodes {
            if node.name == "ball" && node.presentation.position.y < -1 {
                node.removeFromParentNode()
            }
        }
        
    }
    
    

}
