import Combine
import UIKit
//: [Previous](@previous)
/*:
 Now that we undestand how we can create the simplest publishers, let's see if we can create something a bit more elaborate.

 Let's create an extension on `UIControl` to get a `UIEvent` publisher

 ## 7 Creating a UIEvent publisher

 Just like before we are going to need to create a subscription for our publisher.
 But this time we do not know in advance all the values we will need to pass.
 We can however provide our subscription with a reference to the control so it can receive all notifications.

 But before going into the implementation details let's focus on what we are trying to achieve.
 A good API would look like as follow :
 ```(Swift)
 let button = UIButton(title: "MyButton")
 let publisher = button.publisher(for: .touchUpInside)
 ```
 where our publisher would publish a `UIControl.Event` each time this event occurs.

 In order to create our publisher we need to hold the `UIcontrol` object and the events we want to be notified of.
*/
struct UIControlPublisher1 {
    let control: UIControl
    private let controlEvents: UIControl.Event

    init(control: UIControl, events: UIControl.Event = .allEvents) {
        self.control = control
        self.controlEvents = events
    }
}
/*:
 Now let's define the details of our publisher, the Output will be `UIEvent?` and there is no possible failure.
 Unfortunately when adding a target to a control for specific `UIControl.Event` there is no easy way to get which `UIcontrol.Event` triggered the action.
 Instead we can receive the `UIEvent` that is responsible for it.
 And the optional is required because otherwise the application would crash when `sendActions(for:UIControl.Event)` is called, because there is no `UIEvent` associated with the event.

 To implement our `receive<S>(subscriber: S) where S : Subscriber, S.Failure == Failure, S.Input == Output` function lets do the same as for Just and do all the heavy lifting in the subscription.
 */
extension UIControlPublisher1: Publisher {

    typealias Output = UIEvent?
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Failure, S.Input == Output {
        let subscription = _Subscritption(subscriber: subscriber, control: control, events: controlEvents)
        subscriber.receive(subscription: subscription)
    }
}
/*:
 Now for our subscription we need a way to get notified of all the event we are interested in.
 For that we just need the subscription to add itself to the target of the control for events.

 As for the demands let's update a counter each time we receive a demand and each time we send a value.
 */
extension UIControlPublisher1 {
    final class _Subscritption<Downstream: Subscriber>: Subscription where Downstream.Input == UIEvent? {
        private var subscriber: Downstream?
        private let control: UIControl
        private var events: UIControl.Event
        private var demand: Subscribers.Demand = .none

        init(subscriber: Downstream, control: UIControl, events: UIControl.Event) {
            self.subscriber = subscriber
            self.control = control
            self.events = events
            control.addTarget(self, action: #selector(eventHandler(sender:for:)), for: events)
        }

        func request(_ demand: Subscribers.Demand) {
            self.demand += demand
        }

        func cancel() {
            subscriber = nil
            control.removeTarget(self, action: #selector(eventHandler(sender:for:)), for: events)
        }

        @objc func eventHandler(sender: UIControl, for event: UIEvent?) {
            guard demand > 0 else { return }
            demand += subscriber?.receive(event) ?? .none
        }
    }
}
//* This should work as expected.
let button = UIButton()
let allEvents = UIControlPublisher1(control: button).sinkPrint()
let touchUpInsideOnly = UIControlPublisher1(control: button, events: .touchUpInside).sinkPrint()
button.sendActions(for: .touchUpInside)
button.sendActions(for: .touchDown)
button.sendActions(for: .touchCancel)
allEvents.cancel()
touchUpInsideOnly.cancel()
/*:
 Yet there is an imperfection in our implementation, when we register multiple subscriber to our publisher we need to add as many target as subscribers.
 It could be better to balance the work charge between publisher and subscription.
 Granted this is a light optimization and it will bring some complication, but this is a good opportunity to give our publisher something to do because subscription can not alway carry all the logic.
 And we need to learn how to make the one comunicate with the other.

 If we want the publisher to be notified of the `UIEvents` and those events sent to the subscribers, we need it to hold a reference on the subscriptionsin order to pass them the values that needs to be sent.
 */
final class UIControlPublisher {
    let control: UIControl
    private let controlEvents: UIControl.Event
    private var subscriptions: [_Subscritption]

    init(control: UIControl, events: UIControl.Event = .allEvents) {
        self.control = control
        self.controlEvents = events
        self.subscriptions = []
        control.addTarget(self, action: #selector(eventHandler(sender:for:)), for: events)
    }

    @objc private  func eventHandler(sender: UIControl, for event: UIEvent?) {
        print("ifneo")
        subscriptions
            .filter { $0.demand > 0 }
            .forEach { subscription in
                subscription.demand += subscription.subscriber?.receive(event) ?? .none
                subscription.demand -= 1
            }
    }
}

extension UIControlPublisher: Publisher {

    typealias Output = UIEvent?
    typealias Failure = Never

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = _Subscritption(parent: self, subscriber: AnySubscriber(subscriber))
        subscriptions.append(subscription)
        subscriber.receive(subscription: subscription)
    }
}
/*:
 With this implementation subscription barely have anything to do.
 They will keep a reference on the subscriber and keep count of the demand and that's it.
 But since the subscription is not the one doing the work, it needs the publisher to stay alive in order to be fed values.
 */
extension UIControlPublisher {
    final class _Subscritption: Subscription {
        private var parent: UIControlPublisher?
        fileprivate var subscriber: AnySubscriber<UIEvent?, Never>?
        fileprivate var demand: Subscribers.Demand = .none

        init(parent: UIControlPublisher,
             subscriber: AnySubscriber<UIEvent?, Never>) {
            self.parent = parent
            self.subscriber = subscriber
        }

        func request(_ demand: Subscribers.Demand) {
            self.demand += demand
        }

        func cancel() {
            parent = nil
            subscriber = nil
        }
    }
}
/*:
 Now that we have created a brand new type of publisher let's make it easily useable.
 */
extension UIControl {
    func publisher(on events: UIControl.Event) -> UIControlPublisher {
        UIControlPublisher(control: self, events: events)
    }
}
/*:
 This is a nice helper that can help anyone who is not familiar with our custom publisher to find it easily and use it.
 */
let sinkPrint = button.publisher(on: .touchDown)
    .sinkPrint()
button.sendActions(for: .touchDown)
button.sendActions(for: .touchUpOutside)
/*:
 Here we have seen that we can sometimes refactor our publisher and subscriptions so that the publisher manages what is common to each subscribers and subscription what is specific.
 */
//: [Next](@next)
