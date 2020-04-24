import Combine

public extension Future where Failure == Never {
    convenience init(_ guarantee: @escaping () -> Output) {
        self.init { promise in
            promise(.success(guarantee()))
        }
    }
}

public extension Future where Failure == Never, Output == Void {
    convenience init(_ guarantee: @escaping () -> Output) {
        self.init { promise in
            guarantee()
            promise(.success)
        }
    }
}
