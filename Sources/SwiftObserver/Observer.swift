//
//  Created by Oleg Bakharev on 29.09.2021.
//

/// Шаблон Наблюдатель события
///  Слушатель связи "один ко многим".
public final class Observer<Target: AnyObject, Param> : EventHandler<Param> {
    weak var target: Target?

    public typealias Action = (Target)->(Param)->Void
    let action: Action

    public init(target: Target?, action: @escaping Action) {
        self.target = target
        self.action = action
    }

    public override func handle(_ param: Param) -> Bool {
        guard let target = target else { return false }
        action(target)(param)
        return true
    }
}

// MARK: -
/// Посредник (Mediator) для создания обнуляемой связи к постоянному объекту.
public extension Observer {
    final class Link {
        public typealias Action = (Target) -> (Param) -> Void
        weak var target: Target?
        let action: Action

        public init(target: Target, action: @escaping Action) {
            self.target = target
            self.action = action
        }

        func send(_ value: Param) -> Void {
            guard let target = target else { return }
            action(target)(value)
        }
    }
}

// MARK: -
///  Слушатель связи "один ко многим" на основе замыкания.
public final class ObserverClosure<Param> : EventHandler<Param> {
    public typealias Action = (Param)->Void
    let action: Action

    public init(action: @escaping Action) {
        self.action = action
    }

    public override func handle(_ param: Param) -> Bool {
        action(param)
        return true
    }
}

/// Посредник (Mediator) для создания обнуляемой связи к замыканию.
public extension ObserverClosure {
    final class Link {
        public typealias Action = (Param) -> Void
        let action: Action

        public init(action: @escaping Action) {
            self.action = action
        }

        func send(_ value: Param) -> Void {
            action(value)
        }
    }
}

public extension Event {
    /// Добавление слушателя-замыкания.
    /// Использование: event += { value in }
    static func += (event: Event, action: @escaping (Param)->Void) {
        event += ObserverClosure(action: action)
    }

    /// Добавления обнуляемой связи к постоянному объекту. Если link удалится, то связь безопасно порвётся.
    static func +=<Target> (event: Event, link: Observer<Target, Param>.Link) {
        typealias Link = Observer<Target, Param>.Link
        event += Observer(target: link, action: Link.send)
    }
    
    /// Добавления обнуляемой связи к постоянному замыканию. Если link удалится, то связь безопасно порвётся.
    static func += (event: Event, link: ObserverClosure<Param>.Link) {
        typealias Link = ObserverClosure<Param>.Link
        event += Observer(target: link, action: Link.send)
    }
}
