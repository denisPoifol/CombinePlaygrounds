import Combine
/*: [Previous](@previous)

 While going through **Combine** documentation you can see many many things, but let's keep it simple and play around with the *Convenience Publishers*.
 This will provide us more ways to interact with **Combine** without the need to understand all of its kinks and quirks.

 ## 7 ConveniencePublishers

 Among those conveninence publishers we can find `Just` but we are not going to go through it again.

 ### 7.1 Fail

 `Fail` is the same as `Just` except that it does not send a value but a termination Error.
 */
let fail = Fail(outputType: Int.self, failure: MyError.fail)
fail.sinkPrint()
fail.sinkPrint()
print("\n")
/*:
 Once again here the stream is repeated for each subscriber that cares to listen to it.

 ### 7.2 Empty

 `Empty` is the simplest and dullest publisher ever, it just does not publish any values or errors, but it can publish a completion if you want it to.
 */
let empty = Empty(completeImmediately: true, outputType: Int.self, failureType: Never.self)
empty.sinkPrint()
empty.sinkPrint()
print("\n")

/*:
 Once again here if we decide to send a completion then it will be sent to each of the subscribers.

 ### 7.3 Record

 Record enables you to create a Publisher that will publish a defined list of events, either by passing it a list of values and a completion. Or by defining the values using a  `Record<Output, Failure>.Recording`  struct in a closure.
 */
let record1 = Record(output: [1, 2], completion: .failure(MyError.fail))
let record2 = Record<Int, MyError> { recording in
    recording.receive(3)
    recording.receive(4)
    recording.receive(completion: recording.completion)
}
record2.sinkPrint()
record2.sinkPrint()
print("\n")
/*:
 Either way, like all the other publishers storing their events, it streams all these events to the subscriber once it subscribes.

 ### 7.4 Deferred

 `Deferred` enables (like implied by its name) to defer the creation of the publisher to when it receives a subscriber.
 */
let deffered = Deferred { Just(1) }
/*:
 >This could simply be achieved by using lazy var to defer the creation of our publisher, but once again we would lose the declarative usage.


Last of the convenience publishers is `Future` but this one is going to need its own chapter
*/
//: [Next](@next)
