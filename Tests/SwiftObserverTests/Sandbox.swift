//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

import Testing
import SwiftObserver

private protocol Subject {
    var eventVoid: Event<Void> { get }
}

private final class Emitter: Subject {
    private var voidSender = EventSender<Void>()
    var eventVoid: Event<Void> { voidSender.event }

    func send() async {
        await voidSender.send()
    }
}

private final class Receiver: Sendable {
    func onVoid() {
        print("Event received")
    }
}

@Suite struct ObserverSandbox {
    // UIControl-like connection. Connection breaks on target release.
    @Test func testTargetActionObserver() async throws {
        let emitter = Emitter()
        let receiver = Receiver()
        let subject: Subject = emitter
        await subject.eventVoid.addObserver(Observer(target: receiver, action: Receiver.onVoid))
        await emitter.send() // "Event received"
    }

    // UIControl-like connection. Connection breaks on link release.
    @Test func testTargetActionLinkObserver() async throws {
        let emitter = Emitter()
        let receiver = Receiver()
        let subject: Subject = emitter
        var mayBeLink: Any?
        do {
            let link = Observer.Link(target: receiver, action: Receiver.onVoid)
            await subject.eventVoid.addObserver(link)
            mayBeLink = link
        }
        #expect(mayBeLink != nil)
        await emitter.send() // Event received
        mayBeLink = nil
        await emitter.send() // No output
    }

    // Prmanent closure observer
    @Test func testPermanentClosure() async throws {
        let emitter = Emitter()
        let subject: Subject = emitter
//      await subject.eventVoid.addObserver(ObserverClosure<Void>() { ... })
        await subject.eventVoid.addObserver { // OMG!!!
            print("Event received")
        }
        await emitter.send() // Event received
    }

    // Disposable closure observer.
    @Test func testDisposableClosureObserevr() async throws {
        let emitter = Emitter()
        let subject: Subject = emitter
        var receiver: Receiver? = Receiver()
        await subject.eventVoid.addObserver(receiver) {
            print("Event received")
        }
        await emitter.send() // Event received
        receiver = nil
        await emitter.send()  // No output
    }

    // Disposable closure link. Connection breaks on link release.
    @Test func testClosureLinkObserevr() async throws {
        let emitter = Emitter()
        let subject: Subject = emitter
        var maybeLink: Any?
        do {
            let link = ObserverClosure.Link {
                print("Event received")
            }
            await subject.eventVoid.addObserver(link)
            maybeLink = link
        }
        #expect(maybeLink != nil)
        await emitter.send() // Event received
        maybeLink = nil
        await emitter.send() // No output
    }
}
