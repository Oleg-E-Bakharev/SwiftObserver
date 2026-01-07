# SwiftObserver

Реализация шаблона проектирования Наблюдатель на Swift.
Концептуально заменяет схемы применения UIControl и [NS]NotificationCenter на чистом Swift.
Весь код покрыт тестами. Покрытие > 95%.

Штатный способ подключения - Swift Package Manager.
https://github.com/Oleg-E-Bakharev/SwiftObserver

Если нехватает функционала доставки уведомлений на DispatchQueue обратите внимание на пакет
https://github.com/Oleg-E-Bakharev/ObserverPlus

# История изменений:

## V1.0.0
- Пакет собирается на Swift6
- Методы добавления слушателя и рассылки события сделаны асинхронными. Это нужно для нормальной поддержки structural concurrency и Swift6. 
- Для добавления наблюдателей используется метод addObserver вместо оператора +=
- Добавилась возможность добавлять слушателя-замыкания с маркерным объектом времени жизни.

# Примеры использования

```Swift
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
```

# Асинхронное применение

```Swift
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
```
