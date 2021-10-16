//
//  Created by Oleg Bakharev on 03.10.2021.
//

/// Обертка вокруг Event для возможности генерации событий.
/// Во внешний интерфейс выставляем Event. Внутри объявляем EventSender.
public struct EventSender<Parameter> {
    public var event: Event<Parameter>
    
    public init(connectionNotifier: (() -> Void)? = nil) {
        event = .init(connectionNotifier: connectionNotifier)
    }
        
    /// Послать событие всем слушателям о возникновении события
    /// *returns* Есть ли подключения в данный момент (была ли реально произведена отправка)
    @discardableResult
    public mutating func send(_ value: Parameter) -> Bool {
        return event.notifyHandlers(value)
    }

    @discardableResult
    public mutating func send() -> Bool where Parameter == Void {
        return event.notifyHandlers(())
    }
}
