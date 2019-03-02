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
    enum Errors: Error {
        case generic
    }

    public static func actionThatShouldNotBeCalled()
        -> Deliverable.Action {

            return Deliverable.Action(
                name: #function,
                callback: { (_) throws -> Deliverable.Control in

                    XCTFail("This action should not be called")
                    return .end
            })
    }

    public static func actionWithControl(
        control: Deliverable.Control,
        expectation: XCTestExpectation? = nil,
        additionalAction: ((_: Deliverable) throws -> Void)? = nil)
        -> Deliverable.Action {

            return Deliverable.Action(
                name: #function,
                callback: { (deliverable) throws -> Deliverable.Control in

                    expectation?.fulfill()
                    try additionalAction?(deliverable)
                    return control
            })
    }

    public static func actionWithError(
        _ error: Error)
        -> Deliverable.Action {

            return Deliverable.Action(
                name: #function,
                callback: { (_) throws -> Deliverable.Control in

                    throw error
            })
    }

    public static func deliverableInWaitingState(
        _ otherActions: [Deliverable.Action] = [])
        -> Deliverable {

            let waitActionWasCalled = XCTestExpectation(description: "wait action was called")
            let waitAction = self.actionWithControl(
                control: .waitForAsyncDecision,
                expectation: waitActionWasCalled)

            let allActions = [waitAction] + otherActions
            let deliverable = Deliverable(actions: allActions)

            XCTAssertNoThrow(try deliverable.resume())
            return deliverable
    }

    public static func deliverableInEndedState()
        -> Deliverable {

            let deliverable = Deliverable(actions: [])
            XCTAssertNoThrow(try deliverable.resume())
            XCTAssertEqual(deliverable.status, .ended)
            return deliverable
    }

    public static func deliverableInEndedByDecisionState()
        -> Deliverable {

            let endAction = self.actionWithControl(control: .end)
            let deliverable = Deliverable(actions: [endAction])
            XCTAssertNoThrow(try deliverable.resume())
            XCTAssertEqual(deliverable.status, .endedByDecision)
            return deliverable
    }

    public static func deliverableInEndedByExceptionState()
        -> Deliverable {

            let endAction = self.actionWithControl(
                control: .endWithException,
                additionalAction: { (deliverable) throws -> Void in

                    deliverable.error = Errors.generic
            })
            let deliverable = Deliverable(actions: [endAction])
            XCTAssertNoThrow(try deliverable.resume())
            XCTAssertEqual(deliverable.status, .endedByException)
            return deliverable
    }
}
