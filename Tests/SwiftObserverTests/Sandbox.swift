//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

import XCTest
import SwiftObserver

private protocol Subject {
    var eventVoid: Event<Void> { get }
}

private final class Emitter : Subject {
    private var voidSender = EventSender<Void>()
    var eventVoid: Event<Void> { voidSender.event }

    func send() {
        voidSender.send()
    }
}

private final class Receiver {
    func onVoid() {
        print("Event received")
    }
}

final class ObserverSandbox: XCTestCase {
    // UIControl-like connection. Connection breaks on target release.
    public func testTargetActionObserver() {
        let emitter = Emitter()
        let receiver = Receiver()
        let subject: Subject = emitter
        subject.eventVoid += Observer(target: receiver, action: Receiver.onVoid)
        emitter.send() // "Event received"
    }

    // UIControl-like connection. Connection breaks on link release.
    public func testTargetActionLinkObserver() {
        let emitter = Emitter()
        let receiver = Receiver()
        let subject: Subject = emitter
        var mayBeLink: Any?
        do {
            let link = Observer.Link(target: receiver, action: Receiver.onVoid)
            subject.eventVoid += link
            mayBeLink = link
        }
        XCTAssertNotNil(mayBeLink)
        emitter.send() // Event received
        mayBeLink = nil
        emitter.send() // No output
    }

    // Prmanent closure observer
    func testPermanentClosure() {
        let emitter = Emitter()
        let subject: Subject = emitter
//        subject.eventVoid += ObserverClosure<Void>() { ... }
        subject.eventVoid += { // OMG!!!
            print("Event received")
        }
        emitter.send() // Event received
    }

    // Disposable closure link. Connection breaks on link release.
    func testClosureLinkObserevr() {
        let emitter = Emitter()
        let subject: Subject = emitter
        var maybeLink: Any?
        do {
            let link = ObserverClosure.Link {
                print("Event received")
            }
            subject.eventVoid += link
            maybeLink = link
        }
        XCTAssertNotNil(maybeLink)
        emitter.send() // Event received
        maybeLink = nil
        emitter.send() // No output
    }
}
