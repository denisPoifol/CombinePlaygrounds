import Combine
import Foundation
//: [Previous](@previous)
/*:
 `Sink` was a good practice to implement our first ever subscriber, the simplicity mostly comes from the fact that we directly request an unlimited number of values

 But let's look closely how `Subscribers.Demand` works.

 ## 2 Subscribers.Demand

 To understand how demands works let's create a subscriber that request no value but also provide for a method to request values
 */
class RegulatedFlowSubscriber1<Input, Failure: Error>: Subscriber, Cancellable {
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
        subscription.request(.none)
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

    func request(_ demand: Subscribers.Demand) {
        subscription?.request(demand)
    }
}
/*:
 This is basically our `MySink` with the difference that we request no value at subscription, and provide a method to perform a request from outside the class.

 Let's play a bit with it to understand how it works :
 */
let intPublisher = (1...).publisher.print()
let regulatedFlowSubscriber = RegulatedFlowSubscriber1<Int, Never>()
intPublisher.subscribe(regulatedFlowSubscriber)
regulatedFlowSubscriber.request(.max(5))
regulatedFlowSubscriber.request(.max(3))
regulatedFlowSubscriber.request(.none)
regulatedFlowSubscriber.request(.max(1))
print("\n")
/*:
 As you can see requesting values is purely additive, you cannot request 5 values then change your mind and request only 3 instead.

 Let's try when we control both ends of our data stream. For that we are going to use a subject.
 */
let subject = PassthroughSubject<Int, MyError>()
let subjectSubscriber1 = RegulatedFlowSubscriber1<Int, MyError>()
subject
    .print()
    .subscribe(subjectSubscriber) // Comment me once you tried
print("\n")
/*:
 😱 I did not expected a crash from this. What's causing this !?

 This is due to a bug of the implementation of `PassThroughSubject` and `CurrentValueSubject` if you want to know a bit more about it you can look [here](NativeSubjectsCrash)

 To fix this we are just going to request `.max(1)` value instead of `.none` upon subscription
  */
class RegulatedFlowSubscriber<Input, Failure: Error>: Subscriber, Cancellable {
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
        subscription.request(.max(1))
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

    func request(_ demand: Subscribers.Demand) {
        subscription?.request(demand)
    }
}
let subjectSubscriber = RegulatedFlowSubscriber<Int, MyError>()
subject
    .print()
    .subscribe(subjectSubscriber)
subject.send(0)
subjectSubscriber.request(.max(1))
subject.send(1)
subject.send(2)
subject.send(3)
subjectSubscriber.request(.max(2))
subject.send(4)
print("\n")
/*:
 Here we can see that the behaviour is different than when we were subscribing to `(1...).publisher`.

 If we dont request values but some are sent by the subscriber, they are not saved for the next time we request value, they are just dropped.

 Next we are gong to talk about ways to not loose thes values.
 */
//: [Next](@next)
