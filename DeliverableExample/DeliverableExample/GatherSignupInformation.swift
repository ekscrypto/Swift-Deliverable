//
//  GatherSignupInformation.swift
//  DeliverableExample
//
//  Created by Dave Poirier on 2019-03-02.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import UIKit
import Deliverable

class GatherSignupInformation: Deliverable {
    private var signupInformation = SignupInformation()
    private let parentViewController: UIViewController
    
    init(
        from parentViewController: UIViewController,
        onCompletion: @escaping ((_ signupDetails: SignupInformation) -> Void))
    {
        self.parentViewController = parentViewController
        
        let retrieveUserAction = Deliverable.asyncAction(named: "retrieve user name")
        { (deliverable: GatherSignupInformation) in
            deliverable.promptForUsername()
        }
        
        let retrieveEmailAction = Deliverable.asyncAction(named: "retrieve email address")
        { (deliverable: GatherSignupInformation) in
            deliverable.promptForEmailAddress()
        }
        
        let uponCompletionAction = Deliverable.asyncAction(named: "final delivery")
        { (deliverable: GatherSignupInformation) in
            onCompletion(deliverable.signupInformation)
        }

        super.init(actions: [retrieveUserAction, retrieveEmailAction, uponCompletionAction])
    }
    
    private func promptForUsername() {
        self.showAlertPrompt(text: "Enter your name") { (name) in
            self.signupInformation.name = name
            try? self.resume(asyncDecision: .nextAction)
        }
    }
    
    private func promptForEmailAddress() {
        self.showAlertPrompt(text: "Enter your email address") { (email) in
            self.signupInformation.emailAddress = email
            try? self.resume(asyncDecision: .nextAction)
        }
    }
    
    private func showAlertPrompt(text: String, then dismissAction: @escaping ((_ text: String?) -> Void)) {
        let alert = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        alert.popoverPresentationController?.sourceView = parentViewController.view
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (_) in
            dismissAction(alert.textFields?.first?.text)
        }))
        parentViewController.present(alert, animated: true, completion: nil)
    }

}
