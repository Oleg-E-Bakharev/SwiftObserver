//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

import Testing
import SwiftObserver

private protocol Subject {
    var eventVoid: Event<Void> { get }
    var eventInt: Event<Int> { get }
}

private final class Emitter {
    private lazy var voidSender = EventSender<Void>() { [weak self] isConnected in
        self?.isVoidEventConnected = isConnected
    }
    private lazy var intSender = EventSender<Int>() { [weak self] isConnected in
        self?.isIntEventConnected = isConnected
    }
    var isVoidEventConnected = false
    var isIntEventConnected = false

    func sendVoid() async {
        await voidSender.send()
    }

    func sendInt(_ value: Int) async {
        await intSender.send(value)
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

@Suite struct ObserverTests {
    @Test func testEventWithoutParams() async throws {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        await s.eventVoid.addObserver(Observer(target: h, action: Handler.onVoid))
        #expect(!h.isHandledVoid)
        await e.sendVoid()
        #expect(h.isHandledVoid)
    }

    @Test func testEventWithOneParam() async throws {
        let e = Emitter()
        let h = Handler()
        let s: Subject = e
        await s.eventInt.addObserver(Observer(target: h, action: Handler.onInt))
        #expect(!h.isHandledInt)
        await e.sendInt(1)
        #expect(h.isHandledInt)
    }

    @Test func testEventWithTwoObservers() async throws {
        let e = Emitter()
        let s: Subject = e
        let h1 = Handler()
        let h2 = Handler()
        await s.eventVoid.addObserver(Observer(target: h1, action: Handler.onVoid))
        await s.eventVoid.addObserver(Observer(target: h2, action: Handler.onVoid))
        await e.sendVoid()
        #expect(h1.isHandledVoid && h2.isHandledVoid)
    }

    @Test func testEventWithDeadHandler() async throws {
        let e = Emitter()
        let s: Subject = e
        var wh: Handler? = Handler()
        let h1 = Handler()
        let h2 = Handler()
        await s.eventVoid.addObserver(Observer(target: h1, action: Handler.onVoid))
        await s.eventVoid.addObserver(Observer(target: wh, action: Handler.onVoid))
        await s.eventVoid.addObserver(Observer(target: h2, action: Handler.onVoid))
        await e.sendVoid()
        #expect(h1.isHandledVoid && h2.isHandledVoid && (wh?.isHandledVoid ?? false))
        h1.isHandledVoid = false
        h2.isHandledVoid = false
        wh = nil
        // three handlers now wh is dead
        await e.sendVoid()
        // two handlers now
        #expect(h1.isHandledVoid && h2.isHandledVoid)
    }

    @Test func testEventVoidWithLinkHandler() async throws {
        let e = Emitter()
        let s: Subject = e
        let h1 = Handler()
        let h2 = Handler()
        let h3 = Handler()
        await s.eventVoid.addObserver(Observer(target: h1, action: Handler.onVoid))
        var maybeLink: Any?
        do {
            let link = Observer.Link(target: h2, action: Handler.onVoid)
            await s.eventVoid.addObserver(link)
            maybeLink = link
        }
        await e.sendVoid()
        #expect(h1.isHandledVoid)
        #expect(h2.isHandledVoid)
        h1.isHandledVoid = false
        h2.isHandledVoid = false
        #expect(maybeLink != nil)
        maybeLink = nil
        await s.eventVoid.addObserver(Observer(target: h3, action: Handler.onVoid))
        // link dead now but 3 handlers
        await e.sendVoid()
        // two handlers now

        #expect(h1.isHandledVoid)
        #expect(!h2.isHandledVoid)
        #expect(h3.isHandledVoid)
    }

    @Test func testEventIntWithLinkHandler() async throws {
        let e = Emitter()
        let s: Subject = e
        let h1 = Handler()
        let h2 = Handler()
        let h3 = Handler()
        await s.eventInt.addObserver(Observer(target: h1, action: Handler.onInt))
        var mayBeLink: Any?
        do {
            let link = Observer.Link(target: h2, action: Handler.onInt)
            await s.eventInt.addObserver(link)
            mayBeLink = link
        }
        await e.sendInt(1)
        #expect(h1.isHandledInt)
        #expect(h2.isHandledInt)
        h1.isHandledInt = false
        h2.isHandledInt = false
        #expect(mayBeLink != nil)
        mayBeLink = nil
        await s.eventInt.addObserver(Observer(target: h3, action: Handler.onInt))
        // link dead now but 3 handlers
        await e.sendInt(2)
        // two handlers now

        #expect(h1.isHandledInt)
        #expect(!h2.isHandledInt)
        #expect(h3.isHandledInt)
    }

    @Test func testIsConnected() async throws {
        let e = Emitter()
        var h: Handler? = Handler()
        let s: Subject = e
        #expect(!e.isIntEventConnected)
        await e.sendInt(0)
        #expect(!e.isIntEventConnected)
        await s.eventInt.addObserver(Observer(target: h, action: Handler.onInt))
        #expect(e.isIntEventConnected)
        await e.sendInt(0)
        #expect(e.isIntEventConnected)
        h = nil
        // now s.eventInt considered still connected
        #expect(e.isIntEventConnected)
        await e.sendInt(0)
        // new s.eventInt signals that is diconneced
        #expect(!e.isIntEventConnected)
    }
    
    @Test func testObserverClosure() async throws {
        let e = Emitter()
        let s: Subject = e
        var isVoidHandled = false
        var isIntHandled = false
        await s.eventVoid.addObserver {
            isVoidHandled = true
        }
        await s.eventInt.addObserver { value in
            isIntHandled = true
            print(value)
        }
        await e.sendInt(0)
        await e.sendVoid()
        #expect(isVoidHandled)
        #expect(isIntHandled)
    }
    
    @Test func testObserverClosureLink() async throws {
        let e = Emitter()
        let s: Subject = e
        var maybeLink: Any?
        var isIntHandled1 = false
        var isIntHandled2 = false
        var isIntHandled3 = false
        await s.eventInt.addObserver {_ in
            isIntHandled1 = true
        }
        do {
            let link = ObserverClosure.Link { (value: Int) in
                print(value)
                isIntHandled2 = true
            }
            await s.eventInt.addObserver(link)
            maybeLink = link
        }
        await e.sendInt(0)
        #expect(isIntHandled1)
        #expect(isIntHandled2)
        isIntHandled1 = false
        isIntHandled2 = false
        #expect(maybeLink != nil)
        maybeLink = nil
        await s.eventInt.addObserver { (value: Int) in
            print(value)
            isIntHandled3 = true
        }
        // link dead now but 3 handlers
        await e.sendInt(1)
        // two handlers now

        #expect(isIntHandled1)
        #expect(!isIntHandled2)
        #expect(isIntHandled3)
    }
}
