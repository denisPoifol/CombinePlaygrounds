import Combine

public extension Publisher {
    func then<T>(_ guarantee: @escaping () -> T) -> Publishers.Map<Self, T> {
        map { _ in
            guarantee()
        }
    }
    
    func then(_ guarantee: @escaping () -> Void) -> Publishers.Map<Self, Void> {
        map { _ in
            guarantee()
        }
    }
}

public extension Publishers.Sequence {
    func then<T>(_ guarantee: @escaping () -> T) -> Publishers.Sequence<[T], Failure> {
        map { _ in
            guarantee()
        }
    }
}
