//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

import XCTest
import SwiftObserver

protocol AsyncSubject {
    var eventVoid: Event<Void> { get async }
    var eventInt: Event<Int> { get async }
}

actor EmitterActor {
    private var voidSender = EventSender<Void>()
    private var intSender = EventSender<Int>()

    func sendVoid() async {
        voidSender.send()
    }

    func sendInt() async {
        intSender.send(0)
    }
}

extension EmitterActor: AsyncSubject {
    var eventVoid: Event<Void> { voidSender.event }
    var eventInt: Event<Int> { intSender.event }
}


final class ObserverAsyncTests: XCTestCase {

    func testActorEvents() async {
        let voidExp = expectation(description: "Void")
        let intExp = expectation(description: "Int")
        let e = EmitterActor()
        let s: AsyncSubject = e
        await s.eventVoid += {
            voidExp.fulfill()
        }
        await s.eventInt += { _ in
            intExp.fulfill()
        }
        await e.sendVoid()
        await e.sendInt()
        await waitForExpectations(timeout: 1)
    }

}
