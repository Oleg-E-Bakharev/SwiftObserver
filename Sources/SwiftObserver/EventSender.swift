//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

/// Обертка вокруг Event для возможности рассылки уведомлений.
/// Во внешний интерфейс выставляем Event. Внутри объявляем EventSender.
public struct EventSender<Parameter: Sendable>: Sendable {
    public let event: Event<Parameter>

    /// Опциональный уведомитель о подключении первого слушателя к событию
    public init(connectionNotifier: ((Bool) -> Void)? = nil) {
        event = .init(connectionNotifier: connectionNotifier)
    }
        
    /// Послать уведомление всем слушателям о возникновении события
    public func send(_ value: Parameter) async {
        await event.notifyObservers(value)
    }

    public func send() async where Parameter == Void {
        await event.notifyObservers(())
    }
}
