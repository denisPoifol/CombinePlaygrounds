import Foundation
import Combine

public class StubSubscription<Output>: Subscription {

    public init() {}

    public func request(_ demand: Subscribers.Demand) {
        // no-op
    }

    public func cancel() {
        // no-op
    }
}
