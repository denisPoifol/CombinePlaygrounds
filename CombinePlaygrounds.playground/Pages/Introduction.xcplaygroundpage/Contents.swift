/*:

 # Introduction to Combine

 Combine is the reactive programming framework developped by apple launched at WWDC 2019.

 - Callout(Wikipedia):
 Reactive programming is a declarative programming paradigm concerned with data streams and the propagation of change.

 What it means is that reactive programing is about handling streams of data, and is doing that by defining a process applied to each piece of data going through the stream. And stream is to be understood as data being received through time.

 This my interpratation of it but let's see what Apple is saying about combine :

 - Callout(Apple documentation):
 The [Combine framework](https://developer.apple.com/documentation/combine) provides a declarative Swift API for processing values over time. These values can represent many kinds of asynchronous events. Combine declares publishers to expose values that can change over time, and subscribers to receive those values from the publishers.

 Let's give this a little structure :
 - I. Introduction
    - [1. what is a declarative API ?](DeclarativePrograming)
    - [2. why processing values over time is valuable ?](ProcessingValuesOverTime)
 - II. Core concepts
    - [1. Publisher](CoreConcepts)
    - [2. Subscriber](CoreConcepts)
    - [3. Subscription](CoreConcepts)
    - [4. Life cycle](CoreConcepts)
 - III. Using combine
    - [1. First glance](FirstGlance)
    - [2. Sequences](Sequences)
    - [3. Type erasure](TypeErasure)
    - [4. AnyCancellable](AnyCancellable)
    - [5. Subjects](Subjects)
    - [6. Published](Published)
    - [7. Convenience Publishers](ConveniencePublishers)
    - [8. Futures](Futures)
    - [9. Side Effects](SideEffects)
    - [10. Multicast](Multicast)
    - [11. Connectable publisher](ConnectablePublisher)
    - [12. Scheduler](Scheduler)
    - [13. Time operators](TimeOperators)
    - [14. Combining publishers](CombiningPublishers)
    - [15. Managing errors](ManagingErrors)
    - [16. Debuging](Debuging)

 [Next](@next)
*/
