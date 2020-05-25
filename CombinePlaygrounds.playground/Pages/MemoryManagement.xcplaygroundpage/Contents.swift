import Combine
import Foundation
//: [Previous](@previous)
/*:

 If you tend to pay close attention to memory management there might be something bugging you.

 ## 8. Memory management

 We have learned that publishers, subscribers and subscription are merely protocols, so the link between them rely on the implementation details.
 But there are some common practice.

 ### 8.1 Subscriber/Subscription

 [Back when we implemented our own version of `Sink`](MySink) we realized that the subscriber needs to hold a reference on the subscription.
 This enables to cancel the subscriber which will in time cancel its subscription.

 - Callout(Your brain):
 Holding a reference on the subscription is one thing, but that does not tells us if the reference is weak or strong.

 This is undoubtably the good question to ask ourself here.
 Since the kind of subscription the subscriber receive is entirely up to the publisher we need to be prepared to hanlde any type that conforms to `Subscription`.
 So logicaly we are going to have a reference on a type-erased `Subscription` value (the existential type).
 This is important, since the `Subscription` protocol is not class bound, we cannot create a weak reference to a type erased subscription.
 This is because we do not know if are getting a value type or a reference type.

 ### 8.2 Subscription/Subscriber

 We just saw that subscribers hold a strong reference to subscriptions, in order to be able to cancel them.
 But it's really confusing because we also would like for a subscription to hold a reference to the subscriber in order to send events.

 - Callout(Your brain):
 It has to be a weak reference otherwise we will endup with a nasty retain cycle on our hands.

 Well, once again the `Subscriber` protocol is not class bound so we cannot have a weak reference to a type erased value.

 ![Subscriber subscription retain cycle diagram](SubscriberSubscriptionRetainCycle.png)

 Ok, this is an issue!
 But let's look at the whole picture before looking more into this.

 ### 8.3 Publisher/Subscription

 We have seen that in the case of `Just` the `Subscription` can be initialized with all it needs, to be independent from the publisher.
 But in some cases (in the implementation of a subject for exemple) the publisher needs to hold a reference on the subscription to pass event to the subscriber.

 The good news is that the implementation of a `Subscription` is heavily connected to the `Publisher` implementation.
 Which means we will only have one type of subscription for a given publisher, therefore we can make weak references to subscriptions if they are implemented by a class.

 The bad news is that a publisher can have any number of subscriptions.
 And unfortunately there is, yet, no collection that hold weak references, in swift.
 Which means the publisher can either have strong references to subscriptions or use a custom container to have weak reference on the subscriptions.

 It is actually easier to just use strong references let's see where that leads us.

 ![publisher to subscription reference diagram ](PublisherSubscriptionsMemoryManagementDiagram.png)

 ### 8.4 Subscription/Publisher

 Should a subscription hold a reference on the publisher?
 There are some occasion where we want the subscription to notify the subscriber about the number of demands.
 This is because we do not want our publisher to do any thing when there is no subscriber waiting on values.
 For that reason we might need to hold a reference on the publisher.
 So if we need the publisher to perform some task so that subscriptions receive their events, it should not be deallocated while their are still subscriptions.
 In other terms the subscription should hold a strong reference to the publisher.

 At this point we do not have one but two retain cycles :

 ![full memory management diagram](MemoryManagement.png)

 Let's see how **Combine** solves this issue.

 ### 8.5 Releasing memory

 Releasing resources has been brought up before when we were talking about `Cancellable`.

 - Callout(Apple documentation):
 Calling `cancel()` frees up any allocated resources. It also stops side effects such as timers, network access, or disk I/O.

 Since there seems to be a good reason for each references our elements hold on each other, let's assume that cancelling is how we are intended to release memory.
 Subscribers and subscription are the only two that needs to conform to `Cancellable`.
 Cancelling the subscriber will remove the reference from subscriber to subscription and cancel the subscription.
 Cancelling the subscription will remove the reference from subscription to subscriber and from subscription to publisher if there is one.

 ![Canceled subscribers memory management diagram](CanceledSubscribersMemoryManagementDiagram.png)

 As we can see this means that Subscribers can be released if nothing else is holding them.
 But subscriptions will not be released untill the publisher is released.
 That's okay because subsriptions are lightweight objects, and in the case you want these subscription to be released it should be easy enough to notify the publisher that a given subscription has been cancelled.

 This is a good news it means we can rely on cancelling the subscriber to remove the retain cycle it introduced.
 But the bad news is that we need to call cancel otherwise nothing is freed.
 And that seems dangerous because memory leak can happen really easily.

 Fortunately for us **Combine** comes with its share of "magic" to avoid us the burden of canceling everything.
 */
let publisher = PassthroughSubject<Int, Never>()
publisher.sinkPrint()
/*:
 - Callout(Your brain):
 Indeed the subscriber is cancelled even though we never bothered to do it.

 If you remember correctly in our [first glance](FirstGlance) we noticed that `.sink()` is returning a `AnyCancellable` value.
 And that is where the magic happens.
 The hint is that if we only wanted to type erase, something that conform to `Cancellable`, we would have just used the existential type :
 */
let cancellable: Cancellable
/*:
 But `AnyCancellable` is actually a wrapper for a `cancel` function that achieves a bit more.
 It enables both :
 - to keep only the `cancel` function available to the user
 - Callout(Apple documentation):
 Subscriber implementations can use this type to provide a “cancellation token” that makes it possible for a caller to cancel a publisher, but not to use the Subscription object to request items.
*/
/*:
 - and call it automaticaly on `deinit`
 - Callout(Apple documentation):
 An AnyCancellable instance automatically calls cancel() when deinitialized.

 This means **Combine** "magically" handle these retain cycles for us.
 But, *and this is really important*, if we were to create our own `Subscription`, `Subscriber` or `Publisher` we have to make sure that calling `cancel`on the subscriber do release all the resources.
 And if we are not creating custom component we still have to make sure we are not manually attaching our subscriber to publisher using `receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input` otherwise it falls on us to call cancel at some point in our implmentation to free resources taken by that subscriber.
 */
//: [Next](@next)
