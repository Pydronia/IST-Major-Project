//
//  ViewController.swift
//  AR-Table-Tennis
//
//  Created by Jack Carey on 4/9/17.
//  Copyright © 2017 Jack Carey. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import QuartzCore

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var scnView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    var scnScene: SCNScene!
    var gameState: GameState!
    
    // MARK: - Setup Functions
    
    func setupView() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnView.delegate = self
        scnView.isPlaying = true
        gameState = GameState(initialState: .planeMapping)
        statusLabel.layer.cornerRadius = 10
    }
    
    // Load the scene and do some setup
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    // start the session on the view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.isLightEstimationEnabled = true
        scnView.session.run(config)
        // TODO: Test and change this value for optimal performance (1/120 seems to be failsafe w/ 5cm thick planes
        scnView.scene.physicsWorld.timeStep = 1/120
        
        //DEBUG
        scnView.showsStatistics = true
        //scnView.debugOptions
        
        statusLabel.text = "Move your device around and map your environment: When you're satisfied with the surfaces, tap the screen."
    }
    
    // MARK: - Main Methods
    
    // MARK: Plane Mapping
    
    func createPlaneNode(center: vector_float3, extent: vector_float3) -> SCNNode {
        /*
        let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z)))
    
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.4)
        let collider = SCNPhysicsShape(
            geometry: /*SCNBox(width: CGFloat(extent.x), height: CGFloat(extent.z), length: 0.1, chamferRadius: 0)*/planeNode.geometry!,
            options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin : 0.01])
        
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: collider)
        
        planeNode.position = SCNVector3(center.x, 0, center.z)
        planeNode.eulerAngles.x = Float(.degToRad(-90))
        
        return planeNode
        */
        let planeNode = SCNNode(geometry: SCNBox(width: CGFloat(extent.x), height: 0.05, length: CGFloat(extent.z), chamferRadius: 0))
        
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.4)
        
        let collider = SCNPhysicsShape(
            geometry: planeNode.geometry!,
            options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin : 0.01])
        
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: collider)
        
        planeNode.position = SCNVector3(center.x, -0.025, center.z)
        
        return planeNode
        
    }
    
    func updatePlaneNode(_ node: SCNNode, center: vector_float3, extent: vector_float3) {
        
         let geometry = node.geometry as! SCNBox
        
        geometry.width = CGFloat(extent.x)
        geometry.length = CGFloat(extent.z)
        node.position = SCNVector3Make(center.x, -0.025, center.z)
        node.physicsBody?.physicsShape = SCNPhysicsShape(
            geometry: geometry,
            options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin : 0.01])
 
    }
    
    // MARK: Ball Throwing
    
    func throwBall(){
        let ballNode = SCNNode(geometry: SCNSphere(radius: 0.02))
        ballNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.02), options: nil))
        
        let direction = SCNVector3(-scnView.pointOfView!.transform.m31, -scnView.pointOfView!.transform.m32, -scnView.pointOfView!.transform.m33)
        
        ballNode.position = scnView.pointOfView!.position + direction * 0.1
    
        //direction.y = 0.5
        
        ballNode.physicsBody?.applyForce(direction * 5, asImpulse: true)
        
        
        
        scnScene.rootNode.addChildNode(ballNode)
    }
    
    // MARK: - Helper Functions
    
    func showMessage(_ message: String, label: UILabel, seconds: Double){
        let previous = label.text
        label.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            if label.text == message {
                label.text = previous
            }
        }
    }
    
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        switch gameState.currentState {
        case .planeMapping:
            gameState.currentState = .setup
            let newConfig = ARWorldTrackingConfiguration()
            newConfig.isLightEstimationEnabled = true
            scnView.session.run(newConfig)
        default:
            throwBall()
        }
    }

    
    
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        switch gameState.currentState {
        case .planeMapping:
            DispatchQueue.main.async {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    let planeNode = self.createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
                    node.addChildNode(planeNode)
                }
            }
        default:
            break
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        switch gameState.currentState {
        case .planeMapping:
            DispatchQueue.main.async {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    self.updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
                }
            }
        default:
            break
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        switch gameState.currentState {
        case .planeMapping:
            guard anchor is ARPlaneAnchor else { return }
            for child in node.childNodes {
                child.removeFromParentNode()
            }
        default:
            break
        }
        
    }
    
    // MARK: - Error Management
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        scnView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}

