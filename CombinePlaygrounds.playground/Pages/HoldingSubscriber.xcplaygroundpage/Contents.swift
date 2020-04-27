import Combine
import Foundation
//: [Previous](@previous)
/*:
 Before going any further let's take a look back at this `AnyCancellable` I told you to store.

 What if you did not want to cancel this subscriber at all?
 Well you should still keep a reference on it, let's see why.

 ## 17 Holding on to your subscribers

 Let's talk a bit about memory management.
 */
Timer.publish(every: 1, on: .current, in: .default)
    .autoconnect()
    .sinkPrint()
print("\n")
/*:
 🤔 "receive cancel", this is really weird I especially did not want to send a cancel.

 Well it turns out that when a subscriber is released, it calls its `cancel` method, which makes sense, you would not want to keep a stream of data open if no one is listening to it.

 - Callout(Your brain):
 But how come my subscriber gets released.

 Well it actually makes sense, in the above code we are not retaining anything.
 What could we retain then? The only thing we can retain is this `AnyCancellable` value.
 */
let cancellable = Timer.publish(every: 1, on: .current, in: .default)
    .autoconnect()
    .sinkPrint()
cancellable.cancel()
print("\n")
/*:
 - Callout(Your brain):
 How come most of our previous tests, that did not keep a reference on the `AnyCancellable` value, did not fail systematically before?

 This is a legitimate question and the answer is not the same every time.

 In some cases the publisher completes even before sink returns its value.
 This is true for publishers returning a stored result such as `Just`, `Fail`, `Publishers.Sequence`, `Record` and probably more.

 In some other cases, the fact that the subscriber is not deallocated right away because the garbage collector needs to be triggered, gives just enough time for our tests to complete. This can also be seen in the previous examples because the `print("\n")` is executed before the publisher notifies receiving `cancel` (this actually depends upon which line you decide to run the code).
 */
let subject = PassthroughSubject<Int, MyError>()
subject.sinkPrint()
subject.send(1)

autoreleasepool {
    _ = subject.sinkPrint()
}
subject.send(1)
print("\n")
/*:
 The auto releasepool here clearly shows us that the subscriber needs to be stored if we want to be sure to receive any events.

 > `autoreleasepool` enables to run a block of code and makes sure that referenced instances are released upon completion if they need to be, one way to understand it is that we are forcing a garbage collection cycle on our returned value.

 */
//: [Next](@next)
