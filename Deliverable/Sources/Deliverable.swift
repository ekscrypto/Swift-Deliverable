//
//  Deliverable.swift
//  Deliverable
//
//  Created by Dave Poirier on 2019-02-28.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import Foundation

open class Deliverable {
    public enum Control {
        case nextAction
        case waitForAsyncDecision
        case endWithException
        case end
    }

    public enum Status {
        case initialized
        case inProgress
        case waitingForAsyncDecision
        case endedByException
        case endedByDecision
        case ended
    }

    public enum Errors: Error {
        case unexpectedAsyncDecision
        case alreadyExecuting
        case expectedAsyncDecision
        case ended
        case failedAdaptingGeneric
    }

    public struct Log {
        let actionName: String
        let decision: Control
    }

    public typealias ActionCallback = ((_ deliverable: Deliverable) throws -> Control)

    public struct Action {
        let name: String
        let callback: ActionCallback
    }

    private let actions: [Action]
    private var nextAction: Int = 0
    private let lock = NSLock()
    public private(set) var status: Status = .initialized
    public private(set) var logs: [Log] = []
    public var error: Error?

    public init(actions: [Action]) {
        self.actions = actions
    }

    public func resume(
        asyncDecision: Control? = nil)
        throws -> Void {

            if lock.try() == false {
                throw Errors.alreadyExecuting
            }
            defer {
                lock.unlock()
            }

            let endedStates: [Status] = [.ended, .endedByException, .endedByDecision]
            guard false == endedStates.contains(status) else {
                throw Errors.ended
            }

            if status == .waitingForAsyncDecision, asyncDecision == nil {
                throw Errors.expectedAsyncDecision
            }

            if asyncDecision != nil, status != .waitingForAsyncDecision {
                throw Errors.unexpectedAsyncDecision
            }

            if let decision = asyncDecision {
                switch decision {
                case .nextAction:
                    break
                case .end:
                    status = .endedByDecision
                case .waitForAsyncDecision:
                    status = .waitingForAsyncDecision
                case .endWithException:
                    status = .endedByException
                }
                if decision != .nextAction {
                    return
                }
            }
            status = .inProgress

            while nextAction < actions.count {
                let action = actions[nextAction]
                nextAction += 1

                do {
                    let decision = try action.callback(self)
                    logs.append(Log(
                        actionName: action.name,
                        decision: decision))

                    switch decision {
                    case .nextAction:
                        break
                    case .end:
                        status = .endedByDecision
                    case .waitForAsyncDecision:
                        status = .waitingForAsyncDecision
                    case .endWithException:
                        status = .endedByException
                    }
                    if decision != .nextAction {
                        return
                    }
                } catch {
                    logs.append(Log(
                        actionName: action.name,
                        decision: .endWithException))

                    self.error = error
                    status = .endedByException
                    throw error
                }
            }
            status = .ended
    }
}
