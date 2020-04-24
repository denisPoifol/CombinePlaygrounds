import Combine
/*: [Previous](@previous)

 # Using Combine

 ## 1 First glance
 Let's try for now to play with built-in `Subscriber`s. Luckily there is a `Subscribers` enum that enables us to easily find built-in `Subscriber`s and the same goes for `Publishers` and `Publisher`s.
 Within our subscribers list there are only two :
 1. `Assign` which takes an object and a keypath and assign each read value to the property referenced by the keypath for the given object.
 2. `Sink` which takes two closures to handle receiving `Values` and `Completions`

 Going through the Publishers it seems the easiest to start with is `Just` which turns a value into a stream of data.

*/
let subscriber = Subscribers.Sink<Int, Never>(
    receiveCompletion: { completion in
        print("received a completion :", completion)
    },
    receiveValue: { value in
        print("received a value :", value)
    }
)
Just(1).receive(subscriber: subscriber)
print("\n")
/*:
 It turns out this looks like a lot of boiler plate, but fortunately `Publisher` being a protocol it has been extended to make things easier to write and read.
 */
Just(1)
    .sink(receiveCompletion: { completion in
        print("received a completion :", completion)
    }, receiveValue: { value in
        print("received a value :", value)
    })
print("\n")
/*:
 We are going to need to print information quite a lot during our journey through **Combine** so I am going to use the following function to print the events on a publisher and return a `Sink`.
 We will talk about print and some other functions at the end of this section.
 */
extension Publisher {
    func sinkPrint() -> AnyCancellable {
        print()
            .sink(receiveCompletion: { _ in }) { _ in }
    }
}
/*:
 Looking a bit closer at the code, this is actually not the same thing as before, sink return an `AnyCancellable` 🤔.
 But we are getting side tracked once again, we will worry about that later. (we will learn later on that this needs to be stored)

 Let's look into `Just` to understand how the simplest publisher we could find works.
 */

let justPublisher = Just(1)
justPublisher.sinkPrint()
justPublisher.sinkPrint()
print("\n")
//: So it seems we can bind multiple subscribers to the same publisher
justPublisher.sink(
    receiveCompletion: {
        print("received a completion :", $0)
        justPublisher.sinkPrint()
    }
) { print("received a value :", $0) }
print("\n")
/*:
 Even though my first `sink` received a completion I did receive a value on the second `sink` this means a publisher is not a data stream.
 For each new subscriber our publisher is creating a new stream, but since `Publisher` is a protocol, what is true here is not necessarily true everywhere.

 `Just` is good to take a first look at *Combine* but it is a bit limited, let see if we can do the same but with more than 1 value before our stream completes.

 [Next](@next)
 */
