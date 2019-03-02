//
//  TestHelpers.swift
//  DeliverableTests
//
//  Created by Dave Poirier on 2019-03-01.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import XCTest
@testable import Deliverable

class TestHelpers {
    public static func actionThatShouldNotBeCalled() -> Deliverable.Action {
        return Deliverable.Action(name: #function, callback: { (_) -> Deliverable.Control in
            XCTFail("This action should not be called")
            return .end
        })
    }
    
    public static func actionWithControl(
        control: Deliverable.Control,
        expectation: XCTestExpectation,
        additionalAction: (() -> Void)? = nil)
        -> Deliverable.Action
    {
        return Deliverable.Action(name: #function, callback: { (_) -> Deliverable.Control in
            expectation.fulfill()
            additionalAction?()
            return control
        })
    }
    
    public static func actionWithError(_ error: Error) -> Deliverable.Action {
        return Deliverable.Action(name: #function, callback: { (_) -> Deliverable.Control in
            throw error
        })
    }
    
    public static func deliverableInWaitingState(_ otherActions: [Deliverable.Action] = []) -> Deliverable {
        let waitActionWasCalled = XCTestExpectation(description: "wait action was called")
        let waitAction = self.actionWithControl(
            control: .waitForAsyncDecision,
            expectation: waitActionWasCalled)
        
        let allActions = [waitAction] + otherActions
        let flow = Deliverable(actions: allActions)
        
        XCTAssertNoThrow(try flow.resume())
        return flow
    }
    
    public static func deliverableInEndedState() -> Deliverable {
        let deliverable = Deliverable(actions: [])
        XCTAssertNoThrow(try deliverable.resume())
        return deliverable
    }
    
}
