import Combine
//: [Previous](@previous)
/*:
 ## 14 Combining publishers

 One thing about publishers, you can think of it as a graph where a node is a publisher and an arrow is an operator.

 Let's take the publisher we created when looking at `multicast` as example :
 */
let deferredBegin = Deferred { Future(begin) }
let  multicast = deferredBegin
    .multicast(subject: PassthroughSubject())

let finalPublisher = Publishers.Zip(
    multicast.then(performFirstOperation),
    multicast.then(performSecondOperation)
)
    .then(end)
/*:
 ![Multicast publisher graph representation](MulticastPublisherGraph.png)

 This enables us to vizualize a bit better and also make sense of the insanely long type.

 In this chapter we are mostly going to look at operators that, like `Zip`, would be represented by multiple arrows merging into one. Which means we are going to create one publisher from multiple publishers.

 We saw a usage of `Merge3` in the previous chapter so let's look into the merge family.

 ### 14.1 Merge

 Actualy the whole merge family behave the same so let's look at the most obvious one `Merge`.
 Let's represent two publishers as streams of data.
 */
var publisherA = PassthroughSubject<Int, MyError>()
var publisherB = PassthroughSubject<Int, MyError>()
let merge1 = Publishers.Merge(
    publisherA,
    publisherB
).sinkPrint()
publisherA.send(1)
publisherB.send(1)
publisherA.send(2)
publisherA.send(3)
publisherB.send(2)
publisherA.send(completion: .finished)
publisherB.send(3)
publisherB.send(completion: .finished)
print("\n")
/*:
 ![Merge diagram ending with a completion](MergeDiagramComplete.png)

 Of course once one of the publisher finishes we still want to receive informations from the one that is still running.
 But once the second one finishes now there is nothing more to wait for so the `Merge` sends a completion
 */
publisherA = PassthroughSubject<Int, MyError>()
publisherB = PassthroughSubject<Int, MyError>()
let merge2 = Publishers.Merge(
    publisherA,
    publisherB
).sinkPrint()
publisherA.send(1)
publisherB.send(1)
publisherA.send(2)
publisherA.send(3)
publisherB.send(2)
publisherA.send(completion: .failure(.fail))
publisherB.send(3)
print("\n")
/*:
 ![Merge diagram ending with a failure](MergeDiagramError.png)

 - Callout(Your brain):
 You literally just told me that one of the publisher sending a completion do not stop the mergePublisher.

 Well it is true for completions but we would not want to miss out on errors. So when there is an error returned by one of the publisher our mergePublisher stops and sends this error too.

 Now that you have a clear idea of what `Merge` does, we have to worry about type safety. The result of merge is a `Publisher` that publishes the same values and errors as the merged publishers. Which means two publishers have to match their `Output` and `Failure` for a merge to be possible.

 I guess there is no need to go in details about how Merge3 and Merge4 work. But the concept remains the same. Conceptually you could say `Merge3(a, b, c) == Merge(a, Merge(b, c))` and `Merge4(a, b, c, d) == Merge(Merge(a, b), Merge(c, d))`. The implementation details might be a bit different for some optimizations.

 Combine provides with Merge types from 2 to 10, meaning if you need to merge 11+ publishers there is two solutions :
 - either call merge with 10 publishers and merge the result recursively until you have merged all of your publishers.
 - use MergeMany

 `MergeMany` enables to merge as many publishers as you wish on one condition that is a bit more restrictive, the condition is that all publishers have to have the exact same Type. This seems like a big constraint but `eraseToAnyPublisher()` is here for you. 😎

 - Callout(Your brain):
 How come you can merge as many as you want if they are the same type, but if the types are different we can go as far as ten easily but more has to be done by hand?

 Well this restriction actually comes from Swift itself. When we look at the types we can see `Merge` has two type parameters, `Merge3` has 3 ect...
 Which means the implementation relies on something like this.
 ```
 struct Merge<A, B> {
    let publisherA: A
    let publisherB: B
 }
 ```
 While `MergeMany` benefit from the fact that the publishers share the same type so it looks probably like this.
 ```
 struct MergeMany<A> {
    let publishers: [A]
 }
 ```

 - Callout(Your brain):
 🤔 How about using `eraseToAnyPublisher()` like you just said.

 Unfortunately if we want to create a function that takes as many publishers as we want as long as they share the same `Output` and `Failure` we are stuck again because it would require variadic generics.

 This means once Swift supports variadic generics we will probably have a single `Merge` type, to handle merging any number of publishers. But until then we are stuck with `Merge`, `Merge3`ect...

 We have gone through `Merge` let's look at `Zip` because seeing it with a diagram is much nicer 🤩

 ### 14.2 Zip

 First a quick reminder of the basic idea, Zip waits for both publishers to send a value in order to send a tuple from those both values.
 */
publisherA = PassthroughSubject<Int, MyError>()
publisherB = PassthroughSubject<Int, MyError>()
let zip1 = Publishers.Zip(
    publisherA,
    publisherB
).sinkPrint()
publisherA.send(1)
publisherB.send(1)
publisherA.send(2)
publisherB.send(2)
publisherA.send(completion: .finished)
publisherB.send(3)
print("\n")
/*:
 ![Zip diagram complete](ZipDiagramComplete.png)

 What is interesting in this example is that we can see that `Zip` handles completion from its publishers in a smart way : if the publisher that completes is the one that is "late" then our `Zip` completes because there is no way we can publish any more values.
 */
publisherA = PassthroughSubject<Int, MyError>()
publisherB = PassthroughSubject<Int, MyError>()
let zip2 = Publishers.Zip(
    publisherA,
    publisherB
).sinkPrint()
publisherA.send(1)
publisherB.send(1)
publisherA.send(2)
publisherB.send(2)
publisherB.send(2)
publisherB.send(completion: .finished)
publisherA.send(completion: .failure(.fail))
print("\n")
/*:
 ![Zip diagram complete](ZipDiagramError.png)

 The current example confirms what we were thinking : if the publisher that is ahead finishes `Zip` does not finish until one of the next happens :
 - the late one catches up
 - the late one also completes

 And just like `Merge`, `Zip` sends an error if either one of its publisher sends one.

 There is also `Zip3` and `Zip4`. The rules remain the same. `ZipX` waits for all of its publishers to publish at least one value before creating a tuple of it.
 If a publisher has finished and is the latest one, then `ZipX` finishes too. If a publisher sends an error then `ZipX` sends an error.

 > Since we are creating tuples here there is no need for the publishers to publish the same `Output` but we are forwarding the errors, which means the `Failure` type has to be the same.

 ### 14.3 CombineLatest

 Combine latest is similar to `Zip` in the way that it creates tuples from its publishers. But this time the idea is that every time a publisher sends a value `CombineLatest` is going to send one too.
*/
publisherA = PassthroughSubject<Int, MyError>()
publisherB = PassthroughSubject<Int, MyError>()
let combineLatest = Publishers.CombineLatest(
    publisherA,
    publisherB
).sinkPrint()
publisherA.send(0)
publisherA.send(1)
publisherB.send(1)
publisherA.send(2)
publisherB.send(2)
publisherB.send(3)
publisherB.send(completion: .finished)
publisherA.send(3)
publisherA.send(completion: .failure(.fail))
print("\n")
/*:
 ![Combine latest diagram](CombineLatestDiagram.png)

 `CombineLatest` first needs to wait for all publishers to publish at least one value in order to be able to create a tuple (this is very similar to `Zip`).
 But once all publishers have published a value it will send an event every time a publisher sends a new one to update the latest combination of value received

 The completion of one of the publisher does not complete `CombineLatest` since the other one can still update. But once both complete `CombineLatest` also completes of course. Like always if an error occurs it is forwarded by `CombineLatest`.

 And like `Zip` we can find multiple flavours of `CombineLatest` combining 2, 3 or 4 publishers together.

 The same constraints apply, we don't care that the `Output` types do not match since we are building a tuple but the `Failure` type have to be the same

 ### 14.4 SwitchLatest

 Ok this is the weirdest one, it only applies to a `Publisher` that publishes a `Publisher` value.

 So lets create a `Subject` that does that.
*/
var publisherOfPublisher = PassthroughSubject<AnyPublisher<Int, MyError>, MyError>()
let switchToLatest1 = publisherOfPublisher
    .switchToLatest()
    .sinkPrint()
publisherA = PassthroughSubject<Int, MyError>()
publisherB = PassthroughSubject<Int, MyError>()

publisherA.send(1)
publisherOfPublisher.send(publisherA.eraseToAnyPublisher())
publisherA.send(2)
publisherB.send(1)
publisherOfPublisher.send(publisherB.eraseToAnyPublisher())
publisherA.send(3)
publisherB.send(2)
publisherB.send(completion: .finished)
publisherOfPublisher.send(publisherA.eraseToAnyPublisher())
publisherA.send(4)
publisherA.send(completion: .failure(.fail))
print("\n")
/*:
 ![Switch to latest when current publisher sends an error diagram](SwitchToLatestDiagramCurrentPublisherError.png)

 From the result we can see that `publisherOfPublisher` events point us in the direction of what publisher we should look at. Which makes sense when you think about it, after all this operator is called switch to latest.

 We can also see that the current publisher is not responsible for a completion event, this also makes sense because we can look at B and upon completion decide we should now look at A.

 Once again an error message is not to be ignored so if our current publisher sends an error it is forwarded by our operator.
 */
publisherOfPublisher = PassthroughSubject<AnyPublisher<Int, MyError>, MyError>()
let switchToLatest2 = publisherOfPublisher
    .switchToLatest()
    .sinkPrint()
publisherA = PassthroughSubject<Int, MyError>()
publisherB = PassthroughSubject<Int, MyError>()

publisherA.send(1)
publisherOfPublisher.send(publisherA.eraseToAnyPublisher())
publisherA.send(2)
publisherB.send(1)
publisherOfPublisher.send(publisherB.eraseToAnyPublisher())
publisherA.send(3)
publisherB.send(2)
publisherB.send(completion: .finished)
publisherA.send(completion: .failure(.fail))
publisherOfPublisher.send(publisherA.eraseToAnyPublisher())
print("\n")

/*:
 ![Switch to latest when current publisher already sent an error diagram](SwitchToLatestDiagramCurrentPublisherHasPassedError.png)

 We can even see here that if the `publisherOfPublisher` sends the value of a publisher that previously sent an error `SwitchToLatest` will stop with that error.
*/
publisherOfPublisher = PassthroughSubject<AnyPublisher<Int, MyError>, MyError>()
let switchToLatest3 = publisherOfPublisher
    .switchToLatest()
    .sinkPrint()
publisherA = PassthroughSubject<Int, MyError>()
publisherB = PassthroughSubject<Int, MyError>()

publisherA.send(1)
publisherOfPublisher.send(publisherA.eraseToAnyPublisher())
publisherA.send(2)
publisherB.send(1)
publisherOfPublisher.send(publisherB.eraseToAnyPublisher())
publisherA.send(3)
publisherB.send(2)
publisherB.send(completion: .finished)
publisherOfPublisher.send(completion: .failure(.fail))
print("\n")
/*:
 ![](SwitchToLatestDiagramPublisherOfPublisherError.png)

 Of couse `publisherOfPubliser` can also complete the stream by sending an error or a finished event.

 🤔 If `publisherOfPublisher` and `publisherA` can both send an error that will be repeated forwarded by `SwitchToLatest`, that means their `Failure` type has to be the same. And since `publisherA` is a value published by `publisherOfPublisher` then the condition to use `SwitchToLatest` is not only that our publisher is a `Publisher` of values that themself are `Publisher` but also that those publishers' `Failure` type is the same as our first publisher `Failure` type. (if you understood that poorly written sentence here is a medal 🏅)

 In code the above gibberish translates to :
 */
extension Publisher where Output: Publisher, Output.Failure == Failure {
    // Then only you can use SwitchToLatest
}
/*:
 This concludes the ways to combine publishers together, and there is no arguing that one publisher sending an error tends to bring down everything you built on top of it.

 Next we will see how we can handle errors and maybe avoid this issue.
 */
//: [Next](@next)
