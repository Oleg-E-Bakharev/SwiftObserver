//
//  Created by Oleg Bakharev on 29.09.2021.
//

/// Шаблон Наблюдатель события
/// Источник связи "один ко многим".
public class Event<Param> {
    typealias Handler = EventHandler<Param>

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

    /// Уведомить всех слушателей о возникновении события
    /// При этом все отвалившиеся слушатели удаляются из списка
    /// Недоступна для внешнего вызова. Для внешнего вызова использовать фасад EventSource.
    func notifyHandlers(_ value: Param) {
        handlers = recursiveWalk(handlers)
        if hasConnections && handlers == nil {
            hasConnections = false
        }

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
    }
    
    var hasConnections = false

    /// Добавление слушателя. Слушатель добавляется по слабой ссылке. Чтобы убрать слушателя, надо удалить его объект.
    /// Допустимо применять посредника (Observer.Link) для удаления слушателя без удаления целевого боъекта.
    public static func += (event: Event, handler: EventHandler<Param>) {
        if !event.hasConnections {
            event.hasConnections = true
        }
        event.handlers = Node(handler: handler, next: event.handlers)
    }
}

// MARK: -
/// База для обработчиков сообщений.
public class EventHandler<Param> {
    /// Обработать полученное событие.
    /// Возвращает статус true - слушатель готов волучать дальнейшие события. false - больше не послылать.
    public func handle(_ value: Param) -> Bool {
        fatalError("must override")
    }
}
