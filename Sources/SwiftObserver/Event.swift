//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

/// Шаблон Наблюдатель события
/// Источник связи "один ко многим".
public protocol EventProtocol: Sendable {
    associatedtype Parameter: Sendable

    /// Долавление нового слушателя
    func addObserver(_ observer: EventObserver<Parameter>) async
}

// MARK: -
/// База для обработчиков сообщений.
open class EventObserver<Parameter: Sendable>: @unchecked Sendable {
    /// Обработать полученное событие.
    /// Возвращает статус true - слушатель готов получать дальнейшие события. false - больше не посылать.
    open func handle(_ value: Parameter) -> Bool {
        fatalError("must override")
    }

    /// Необходимо для возможности производить наследников в других модулях.
    public init() {}
}

// MARK: -
/// Реализация
public final class Event<Parameter: Sendable>: EventProtocol, @unchecked Sendable {
    public typealias Observer = EventObserver<Parameter>

    /// Cписок обработчиков.
    /// Потокобезопасность обеспечиваем через actor NodeList
    private final class Node: @unchecked Sendable {
        var observer: Observer
        var next: Node?

        init(observer: Observer, next: Node?) {
            self.observer = observer
            self.next = next
        }
    }

    private actor NodeList {
        var head: Node?

        func add(observer: Observer) async {
            head = Node(observer: observer, next: head)
        }

        func notify(_ value: Parameter) async {
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

            head = recursiveWalk(head)
        }
    }

    private let observers = NodeList()
    private let connectionNotifier: ((Bool) -> Void)?

    /// connectedNotifier - опциональный слушатель подключения первого наблюдателя и отключения последнего
    internal init(connectionNotifier: ((Bool) -> Void)?) {
        self.connectionNotifier = connectionNotifier
    }

    /// Уведомить всех слушателей о возникновении события
    /// При этом все отвалившиеся слушатели удаляются из списка.
    /// Недоступна для внешнего вызова.
    /// Для внешнего вызова использовать EventSource.
    internal func notifyObservers(_ value: Parameter) async {
        await observers.notify(value)
        if await self.observers.head == nil {
            self.connectionNotifier?(false)
        }
    }
    
    /// Добавление слушателя. Слушатель добавляется по слабой ссылке. Чтобы убрать слушателя, надо удалить его объект.
    /// Допустимо применять посредника (Observer.Link) для отключения слушателя без удаления целевого боъекта.
    public func addObserver(_ observer: EventObserver<Parameter>) async {
        if await observers.head == nil {
            connectionNotifier?(true)
        }
        await observers.add(observer: observer)
    }
}
