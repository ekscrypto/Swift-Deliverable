//
//  Deliverable.swift
//  Deliverable
//
//  Created by Dave Poirier on 2019-02-28.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import Foundation

public class Deliverable {
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
    }
    
    public struct Log {
        let actionName: String
        let decision: Control
    }
    
    public struct Action {
        let name: String
        let callback: ((_ deliverable: Deliverable) throws -> Control)
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

    public func resume(asyncDecision: Control? = nil) throws {
        lock.lock()
        let endedStates: [Status] = [.ended, .endedByException, .endedByDecision]
        guard false == endedStates.contains(status) else {
            lock.unlock()
            throw Errors.ended
        }

        if status == .waitingForAsyncDecision, asyncDecision == nil {
            lock.unlock()
            throw Errors.expectedAsyncDecision
        }
        
        if asyncDecision != nil, status != .waitingForAsyncDecision {
            lock.unlock()
            throw Errors.unexpectedAsyncDecision
        }
        
        if status != .initialized, status != .waitingForAsyncDecision {
            lock.unlock()
            throw Errors.alreadyExecuting
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
                lock.unlock()
                return
            }
        }
        
        status = .inProgress
        while nextAction < actions.count {
            let flowAction = actions[nextAction]
            nextAction += 1
            
            do {
                let decision = try flowAction.callback(self)
                logs.append(Log(
                    actionName: flowAction.name,
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
                    lock.unlock()
                    return
                }
            } catch {
                logs.append(Log(
                    actionName: flowAction.name,
                    decision: .endWithException))
                
                self.error = error
                status = .endedByException
                lock.unlock()
                throw error
            }
        }
        status = .ended
        lock.unlock()
    }
}
