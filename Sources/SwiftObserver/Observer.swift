//  Copyright (C) Oleg Bakharev 2021. All Rights Reserved

/// Наблюдатель события, доставляющий уведомления методу класса.
public final class Observer<Target: AnyObject, Parameter>: EventObserver<Parameter> {
    public typealias Action = (Target) -> (Parameter) -> Void
    public typealias VoidAction = (Target) -> () -> Void

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
    final class Link: @unchecked Sendable {
        public typealias Action = (Target) -> (Parameter) -> Void
        public typealias VoidAction = (Target) -> () -> Void
        
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
public final class ObserverClosure<Parameter> : EventObserver<Parameter> {
    public typealias Action = (Parameter) -> Void
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
    final class Link: @unchecked Sendable {
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
    func addObserver(action: @escaping (Parameter)->Void) async {
        await addObserver(ObserverClosure(action: action))
    }

    /// Добавления обнуляемой связи к постоянному объекту. Если link удалится, то связь безопасно порвётся.
    func addObserver<Target>(_ link: Observer<Target, Parameter>.Link) async {
        typealias Link = Observer<Target, Parameter>.Link
        await addObserver(Observer(target: link, action: Link.forward))
    }
    
    /// Добавления обнуляемой связи к постоянному замыканию. Если link удалится, то связь безопасно порвётся.
    func addObserver(_ link: ObserverClosure<Parameter>.Link) async {
        typealias Link = ObserverClosure<Parameter>.Link
        await addObserver(Observer(target: link, action: Link.forward))
    }
}
