import Combine
import Foundation
//: [Previous](@previous)
/*:
 We seen more than enough for you to use combine in a project but lets keep digging!

 # Combine in depth

 - Callout(Your brain):
 The tools provided by combine are great but what if I want to do something really custom ?

 That's totally possible, indeed the **Combine** API relies mostly on protocols, which means you can conform to those.

 Let's try to recreate the `Sink` subscriber, if we can do that it will be a good start to create fully custom subscribers.

## 1 Implementing Sink

 First `Sink` is a class so `MySink` will be too.
 Second it is generic over the type of `Input` and the type of `Failure`.
 And third it mostly relies on two closures given at initialization.
 */
class MySink1<Input, Failure: Error> {
    private let receiveValue: (Input) -> Void
    private let receiveCompletion: (Subscribers.Completion<Failure>) -> Void

    init(receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void  = { _ in },
         receiveValue: @escaping (Input) -> Void = { _ in }) {
        self.receiveValue = receiveValue
        self.receiveCompletion = receiveCompletion
    }
}
/*:
 So that will be our base let's try to conform to Subcriber. If I remember correctly there are three functions we need to implement :
 1. ```func receive(subscription: Subscription)```
 2. ```func receive(_ input: Self.Input) -> Subscribers.Demand```
 3. ```func receive(completion: Subscribers.Completion<Self.Failure>)```

 So when we receive a subscription what should we do with it ? Actually the subscription protocol only defines one method : `request(Subscribers.Demand)` so we probably should do something along these lines.
 This also how apple described the life cycle of a publisher :

 ![Publisher life cycle graph](PublisherLifeCycle.png)

 So the publisher passed our subscriber a subscription and we are going to use it to request elements from the publisher.
 For that we need to specify a `Subscribers.Demand` which can be initialize in 3 different ways using :
 - `none` which will obviously will ask no value to the publisher.
 - `unlimited` which will ask all the values it can get from the publisher.
 - `max(Int)` which will define the maximum number of values it wants to receiv from the publisher.

 For now we are trying to recreate `Sink` the nice thing about it is that we know from the documentation that it request an unlimited number of value upon subscription, so we don't have to think too much about the `Subscribers.Demand`.
 */
extension MySink1 {
    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }
}
/*:
 The second function we need to implement is `func receive(_ input: Self.Input) -> Subscribers.Demand`, this is quite simple when we receive a value we want to call our stored closure with the value as parameter. We also have to return an other `Subscribers.Demand` value, since we requested an unlimited number of value already we can return whatever we want.
 */
extension MySink1 {
    func receive(_ input: Input) -> Subscribers.Demand {
        receiveValue(input)
        return .unlimited
    }
}
/*:
The last function we need to implement is `func receive(completion: Subscribers.Completion<Self.Failure>)`, this is also really simple when we receive a completion we want to call our stored closure with the completion as parameter.
*/
extension MySink1 {
    func receive(completion: Subscribers.Completion<Failure>) {
        receiveCompletion(completion)
    }
}
/*:
 Now we can conform to Subscriber and we can test our implementation againt `Subscribers.Sink`.
 */
extension MySink1: Subscriber {}

func mySink1ComparedWithSink<Output, Failure: Error>(publisher: AnyPublisher<Output, Failure>) {
    print("MySink")
    let mySink = MySink1<Output, Failure>()
    publisher.subscribe(mySink)
    print("")

    print("Subscribers.Sink")
    publisher.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    print("\n")
}

mySink1ComparedWithSink(publisher: Just(5).print().eraseToAnyPublisher())
mySink1ComparedWithSink(publisher: (1...5).publisher.print().eraseToAnyPublisher())
/*:
 We can notice that our implementation prints more lines which are : `request unlimited (synchronous)`
 These line are caused by our returned demand when we receive a value, if we want the same output we should just return `.none` instead of `.unlimited` which will have the exact same effect since we already ask for an unlimited number of values upon subscirption.

 The other think we might remember is that `Sink` is `Cancellable`and so should our implementation.
 To conform to cancellable we just have to implement the `cancel` function. But what can we do inside pf that cancel function!?

 Lucky for us, it seems that `Subscription` inherrits from `Cancellable` which means our implementation could just be cancelling the subscription. But to do that we need to store the `Subscription`
 */
class MySink2<Input, Failure: Error>: Subscriber, Cancellable {
    private let receiveValue: (Input) -> Void
    private let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
    private var subscription: Subscription?

    init(receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void  = { _ in },
         receiveValue: @escaping (Input) -> Void = { _ in }) {
        self.receiveValue = receiveValue
        self.receiveCompletion = receiveCompletion
        subscription = nil
    }

    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        receiveValue(input)
        return .none
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        receiveCompletion(completion)
    }

    func cancel() {
        subscription?.cancel()
    }
}
let subject = PassthroughSubject<Int, Never>()
autoreleasepool {
    subject.print().subscribe(MySink2<Int, Never>())
    _ = subject.print().sink { _ in }
    subject.send(1)
}
subject.send(2)
/*:
 When testing with a `PassthroughSubject` we cans see that something went wrong here, the `Publishers.Sink` implmentation cancelled when released, and we can see how this is important. Indeed if we do not cancel the subscription upon release then we cannot notify the print operator that we are not listening to event anymore.

 To fix that we just need to call `cancel` in our `deinit` method

 We can finally complete our `Sink` implementation. Which as far as I know is the same as `Publishers.Sink` at least functionaly.
 */
class MySink<Input, Failure: Error>: Subscriber, Cancellable {
    private let receiveValue: (Input) -> Void
    private let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
    private var subscription: Subscription?

    init(receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void  = { _ in },
         receiveValue: @escaping (Input) -> Void = { _ in }) {
        self.receiveValue = receiveValue
        self.receiveCompletion = receiveCompletion
        subscription = nil
    }

    deinit {
        cancel()
    }

    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        receiveValue(input)
        return .none
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        receiveCompletion(completion)
    }

    func cancel() {
        subscription?.cancel()
    }
}
//: [Next](@next)
