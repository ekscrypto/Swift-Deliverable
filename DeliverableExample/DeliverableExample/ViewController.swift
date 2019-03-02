//
//  ViewController.swift
//  DeliverableExample
//
//  Created by Dave Poirier on 2019-02-28.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import UIKit
import Deliverable

class ViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var emailLabel: UILabel?
    @IBOutlet weak var allDoneLabel: UILabel?
    
    private var gatherSignupInformation: GatherSignupInformation?

    @IBAction func startSignupProcess(_: Any?) {
        beginSignupProcess()
    }

    private func beginSignupProcess() {
        gatherSignupInformation = GatherSignupInformation(from: self, onCompletion: { (signupInformation) in
            self.nameLabel?.text = signupInformation.name
            self.emailLabel?.text = signupInformation.emailAddress
            self.unhideAllLabels()
        })
        try? gatherSignupInformation?.resume()
    }
    
    private func unhideAllLabels() {
        nameLabel?.isHidden = false
        emailLabel?.isHidden = false
        allDoneLabel?.isHidden = false
    }
}

