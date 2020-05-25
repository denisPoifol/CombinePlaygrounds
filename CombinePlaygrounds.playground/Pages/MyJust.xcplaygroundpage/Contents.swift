import Combine
import Foundation
//: [Previous](@previous)
/*:
 We have seen how we can create a custom subscriber, and how it can be valuable if we want to apply back pressure since `Sink` cannot do it for us.

 Let's move on to what everybody want to start with, a custom publisher.
 Because we are lazy, and mostly because we do not want to get into something too hard yet, we are going to start with implementing our own version of `Just`.

 ## 6 Implementing a simple publisher

 For starters `Just` as a private value and is a generic struct :
*/
struct MyJust<Output> {
    private let value: Output

    init(_ value: Output) {
        self.value = value
    }
}
/*:
 Okay, to conform to `Publisher` we only need one method:
 `func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input`

 As we can recall from the [life cycle of a publisher](CoreConcepts).
 Within this method we should give our subscriber a subscription.
 Unfortunatelly for us **Combine** does not come with built in subscriptions so we are going to need to create one.
 But let's start simple and use `StubSubscription<Output>` as a subscription we will replace it once we figured out what we need to do with it.

 We also need to define our `Output` and `Failure` types, since `Just` never fails our `Failure` type is going to be `Never` and the `Output` will be a type parameter of our generic struct
 */
struct MyJustStub<Output>: Publisher {
    typealias Failure = Never

    private let value: Output

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = StubSubscription<Output>()
        subscriber.receive(subscription: subscription)
    }
}
/*:
 - Callout(Your brain):
 This already seems way too complicated for such a simple publisher.
 We could simply call `subscriber.receive(value)` then `subscriber.receive(completion: .finished)` and we would already be done with it.

 But we would be dead wrong to implement our publisher that way, because this implementation sends a value to a subscriber that did not request any.
 That is why we need even for the simplest publisher to create a subscription and provide the subscriber a chance to apply back pressure.

 Now we have two entities here a publisher and a subscription we need to decide which one is going to send values to the subscriber.
 When you think about it, it is more logical to say that the subscription is responsible for sending the values because for every subscriber there is a subscription. So the one one relation ship is probably easier to manage sending values or not depending on the demand.

 This means our subscription need to hold a reference on its subscriber.
 And since our publisher is so simple let's pass the value to the subscription instead of asking it to the publisher when we might need it.
 */
extension MyJust {
    class MySubscription<Downstream: Subscriber>: Subscription where Downstream.Input == Output {
        private var downstream: Downstream?
        private let value: Output

        init(value: Output, downstream: Downstream) {
            self.downstream = downstream
            self.value = value
        }
    }
}
/*:
 Our subscription object will need to implement two function `cancel` and `request(_:Subscribers.Demand)`.
 We are going to start with the simplest : `cancel`.
 This function hardly does anything else than freeing ressources, and here the only ressource to free is the subscriber.
 */
extension MyJust.MySubscription {
    func cancel() {
        downstream = nil
    }
}
/*:
 What about `request(_:Subscribers.Demand)` ? Well this should be simple as well, we need to check if the demand is at least one, and if it is then we can send our value followed by a completion.
 */
extension MyJust.MySubscription {
    func request(_ demand: Subscribers.Demand) {
        guard demand > 0 else { return }
        // we can ignore the returned demand because we are sending a completion immediatly after.
        _ = downstream?.receive(value)
        downstream?.receive(completion: .finished)
    }
}
/*:
 So now if we want our implementation of just to be complete we simply need to create a subscription for each new subscriber.
 */
extension MyJust: Publisher {
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        let subscription = MySubscription(value: value, downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }
}
/*:
 And that's all for the implementation of `Just`.
 There is one difference with the implementation provided by **Combine** though.
 If we were to send a demand for no values to our implementation it would be ignored, while if we sent it to the actual `Just` implementation our program would crash because there is an assertion for a strictly positive demand instead of only a simple check.
 */
let just5 = MyJust(5)
just5.sinkPrint()
just5.sinkPrint()
Logger.shared.returnLogs()
//: [Next](@next)
