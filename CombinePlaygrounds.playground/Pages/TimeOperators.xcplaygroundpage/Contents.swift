import Combine
import Foundation
//: [Previous](@previous)
/*:
 ## 13 Time operators

 All the operators here enable to specify on which Scheduler the publisher is going to send events.

 The following operators are well known and well discribed by the documentation, so I am not going to explain them. The goal here is to list them for you to know they are available in **Combine**.
 */
// how this publisher is created here is not relevant, so do not spend too much time scratching your head to figure out how it works. Its behaviour is describbed just a few lines below.
var counter = 1
let intPublisher = Deferred {
        Publishers.Merge3(
            Timer
                .publish(every: 0.5, on: .current, in: .common)
                .autoconnect(),
            Timer
                .publish(every: 0.7, on: .current, in: .common)
                .autoconnect(),
            Just(Date())
                .delay(for: .seconds(0.2), scheduler: RunLoop.current)
        )
            .map { (_: Date) -> Int in return counter }
            .map { (value: Int) -> Int in
                counter += 1
                return value
        }
    }
/*:
 Our `intPublisher` publishes values of a counter that is increased with each message. Simply said it publishes integers in inscreasing order.
 It publishes a first element at 0.2 secs and on two different frequencies :
 - 0.5 seconds
 - 0.7 seconds

 This enables us to test our operators that would not be very interesting if the publisher fired at a single constant rate.

 ### 13.1 mesureInterval
 */
let mesureInterval = intPublisher
    .measureInterval(using: RunLoop.current)
    .sinkPrint()
// Run until here to see mesureInterval
mesureInterval.cancel()
Logger.shared.returnLogs()
/*:
 ### 13.2 debounce
 */
let debounced = intPublisher
    .debounce(for: .seconds(0.2), scheduler: RunLoop.current)
    .sinkPrint()
// Run until here to see debounced
debounced.cancel()
Logger.shared.returnLogs()
/*:
 ### 13.3 throttle
 */
let throttled1 = intPublisher
    .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
    .sinkPrint()
// Run until here to see throttled1
throttled1.cancel()
Logger.shared.returnLogs()

let throttled2 = intPublisher
    .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
    .sinkPrint()
// Run until here to see throttled2
throttled2.cancel()
Logger.shared.returnLogs()
/*:
 ### 13.4 delay

 If needed delay can take parameters for the scheduler, the type of these paremeters is defined by `Scheduler.SchedulerOptions`
 > RunLoop.SchedulerOptions does not have an initializer and seems to be an empty struct so we cannot use it
 */
let dispatchQueueDelayed = intPublisher
    .delay(for: .seconds(0.5), tolerance: .nanoseconds(10), scheduler: DispatchQueue.global())
    .sinkPrint()
// Run until here to see dispatchQueueDelayed
dispatchQueueDelayed.cancel()
Logger.shared.returnLogs()

let runloopDelayed = intPublisher
    .delay(for: .seconds(0.5), tolerance: .nanoseconds(10), scheduler: RunLoop.current)
    .sinkPrint()
// Run until here to see runloopDelayed
runloopDelayed.cancel()
Logger.shared.returnLogs()
/*:
 ### 13.5 timeOut

 When using timeOut you can either simply send a completion if the publisher times out, or if you need to you can provide an error (provided it matches the type of your publisher Failure type) using a closure.
 */
let timeOut = intPublisher
    .timeout(.seconds(0.4), scheduler: RunLoop.current)
    .sinkPrint()
// Run until here to see timeOut
runloopDelayed.cancel()
Logger.shared.returnLogs()

let timeOutWithCustomError = intPublisher
    .mapError { (_: Never) -> MyError in MyError.fail }
    .timeout(.seconds(0.4), scheduler: RunLoop.current) { .fail }
    .sinkPrint()
// Run until here to see timeOut
runloopDelayed.cancel()
Logger.shared.returnLogs()
/*:
 You probably noticed that I had to create a pretty strange publisher for us to be able to test and play with our time operators. Actually not that strange since there is only one thing we did not review yet to known all of the feature used. `Merge3` is a publisher used to **Combine** multiple publishers, we will see how it works (and more) in the next chapter.
 */
//: [Next](@next)
