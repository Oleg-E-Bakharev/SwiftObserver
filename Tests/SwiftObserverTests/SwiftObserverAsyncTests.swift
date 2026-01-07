//  Copyright (C) Oleg Bakharev 2021-2025. All Rights Reserved

import Testing
import SwiftObserver

protocol AsyncSubject {
    var eventVoid: Event<Void> { get async }
    var eventInt: Event<Int> { get async }
}

actor EmitterActor {
    private var voidSender = EventSender<Void>()
    private var intSender = EventSender<Int>()

    func sendVoid() async {
        await voidSender.send()
    }

    func sendInt() async {
        await intSender.send(0)
    }
}

extension EmitterActor: AsyncSubject {
    var eventVoid: Event<Void> { voidSender.event }
    var eventInt: Event<Int> { intSender.event }
}

actor ReceiverA {
    func subsribe(_ event: Event<Void>) async {
        await event.addObserver { }
    }
}

actor ReceiverB {
    func subsribe(_ event: Event<Void>) async {
        await event.addObserver { }
    }
}

@Test func testActorEvents() async throws {
    let e = EmitterActor()
    let s: AsyncSubject = e
    var voidReceived = false
    var intRevceivd = false

    await s.eventVoid.addObserver {
        voidReceived = true
    }
    await s.eventInt.addObserver { _ in
        intRevceivd = true
    }
    await e.sendVoid()
    await e.sendInt()

    #expect(voidReceived)
    #expect(intRevceivd)
}
