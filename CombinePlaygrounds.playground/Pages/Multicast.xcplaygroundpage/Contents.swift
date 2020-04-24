import Combine
//: [Previous](@previous)
/*:
 Let's create a more complicated workflow to see how sometimes `Deferred` is not going to be enough. For this we are going to look at multicast.

 ## 10 Multicast

 Let's say we have some heavy tasks we want to complete, we are going to represent it by to different functions mutating a value.
 */
var operationAcheivedCount = 0
func reset() {
    operationAcheivedCount = 0
}
func begin() {
    print("begin")
    reset()
}
func performFirstOperation() {
    print("first")
    operationAcheivedCount += 1
}
func performSecondOperation() {
    print("second")
    operationAcheivedCount += 1
}

func end() {
    print("end", operationAcheivedCount)
    reset()
}
/*:
 What we want to do is reset then perform our two operations and once they are both completed print the end of our workflow.

 ![workflow diagram](Workflow.png)
 Ok so let's see if `Deferred` works here.
 */
let deferredBegin = Deferred { Future(begin) }
Publishers.Zip(
    deferredBegin.then(performFirstOperation),
    deferredBegin.then(performSecondOperation)
)
    .then(end)
    .sinkPrint()
print("\n")
/*:
 This prints begin twice which means something is wrong and we are actualy doing this :
 
 ![wrong workflow diagram](WrongWorkflow.png)

 In this use case we want to be using `share`
 */
// now this means when an event is sent from printBegin it will be sent by multicast.
let  multicast = deferredBegin
    .multicast(subject: PassthroughSubject())
// this part does not change.
Publishers.Zip(
    multicast.then(performFirstOperation),
    multicast.then(performSecondOperation)
)
    .then(end)
    .sinkPrint()
// using a multicast no event is processed until connect is called.
multicast.connect()
print("\n")
/*:
 Calling connect is a way to make sure everything that should be listening to the multicast is already set up.
 If for some reason you do not want to wait for everything to be connected you can call `autoconnect` which means a call to `connect` is made as soon as the multicast receives a subscriber.

 Which is not our case here :
 */

let  autoConnectMulticast = deferredBegin
    .multicast(subject: PassthroughSubject())
    .autoconnect()
Publishers.Zip(
    autoConnectMulticast.then(performFirstOperation),
    autoConnectMulticast.then(performSecondOperation)
)
    .then(end)
    .sinkPrint()
print("\n")
/*:
 > `Zip` waits for one value from each publisher to publish a value of its own, but it immediately publish a completion when receiving one from any of its publishers.

 Now this is not over, we still have to understand how this subject is working.
 Let's say give it a CurrentValueSubject instead how will it impact our publisher?
 */
reset()
let  currentValueMulticast = deferredBegin
    .multicast(subject: CurrentValueSubject(()))
Publishers.Zip(
    currentValueMulticast.then(performFirstOperation),
    currentValueMulticast.then(performSecondOperation)
)
    .then(end)
    .sinkPrint()
currentValueMulticast.connect()
print("\n")
/*:
 Using a CurrentValueSubject means there is a buffer for the last event and it must have an initial value, here we give it an instance of `Void`.
 This means when connecting using `then` we will immediatly receive a `Void` event which will trigger the first and second operation and once both completed the end.
 But this does not include the event sent when `deferredBegin` is executed, which trigger a new event from the multicast.

 Now there is also a way to create a multicast where all subscribers receive a different subject, but we will ignore this one 🙈.
 We might get back to it once we understand the inside and out of the `Subscriber`protocol.

 But let's look at this `connect` functionality, this seems like something that could be usefull not only to multicast.
 */
//: [Next](@next)
