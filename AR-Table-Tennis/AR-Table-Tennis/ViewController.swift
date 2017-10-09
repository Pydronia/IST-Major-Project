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
   @IBOutlet weak var crosshair: UIImageView!
   
   // MARK: Globals
   var scnScene: SCNScene!
   var gameState: GameState!
   
   var planeNodes: [SCNNode] = []
   
   var currentStatus: String? = nil
   
   var ambLight: SCNNode!
   
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
      
      
      statusLabel.text = "Move your device around and map your environment: When you're satisfied with the surfaces, tap the screen."
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
      ballNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
      ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.02), options: nil))
      
      // TODO: Convert to extension
      let direction = SCNVector3(-scnView.pointOfView!.transform.m31, -scnView.pointOfView!.transform.m32, -scnView.pointOfView!.transform.m33)
      
      ballNode.position = scnView.pointOfView!.position + direction * 0.1
      
      //direction.y = 0.5
      
      ballNode.physicsBody?.applyForce(direction * 5, asImpulse: true)
      
      
      
      scnScene.rootNode.addChildNode(ballNode)
   }
   
   // MARK: - Helper Functions
   
   func showMessage(_ message: String, temp: Bool, seconds: Double?){
      
      if !temp {
         currentStatus = message
      }
      
      statusLabel.text = message
      
      if temp && seconds != nil {
         DispatchQueue.main.asyncAfter(deadline: .now() + seconds!) {
            if self.statusLabel.text == message {
               self.statusLabel.text = self.currentStatus
            }
            
         }
      }
      
      /*
      if message == nil {
         label.text = previousStatus
         return
      }
      
      if previousStatus == nil {
         previousStatus = label.text
      }
      
      label.text = message!
      guard let time = seconds else {return}
      
      DispatchQueue.main.asyncAfter(deadline: .now() + time) {
         label.text = self.previousStatus
         self.previousStatus = nil
      }
      */
      
      
      
   }
   
   
   func addBallAtTransform(_ transform: SCNMatrix4) {
      /*
      let ballNode = SCNNode(geometry: SCNSphere(radius: 0.05))
      ballNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
      ballNode.transform = transform
      scnScene.rootNode.addChildNode(ballNode)
      */
      // TODO: need to check this works
      let table = SCNReferenceNode(url: URL(fileURLWithPath: "Resources.scnassets/Models/table.scn"))!
      scnScene.rootNode.addChildNode(table)
      table.load()
      
   }
   
   func updateLightIntensity(_ estimate: ARLightEstimate) {
      ambLight.light?.intensity = estimate.ambientIntensity
      ambLight.light?.temperature = estimate.ambientColorTemperature
   }
   
   
   // MARK: - Touches
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      
      switch gameState.currentState {
      case .planeMapping:
         gameState.currentState = .setup
         
         for plane in planeNodes {
            // Make planes invisible but cull other objects (e.g. you won't see a ball under a mapped table)
            let material = plane.geometry!.firstMaterial!
            material.diffuse.contents = nil
            material.lightingModel = .constant
            material.writesToDepthBuffer = true
            material.colorBufferWriteMask = []
            plane.renderingOrder = -1
         }
         
         
         crosshair.isHidden = false
         statusLabel.text = "Select a place for the table"
         
         let newConfig = ARWorldTrackingConfiguration()
         newConfig.isLightEstimationEnabled = true
         scnView.session.run(newConfig)
      case .setup:
         let viewCenter = CGPoint(x: scnView.bounds.width/2, y: scnView.bounds.height/2)
         if let hit = scnView.hitTest(viewCenter, types: .existingPlaneUsingExtent).first {
            // TODO: add Anchor instead of node (?)
            addBallAtTransform(SCNMatrix4(hit.worldTransform))
         } else if let hit = scnView.hitTest(viewCenter, types: .featurePoint).last {
            // TODO: same as above
            addBallAtTransform(SCNMatrix4(hit.worldTransform))
         }
      default:
         throwBall()
      }
   }
   
   
   
   
   // MARK: - ARSCNViewDelegate
   
   func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
      switch gameState.currentState {
      case .setup:
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
            showMessage("Too much movement!", temp: true, seconds: nil)
         case .insufficientFeatures:
            showMessage("Not enough distinct features!", temp: true, seconds: nil)
         default:
            showMessage("Limited Tracking", temp: true, seconds: nil)
         }
      default:
         statusLabel.text = currentStatus
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

