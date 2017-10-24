//
//  MenuViewController.swift
//  AR Ping Pong
//
//  Created by Jack Carey on 20/10/17.
//  Copyright © 2017 Jack Carey. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import QuartzCore

class MenuViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
   
   
   @IBOutlet weak var scnView: ARSCNView!
   @IBOutlet weak var introLabel: UILabel!
   @IBOutlet weak var easyButton: UIButton!
   @IBOutlet weak var mediumButton: UIButton!
   @IBOutlet weak var hardButton: UIButton!
   
   
   var scnScene: SCNScene!
   var selectedDifficulty: Difficulty!
   
   @IBAction func easyButtonPressed(_ sender: UIButton) {
      selectedDifficulty = .easy
      self.performSegue(withIdentifier: "mainSegue", sender: nil)
   }
   @IBAction func mediumButtonPressed(_ sender: UIButton) {
      selectedDifficulty = .medium
      self.performSegue(withIdentifier: "mainSegue", sender: nil)
   }
   @IBAction func hardButtonPressed(_ sender: UIButton) {
      selectedDifficulty = .hard
      self.performSegue(withIdentifier: "mainSegue", sender: nil)
   }
   
   
   
   
   override func viewDidLoad() {
      super.viewDidLoad()
      scnScene = SCNScene()
      scnView.scene = scnScene
      scnView.delegate = self
      scnView.session.delegate = self
      
      let config = ARWorldTrackingConfiguration()
      scnView.session.run(config)
      
      introLabel.layer.cornerRadius = 10
      easyButton.layer.cornerRadius = 10
      mediumButton.layer.cornerRadius = 10
      hardButton.layer.cornerRadius = 10
      
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      super.prepare(for: segue, sender: sender)
      // Code and tips from Damian Camilleri, from the CGS Computing Forum
      let destination = segue.destination as! ViewController
      destination.gameDifficulty = selectedDifficulty
   }
   
   
   override var prefersStatusBarHidden: Bool {
      get {
         return true
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   
   /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
   
}
