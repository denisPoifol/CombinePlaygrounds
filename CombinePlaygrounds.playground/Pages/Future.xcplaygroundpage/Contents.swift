import Combine
import Foundation
/*: [Previous](@previous)

 ## 8 Future

 `Future` is similar to `Just` or `Fail` in the way it only send one value and then finish, or it just fail.
 */
let future = Future<Int, MyError> { promise in
    promise(.success(3))
}
future.sinkPrint()
future.sinkPrint()
print("\n")
/*:
 Remember [when we were trying to chain tasks](ProcessingValuesOverTime), well this is it!

 What seemed complicated back then, is actually a "simple" example of one of the uses that **Combine** provides 🤯. Let's see!
 */
func someOperation() {
    sleep(1)
    print("SomeOperation")
}
func someOtherOperation() {
    print("SomeOtherOperation")
}
Future<Void, Never> {
    someOperation()
    $0(.success(()))
}.map { _ in
    someOtherOperation()
}.sinkPrint()
print("\n")
/*:
 There is a couple of things here that still feels off : for starters `$0(.success(()))` maybe it's just me but I cringe a little bit at the sight of that `(())` 😬
 So I am going to create an extension for that.
 */
extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}
/*:
 The second thing that is bothering me, is that we are mapping over a container of void `.map { _ in` our ignored parameter here is `()` which seems a little disgraceful to me. One of two things happened :
 - I just did not manage to found the operator that just ignores the value sent
 - Combine developpers thought that it was not worth the trouble

 A possibility would be to create our custom operator that does not take into account the value it receives, that we could call `then`.

 One common problem when creating such a flow of operation is that we often want to perform a couple of operations and once they succeed perform another one on top of it, and that is when the framework begins to feel useful because you don't have to manage dispatch group, mutex or semaphore. You can just find the precious function that does it all for you, sit back and relax. 😎 

 Combine do have that magic function that is going to solve our problems, remember when we said publishers behave like sequences and benefit from many common function, well it's time to go and find the zip operator.
 */
func aThirdOperation() {
    print("aThirdOperation")
}

Publishers.Zip(
    Future<Void, Never> {
        someOperation()
        $0(.success)
    },
    Future<Void, Never> {
        someOtherOperation()
        $0(.success)
    }
).map { _ in
    aThirdOperation()
}.sinkPrint()
print("\n")
/*:
 As we can see our third operation is only executed once both operation finish first.

 Here we decided to use `Zip.init` but we can use chaining like for other operators
 */
Future<Void, Never> {
    someOperation()
    $0(.success)
}.zip(Future<Void, Never> {
    someOtherOperation()
    $0(.success)
    }
).map { _ in
    aThirdOperation()
}.sinkPrint()
print("\n")
/*:
 But I have to say I dont think this reads well especially since our `Future` wrapping `someOtherOperation` is not a oneliner.
 Let's see if we can tweak this into something that feels a bit more natural.
 */

let someOtherOperationFuture = Future<Void, Never> {
    someOtherOperation()
    $0(.success)
}
Future<Void, Never> {
    someOperation()
    $0(.success)
}
.zip(someOtherOperationFuture)
.map { _ in
    aThirdOperation()
}.sinkPrint()
print("\n")
//: This reads a bit better but I am convinced we can do even better!
extension Future where Failure == Never {
    convenience init(_ guarantee: @escaping () -> Output) {
        self.init { promise in
            promise(.success(guarantee()))
        }
    }
}

extension Future where Output == Void, Failure == Never {
    convenience init(_ guarantee: @escaping () -> Output) {
        self.init { promise in
            guarantee()
            promise(.success)
        }
    }
}
Future(someOperation)
    .zip(Future(someOtherOperation))
    .map { _ in
        aThirdOperation()
    }.sinkPrint()
print("\n")
/*:
 This looks great 🤩, at least to me. And I do feel that these two extensions should be part of **Combine**.

 We can even push this further by creating our `then` operator.
 */
extension Publisher {
    func then<T>(_ guarantee: @escaping () -> T) -> Publishers.Map<Self, T> {
        map { _ in
            guarantee()
        }
    }
}

Future(someOperation)
    .zip(Future(someOtherOperation))
    .then(aThirdOperation)
    .sinkPrint()
print("\n")
/*:
 This is great but there is a problem with our extension : we might be causing performance issues when applying `then` to a `Publishers.Sequence` because we will be returning a `Publisher.Map<Self, T>` where we should probably be returning `Self`
 */
extension Publishers.Sequence {
    func then<T>(_ guarantee: @escaping () -> T) -> Publishers.Sequence<[T], Failure> {
        map { _ in
            guarantee()
        }
    }
}
/*:
 It's worth noticing that in contrary to other Promises frameworks such as PromiseKit, our final publisher here is not a `Future`. In our final example we end up with a `Combine.Publishers.Map<Combine.Publishers.Zip<Combine.Future<Void, Never>, Combine.Future<Void, Never>>, Void>` which if it were exposed as part of an API would probably be erased to an AnyPublisher. This unfortunatelly means your final type does not reflect that you are manipulating a `Publisher` that behaves like a `Future`.

 Indeed **most** operators will conserve the `Future` property because **most** operators change the Output of our publisher but do not add published events. Which means **most of the time**, when you start with a `Future` you end up with a `Publisher` that also publishes one value then finishes, or immediately fails, but definitely not always.

 Next we are going to talk about handling when and how your `Publisher` sends events, but first why you might need it and for that we are going to discuss side effects and multicast.
 */
//: [Next](@next)
