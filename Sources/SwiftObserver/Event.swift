//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

/// Шаблон Наблюдатель события
/// Источник связи "один ко многим".
public protocol EventProtocol: AnyObject {
    associatedtype Parameter

    /// Долавление нового слушателя
    static func += (event: Self, handler: EventHandler<Parameter>)
}

// MARK: -
/// База для обработчиков сообщений.
public class EventHandler<Parameter> {
    /// Обработать полученное событие.
    /// Возвращает статус true - слушатель готов получать дальнейшие события. false - больше не посылать.
    public func handle(_ value: Parameter) -> Bool {
        fatalError("must override")
    }
}

// MARK: -
/// Реализация
public final class Event<Parameter>: EventProtocol {
    public typealias Handler = EventHandler<Parameter>

    /// Cписок обработчиков.
    private final class Node {
        var handler: Handler
        var next: Node?

        init(handler: Handler, next: Node?) {
            self.handler = handler
            self.next = next
        }
    }
    private var handlers: Node?
    private var connectionNotifier: (() -> Void)?
    
    /// connectedNotifier - опциональный слушатель подключения первого наблюдателя
    internal init(connectionNotifier: (() -> Void)? ) {
        self.connectionNotifier = connectionNotifier
    }

    /// Уведомить всех слушателей о возникновении события
    /// При этом все отвалившиеся слушатели удаляются из списка
    /// Недоступна для внешнего вызова.
    /// Для внешнего вызова использовать EventSource.
    /// *returns* true если есть подключения слушателей
    internal func notifyHandlers(_ value: Parameter) -> Bool {
        // Рекурсивный проход по слушателям с удалением отвалившихся.
        func recursiveWalk(_ node: Node?) -> Node? {
            guard node != nil else { return nil }
            var node = node
            // Схлопываем пустые узлы
            while let current = node, !current.handler.handle(value) {
                node = current.next
            }
            if let current = node {
                current.next = recursiveWalk(current.next)
            }
            return node
        }
        
        handlers = recursiveWalk(handlers)
        return handlers != nil
    }
    
    /// Добавление слушателя. Слушатель добавляется по слабой ссылке. Чтобы убрать слушателя, надо удалить его объект.
    /// Допустимо применять посредника (Observer.Link) для удаления слушателя без удаления целевого боъекта.
    public static func += (event: Event, handler: Handler) {
        if event.handlers == nil {
            event.connectionNotifier?()
        }
        event.handlers = Node(handler: handler, next: event.handlers)
    }
}
