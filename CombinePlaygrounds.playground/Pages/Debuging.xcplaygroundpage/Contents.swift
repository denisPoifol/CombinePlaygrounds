import Combine
//: [Previous](@previous)
/*:
 ## 16 Debuging

 Let's start with the one we already kind of know.

 ### 16.1 Print

 We used it quite a lot to understand how most `Publisher` and operator work, it enables to print every publishing events.

 `print` has two parameter :
 - *prefix* the first one prefix any printed information with a string you passed
 - *output* is a `TextOutputStream` and as default print messages to the debuging console

### 16.2 Breakpoint

 `breakpoint` has three closure parameters :

 - *receiveSubscription :* A closure that executes when the publisher receives a subscription.
 - *receiveOutput :* A closure that executes when the publisher receives a value.
 - *receiveCompletion :* A closure that executes when the publisher receives a completion.

 For each closure if the return value is true then it will raise a `SIGTRAP` exception otherwise it will just continue executing

 this should be tested in a project since playground is not cut out for this usage. But we can still see it stops the executed code.
 */

let breakPoint = (1...5).publisher
    .breakpoint(
//        receiveSubscription: { _ in true },
//        receiveOutput: { _ in true },
//        receiveCompletion: { _ in true }
// the previous closures have to be commented to execute any of the follwing code exemples
    )
    .sinkPrint()
print("\n")
/*:
 ### 16.2 breakpointOnError

 `breakpointOnError` simply raise a `SIGTRAP` when a `Failure` event is sent.
 */

let breakPointOnError = (1...5).publisher
    .breakpointOnError()
    .then { print("No error") }
    .tryMap { _ in throw MyError.fail }
//    .breakpointOnError()
// comment the previous operator to be able to run any of the following code axemples
    .sinkPrint()
print("\n")
/*:
 16.3 HandleEvents

 `handleEvents` provides you with the possiblity to run a closure that is passed as argument each time a publishing event occurs.
 *receiveSubscription :* A closure that executes when the publisher receives the subscription.
 *receiveOutput :* A closure that executes when the publisher receives a value.
 *receiveCompletion :* A closure that executes when the publisher receives a completion.
 *receiveCancel :* A closure that executes when the publisher receives a cancel event.
 *receiveRequest :* A closure that executes when the publisher receives a request.

 This is pretty much the only core operator on a publisher, I am pretty confident only with this one we can reconstruct all the others.
 */
let handleEvents = (1...5).publisher
    .handleEvents(
        receiveSubscription: { print($0) },
        receiveOutput: { print($0) },
        receiveCompletion: { print($0) },
        receiveCancel: { print("Cancel") },
        receiveRequest: { print($0) }
    )
    .sink { _ in }
handleEvents.cancel()

//: [Next](@next)
