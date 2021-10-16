//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

/// Обертка вокруг Event для возможности рассылки уведомлений.
/// Во внешний интерфейс выставляем Event. Внутри объявляем EventSender.
public struct EventSender<Parameter> {
    public var event: Event<Parameter>
    
    /// Опциональный уведомитель о подключении первого слушателя к событию
    public init(connectionNotifier: (() -> Void)? = nil) {
        event = .init(connectionNotifier: connectionNotifier)
    }
        
    /// Послать уведомление всем слушателям о возникновении события
    /// *returns* Есть ли подключения в данный момент (была ли реально произведена отправка уведомления)
    @discardableResult
    public mutating func send(_ value: Parameter) -> Bool {
        return event.notifyHandlers(value)
    }

    @discardableResult
    public mutating func send() -> Bool where Parameter == Void {
        return event.notifyHandlers(())
    }
}
