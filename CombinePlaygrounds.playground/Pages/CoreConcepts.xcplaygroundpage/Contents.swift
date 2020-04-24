//: [Previous](@previous)
/*:
 Enough with the introduction let's go and look into **Combine** now! 🙌

 - Callout(Apple documentation):
  Combine declares publishers to expose values that can change over time, and subscribers to receive those values from the publishers.

  Ok so let's go, our data streams are exposed by `Publisher`s and to interact with these streams we have to use `Subscriber`s. We can play with it and we will figure out how it works along the way.
  */
 import Combine
/*:
  How do I create a publisher 🤔 ?
  Ok maybe we need a little more context. We will go through the core concepts and that's it! After that we are getting our coding on.

 # Core concepts

 ## 1 Publisher

 So `Publisher` is a protocol with two associated types `Output` and `Failure`. Failure needs to conform to `Error`. The protocol also displays one method `func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input`
 this means a `Subscriber` can only subscribe to a `Publisher` if it reads the type of data the `Publisher` sends. It makes sense since we love type safety. 😍

 `Publisher` being a protocol means anything could be a publisher and even I could create my own, but let's not get ahead of ourselves.

 ## 2 Subscriber

 `Subscriber` seems a bit more complicated, we still have our two associated types `Input` and `Failure` where `Failure` still needs to be an `Error` type. But this time there are three different methods :
 1. ```func receive(subscription: Subscription)```
 2. ```func receive(_ input: Self.Input) -> Subscribers.Demand```
 3. ```func receive(completion: Subscribers.Completion<Self.Failure>)```
 - *3* is clear enough, we do something when the stream completes or returns an error.
 - *2* is the same when we receive a value, but I do not understand what `Subscribers.Demand` is and how it is used yet
 - *1* No clue of what a subscription is and what we are supposed to do with it.

 ## 3 Subscription

 `Subscription` is also a protocol but we will not go through the details of it right now. It is less documented because we do not need to know much about it to complete most of the challenge we can face using **Combine**, so we are going to keep it very short here. We might come back to it later.

 In [introduction to **Combine**](https://developer.apple.com/videos/play/wwdc2019/722/) Tony Parker mentions it only twice and descibes it like this :

 - Callout(Tony Parker):
 A subscription is how a Subscriber controls the flow of data from a Publisher to a Subscriber.

 A `Demand` from the subscriber enables it to control the amount of data that it is going to receive from the publisher, but more often than not the subscriber will send a request for an unlimited amount of data. For that reason it is not highly important to know in depth how subscriber and publisher communicate together.

 ## 4 Life cycle

 This diagram from the WWDC gives a good understanding of how the life cycle of a publisher works.

 ![Publisher life cycle graph](PublisherLifeCycle.png)

 - Callout(Tony Parker):
 At that point, the Publisher will send a subscription to the Subscriber which the Subscriber will use to make a request from the Publisher for a certain number of values or unlimited. At that point, the Publisher is free to send that number of values or less to the Subscriber. And again, if the Publisher is finite, then it will eventually send a Completion or an Error. So again, one subscription, zero or more values and a single Completion.

 This is all you need to for a *basic* use of **Combine**.
 */
//: [Next](@next)
