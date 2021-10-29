//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

/// Шаблон Наблюдатель события
/// Источник связи "один ко многим".
public protocol EventProtocol {
    associatedtype Parameter

    /// Долавление нового слушателя
    static func += (event: Self, handler: EventObserver<Parameter>)
}

// MARK: -
/// База для обработчиков сообщений.
open class EventObserver<Parameter> {
    /// Обработать полученное событие.
    /// Возвращает статус true - слушатель готов получать дальнейшие события. false - больше не посылать.
    public func handle(_ value: Parameter) -> Bool {
        fatalError("must override")
    }
}

// MARK: -
/// Реализация
public final class Event<Parameter>: EventProtocol {
    public typealias Observer = EventObserver<Parameter>

    /// Cписок обработчиков.
    private final class Node {
        var observer: Observer
        var next: Node?

        init(observer: Observer, next: Node?) {
            self.observer = observer
            self.next = next
        }
    }
    private var observers: Node?
    private var connectionNotifier: (() -> Void)?
    
    /// connectedNotifier - опциональный слушатель подключения первого наблюдателя
    internal init(connectionNotifier: (() -> Void)?) {
        self.connectionNotifier = connectionNotifier
    }

    /// Уведомить всех слушателей о возникновении события
    /// При этом все отвалившиеся слушатели удаляются из списка
    /// Недоступна для внешнего вызова.
    /// Для внешнего вызова использовать EventSource.
    /// *returns* true если есть подключения слушателей
    internal func notifyObservers(_ value: Parameter) -> Bool {
        // Рекурсивный проход по слушателям с удалением отвалившихся.
        func recursiveWalk(_ node: Node?) -> Node? {
            guard node != nil else { return nil }
            var node = node
            // Схлопываем пустые узлы
            while let current = node, !current.observer.handle(value) {
                node = current.next
            }
            if let current = node {
                current.next = recursiveWalk(current.next)
            }
            return node
        }
        
        observers = recursiveWalk(observers)
        return observers != nil
    }
    
    /// Добавление слушателя. Слушатель добавляется по слабой ссылке. Чтобы убрать слушателя, надо удалить его объект.
    /// Допустимо применять посредника (Observer.Link) для отключения слушателя без удаления целевого боъекта.
    public static func += (event: Event, observer: Observer) {
        if event.observers == nil {
            event.connectionNotifier?()
        }
        event.observers = Node(observer: observer, next: event.observers)
    }
}
