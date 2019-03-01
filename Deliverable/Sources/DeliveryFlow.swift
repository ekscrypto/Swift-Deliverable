//
//  DeliveryFlow.swift
//  Deliverable
//
//  Created by Dave Poirier on 2019-02-28.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import Foundation

extension Deliverable {
    public class Flow {
        public enum Control {
            case nextAction
            case jumpTo(_ actionName: String?)
            case waitForAsyncDecision
            case endWithException
            case end
        }
        
        public enum Status {
            case initialized
            case executing
            case waitingForAsyncDecision
            case endedByThrowable
            case endedByDecision
            case ended
        }
        
        public enum Errors: Error {
            case unexpectedAsyncDecision
            case alreadyExecuting
            case expectedAsyncDecision
        }
        
        public struct Log {
            let actionName: String
            let decision: Control
        }
        
        public struct Action {
            let name: String
            let callback: ((_ flow: Flow) -> Control)
        }
        
        private let actions: [Action] = []
        private var nextAction: Int = 0
        private let lock = NSLock()
    }
}
