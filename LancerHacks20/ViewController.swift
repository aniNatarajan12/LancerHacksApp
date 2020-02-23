//
//  ViewController.swift
//  LancerHacks20
//
//  Created by Anirudh Natarajan on 6/26/19.
//  Copyright © 2019 Anirudh Natarajan. All rights reserved.
//

import UIKit
import Firebase

enum LoginSignupViewMode {
    case login
    case signup
}

var usr = ""
var names = [String]()
var scores = [Int]()
var imagesScanned = [String]()
var images = [["snowman", "earth", "crown", "treasure", "fox", "laptop", "elephant", "tree", "mountain", "UFO", "glasses", "apple", "donut", "basketball", "books"], [10, 20, 30, 50, 15, 15, 15, 15, 15, 5, 5, 3, 3, 5, 5]]

class ViewController: UIViewController {
    
    let animationDuration = 0.25
    var mode:LoginSignupViewMode = .signup
    
    @IBOutlet weak var backImageLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var backImageBottomConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var loginContentView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginButtonVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginWidthConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var signupView: UIView!
    @IBOutlet weak var signupContentView: UIView!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var signupButtonVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var signupButtonTopConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoButtomInSingupConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoCenterConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var loginEmailInputView: InputView!
    @IBOutlet weak var loginPasswordInputView: InputView!
    @IBOutlet weak var signupEmailInputView: InputView!
    @IBOutlet weak var signupPasswordInputView: InputView!
    @IBOutlet weak var signupPasswordConfirmInputView: InputView!
    @IBOutlet weak var wrongView: UIView!
    @IBOutlet weak var wrongLabel: UILabel!
    
    var shown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set view to login mode
        toggleViewMode(animated: false)
        wrongView.isHidden = true
        
        //add keyboard notification
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChange(notification:)), name: ViewController.keyboardWillChangeFrameNotification, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func tapped() {
        self.view.endEditing(true)
        if shown {
            animateWrong(text: "")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func loginButtonTouchUpInside(_ sender: AnyObject) {
        
        if mode == .signup {
            toggleViewMode(animated: true)
            loginEmailInputView.textFieldView.text = ""
            loginPasswordInputView.textFieldView.text = ""
        } else {
            
            if loginEmailInputView.textFieldView.text == "" || loginPasswordInputView.textFieldView.text == "" {
                animateWrong(text: "Please input all values")
                return
            }
            
            Auth.auth().signIn(withEmail: "\(loginEmailInputView.textFieldView.text!.split(separator: " ")[0])", password: loginPasswordInputView.textFieldView.text!) { (user, error) in
                
                if error != nil {
                    self.animateWrong(text: String(error!.localizedDescription.split(separator: ".")[0]))
                    return
                }
                
                usr = self.getUsername(text: self.loginEmailInputView.textFieldView.text!)
                self.getImageData(child: usr)
                self.getScoreData()
            }
        }
    }
    
    @IBAction func signupButtonTouchUpInside(_ sender: AnyObject) {
        
        if mode == .login {
            toggleViewMode(animated: true)
            signupEmailInputView.textFieldView.text = ""
            signupPasswordInputView.textFieldView.text = ""
            signupPasswordConfirmInputView.textFieldView.text = ""
        } else {
            
            if signupEmailInputView.textFieldView.text == "" || signupPasswordInputView.textFieldView.text == "" || signupPasswordConfirmInputView.textFieldView.text == "" {
                animateWrong(text: "Please input all values")
                return
            }
            
            if signupPasswordInputView.textFieldView.text != signupPasswordConfirmInputView.textFieldView.text {
                animateWrong(text: "Passwords don't match")
                return
            }
            
            Auth.auth().createUser(withEmail: "\(signupEmailInputView.textFieldView.text!.split(separator: " ")[0])", password: signupPasswordInputView.textFieldView.text!) { (user, error) in
                if error != nil {
                    self.animateWrong(text: String(error!.localizedDescription.split(separator: ".")[0]))
                    return
                }
                
                let ref = Database.database().reference(fromURL: "https://lancerhacks20.firebaseio.com/")
                let scoreReference = ref.child("Scores")
                let values = [self.getUsername(text: self.signupEmailInputView.textFieldView.text!): "0"]
                scoreReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
                    if err != nil {
                        print(err)
                        return
                    }
                })
                usr = self.getUsername(text: self.signupEmailInputView.textFieldView.text!)
                self.getImageData(child: usr)
                self.getScoreData()
            }
        }
    }
    
    func getUsername(text: String) -> String {
        var t = "\(text.split(separator: "@")[0])"
        t = t.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range:nil)
        t = t.replacingOccurrences(of: "#", with: "", options: NSString.CompareOptions.literal, range:nil)
        t = t.replacingOccurrences(of: "$", with: "", options: NSString.CompareOptions.literal, range:nil)
        t = t.replacingOccurrences(of: "[", with: "", options: NSString.CompareOptions.literal, range:nil)
        t = t.replacingOccurrences(of: "]", with: "", options: NSString.CompareOptions.literal, range:nil)
        return t.lowercased()
    }
    
    func getScoreData() {
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
            
            self.performSegue(withIdentifier: "authenticated", sender: self)
        })
    }
    
    func getImageData(child:String) {
        imagesScanned = []
        let ref = Database.database().reference(fromURL: "https://lancerhacks20.firebaseio.com/").child("Images")
        ref.child(child).observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                imagesScanned.append("\(key)")
            }
        })
    }
    
    // TOGGLE
    func toggleViewMode(animated:Bool) {
        
        // toggle mode
        mode = mode == .login ? .signup:.login
        
        
        // set constraints changes
        backImageLeftConstraint.constant = mode == .login ? 0:-self.view.frame.size.width
        
        
        loginWidthConstraint.isActive = mode == .signup ? true:false
        logoCenterConstraint.constant = (mode == .login ? -1:1) * (loginWidthConstraint.multiplier * self.view.frame.size.width)/2
        loginButtonVerticalCenterConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(mode == .login ? 300:900))
        signupButtonVerticalCenterConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(mode == .signup ? 300:900))
        
        
        //animate
        tapped()
        wrongView.isHidden = true
        
        UIView.animate(withDuration:animated ? animationDuration:0) {
            
            //animate constraints
            self.view.layoutIfNeeded()
            
            //hide or show views
            self.loginContentView.alpha = self.mode == .login ? 1:0
            self.signupContentView.alpha = self.mode == .signup ? 1:0
            
            // rotate and scale login button
            let scaleLogin:CGFloat = self.mode == .login ? 1:0.4
            let rotateAngleLogin:CGFloat = self.mode == .login ? 0:CGFloat(-M_PI_2)
            
            var transformLogin = CGAffineTransform(scaleX: scaleLogin, y: scaleLogin)
            transformLogin = transformLogin.rotated(by: rotateAngleLogin)
            self.loginButton.transform = transformLogin
            
            
            // rotate and scale signup button
            let scaleSignup:CGFloat = self.mode == .signup ? 1:0.4
            let rotateAngleSignup:CGFloat = self.mode == .signup ? 0:CGFloat(-M_PI_2)
            
            var transformSignup = CGAffineTransform(scaleX: scaleSignup, y: scaleSignup)
            transformSignup = transformSignup.rotated(by: rotateAngleSignup)
            self.signupButton.transform = transformSignup
        }
        
    }
    
    // KEYBOARD
    
    @objc func keyboardFrameChange(notification:NSNotification) {
        
        guard let info = notification.userInfo else { return }
        guard let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {return}
        guard let animationDuration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        guard let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        let top = keyboardFrame.origin.y
        
        var animationCurve:UIView.AnimationCurve = .easeOut
        animationCurve =  UIView.AnimationCurve.init(rawValue: curve.intValue)!
        
        // check keyboard is showing
        let keyboardShow = top != self.view.frame.size.height
        
        
        //hide logo in little devices
        let hideLogo = self.view.frame.size.height < 667
        
        // set constraints
        backImageBottomConstraint.constant = self.view.frame.size.height - top
        
        logoTopConstraint.constant = keyboardShow ? (hideLogo ? 0:20):50
        logoHeightConstraint.constant = keyboardShow ? (hideLogo ? 0:40):60
        logoBottomConstraint.constant = keyboardShow ? 20:32
        logoButtomInSingupConstraint.constant = keyboardShow ? 20:32
        
        loginButtonTopConstraint.constant = keyboardShow ? 25:30
        signupButtonTopConstraint.constant = keyboardShow ? 23:35
        
        loginButton.alpha = keyboardShow ? 1:0.7
        signupButton.alpha = keyboardShow ? 1:0.7
        
        
        
        // animate constraints changes
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        
        self.view.layoutIfNeeded()
        
        UIView.commitAnimations()
        
    }
    
    func animateWrong(text: String) {
        wrongLabel.text = text
        
        if !shown {
            wrongView.alpha = 0
            wrongView.isHidden = false
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.wrongView.alpha = self.shown ? 0:1
        }, completion: { (success) in
            if self.shown {
                self.wrongView.isHidden = true
            }
            self.shown.toggle()
        })
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
