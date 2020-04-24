import Combine
//: [Previous](@previous)
/*:
 ## 14 Combining publishers

 One thinking about publisher, you can think of it as a graph where a node is a publisher and an arrow is an operator.

 Let's take the publisher we created when looking at `multicast` as exemple :
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

 This enable us to vizualize a bit better and also the insanely long type can make sense if you look at it that way.

 In this chapter we are mostly going to look at operator that, like `Zip`, would be represented by multiple arrows merging into one. Which means we are going to create one publisher from multiple publishers.

 We saw a usage of `Merge3` in the previous so let's look into the merge family.

 ### 14.1 Merge

 Actualy the whole merge family behave the same so let's look at the most obvious one `Merge`.
 Let's represent two publisher as streams of data.
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

 Of course once one of the publisher finishes we still want to receive informations form the one that is still running.
 But once the second one finishes now there is nothing more to wait for so the `Merge` send a completion
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
 You litteraly just told me that one of the publisher sending a completion do not stop the mergePublisher.

 Well it is true for completions but we would not want to miss out on errors. So when there is an error returned by one of the publisher our mergePublisher stops and sends this error too.

 Now that you have a clear idea of what `Merge` do, we have to address the elephant in the room. The result of merge is a `Publisher` that publish the same values and errors as the merged publishers. Which means two publishers have to match their `Output` and `Failure` for a merge to be possible.

 I guess there is no need to go in details about how Merge3 and Merge4 work. But the concept remains the same. Conceptualy you could say `Merge3(a, b, c) == Merge(a, Merge(b, c))` and `Merge4(a, b, c, d) == Merge(Merge(a, b), Merge(c, d))`. The implementation details might be a bit different for some optimizations.

 Combine provides with Merge types from 2 to 10 meaning if you need to merge 11+ publisher there is two solutions :
 - either call merge with 10 publishers and merge the result recursively until you have merged all of your publishers.
 - use MergeMany

 `MergeMany` enables to merge as many publisher as you wish on one condition that is a bit more restrictive, the condition is that all publisher have to have the exact same Type. This seems like a big constraint but `eraseToAnyPublisher()` is here for you. 😎

 - Callout(Your brain):
 How come you can merge as many as you want if they are the same type. But if the types are different we can go as far as ten easily but more as to be done by hand?

 Well this restriction actualy comes from Swift itself. When we look at the types we can see `Merge` has two type parameters, `Merge3` has 3 ect...
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

 Unfortunately if we want to create a function that takes as many publisher as we want as long as they share the same `Output` and `Failure` we are stuck again because it would require variadic generics.

 We have gone through `Merge` let's look at `Zip` because seeing it with a diagram is much nicer 🤩

 ### 14.2 Zip

 First a quick reminder of the basic idea, Zip waits for both publisher to send a value in order to send a tuple from those both values.
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
 What is interesting in this exemple is that we can see that `Zip` handles completion from its publsihers in a smart way : if the publisher that complete is the one that is "late" then our `Zip` completes because there is no way we can publish any more values.

 ![Zip diagram complete](ZipDiagramComplete.png)
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
 The last we just saw exemple confirm what we were thinking : if the publisher that is ahead finishes `Zip` does not finish until one of the next happens :
 - the late one catches up
 - the late one also completes

 ![Zip diagram complete](ZipDiagramError.png)

 And just like merge `Zip` sends an error if either one of its publisher sends one.

 There is also `Zip3` and `Zip4`. The rules remains the same. `ZipX` waits for all of its publisher to publish at least one value before creating a tuple of it.
 If a publisher as finished and is the latest one, then `ZipX` finishes too. If a publisher sends an error then `ZipX` sends an error.

 > Since we are creating tuples here there is no need for publisher to publish the same `Output` but we are forwarding the errors, which means the `Failure` type as to be the same.

 ### 14.3 CombineLatest

 Combine latest is similar to `ZIP` in the way that it creates tuples from its publishers. But this times the idea is that every time a publisher sends a value `CombineLatest` is going to send one too.
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
 `CombineLatest`first needs to wait for all publisher to publish at least one value in order to be able to create a tuple (this is very similar to `Zip`).
 But once all publisher have published a value it will send an event evry time a publiser sends a new one to update the latest combination of value receives

 ![Combine latest diagram](CombineLatestDiagram.png)

 The completion of one of the publisher does not complete `CombineLatest` since the other one can still update. But once both completes `CombineLatest` also completes of course. Like always if an error occurs it is forwarded by `CombineLatest`.

 And like `Zip` we can find multiple flavour of `CombineLatest` combining 2, 3 or 4 publishers together.

 The same constraints applie, we don't care that the `Output` types do not match since we are building a tuple be the `Failure` type have to be the same

 ### 14.4 SwitchLatest

 Ok this is the weirdest one this applies only to a `Pusblisher` that publishes `Publisher` value.

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

 From the result we can see that `publisherOfPublisher` events point us in the direction of what publisher we should look at. Which makes sense when you think avout it, after all this operator is called switch to latest.

 We can also see that the current publisher is not responsible for a completion event, this also make sense because we can look at B and upon completion decide we should now look at A.

 Once again an error message is not to be ignored so if our current publisher send an error it is forwarded by our operator.
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

 🤔 If `publisherOfPublisher` and `publisherA` can both send an error that will be repeated forwarded by `SwitchToLatest`, that means their `Failure` type has to be the same. And since `publisherA`is a value published by `publisherOfPublisher` then the condition to use `SwitchToLatest`is not only that our publisher is a `Publisher` of values that themself are `Publisher` but also that those publishers' `Failure` type is the same as our first publisher `Failure` type. (if you understood that poorly written sentence here is a medal 🏅)

 In code the above gebbrish translates as :
 */
extension Publisher where Output: Publisher, Output.Failure == Failure {
    // Then only you can use SwitchToLatest
}
/*:
 This concludes ways to combine publisher together, and there is not arguing that one publisher sending an error tends to bring down, everything you built on top of it.

 Next we will see how we can handle errors and maybe avoid this issue.
 */
//: [Next](@next)
