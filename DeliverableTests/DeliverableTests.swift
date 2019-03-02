//
//  DeliverableTests.swift
//  DeliverableTests
//
//  Created by Dave Poirier on 2019-02-28.
//  Copyright © 2019 Dave Poirier. All rights reserved.
//

import XCTest
@testable import Deliverable

class DeliverableTests: XCTestCase {

    func testCannotResumeWithDecisionOnNewFlow() {
        let deliverable = Deliverable(actions: [])
        XCTAssertThrowsError(
            try deliverable.resume(asyncDecision: .end),
            "Providing a decision on a new flow, which is not waiting for a decision, should not be allowed"
        ) { (error) in
            XCTAssertEqual(error as? Deliverable.Errors, Deliverable.Errors.unexpectedAsyncDecision)
        }
        XCTAssertEqual(deliverable.status, .initialized)
    }
    
    func testAsyncResumeWithFlowThroughContinuesToNextAction() {
        let afterResumeWasCalled = XCTestExpectation(description: "after resume action to be called")
        var afterResumeActionExecuted = false
        let afterResumeAction = TestHelpers.actionWithControl(
            control: .nextAction,
            expectation: afterResumeWasCalled) {
                afterResumeActionExecuted = true
        }
        
        let deliverable = TestHelpers.deliverableInWaitingState([afterResumeAction])
        XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
        XCTAssertFalse(afterResumeActionExecuted)
        XCTAssertNoThrow(try deliverable.resume(asyncDecision: .nextAction))
        wait(for: [afterResumeWasCalled], timeout: 0.1)
        XCTAssertTrue(afterResumeActionExecuted)
        XCTAssertEqual(deliverable.status, .ended)
    }
    
    func testAsyncResumeWithEndDoesNotExecuteFurtherActions() {
        let deliverable = TestHelpers.deliverableInWaitingState([TestHelpers.actionThatShouldNotBeCalled()])
        XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
        XCTAssertNoThrow(try deliverable.resume(asyncDecision: .end))
        XCTAssertEqual(deliverable.status, .endedByDecision)
    }
    
    func testAsyncResumeWithWaitingForAsyncDecisionExecutesNoFurtherActions() {
        let deliverable = TestHelpers.deliverableInWaitingState([TestHelpers.actionThatShouldNotBeCalled()])
        XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
        XCTAssertNoThrow(try deliverable.resume(asyncDecision: .waitForAsyncDecision))
        XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
    }
    
    func testAsyncResumeWithThrewExceptionExecutesNoFurtherActions() {
        let deliverable = TestHelpers.deliverableInWaitingState([TestHelpers.actionThatShouldNotBeCalled()])
        XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
        XCTAssertNoThrow(try deliverable.resume(asyncDecision: .endWithException))
        XCTAssertEqual(deliverable.status, .endedByException)
    }
    
    func testCannotResumeWithoutDecisionWhenWaitingForDecision() {
        let deliverable = TestHelpers.deliverableInWaitingState([TestHelpers.actionThatShouldNotBeCalled()])
        XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
        XCTAssertThrowsError(
            try deliverable.resume(),
            "resuming without any decision a flow waiting for a decision is not allowed"
        ) { (error) in
            XCTAssertEqual(error as? Deliverable.Errors, Deliverable.Errors.expectedAsyncDecision)
        }
        XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
    }
    
    func testCannotResumeEndedFlows() {
        let deliverable = TestHelpers.deliverableInEndedState()
        XCTAssertEqual(deliverable.status, .ended)
        
        XCTAssertThrowsError(
            try deliverable.resume(asyncDecision: .nextAction),
            "resuming ended flows should not be allowed"
        ) {
            (error) in
            XCTAssertEqual(error as? Deliverable.Errors, Deliverable.Errors.ended)
        }
    }
}
