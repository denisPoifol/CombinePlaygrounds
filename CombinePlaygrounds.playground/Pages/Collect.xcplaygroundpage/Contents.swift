import Combine
import Foundation
//: [Previous](@previous)
/*:
 ## 5 Collect

 The `collect` operator enables to group values together so that instead of handling n value events, instead we will be handling one value event where the value is an array of n elements.

 `collect` comes in many flavors, let's go through them all.

 The first one is calling collect with no parameters.
 */
var subject = PassthroughSubject<Int, MyError>()
let collectNoParameterFinished = subject
    .collect()
    .sinkPrint()
subject.send(1)
subject.send(2)
subject.send(3)
subject.send(4)
subject.send(completion: .finished)
Logger.shared.returnLogs()
/*:
 What it does is that it store all received values until receiving a completion, and once `collect` receives a completion it sends an array containing all its received value.
 */
subject = PassthroughSubject<Int, MyError>()
let collectNoParameterFailure = subject
    .collect()
    .sinkPrint()
subject.send(1)
subject.send(2)
subject.send(3)
subject.send(4)
subject.send(completion: .failure(.fail))
Logger.shared.returnLogs()
/*:
 It's important to notice that no value is emitted if `collect` does not receive a `finished` completion or receives an error.

 An other way you can use `collect` is by passing a count parameter, this time the `collect` will send an array each time the number of received value is equal to the count parameter.

 But before let's create an extension on `Subject` to make our code easier to read.
 */
extension Subject where Output == Int {
    func send(_ range: ClosedRange<Int>) {
        for value in range {
            send(value)
        }
    }
}
/*:
 Now let's see `collect` with a count parameter in action
 */
subject = PassthroughSubject<Int, MyError>()
let collectCountParameter = subject
    .collect(5)
    .sinkPrint()
subject.send(1...3)
subject.send(4...6)
subject.send(completion: .finished)
Logger.shared.returnLogs()
/*:
 So now we receive an array of n element where n is our count parameter.
 And the remaining values are sent in an array when the stream finishes.
 Here again if we receive an error the last values are not sent.

 But there is two more ways to creat a `collect` operator; using a `TimeGroupingStrategy` :
 - `byTime` periocally it will send an array of the acumulated values
 - `byTimeOrCount` which is essentialy the same thing except that it will also send a value when reaching a given number of accumulated values.

 Both these `TimeGroupingStrategy` require a `Scheduler` and we can also pass options to this `Scheduler`.
 */
subject = PassthroughSubject<Int, MyError>()
let collectByTime = subject
    .collect(.byTime(DispatchQueue.main, .seconds(2)))
    .sinkPrint()
subject.send(1...5)
subject.send(6...12)
subject.send(completion: .failure(.fail))
Logger.shared.returnLogs()
/*:
Once again if the publisher emits a failure before pending values are sent they are lost.
 */
subject = PassthroughSubject<Int, MyError>()
let collectByTimeOrCount = subject
    .collect(.byTimeOrCount(RunLoop.current, .seconds(2), 3))
    .measureInterval(using: RunLoop.current)
    .sinkPrint()
subject.send(1...4)
subject.send(5...8)
subject.send(completion: .failure(.fail))
Logger.shared.returnLogs()
/*:
 If you play around with it you might notice that the time and count are not linked. Meanning if your publisher sends a value because it reached the max count, the timer to produce the next value does not reset.

 To sum up, `collect` is a powerful operator but you might end up loosing values if your stream ends in a `Failure` so watch out for that.
 */
//: [Next](@next)
