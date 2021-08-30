
import Combine
import Foundation
//: [Previous](@previous)
/*:
 We learned that sometime values can be dropped between a publisher and his subscribber, let's look into ways to avoid losing these values using `buffer`.

 ## 4 Buffers

 **Combine** provides us with yet another usefull operator, `buffer` that enables us to buffer value events. The `buffer` operator comes with three parameters :
 - size
 - `PrefecthStrategy` which defines how back pressure is applied by the buffer
 - `BufferingStrategy` which defines the behaviour of the buffer when full
 */
var subject = PassthroughSubject<Int, MyError>()
var subjectSubscriber = RegulatedFlowSubscriber<Int, MyError>()
subject
    .buffer(size: 1, prefetch: .keepFull, whenFull: .dropOldest)
    .print(to: Logger.shared)
    .subscribe(subjectSubscriber)
subject.send(0)
subjectSubscriber.request(.max(1))
subject.send(1)
subject.send(2)
subject.send(3)
subjectSubscriber.request(.max(2))
subject.send(4)
Logger.shared.returnLogs()
/*:
 We can see here that the buffer enables us to avoid droping elements, until its capacity is reached.

 When the buffer is full, `BufferingStrategy` provides 3 different wyas to handle new values :
 - `dropNewest` ignore any new received values while the buffer is full
 - `dropOldest` free the oldest value event in order to store the new one
 - `customError` provides a closure to return an error matching your publsiher `Failure` type

 Let's look into the more interesting part, what are the different `PrefecthStrategy`. There are only 2, `byRequest` and
 `keepFull`.

 Let's start with the simplest strategy, `.byRequest` :
 */
subject = PassthroughSubject<Int, MyError>()
subjectSubscriber = RegulatedFlowSubscriber<Int, MyError>()
let byRequestBuffer = subject
    .print("Buffer by request", to: Logger.shared) // Event treated by the buffer will be prefixed "Buffer by request"
    .buffer(size: 2, prefetch: .byRequest, whenFull: .dropOldest)
byRequestBuffer.print(to: Logger.shared).subscribe(subjectSubscriber)
Logger.shared.returnLogs()
/*:
 We do not need anything else than this to know how our buffer is going to work.
 Indeed we saw earlier that the requested number of value is purely cumulative and once you have asked for n you cannot ask for less.
 Here the buffer request an unlimited number of values, which means it will not apply any back pressure at all.
 It will receive all the event and keep the last or oldest n elements where n is the size of our buffer.

 Now let's look at `.keepFull`.
 */
subject = PassthroughSubject<Int, MyError>()
subjectSubscriber = RegulatedFlowSubscriber<Int, MyError>()
let keepFullBuffer = subject
    .print("Buffer keep full", to: Logger.shared) // Event treated by the buffer will be prefixed "Buffer keep full"
    .buffer(size: 2, prefetch: .keepFull, whenFull: .dropOldest)
keepFullBuffer.print(to: Logger.shared).subscribe(subjectSubscriber)
subject.send(1)
subject.send(2)
subject.send(3)
subject.send(4)
subject.send(5)
subjectSubscriber.request(.max(2))
subject.send(6)
subject.send(7)
subject.send(8)
subject.send(9)
Logger.shared.returnLogs()
/*:
 Let's make a diagram to see what is going on :

 ![Keep full buffer diagram](KeepFullBufferDiagram.png)

 As expected `.keepFull` request as many values needed to fill the buffer.
 Then the subscriber request 1 value, that request is forwarded by the buffer, which make sense : if you take one value from the buffer to give it to the subscriber we need a new one to keep the buffer full.

 Then when the publisher emmits it's first value, the buffer forwards this value to the subscriber since it asked for one value.
 But something weird happens (a bug in my humble opinion) `receive(_:Input) -> Subscribers.Demand` implementation of the buffer returns a demand for 1 value.
 This means that our buffer asked for 3 values while it only can store 2 of them. 🐛
 So the next 3 values are received by the buffer and since the `BufferingStrategy` is `.dropOldest` we end up with a buffer containing **3** and **4**
 The five value, has never been requested by our buffer therefore it is dropped by the subject.

 So far this make **almost** sense, the buffer asked for one more value than it should have but other than that it's what we would expect.
 But here comes the part I cannot even begin to explain and makes me think the `keepFull` implementation of the buffer operator is completely broken. ☠️
 Our subscriber requests for 2 values, since these values are buffered the buffer returns these values right away.
 But now the buffer is empty so it must be filled again, so in order to fill it the buffer operator request 4 values.
 Why 4 ? I really do not know, I have tried to change the size of the buffer and the request sent by the subscriber to make sense of it but nothing seemed logical to me.

 If you do find a logic in there please let me know, but as far as I know about combine you should not be using buffer `.keepFull`. 😕

 Maybe we should be looking at an other option which was `collect`
 */
//: [Next](@next)
