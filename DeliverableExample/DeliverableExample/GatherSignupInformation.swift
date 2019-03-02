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
        onCompletion: @escaping ((_ signupDetails: SignupInformation) -> Void)) {

        let retrieveUserAction = Deliverable.asyncAction(
            named: "retrieve user name",
            action: { (deliverable: GatherSignupInformation) -> Void in

                deliverable.promptForUsername()
        })

        let retrieveEmailAction = Deliverable.asyncAction(
            named: "retrieve email address",
            action: { (deliverable: GatherSignupInformation) -> Void in

                deliverable.promptForEmailAddress()
        })

        let uponCompletionAction = Deliverable.asyncAction(
            named: "final delivery",
            action: { (deliverable: GatherSignupInformation) -> Void in

                onCompletion(deliverable.signupInformation)
        })

        self.parentViewController = parentViewController
        super.init(actions: [
            retrieveUserAction,
            retrieveEmailAction,
            uponCompletionAction
            ])
    }

    private func promptForUsername()
        -> Void {

            self.showAlertPrompt(text: "Enter your name") { (name) in
                self.signupInformation.name = name
                try? self.resume(asyncDecision: .nextAction)
            }
    }

    private func promptForEmailAddress()
        -> Void {

            self.showAlertPrompt(text: "Enter your email address") { (email) in
                self.signupInformation.emailAddress = email
                try? self.resume(asyncDecision: .nextAction)
            }
    }

    private func showAlertPrompt(
        text: String,
        then dismissAction: @escaping ((_ text: String?) -> Void))
        -> Void {

            let alert = UIAlertController(title: text, message: nil, preferredStyle: .alert)
            alert.popoverPresentationController?.sourceView = parentViewController.view
            alert.addTextField(configurationHandler: nil)
            alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (_) in
                dismissAction(alert.textFields?.first?.text)
            }))
            parentViewController.present(alert, animated: true, completion: nil)
    }

}
