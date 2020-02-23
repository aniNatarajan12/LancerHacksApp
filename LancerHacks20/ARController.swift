//
//  ARController.swift
//  LancerHacks20
//
//  Created by Anirudh Natarajan on 6/29/19.
//  Copyright © 2019 Anirudh Natarajan. All rights reserved.
//

import UIKit
import Firebase
import SceneKit
import ARKit
import simd
import RealityKit
import PopupDialog

class ARController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    var dismissButton: UIButton!
    var delegate: recievingData!
    
    let session = ARSession()
    var sceneView : ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        delegate.reload()
        sceneView.session.pause()
    }
    
    func setupUI() {
        setupAR()
        
        let size: CGFloat = 75
        dismissButton = UIButton(type: .custom)
        dismissButton.frame = CGRect(x: view.frame.width/2 - size/2, y: view.frame.height - size - 34, width: size, height: size)
        dismissButton.setTitle("X", for: .normal)
        dismissButton.setTitleColor(UIColor(displayP3Red: 214/255.0, green: 72/255.0, blue: 56/255.0, alpha: 1), for: .normal)
        dismissButton.backgroundColor = .white
        dismissButton.layer.cornerRadius = dismissButton.frame.width/2
        dismissButton.addTarget(self, action:#selector(self.dismissPressed), for: .touchUpInside)
        dismissButton.titleLabel?.font = .systemFont(ofSize: 45, weight: .semibold)
        self.view.addSubview(dismissButton)
    }
    
    func setupAR() {
        
        sceneView = ARSCNView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height))
        sceneView.scene = SCNScene()
        
        let config = ARImageTrackingConfiguration()
        
        guard let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "ReferenceImages", bundle: Bundle.main) else {
            print("No images available")
            return
        }
        
        config.trackingImages = trackedImages
        config.maximumNumberOfTrackedImages = 1
        sceneView.autoenablesDefaultLighting = true
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session = session
        
        sceneView.session.delegate = self
        
        self.view = sceneView
        sceneView.session.run(config)
        
    }
    
    @objc func dismissPressed(_ sender: Any) {
        dismiss()
    }
    
    func dismiss() {
        scores = []
        names = []
        let ref = Database.database().reference(fromURL: "https://lancerhacks20.firebaseio.com/").child("Scores")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                let value = snap.value
                names.append("\(key)")
                let x = "\(value!)"
                scores.append(Int(x)!)
            }
            let combined = zip(scores, names).sorted(by: {$0.0 > $1.0})
            scores = combined.map {$0.0}
            names = combined.map {$0.1}
            
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.8)
            plane.firstMaterial?.lightingModel = .physicallyBased
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            
            let n = imageAnchor.referenceImage.name!
            let modelScene = SCNScene(named: "\(n).scn")!
            let modelNode = modelScene.rootNode.childNodes.first!
            modelNode.position = SCNVector3Zero
            modelNode.simdLocalRotate(by: simd_quatf(angle: .pi/2, axis: [1,0,0]))
            modelNode.position.z = 0.065
            if n=="apple" || n=="glasses"{
                modelNode.position.y = Float(-plane.height/2)
            }
            if n=="apple" || n=="earth" || n=="glasses" || n=="mountain" || n=="treasure" {
                modelNode.position.z = 0
            } else if n=="tree" {
                modelNode.position.z = 0.122
            } else if n=="laptop" {
                modelNode.position.z = 0.01
            }

            planeNode.addChildNode(modelNode)
            
            let particleSystem = SCNParticleSystem(named: "explosion", inDirectory: nil)
            let systemNode = SCNNode()
            systemNode.addParticleSystem(particleSystem!)
            systemNode.scale = SCNVector3(x: 0.001, y: 0.001, z: 0.001)
            systemNode.position = planeNode.position
            systemNode.position.y -= 0.1
            
            var s = ""
            if imagesScanned.contains(n) {
                s = "Already Claimed."
            } else {
                let imageNames = images[0] as! [String]
                let imageIndex = imageNames.firstIndex(of: n)
                let newScore = "\(images[1][imageIndex!])"
                s = "+\(newScore) Points!"
                
                let title = "You scanned the \(n)!"
                var message = ""
                var placeholder = ""
                if newScore=="15" {
                    message = "+15 points, nice! Did you enjoy the session? Leave a rating!"
                    placeholder = "Any comments/ideas for improvement?"
                } else if newScore=="5" {
                    message = "That's 5 more points, woohoo!"
                    placeholder = "What's their name?"
                } else if newScore=="3" {
                    message = "Free 3 points! Everybody likes food. Leave a rating!"
                    placeholder = "What did you eat?"
                } else if newScore=="50"{
                    message = "You solved the impossible problem!!! It was easy wasn't it ;)"
                    placeholder = "Did you like it?"
                } else {
                    message = "You just earned \(newScore) more points! Rate the problem!"
                    placeholder = "Any comments/ideas for improvement?"
                }
                DispatchQueue.main.async { () -> Void in
                    self.showPopup(title: title, message: message, placeholder: placeholder, imageName: n, newScore: newScore)
                }
            }
            
            node.addChildNode(planeNode)
            node.addChildNode(systemNode)
            addText(string: s, parent: node)
        }
        return node
    }
    
    func createTextNode(string: String) -> SCNNode {
        let text = SCNText(string: string, extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1)
        text.flatness = 0.005
        if string == "Already Claimed."{
            text.firstMaterial?.diffuse.contents = UIColor.red
        } else {
            text.firstMaterial?.diffuse.contents = UIColor.green
        }
        
        let textNode = SCNNode(geometry: text)

        let fontSize = Float(0.04)
        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        
        var minVec = SCNVector3Zero
        var maxVec = SCNVector3Zero
        (minVec, maxVec) =  textNode.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation(
            minVec.x + (maxVec.x - minVec.x)/2,
            minVec.y,
            minVec.z - (minVec.z + 5)/2
        )

        return textNode
    }
    
    func addText(string: String, parent: SCNNode) {
        let textNode = self.createTextNode(string: string)
        textNode.position = SCNVector3Zero

        parent.addChildNode(textNode)
    }
    
    func showPopup(title: String, message: String, placeholder: String, imageName: String, newScore: String) {

        let ratingVC = RatingViewController(nibName: "RatingViewController", bundle: nil)

        let popup = PopupDialog(viewController: ratingVC,
                                buttonAlignment: .horizontal,
                                transitionStyle: .bounceDown,
                                tapGestureDismissal: false,
                                panGestureDismissal: false)
        
        ratingVC.titleLabel.text = title
        ratingVC.messageLabel.text = message
        ratingVC.commentTextField.placeholder = placeholder

        let button = DefaultButton(title: "Send Feedback", height: 60) {
//            self.label.text = "You rated \(ratingVC.cosmosStarRating.rating) stars"
            self.addScore(imageName: imageName, newScore: newScore)
            let ref = Database.database().reference(fromURL: "https://lancerhacks20.firebaseio.com/").child("Feedback").child(imageName).child(usr)
            let v = ["textField": "\(ratingVC.commentTextField.text ?? "empty")", "stars": "\(ratingVC.cosmosStarRating.rating)"]
            ref.updateChildValues(v, withCompletionBlock: { (err, ref) in
                if err != nil {
                    print(err)
                    return
                }
            })
        }
        button.titleColor = ratingVC.titleLabel.textColor
        popup.addButtons([button])
        
        present(popup, animated: true, completion: nil)
    }
    
    func addScore(imageName: String, newScore: String){
        imagesScanned.append(imageName)
        let ref = Database.database().reference(fromURL: "https://lancerhacks20.firebaseio.com/")
        let imageRef = ref.child("Images").child(usr)
        var v = [imageName: "scanned"]
        imageRef.updateChildValues(v, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err)
                return
            }
        })
        
        let index = names.firstIndex(of: usr)
        let current = scores[index!]
        let scoreRef = ref.child("Scores")
        v = [usr: "\(current + Int(newScore)!)"]
        scores[index!] = current + Int(newScore)!
        scoreRef.updateChildValues(v, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err)
                return
            }
        })
    }
}
