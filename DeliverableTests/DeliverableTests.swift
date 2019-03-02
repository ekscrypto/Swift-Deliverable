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

    func testCannotResumeWithDecisionOnNewDeliverable()
        -> Void {

            let deliverable = Deliverable(actions: [])
            XCTAssertThrowsError(
                try deliverable.resume(asyncDecision: .end),
                "Providing a decision on a new deliverable, which is not waiting for a decision, should not be allowed"
            ) { (error) in
                XCTAssertEqual(error as? Deliverable.Errors, Deliverable.Errors.unexpectedAsyncDecision)
            }
            XCTAssertEqual(deliverable.status, .initialized)
    }

    func testAsyncResumeWithNextActionContinuesToNextAction()
        -> Void {

            let afterResumeWasCalled = XCTestExpectation(description: "after resume action to be called")
            var afterResumeActionExecuted = false
            let afterResumeAction = TestHelpers.actionWithControl(
                control: .nextAction,
                expectation: afterResumeWasCalled) { (_) in
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

    func testAsyncResumeWithEndDoesNotExecuteFurtherActions()
        -> Void {

            let deliverable = TestHelpers.deliverableInWaitingState([TestHelpers.actionThatShouldNotBeCalled()])
            XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
            XCTAssertNoThrow(try deliverable.resume(asyncDecision: .end))
            XCTAssertEqual(deliverable.status, .endedByDecision)
    }

    func testAsyncResumeWithWaitingForAsyncDecisionExecutesNoFurtherActions()
        -> Void {

            let deliverable = TestHelpers.deliverableInWaitingState([TestHelpers.actionThatShouldNotBeCalled()])
            XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
            XCTAssertNoThrow(try deliverable.resume(asyncDecision: .waitForAsyncDecision))
            XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
    }

    func testAsyncResumeWithThrewExceptionExecutesNoFurtherActions()
        -> Void {

            let deliverable = TestHelpers.deliverableInWaitingState([TestHelpers.actionThatShouldNotBeCalled()])
            XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)

            XCTAssertNoThrow(try deliverable.resume(asyncDecision: .endWithException))
            XCTAssertEqual(deliverable.status, .endedByException)
    }

    func testCannotResumeWithoutDecisionWhenWaitingForDecision()
        -> Void {

            let deliverable = TestHelpers.deliverableInWaitingState([TestHelpers.actionThatShouldNotBeCalled()])
            XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)

            XCTAssertThrowsError(
                try deliverable.resume(),
                "resuming without any decision a deliverable waiting for a decision is not allowed"
            ) { (error) in
                XCTAssertEqual(error as? Deliverable.Errors, Deliverable.Errors.expectedAsyncDecision)
            }
            XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
    }

    func testCannotResumeEndedDeliverable()
        -> Void {

            let deliverable = TestHelpers.deliverableInEndedState()
            XCTAssertEqual(deliverable.status, .ended)

            XCTAssertThrowsError(
                try deliverable.resume(asyncDecision: .nextAction),
                "resuming ended deliverable should not be allowed"
            ) {
                (error) in
                XCTAssertEqual(error as? Deliverable.Errors, Deliverable.Errors.ended)
            }
    }

    func testCannotResumeEndedByExceptionDeliverable()
        -> Void {

            let deliverable = TestHelpers.deliverableInEndedByExceptionState()
            XCTAssertEqual(deliverable.status, .endedByException)

            XCTAssertThrowsError(
                try deliverable.resume(asyncDecision: .nextAction),
                "resuming ended deliverable should not be allowed"
            ) {
                (error) in
                XCTAssertEqual(error as? Deliverable.Errors, Deliverable.Errors.ended)
            }
    }

    func testCannotResumeEndedByDecisionDeliverable()
        -> Void {

            let deliverable = TestHelpers.deliverableInEndedByDecisionState()
            XCTAssertEqual(deliverable.status, .endedByDecision)

            XCTAssertThrowsError(
                try deliverable.resume(asyncDecision: .nextAction),
                "resuming ended deliverable should not be allowed"
            ) {
                (error) in
                XCTAssertEqual(error as? Deliverable.Errors, Deliverable.Errors.ended)
            }
    }

    func testCannotResumeInProgressDeliverable()
        -> Void {

            let testAction = TestHelpers.actionWithControl(control: .nextAction) { (deliverable) throws in
                XCTAssertEqual(deliverable.status, .inProgress)
                XCTAssertThrowsError(
                    try deliverable.resume(asyncDecision: .nextAction),
                    "resuming inProgress deliverable should not be allowed"
                ) {
                    (error) in
                    XCTAssertEqual(error as? Deliverable.Errors, Deliverable.Errors.alreadyExecuting)
                }
            }
            let deliverable = Deliverable(actions: [testAction])
            XCTAssertNoThrow(try deliverable.resume())
    }

    func testEndsOnControlEndWithNoFurtherActions()
        -> Void {

            let actionWasCalled = XCTestExpectation(description: "end action to be called")
            let endAction = TestHelpers.actionWithControl(
                control: .end,
                expectation: actionWasCalled)

            let deliverable = Deliverable(actions: [
                endAction,
                TestHelpers.actionThatShouldNotBeCalled()])

            XCTAssertNoThrow(try deliverable.resume())
            wait(for: [actionWasCalled], timeout: 0.1)

            XCTAssertEqual(deliverable.status, .endedByDecision)
    }

    func testEndsOnControlEndWithException()
        -> Void {

            let actionWasCalled = XCTestExpectation(description: "end action to be called")
            let endAction = TestHelpers.actionWithControl(
                control: .endWithException,
                expectation: actionWasCalled)

            let deliverable = Deliverable(actions: [
                endAction,
                TestHelpers.actionThatShouldNotBeCalled()])

            XCTAssertNoThrow(try deliverable.resume())
            wait(for: [actionWasCalled], timeout: 0.1)

            XCTAssertEqual(deliverable.status, .endedByException)
    }

    func testContinuesOnControlNextAction()
        -> Void {

            let firstActionWasCalled = XCTestExpectation(description: "first action to be called")
            let firstAction = TestHelpers.actionWithControl(
                control: .nextAction,
                expectation: firstActionWasCalled)

            let deliverable = Deliverable(actions: [
                firstAction])

            XCTAssertNoThrow(try deliverable.resume())
            wait(for: [firstActionWasCalled], timeout: 0.1)

            XCTAssertEqual(deliverable.status, .ended)
    }

    func testPausesOnControlWaitForAsyncDecision()
        -> Void {

            let waitActionWasCalled = XCTestExpectation(description: "wait action to be called")
            let waitAction = TestHelpers.actionWithControl(
                control: .waitForAsyncDecision,
                expectation: waitActionWasCalled)

            let deliverable = Deliverable(actions: [
                waitAction,
                TestHelpers.actionThatShouldNotBeCalled()])

            XCTAssertNoThrow(try deliverable.resume())
            wait(for: [waitActionWasCalled], timeout: 0.1)

            XCTAssertEqual(deliverable.status, .waitingForAsyncDecision)
    }

    func testEndsIfExecutionExceptionGenerated()
        -> Void {

            let errorAction = TestHelpers.actionWithError(TestHelpers.Errors.generic)
            let deliverable = Deliverable(actions: [errorAction])

            XCTAssertThrowsError(try deliverable.resume())

            XCTAssertEqual(deliverable.status, .endedByException)
            XCTAssertEqual(deliverable.error as? TestHelpers.Errors, TestHelpers.Errors.generic)
    }

    func testNoActionsImmediatelyEndsWithStatusEnded()
        -> Void {

            let deliverable = Deliverable(actions: [])

            XCTAssertNoThrow(try deliverable.resume())

            XCTAssertEqual(deliverable.status, .ended)
    }

    func testActionsAreExecutedInOrder()
        -> Void {

            var expectations = [XCTestExpectation]()
            var actions = [Deliverable.Action]()
            var calledSoFar: Int = 0
            for i in 1...5 {
                let expectation = XCTestExpectation(description: "\(i) action to be called")
                let action = TestHelpers.actionWithControl(
                    control: .nextAction,
                    expectation: expectation) { (_) in
                        calledSoFar += 1
                        XCTAssertEqual(calledSoFar, i)
                }
                expectations.append(expectation)
                actions.append(action)
            }

            let deliverable = Deliverable(actions: actions)
            XCTAssertEqual(calledSoFar, 0)

            XCTAssertNoThrow(try deliverable.resume())
            wait(for: expectations, timeout: 0.1, enforceOrder: true)

            XCTAssertEqual(deliverable.status, .ended)
            XCTAssertEqual(calledSoFar, actions.count)
    }
}
