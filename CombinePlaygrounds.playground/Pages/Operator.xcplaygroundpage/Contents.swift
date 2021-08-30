import Foundation
import Combine
//: [Previous](@previous)
/*:
 Creating custom publishers is great but what makes **Combine** awesome is the ability to mix unitary operators in order to create complex publishers.
 So maybe we might want to be able to create some custom operators.

 ## 9 Implementing an operator

 We've repeatedly seen that data stream could be thought as collections, but there is no enumerated operator.
 Let's try to implement one.

 First, what is an operator ?

 Let's look at `map` : it is a function implemented by all publishers that returns another publisher of type `Map<MyPublisher, NewOutput>`.
 Since `Map` is a publisher initialized by an upstream publisher and a closure it is actually quite simple to implement the `map` function.
 ```
 extension Publisher {
     func map<NewOutput>(upstream: Self,
                         transform: @escaping (Self.Output) -> NewOutput) -> Publishers.Map<Self, NewOutput> {
         Publishers.Map(upstream: self, transform: transform)
     }
 }
 ```

 So our job is to create a `Publishers.Enumerated`, creating the extension on `Publisher` should be quite easy.

 Our `Enumerated` publisher is going to be generic over the upstream publisher, because the `Output` type depends on the upstream publisher.
*/
extension Publishers {
    struct Enumerated<Upstream: Publisher>: Publisher {
        typealias Output = (Upstream.Output, Int)
        typealias Failure = Upstream.Failure

        private let upstream: Upstream

        init(upstream: Upstream) {
            self.upstream = upstream
        }
    }
}
/*:
 Now to conform to the `Publisher` protocol we just need to implement :

 `func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input`

 On one side we have an upstream publisher, and on the other a subscriber. What we are trying to do is connect the two together but we also want to intercept the values to modify them.

 The first idea that comes to mind would be to create a subscriber that subscribes to the upstream publisher. And the subscriber would forward demands from the outside to the upstream publisher.

 - Callout(Your brain):
 How is this publisher going to handle multiple subscribers ?

 Exactly! Doing so give our upstream publisher only one subscriber, which means we could not properly attach multiple subscribers to our final publisher.

 The solution here is to wrap the subscriber just like we wrapped the publisher.
 */
extension Publishers.Enumerated {
    class Inner<Downstream: Subscriber>: Subscriber
        where Downstream.Input == Output, Downstream.Failure == Upstream.Failure
    {
        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure

        private let downstream: Downstream
        private var currentValue: Int = 0

        let combineIdentifier = CombineIdentifier()

        fileprivate init(downstream: Downstream) {
            self.downstream = downstream
        }
    }
}
/*:
 Here it is much simpler to intercept the events before forwarding them to the downstream subscriber.

 Subscription are forwarded, and we can modify values before forwarding them.
 */
extension Publishers.Enumerated.Inner {
    func receive(subscription: Subscription) {
        downstream.receive(subscription: subscription)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        currentValue += 1
        let demand = downstream.receive((input, currentValue))
        return demand
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        downstream.receive(completion: completion)
    }
}
/*:
 This actualy look a lot like the implementation of `Publishers.Map`.

 Now to implement the `Publisher` protocol is pretty simple, we just need to wrap the received subscriber in our `Inner` subscriber and forward this modified subscriber to the upstream publisher.
 */
extension Publishers.Enumerated {
    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        upstream.subscribe(Inner(downstream: subscriber))
    }
}
/*:
 The nice thing about this implementation, is that passing demands to the upstream publisher, is done without any added complexity and without altering the downstream subscriber's demands count.

 Now if we want to create an extension on all publishers it is really easy, just like the `map` inmplementation discussed earlier.
 */
extension Publisher {
    func enumerated() -> Publishers.Enumerated<Self> {
        Publishers.Enumerated(upstream: self)
    }
}

(1...5)
    .publisher
    .enumerated()
    .sinkPrint()
Logger.shared.returnLogs()
/*:
 Let's do another one.

 Now I want to keep only one out of n values.
 */
extension Publishers {
    struct KeepOneOutOf<Upstream: Publisher>: Publisher {
        typealias Output = (Upstream.Output)
        typealias Failure = Upstream.Failure

        private let upstream: Upstream
        private let modulo: Int

        init(upstream: Upstream, modulo: Int) {
            self.upstream = upstream
            self.modulo = modulo
        }

        func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            upstream.subscribe(Inner(downstream: subscriber, modulo: modulo))
        }
    }
}
/*:
 The idea is the same, we need to create an `Inner` subscriber that is going to wrap our downstream subscriber.

 Here the core of our implementation is going to be in the `receive(_:Input)`.
 We need to keep track of the "index" of the current value and either forward or skip it.

 But the important thing is to request a single new value if we skip one : so that our downstream subscriber receives the exact number of values it asked for.
 */
extension Publishers.KeepOneOutOf {
    class Inner<Downstream: Subscriber>: Subscriber
        where Downstream.Input == Output, Downstream.Failure == Upstream.Failure
    {
        typealias Input = Upstream.Output

        typealias Failure = Upstream.Failure

        private let downstream: Downstream
        private var currentValue: Int = 0
        private let modulo: Int

        let combineIdentifier = CombineIdentifier()

        fileprivate init(downstream: Downstream,
                         modulo: Int) {
            self.downstream = downstream
            self.modulo = modulo
        }

        func receive(subscription: Subscription) {
            downstream.receive(subscription: subscription)
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            currentValue += 1
            if currentValue % modulo == 0 {
                let demand = downstream.receive(input)
                return demand
            } else {
                return .max(1)
            }
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            downstream.receive(completion: completion)
        }
    }
}

extension Publisher {
    func keepOneOutOf(_ modulo: Int) -> Publishers.KeepOneOutOf<Self> {
        Publishers.KeepOneOutOf(upstream: self, modulo: modulo)
    }
}

(0...5)
    .publisher
    .keepOneOutOf(2)
    .sinkPrint()
Logger.shared.returnLogs()

/*:
 This is how you are suppose to create custom operator. Just like we have seen it, it is easy to manage demands and it allows for multiple subscribers, like it should be possible.
 */

//: [Next](@next)
