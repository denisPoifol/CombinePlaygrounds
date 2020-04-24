import Combine
/*: [Previous](@previous)

 We have talked about type erasure for `Publsihers` now we need to talk about type erasure for `Subscribers`

 ## 4 AnyCancellable

 Some subscribers are cancellable. Indeed at some point we might want to stop listening to our publisher.
 
 So in order to be able to cancel we need to have a reference on our subscriber. And since this is the only thing we can and should do with a Subscriber once it has been attached to a publisher, our subscriber is type erased by `AnyCancellable`.

 This explains the strange value returned by `Publishers.sink`.
 */
var cancellables: Set<AnyCancellable> = []
(1...10).publisher
    .sinkPrint()
    .store(in: &cancellables)
/*:
 Now we are able to cancel the subscribtion of our sink (even though in this case our publisher will send a completion before we even have the opportunity to cancel the subscribtion). Actually all of the publisher we have created until now, completes their data stream before even returning the `Anycancellable`.
 >Calling `store(in:)` on the returned cancellable, enables to keep our declarative flow.

 To levrage the possibility of cancelling a subscriber we are going to need other publishers. (This is also the result of how `Sink` is implemented but we are going to stick with it for now).

 The publisher we currently use publish un certain amount of values and immediatly after a completion. Next we will learn about `Subjects` another concept from **Combine** that enable us to publish in an imperative fashion.
 */

//: [Next](@next)
