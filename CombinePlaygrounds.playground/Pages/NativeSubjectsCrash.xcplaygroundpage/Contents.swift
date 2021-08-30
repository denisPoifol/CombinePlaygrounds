import Combine
import Foundation
//: [Previous](@previous)
/*:
 ## 1. Native subject crash

 We are discussing here the crash that occured when we were lloking at `Subscribers.Demand`
 We were using a custom subscriber that request no element to its publsiher upon subscription or receiving value, and only does when calling the `request(_:Subscribers.Demand)` method.
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

let subject = PassthroughSubject<Int, MyError>()
let subjectSubscriber1 = RegulatedFlowSubscriber1<Int, MyError>()
subject
    .print()
//    .subscribe(subjectSubscriber) // Comment me once you tried
print("\n")
/*:
 The last line of our stack trace is :

 ```Combine`Combine.PassthroughSubject.(Conduit in _A517F1CF3C35FD924691D71B0A4E0FAF).request(Combine.Subscribers.Demand) -> ()```
 And the exception raised is the following : `EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)`
 ```
 assertionFailure()
 ```
 Raise the same exception, so let's consider this is what is happenning here. Which mean we ran into a case scenario that should never happen when using a `PassThroughSubject`.

 What is peciliar with our `Subscriber` is that it requests no value upon subscription. So let's try and see if this is what's causing our problem.
 */
class RegulatedFlowSubscriber2<Input, Failure: Error>: Subscriber, Cancellable {
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

let subjectSubscriber2 = RegulatedFlowSubscriber2<Int, MyError>()
subject
    .print()
    .subscribe(subjectSubscriber2)
subject.send(1)
subject.send(2)
subject.send(3)
subjectSubscriber2.request(.max(1))
print("\n")
/*:
 This time no exception is raised. This is a bit strange, but subjects (at least `PassthroughSubject` and `CurrentValueSubject`) raise an exception because thezy seem to expect a request for 1 or more value.

 Let's try something else, this time we are going to delay our request upon subscirption.
 */
class RegulatedFlowSubscriber3<Input, Failure: Error>: Subscriber, Cancellable {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            subscription.request(.none)
        }
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

let delayed = RegulatedFlowSubscriber3<Int, MyError>()
subject
    .print()
    .subscribe(delayed)
/*:
 This is does not raise an exception either, so it got to be a bug in the implementation of both subject classes.
 */
//: [Next](@next)
