import Combine
import Foundation
//: [Previous](@previous)
/*:

 ## 11 ConnectablePublisher

 We just saw that `multicast` provides a `connect` function that is really convinient. It holds off every event until a call to connect is made.
 The good news is that it comes from the `ConnectablePublisher` protocol which means it can be implemented on other types and already is in some built-in publishers.

 Its possible to make any publisher that never fails (`Failure == Never`) into a connectablePublisher by using `makeConnectable`
 */
let connectableJust = Just(5)
    .makeConnectable()
connectableJust.sinkPrint()
print("connecting")
connectableJust.connect()
print("\n")

/*:
 `ConnectablePublisher` also enables to use `autoConnect` which remove the connectable aspect of the publisher, this is usefull if you don't need it and want to keep the code declarative.

 We just saw that it could be used on a multicast but this is also the case for a `TimerPublisher`
 */
let start = Date()
var cancellables: [AnyCancellable] = []
Timer.publish(every: 1, on: .current, in: RunLoop.Mode.common)
    .autoconnect()
    .map { (value: Date) -> Date in
        guard value > start.advanced(by: 3) else { return value }
        cancellables.forEach { $0.cancel() }
        return value
    }
    .sinkPrint()
    .store(in: &cancellables)

/*:
>`ConnectablePublisher` being a protocol means we could conforms to it when we create our custom publishers. But that is something for later, we still have so much to learn before creating publishers of our own.

 This protocol definitely give us control on the start of our publisher but there is many other way to interact with the timing of our events.
 */
//: [Next](@next)
