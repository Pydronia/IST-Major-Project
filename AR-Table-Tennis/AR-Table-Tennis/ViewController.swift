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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
   // TODO: Reset button and progression button
   
   // MARK: - Variables
   // MARK: Outlets
   @IBOutlet weak var scnView: ARSCNView!
   @IBOutlet weak var statusLabel: UILabel!
   @IBOutlet weak var errorLabel: UILabel!
   @IBOutlet weak var crosshair: UIImageView!
   
   // MARK: Globals
   var scnScene: SCNScene!
   var gameState: GameState!
   
   var planeNodes: [SCNNode] = []
   
   var ambLight: SCNNode!
    
   var scoreboard: [Int] = []
   
   var table: SCNReferenceNode!
   var paddle: SCNNode!
   var ball: SCNNode!
   
   let tableConstraint = SCNNode()
   
   // MARK: Constants
   var viewCenter: CGPoint!
   
   // MARK: - Setup Functions
   
   func setupView() {
      scnScene = SCNScene()
      scnView.scene = scnScene
      scnView.delegate = self
      scnView.session.delegate = self
      scnView.isPlaying = true
      
      // Ambient light
      
      ambLight = SCNNode()
      ambLight.position = SCNVector3(0,0,0)
      ambLight.light = SCNLight()
      ambLight.light?.type = .ambient
      ambLight.light?.intensity = 1000
      scnScene.rootNode.addChildNode(ambLight)
      
      
      //DEBUG
      
      scnView.showsStatistics = true
      //scnView.debugOptions = .showPhysicsShapes
      
      
      gameState = GameState(initialState: .planeMapping)
      statusLabel.layer.cornerRadius = 10
      errorLabel.layer.cornerRadius = 10
      
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
      // TODO: This doesn't work, so currently manually updating ambient light.
      scnView.automaticallyUpdatesLighting = true
      scnView.session.run(config)
      // TODO: Test and change this value for optimal performance (1/120 seems to be failsafe w/ 5cm thick planes and 1cm collision margin)
      scnView.scene.physicsWorld.timeStep = 1/120
      
      statusLabel.text = "Move your device around and map your environment: When you're satisfied with the surfaces, tap the screen to place the table"
   }
   
   override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      viewCenter = CGPoint(x: scnView.bounds.width/2, y: scnView.bounds.height/2)
   }
   
   // MARK: - Main Methods
   
   // MARK: Plane Mapping
   
   func createPlaneNode(center: vector_float3, extent: vector_float3) -> SCNNode {
      
      // TODO: Make Planes always visible through table
      
      let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z)))
      
      let material = SCNMaterial()
      material.diffuse.contents = UIImage(named: "Resources.scnassets/Textures/PlaneTex.png")
      material.diffuse.wrapS = .repeat
      material.diffuse.wrapT = .repeat
      material.diffuse.contentsTransform = SCNMatrix4MakeScale(extent.x*2, extent.z*2, 1)
      planeNode.geometry?.firstMaterial = material
      
      let collider = SCNPhysicsShape(
         geometry: SCNBox(width: CGFloat(extent.x), height: CGFloat(extent.z), length: 0.05, chamferRadius: 0),
         options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin : 0.01])
      
      let fixedCollider = SCNPhysicsShape(shapes: [collider], transforms: [SCNMatrix4MakeTranslation(0, 0, -0.025) as NSValue])
      
      planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: fixedCollider)
      planeNode.eulerAngles.x = Float(.degToRad(-90))
      planeNode.position = SCNVector3(center.x, 0, center.z)
      
      return planeNode
      
   }
   
   func updatePlaneNode(_ node: SCNNode, center: vector_float3, extent: vector_float3) {
      let geometry = node.geometry as! SCNPlane
      
      geometry.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(extent.x*2, extent.z*2, 1)
      
      geometry.width = CGFloat(extent.x)
      geometry.height = CGFloat(extent.z)
      node.position = SCNVector3Make(center.x, 0, center.z)
      let collider = SCNPhysicsShape(
         geometry: SCNBox(width: CGFloat(extent.x), height: CGFloat(extent.z), length: 0.05, chamferRadius: 0),
         options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin : 0.01])
      let fixedCollider = SCNPhysicsShape(shapes: [collider], transforms: [SCNMatrix4MakeTranslation(0, 0, -0.025) as NSValue])
      node.physicsBody?.physicsShape = fixedCollider
      
   }
   
   // MARK: Ball Throwing
   
   func throwBall(){

      let ballNode = SCNNode(geometry: SCNSphere(radius: 0.02))
      ballNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Resources.scnassets/Textures/sphereTex.png")
      ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.02), options: nil))
      ballNode.physicsBody?.restitution = 0.9
      
      let direction = scnView.pointOfView!.forwardDirection
      
      ballNode.position = scnView.pointOfView!.position + direction * 0.1
      
      ballNode.physicsBody?.applyForce(direction * 5, asImpulse: true)
      
      scnScene.rootNode.addChildNode(ballNode)
   }
   
   // MARK: Object adding
   
   func addTable(_ transform: SCNMatrix4) {
      
      let path = Bundle.main.path(forResource: "Table", ofType: "scn", inDirectory: "Resources.scnassets/Models")
      let referenceURL = URL(fileURLWithPath: path!)
      
      table = SCNReferenceNode(url: referenceURL)!
      table.load()
      // TODO: Make function to get world position easily
      table.transform = transform
      
      scnScene.rootNode.addChildNode(table)
      
      gameState.currentState = .ready
      
   }
   
   func anchorTable(){
      
      for plane in planeNodes {
         // Make planes invisible but cull other objects (e.g. you won't see a ball under a mapped table)
         let material = plane.geometry!.firstMaterial!
         material.diffuse.contents = nil
         material.lightingModel = .constant
         material.writesToDepthBuffer = true
         material.colorBufferWriteMask = []
         plane.renderingOrder = -1
      }
      
      table.constraints = []
      
      let tableModel = table.childNode(withName: "table", recursively: false)!
      tableModel.physicsBody?.type = .static
      let netModel = table.childNode(withName: "net", recursively: false)!
      netModel.physicsBody?.type = .static
      
      
      table.opacity = 1
      
      gameState.currentState = .ready
      statusLabel.text = "When you're ready, tap to serve the ball!"
      addPaddleAndBall()
      
   }
   
   func addPaddleAndBall() {
      paddle = SCNNode(geometry: SCNBox(width: 0.2, height: 0.2, length: 0.05, chamferRadius: 0.025))
      paddle.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
      paddle.geometry!.firstMaterial?.diffuse.contents = UIColor.red
      paddle.position = SCNVector3(0.1, -0.15, -0.6)
      
      ball = SCNNode(geometry: SCNSphere(radius: 0.02))
      ball.geometry!.firstMaterial?.diffuse.contents = UIImage(named: "Resources.scnassets/Textures/sphereTex.png")
      ball.position = SCNVector3(0.1, 0, -0.6)
      
      
      scnView.pointOfView!.addChildNode(paddle)
      scnView.pointOfView!.addChildNode(ball)
   }
   
   // MARK: Serving
   // TODO: serveBallForPlayer
   func serveBall() {
      ball.removeFromParentNode()
      scnScene.rootNode.addChildNode(ball)
      ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.02), options: nil))
      ball.physicsBody?.restitution = 0.9
      ball.position = scnView.pointOfView!.convertPosition(ball.position, to: nil)
      ball.physicsBody?.applyForce(scnView.pointOfView!.forwardDirection * 5, asImpulse: true)
      
   }
 
   // MARK: - Madoc's funcs WIP
   
   func hit() {
      //send ball in direction it is hit
   }
   
   func tableContact(hit: Int) {
      
      /*
       0
       [1][2]
       ------
       [3][4]
       5
       */
      //register area of contact on table, update scoreboard
      var previousHit = 5
      var playerScore = 0
      var AiScore = 0
      switch hit {
      case 1,2:
         if previousHit == 0 {
            playerScore += 1
         } else if previousHit == 5 {
            AiScore += 1
         } else if previousHit == 3 || previousHit == 4 {
            AiScore += 1
         }
      case 3,4:
         if previousHit == 0 {
            AiScore += 1
         } else if previousHit == 5 {
            playerScore += 1
         } else if previousHit == 1 || previousHit == 2 {
            playerScore += 1
         }
      default:
         break
         //let test = "test"break
         
      }
      previousHit = hit
   }
   
   func checkPreviousHit() -> Int {
      let number = 10
      return number
   }
   
   func ai() {
      //create opposing paddle which will return ball with some degree of randomness
   }
   
   
   
   // MARK: - Helper Functions
   
   func showMessage(_ message: String?){
      
      if message == nil {
         errorLabel.isHidden = true
      } else {
         errorLabel.isHidden = false
         errorLabel.text = message!
      }
      
   }
   
   func updateLightIntensity(_ estimate: ARLightEstimate) {
      ambLight.light?.intensity = estimate.ambientIntensity
      ambLight.light?.temperature = estimate.ambientColorTemperature
   }
   
   
   // MARK: - Touches
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      
      switch gameState.currentState {
      case .planeMapping:
         // Finished plane mapping
         // Place table to start with
         if let hit = scnView.hitTest(viewCenter, types: .existingPlaneUsingExtent).first {
            addTable(SCNMatrix4(hit.worldTransform))
            gameState.currentState = .setup
         } else if let hit = scnView.hitTest(viewCenter, types: .featurePoint).last {
            addTable(SCNMatrix4(hit.worldTransform))
            gameState.currentState = .setup
         }
         
         
         statusLabel.text = "Tap to lock the table in place"
         scnScene.rootNode.addChildNode(tableConstraint)
         let constraint = SCNLookAtConstraint(target: self.tableConstraint)
         constraint.isGimbalLockEnabled = true
         constraint.localFront = SCNVector3(0,0,1)
         table.constraints = [constraint]
         
         table.opacity = 0.5
         
         let newConfig = ARWorldTrackingConfiguration()
         newConfig.isLightEstimationEnabled = true
         scnView.session.run(newConfig)
      case .setup:
         
         if let _ = scnView.hitTest(viewCenter, types: .existingPlaneUsingExtent).first {
            anchorTable()
         } else if let _ = scnView.hitTest(viewCenter, types: .featurePoint).last {
            anchorTable()
         }

         
      case .ready:
         serveBall()
         gameState.currentState = .playing
      default:
         throwBall()
      }
   }
   
   
   
   
   // MARK: - ARSCNViewDelegate
   
   func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
      // TODO: Remove fallen balls
      switch gameState.currentState {
      case .setup:
         
         // TODO: Remove table if not on a plane
         
         DispatchQueue.main.async {
            if let hit = self.scnView.hitTest(self.viewCenter, types: .existingPlaneUsingExtent).first {
               self.table.transform = SCNMatrix4(hit.worldTransform)
               self.tableConstraint.position = SCNVector3(self.scnView.pointOfView!.position.x, self.table.position.y, self.scnView.pointOfView!.position.z)
               
            }
         }
         
         break
      default:
         break
      }
   }
   
   func session(_ session: ARSession, didUpdate frame: ARFrame) {
      
      DispatchQueue.main.async {
         if let lightEstimate = frame.lightEstimate {
            self.updateLightIntensity(lightEstimate)
         }
      }
      
      DispatchQueue.main.async {
         self.updateTrackingErrors(for: frame)
      }
   }
   
   // MARK: Plane Mapping
   
   func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
      switch gameState.currentState {
      case .planeMapping:
         DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
               let planeNode = self.createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
               node.addChildNode(planeNode)
               self.planeNodes.append(planeNode)
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
   
   func updateTrackingErrors(for frame: ARFrame) {
      
      let state = frame.camera.trackingState
      switch state {
      case .limited(let reason):
         switch reason {
         case .excessiveMotion:
            showMessage("Too much movement!")
         case .insufficientFeatures:
            showMessage("Not enough distinct features!")
         case .initializing:
            showMessage("Loading...")
         }
      default:
         
         guard let brightness = frame.lightEstimate?.ambientIntensity else {
            showMessage(nil)
            break
         }
         
         if brightness < 100 {
            showMessage("Too dark!")
         } else {
            showMessage(nil)
         }
         
      }
      
   }
    
   
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

