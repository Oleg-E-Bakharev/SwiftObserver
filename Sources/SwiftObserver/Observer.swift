//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

/// Наблюдатель события, доставляющий уведомления методу класса.
public final class Observer<Target: AnyObject, Parameter> : EventHandler<Parameter> {
    public typealias Action = (Target)->(Parameter)->Void
    public typealias VoidAction = (Target)->()->Void
    
    weak var target: Target?
    let action: Action?
    let voidAction: VoidAction?

    public init(target: Target?, action: @escaping Action) {
        self.target = target
        self.action = action
        self.voidAction = nil
    }

    public init(target: Target?, action: @escaping VoidAction) where Parameter == Void {
        self.target = target
        self.action = nil
        self.voidAction = action
    }
    
    public override func handle(_ value: Parameter) -> Bool {
        guard let target = target else { return false }
        if let action = action {
            action(target)(value)
        } else {
            voidAction?(target)()
        }
        return true
    }
}

// MARK: -
/// Посредник (Mediator) для создания обнуляемой связи к постоянному объекту.
public extension Observer {
    final class Link {
        public typealias Action = (Target) -> (Parameter) -> Void
        public typealias VoidAction = (Target)->()->Void
        
        weak var target: Target?
        let action: Action?
        let voidAction: VoidAction?

        public init(target: Target?, action: @escaping Action) {
            self.target = target
            self.action = action
            self.voidAction = nil
        }
        
        public init(target: Target?, action: @escaping VoidAction) where Parameter == Void {
            self.target = target
            self.action = nil
            self.voidAction = action
        }

        func forward(_ value: Parameter) -> Void {
            guard let target = target else { return }
            if let action = action {
                action(target)(value)
            } else {
                voidAction?(target)()
            }
        }
    }
}

// MARK: -
///  Слушатель связи "один ко многим" на основе замыкания.
public final class ObserverClosure<Parameter> : EventHandler<Parameter> {
    public typealias Action = (Parameter)->Void
    let action: Action

    public init(action: @escaping Action) {
        self.action = action
    }

    public override func handle(_ value: Parameter) -> Bool {
        action(value)
        return true
    }
}

// MARK: -
/// Посредник (Mediator) для создания обнуляемой связи к замыканию.
public extension ObserverClosure {
    final class Link {
        public typealias Action = (Parameter) -> Void
        let action: Action

        public init(action: @escaping Action) {
            self.action = action
        }

        func forward(_ value: Parameter) -> Void {
            action(value)
        }
    }
}

// MARK: -
public extension EventProtocol {
    /// Добавление слушателя-замыкания.
    /// Использование: event += { value in }
    static func += (event: Self, action: @escaping (Parameter)->Void) {
        event += ObserverClosure(action: action)
    }

    /// Добавления обнуляемой связи к постоянному объекту. Если link удалится, то связь безопасно порвётся.
    static func +=<Target> (event: Self, link: Observer<Target, Parameter>.Link) {
        typealias Link = Observer<Target, Parameter>.Link
        event += Observer(target: link, action: Link.forward)
    }
    
    /// Добавления обнуляемой связи к постоянному замыканию. Если link удалится, то связь безопасно порвётся.
    static func += (event: Self, link: ObserverClosure<Parameter>.Link) {
        typealias Link = ObserverClosure<Parameter>.Link
        event += Observer(target: link, action: Link.forward)
    }
}
