import Combine
/*: [Previous](@previous)

 We have gone through `Just` and publisher initialization using a `Sequence` which is good to begin with but let's look at something a bit different and introduce a new concept.

 ## 5 Subject

 `Subject` is yet another protocol provided by **Combine**.

 - Callout(Apple documentation):
 A subject is a publisher that you can use to ”inject” values into a stream, by calling its send(_:) method. This can be useful for adapting existing imperative code to the Combine model.

 Great, what are the built-in subjects in **Combine** ?

 ### 5.1 PassThroughSubject
 `PassThroughSubject` is the simplest subject you can imagine, it only publishes values you send through it :
 */
var anyCancellables: [AnyCancellable] = []
let passThroughSubject = PassthroughSubject<Int, Error>()
passThroughSubject.send(1)
passThroughSubject.send(2)
passThroughSubject
    .sinkPrint()
    .store(in: &anyCancellables)
passThroughSubject.send(3)
passThroughSubject.send(4)
anyCancellables.forEach { $0.cancel() }
passThroughSubject.send(5)
passThroughSubject.send(completion: .finished)
print("\n")
/*:
 We can see that contrary to `Just` and `Publishers.Sequence` our subject does not repeat passed elements to a new subscriber. And now cancelling a subscriber makes sense since we are able with this subscriber to send values when we want and not only directly after a subscriber is attached to the publisher.

 With this subscriber we only receive the values sent while our subscriber is attached. Now we start to see the processing of values over time. What's cool about `Subject` is that it gives a smooth transition to programming with streams, since it publishes events imperatively.


 ### 5.2 CurrentValueSubject
 `CurrentValueSubject` does everything a passthrough subject does but it also keeps track of the last value sent. That way when we subscribe to this subject we receive the last value published by it.
 */
let currentValueSubject = CurrentValueSubject<Int, Never>(1)
currentValueSubject.send(1)
currentValueSubject.send(2)
currentValueSubject
    .sinkPrint()
    .store(in: &anyCancellables)
currentValueSubject.send(3)
currentValueSubject.send(4)
anyCancellables.forEach { $0.cancel() }
currentValueSubject.send(5)
currentValueSubject.send(completion: .finished)
currentValueSubject
    .sinkPrint()
    .store(in: &anyCancellables)
print("\n")
/*:
 We are slowly getting to know more and more about publishers and how they work, let's keep going and learn about one you probably already heard about `@published`.
 
 [Next](@next)
 */
