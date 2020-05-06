import Combine

public class RegulatedFlowSubscriber<Input, Failure: Error>: Subscriber, Cancellable {
    private let receiveValue: (Input) -> Void
    private let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
    private var subscription: Subscription?

    public init(receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void  = { _ in },
         receiveValue: @escaping (Input) -> Void = { _ in }) {
        self.receiveValue = receiveValue
        self.receiveCompletion = receiveCompletion
        subscription = nil
    }

    deinit {
        cancel()
    }

    public func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.max(1))
    }

    public func receive(_ input: Input) -> Subscribers.Demand {
        receiveValue(input)
        return .none
    }

    public func receive(completion: Subscribers.Completion<Failure>) {
        receiveCompletion(completion)
    }

    public func cancel() {
        subscription?.cancel()
    }

    public func request(_ demand: Subscribers.Demand) {
        subscription?.request(demand)
    }
}
