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
   
   // MARK: - Variables
   // MARK: Outlets
   @IBOutlet weak var scnView: ARSCNView!
   @IBOutlet weak var statusLabel: UILabel!
   @IBOutlet weak var errorLabel: UILabel!
   @IBOutlet weak var crosshair: UIImageView!
   @IBOutlet weak var progressButton: UIButton!
   @IBOutlet weak var resetButton: UIButton!
   @IBOutlet weak var scoreLabel: UILabel!
    
    
    
    // MARK: Globals
   var scnScene: SCNScene!
   var gameState: GameState!
   
   var planeNodes: [SCNNode] = []
   
   var ambLight: SCNNode!
    
   var scoreboard: [Int] = []
   
   public var gameDifficulty: Difficulty = .hard
   
   var table: SCNNode!
   var paddle: SCNNode!
   var aiPaddle: SCNNode!
   var ball: SCNNode!
   
   var aiController: AIController!
   
   let tableConstraint = SCNNode()
   let paddleConstraint = SCNNode()
   
   var shouldUpdateErrors: Bool = true
   var tableIsHalved: Bool? = nil
   
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
      
      scnView.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
      
      //DEBUG
      
      //scnView.showsStatistics = true
      //scnView.debugOptions = .showPhysicsShapes
      
      
      gameState = GameState(initialState: .planeMapping)
      statusLabel.layer.cornerRadius = 10
      errorLabel.layer.cornerRadius = 10
      progressButton.layer.cornerRadius = 10
      scoreLabel.layer.cornerRadius = 10
      
   }
   
   func startSession(reset: Bool){
      let config = ARWorldTrackingConfiguration()
      config.planeDetection = .horizontal
      config.isLightEstimationEnabled = true
      // TODO: This doesn't work, so currently manually updating ambient light.
      scnView.automaticallyUpdatesLighting = true
      
      if reset {
         scnView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
      } else {
         scnView.session.run(config)
      }
      
      
      // TODO: Test and change this value for optimal performance (1/120 seems to be failsafe w/ 5cm thick planes and 1cm collision margin)
      scnView.scene.physicsWorld.timeStep = 1/120
      
      statusLabel.text = "Move your device around and map your environment. When you're ready, look at a surface and tap the arrow!"
   }
   
   // Load the scene and do some setup
   override func viewDidLoad() {
      super.viewDidLoad()
      
      let tapper = UITapGestureRecognizer(target: self, action: #selector(self.errorLabelTapped))
      errorLabel.addGestureRecognizer(tapper)
      
      setupView()
   }
   
   // start the session on the view
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      startSession(reset: false)
   }
   
   override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      viewCenter = CGPoint(x: scnView.bounds.width/2, y: scnView.bounds.height/2)
   }
   
   override var prefersStatusBarHidden: Bool {
      get {
         return true
      }
   }
   
   // MARK: - Main Methods
   
   // MARK: Plane Mapping
   
   func createPlaneNode(center: vector_float3, extent: vector_float3) -> SCNNode {
      
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
   
   func addTable(_ transform: matrix_float4x4) {
      
      table = SCNNode()
      
      let tableScene = SCNScene(named: "Resources.scnassets/Models/Table.scn")!
      for child in tableScene.rootNode.childNodes {
         table.addChildNode(child)
      }
      
      table.position = SCNMatrix4(transform).worldPosition
      
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
      
      let tableModel = table.childNode(withName: "table", recursively: false)!
      let netModel = table.childNode(withName: "net", recursively: false)!
      
      tableModel.physicsBody?.type = .static
      netModel.physicsBody?.type = .static
      
      
      
      table.constraints = []
      tableConstraint.removeFromParentNode()
      table.opacity = 1
      
      gameState.currentState = .ready
      statusLabel.text = "When you're ready, tap to serve the ball!"
      addPaddleAndBall()
      addAI()
      
   }
   
   func addPaddleAndBall() {
      paddle = SCNNode(geometry: SCNBox(width: 0.17, height: 0.17, length: 0.05, chamferRadius: 0.025))
      paddle.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: SCNBox(width: 0.17, height: 0.17, length: 0.05, chamferRadius: 0.025), options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin: 0.01]))
      paddle.geometry!.firstMaterial?.diffuse.contents = UIColor.green
      paddle.position = SCNVector3(0.1, -0.15, -0.6)
      
      ball = SCNNode(geometry: SCNSphere(radius: 0.02))
      ball.geometry!.firstMaterial?.diffuse.contents = UIImage(named: "Resources.scnassets/Textures/sphereTex.png")
      ball.position = SCNVector3(0.1, 0, -0.6)
      ball.movabilityHint = .movable
      ball.geometry!.firstMaterial?.lightingModel = .physicallyBased
      
      
      scnView.pointOfView!.addChildNode(paddle)
      scnView.pointOfView!.addChildNode(ball)
   }
   
   func addAI() {
      aiPaddle = SCNNode(geometry: SCNBox(width: 0.17, height: 0.17, length: 0.05, chamferRadius: 0.025))
      aiPaddle.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: SCNBox(width: 0.17, height: 0.17, length: 0.05, chamferRadius: 0.025), options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin: 0.01]))
      aiPaddle.geometry!.firstMaterial?.diffuse.contents = UIColor.red
      
      if !tableIsHalved! {
         aiPaddle.position = SCNVector3(0, 0.3, -1.5)
      } else {
         aiPaddle.position = SCNVector3(0, 0.3, -0.85)
      }
      
      
      
      paddleConstraint.position = SCNVector3(0,0.4,0)
      
      let constraint = SCNLookAtConstraint(target: paddleConstraint)
      constraint.isGimbalLockEnabled = true
      aiPaddle.constraints = [constraint]
      
      table.addChildNode(aiPaddle)
      table.addChildNode(paddleConstraint)
      
      aiController = AIController(paddle: aiPaddle, difficulty: gameDifficulty)
      
   }
   
   // MARK: Serving
   // TODO: serveBallForPlayer
   func serveBall() {
      ball.removeFromParentNode()
      table.addChildNode(ball)
      ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.02), options: nil))
      ball.physicsBody?.restitution = 0.9
      ball.position = scnView.pointOfView!.convertPosition(ball.position, to: table)
      ball.physicsBody?.applyForce(scnView.pointOfView!.forwardDirection * 7, asImpulse: true)
      
      gameState.currentState = .playing
      
   }
   
   // MARK: - Helper Functions
   
   func tableSize(half: Bool) {
      
      // Very dodgy copy paste here: I apologiese!
      if let isHalved = tableIsHalved {
         if isHalved && half {
            return
         } else if !isHalved && !half {
            return
         }
         
         let tableModel = table.childNode(withName: "table", recursively: false)!
         let netModel = table.childNode(withName: "net", recursively: false)!
         let tableBox = tableModel.geometry! as! SCNBox
         let netBox = netModel.geometry! as! SCNBox
         if half {
            tableBox.length /= 2
            tableBox.width /= 2
            netBox.width /= 2
            netBox.height /= 2
            netModel.position.y = 0.088
            tableModel.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: tableModel.geometry!, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin : 0.01]))
            netModel.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: netModel.geometry!, options: [SCNPhysicsShape.Option.collisionMargin : 0.04, SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox]))
            
         } else {
            tableBox.length *= 2
            tableBox.width *= 2
            netBox.width *= 2
            netBox.height *= 2
            netModel.position.y = 0.126
            tableModel.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: tableModel.geometry!, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin : 0.01]))
            netModel.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: netModel.geometry!, options: [SCNPhysicsShape.Option.collisionMargin : 0.04, SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox]))
         }
         
      } else if !half {
         return
      } else {
      
         let tableModel = table.childNode(withName: "table", recursively: false)!
         let netModel = table.childNode(withName: "net", recursively: false)!
         let tableBox = tableModel.geometry! as! SCNBox
         let netBox = netModel.geometry! as! SCNBox
         if half {
            tableBox.length /= 2
            tableBox.width /= 2
            netBox.width /= 2
            netBox.height /= 2
            netModel.position.y = 0.088
            tableModel.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: tableModel.geometry!, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.collisionMargin : 0.01]))
            netModel.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: netModel.geometry!, options: [SCNPhysicsShape.Option.collisionMargin : 0.04, SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox]))
         } else {
            tableBox.length *= 2
            tableBox.width *= 2
            netBox.width *= 2
            netBox.height *= 2
         }
      }
   }
   
   func resetSession(){
      scnView.session.pause()
      
      planeNodes = []
      
      if table != nil {
         table.removeFromParentNode()
      }
      
      if paddle != nil {
         paddle.removeFromParentNode()
      }
      
      if ball != nil {
         ball.removeFromParentNode()
      }
      
      table = nil
      paddle = nil
      ball = nil
      
      scoreboard = []
      tableIsHalved = nil
      
      progressButton.isHidden = false
      
      setupView()
      startSession(reset: true)
   }
   
   func resetBall() {
      gameState.currentState = .ready
      ball.removeFromParentNode()
      scnView.pointOfView!.addChildNode(ball)
      ball.physicsBody = nil
      ball.position = SCNVector3(0.1, 0, -0.6)
      aiController.returnToStart()
      statusLabel.isHidden = false
      
   }
   
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

   @IBAction func resetButtonTouched(_ sender: UIButton) {
      
      
      if gameState.currentState == .playing {
         resetBall()
      } else {
         shouldUpdateErrors = true
         resetSession()
      }
      
      
   }
   
   
   @IBAction func nextButtonTouched(_ sender: UIButton) {
      
      switch gameState.currentState {
      case .planeMapping:
         // Finished plane mapping
         // Place table to start with
         if let hit = scnView.hitTest(viewCenter, types: .existingPlaneUsingExtent).first {
            addTable(hit.worldTransform)
            gameState.currentState = .setup
            
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
         }
      case .setup:
         
         if let _ = scnView.hitTest(viewCenter, types: .existingPlaneUsingExtent).first {
            anchorTable()
         }
         
         sender.isHidden = true
      default:
         break
      }
      
   }
   
   @objc func errorLabelTapped(sender: UITapGestureRecognizer) {
      shouldUpdateErrors = false
      errorLabel.isHidden = true
   }
   
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      switch gameState.currentState {
      case .ready:
         if gameState.playerScore == 0 && gameState.aiScore == 0 {
            statusLabel.isHidden = true
         }
         serveBall()
         gameState.currentState = .playing
      default:
         break
      }
   }
   
   
   
   
   // MARK: - ARSCNViewDelegate
   
   func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
      switch gameState.currentState {
      case .setup:
         
         
         DispatchQueue.main.async {
            if let hit = self.scnView.hitTest(self.viewCenter, types: .existingPlaneUsingExtent).first {
               self.table.isHidden = false
               self.table.position = SCNMatrix4(hit.worldTransform).worldPosition
               self.tableConstraint.position = SCNVector3(self.scnView.pointOfView!.position.x, self.table.position.y, self.scnView.pointOfView!.position.z)
               let planeAnchor = hit.anchor as! ARPlaneAnchor
               
               if planeAnchor.extent.x < 1.4 && planeAnchor.extent.z < 1.4 {
                  self.tableSize(half: true)
                  self.tableIsHalved = true
               } else {
                  self.tableSize(half: false)
                  self.tableIsHalved = false
               }
             
            } else {
               self.table.isHidden = true
            }
         }
         
         break
      case .playing:
         DispatchQueue.main.async {
            self.aiController.moveTo(x: self.ball.presentation.position.x, y: self.ball.presentation.position.y)
            
         }
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
         if self.shouldUpdateErrors {
            self.updateTrackingErrors(for: frame)
         }
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
      shouldUpdateErrors = true
      showMessage("An unknown error occured. Restarting.")
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
         self.showMessage(nil)
         self.resetSession()
      }
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

