//
//  RatingViewController.swift
//  LancerHacks20
//
//  Created by Anirudh Natarajan on 2/3/20.
//  Copyright © 2020 Anirudh Natarajan. All rights reserved.
//

import UIKit

class RatingViewController: UIViewController {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet weak var cosmosStarRating: CosmosView!
    @IBOutlet weak var commentTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        commentTextField.delegate = self
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func endEditing() {
        view.endEditing(true)
    }
}

extension RatingViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing()
        return true
    }
}
