//
//  Deliverable+Actions.swift
//  Deliverable
//
//  Created by Dave Poirier on 2019-03-02.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import Foundation

extension Deliverable {
    public static func asyncAction<T: Deliverable>(
        named actionName: String,
        action: @escaping ((_ deliverable: T) throws -> Void))
        -> Deliverable.Action {

            return Deliverable.Action(
                name: actionName,
                callback: { (deliverable) throws -> Deliverable.Control in

                    guard let requestedDeliverable = deliverable as? T else {
                        throw Errors.failedAdaptingGeneric
                    }

                    DispatchQueue.main.async {
                        do {
                            try action(requestedDeliverable)
                        } catch {
                            deliverable.error = error
                            try? deliverable.resume(asyncDecision: Deliverable.Control.endWithException)
                        }
                    }

                    return .waitForAsyncDecision
            })
    }
}
