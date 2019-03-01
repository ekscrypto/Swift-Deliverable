//
//  Deliverable.swift
//  Deliverable
//
//  Created by Dave Poirier on 2019-02-28.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import Foundation

public class Deliverable {
    
    public struct Log {
        let action: APIFlowAction
        let decision: FlowControl
    }
    
    public enum Status {
        case initialized
        case executing
        case waitingForAsyncDecision
        case rollingBack
        case endedByThrowable
        case endedByDecision
        case ended
    }
    
    
    public typealias Action = ((_: Flow) throws -> FlowControl)

}
