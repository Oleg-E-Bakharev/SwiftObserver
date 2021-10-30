# SwiftObserver

Реализация шаблона проектирования Наблюдатель на Swift.
Концептуально заменяет схемы применения UIControl и [NS]NotificationCenter на чистом Swift.
Весь код покрыт тестами. Покрытие > 95%.

Штатный способ подключения - Swift Package Manager.
https://github.com/Oleg-E-Bakharev/SwiftObserver

Если нехватает функционала доставки уведомлений на DispatchQueue обратите внимание на пакет
https://github.com/Oleg-E-Bakharev/ObserverPlus

# Примеры использования

```Swift

import XCTest
import SwiftObserver

private protocol Subject {
    var eventVoid: Event<Void> { get }
}

private final class Emitter: Subject {
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
    public func testTargetActionObserver() {
        let emitter = Emitter()
        let receiver = Receiver()
        let subject: Subject = emitter
        subject.eventVoid += Observer(target: receiver, action: Receiver.onVoid)
        emitter.send() // "Event received"
    }
    
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

    // Disposable closure link
    func testCaseFour() {
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
```
