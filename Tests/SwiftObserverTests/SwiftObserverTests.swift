//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

import XCTest
import SwiftObserver

private protocol Subject {
    var eventVoid: Event<Void> { get }
    var eventInt: Event<Int> { get }
}

private final class Emitter {
    private lazy var voidSender = EventSender<Void>() { [weak self] in
        self?.isVoidEventConnected = true
    }
    private lazy var intSender = EventSender<Int>() { [weak self] in
        self?.isIntEventConnected = true
    }
    var isVoidEventConnected = false
    var isIntEventConnected = false

    func sendVoid() {
        isVoidEventConnected = voidSender.send()
    }

    func sendInt(_ value: Int) {
        isIntEventConnected = intSender.send(value)
    }
        
    func onVoidConnected(_ isConnected: Bool) {
        isVoidEventConnected = isConnected
    }
    
    func onIntConnected(_ isConnected: Bool) {
        isIntEventConnected = isConnected
    }
}

extension Emitter: Subject {
    var eventVoid: Event<Void> { voidSender.event }
    var eventInt: Event<Int> { intSender.event }
}

private final class Handler {
    var isHandledVoid = false
    var isHandledInt = false
    func onVoid() {
        isHandledVoid = true
    }
    func onInt(_: Int) {
        isHandledInt = true
    }
}

final class ObserverTests: XCTestCase {
    func testEventWithoutParams() {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        s.eventVoid += Observer(target: h, action: Handler.onVoid)
        XCTAssertFalse(h.isHandledVoid)
        e.sendVoid()
        XCTAssertTrue(h.isHandledVoid)
    }

    func testEventWithOneParam() {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        s.eventInt += Observer(target: h, action: Handler.onInt)
        XCTAssertFalse(h.isHandledInt)
        e.sendInt(1)
        XCTAssertTrue(h.isHandledInt)
    }

    func testEventWithTwoObservers() {
        let e = Emitter()
        let s: Subject = e
        let h1 = Handler()
        let h2 = Handler()
        s.eventVoid += Observer(target: h1, action: Handler.onVoid)
        s.eventVoid += Observer(target: h2, action: Handler.onVoid)
        e.sendVoid()
        XCTAssertTrue(h1.isHandledVoid && h2.isHandledVoid)
    }

    func testEventWithDeadHandler() {
        let e = Emitter()
        let s: Subject = e
        var wh: Handler? = Handler()
        let h1 = Handler()
        let h2 = Handler()
        s.eventVoid += Observer(target: h1, action: Handler.onVoid)
        s.eventVoid += Observer(target: wh, action: Handler.onVoid)
        s.eventVoid += Observer(target: h2, action: Handler.onVoid)
        e.sendVoid()
        XCTAssertTrue(h1.isHandledVoid && h2.isHandledVoid && (wh?.isHandledVoid ?? false))
        h1.isHandledVoid = false
        h2.isHandledVoid = false
        wh = nil
        // three handlers now wh is dead
        e.sendVoid()
        // two handlers now
        XCTAssertTrue(h1.isHandledVoid && h2.isHandledVoid)
    }

    func testEventVoidWithLinkHandler() {
        let e = Emitter()
        let s: Subject = e
        let h1 = Handler()
        let h2 = Handler()
        let h3 = Handler()
        s.eventVoid += Observer(target: h1, action: Handler.onVoid)
        var maybeLink: Any?
        do {
            let link = Observer.Link(target: h2, action: Handler.onVoid)
            s.eventVoid += link
            maybeLink = link
        }
        e.sendVoid()
        XCTAssertTrue(h1.isHandledVoid)
        XCTAssertTrue(h2.isHandledVoid)
        h1.isHandledVoid = false
        h2.isHandledVoid = false
        XCTAssertNotNil(maybeLink)
        maybeLink = nil
        s.eventVoid += Observer(target: h3, action: Handler.onVoid)
        // link dead now but 3 handlers
        e.sendVoid()
        // two handlers now

        XCTAssertTrue(h1.isHandledVoid)
        XCTAssertFalse(h2.isHandledVoid)
        XCTAssertTrue(h3.isHandledVoid)
    }

    func testEventIntWithLinkHandler() {
        let e = Emitter()
        let s: Subject = e
        let h1 = Handler()
        let h2 = Handler()
        let h3 = Handler()
        s.eventInt += Observer(target: h1, action: Handler.onInt)
        var mayBeLink: Any?
        do {
            let link = Observer.Link(target: h2, action: Handler.onInt)
            s.eventInt += link
            mayBeLink = link
        }
        e.sendInt(1)
        XCTAssertTrue(h1.isHandledInt)
        XCTAssertTrue(h2.isHandledInt)
        h1.isHandledInt = false
        h2.isHandledInt = false
        XCTAssertNotNil(mayBeLink)
        mayBeLink = nil
        s.eventInt += Observer(target: h3, action: Handler.onInt)
        // link dead now but 3 handlers
        e.sendInt(2)
        // two handlers now

        XCTAssertTrue(h1.isHandledInt)
        XCTAssertFalse(h2.isHandledInt)
        XCTAssertTrue(h3.isHandledInt)
    }

    func testIsConnected() {
        let e = Emitter()
        var h: Handler? = Handler()
        let s: Subject = e
        XCTAssertFalse(e.isIntEventConnected)
        e.sendInt(0)
        XCTAssertFalse(e.isIntEventConnected)
        s.eventInt += Observer(target: h, action: Handler.onInt)
        XCTAssertTrue(e.isIntEventConnected)
        e.sendInt(0)
        XCTAssertTrue(e.isIntEventConnected)
        h = nil
        // now s.eventInt considered still connected
        XCTAssertTrue(e.isIntEventConnected)
        e.sendInt(0)
        // new s.eventInt signals that is diconneced
        XCTAssertFalse(e.isIntEventConnected)
    }
    
    func testObserverClosure() {
        let e = Emitter()
        let s: Subject = e
        var isVoidHandled = false
        var isIntHandled = false
        s.eventVoid += {
            isVoidHandled = true
        }
        s.eventInt += { value in
            isIntHandled = true
            print(value)
        }
        e.sendInt(0)
        e.sendVoid()
        XCTAssertTrue(isVoidHandled)
        XCTAssertTrue(isIntHandled)
    }
    
    func testObserverClosureLink() {
        let e = Emitter()
        let s: Subject = e
        var maybeLink: Any?
        var isIntHandled1 = false
        var isIntHandled2 = false
        var isIntHandled3 = false
        s.eventInt += {_ in
            isIntHandled1 = true
        }
        do {
            let link = ObserverClosure.Link { (value: Int) in
                print(value)
                isIntHandled2 = true
            }
            s.eventInt += link
            maybeLink = link
        }
        e.sendInt(0)
        XCTAssertTrue(isIntHandled1)
        XCTAssertTrue(isIntHandled2)
        isIntHandled1 = false
        isIntHandled2 = false
        XCTAssertNotNil(maybeLink)
        maybeLink = nil
        s.eventInt += { (value: Int) in
            print(value)
            isIntHandled3 = true
        }
        // link dead now but 3 handlers
        e.sendInt(1)
        // two handlers now

        XCTAssertTrue(isIntHandled1)
        XCTAssertFalse(isIntHandled2)
        XCTAssertTrue(isIntHandled3)
    }
}
