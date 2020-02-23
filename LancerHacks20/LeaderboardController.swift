//
//  LeaderboardController.swift
//  LancerHacks20
//
//  Created by Anirudh Natarajan on 6/28/19.
//  Copyright © 2019 Anirudh Natarajan. All rights reserved.
//

import UIKit
import Firebase

protocol recievingData {
    func reload()  //data: string is an example parameter
}

class LeaderboardController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate, recievingData{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var userPositionLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userScoreLabel: UILabel!
    
    var refreshControl = UIRefreshControl()
    
    let circleSegue = CircleSegue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.reloadData()
        
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        
        cameraButton.layer.cornerRadius = cameraButton.frame.width/2
    }
    
    @objc func refresh() {
        print(1)
        var s = [Int]()
        var n = [String]()
        let ref = Database.database().reference(fromURL: "https://lancerhacks20.firebaseio.com/").child("Scores")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                let value = snap.value
                n.append("\(key)")
                let x = "\(value!)"
                s.append(Int(x)!)
            }
            let combined = zip(s, n).sorted(by: {$0.0 > $1.0})
            scores = combined.map {$0.0}
            names = combined.map {$0.1}
            
            self.refreshControl.endRefreshing()
            self.reload()
        })
    }
    
    func reload() {
        updateUser()
        tableView.reloadData()
    }
    
    func updateUser() {
        userNameLabel.text = usr
        let index = names.firstIndex(of: usr)
        userPositionLabel.text = "\(index!+1)."
        userScoreLabel.text = "\(scores[index!])"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateUser()
        userView.isHidden = false
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rankCell", for: indexPath) as! RankTableViewCell
        
        cell.usernameLabel.text = "\(names[indexPath.row])"
        cell.positionLabel.text = "\(indexPath.row+1)."
        cell.scoreLabel.text = "\(scores[indexPath.row])"
        cell.mainView.layer.cornerRadius = 15
        
        return cell
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        circleSegue.transitionMode = .present
        circleSegue.startingPoint = cameraButton.center
        circleSegue.circleColor = cameraButton.backgroundColor!

        return circleSegue
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        circleSegue.transitionMode = .dismiss
        circleSegue.startingPoint = cameraButton.center
        circleSegue.circleColor = cameraButton.backgroundColor!

        return circleSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? ARController {
            dest.transitioningDelegate = self
            dest.modalPresentationStyle = .custom
            dest.delegate = self
        }
    }
}
