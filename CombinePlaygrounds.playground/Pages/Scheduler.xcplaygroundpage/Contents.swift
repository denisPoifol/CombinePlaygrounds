//: [Previous](@previous)
/*:
 On the subject of timing the event of our publisher **Combine** provdes a couple of really usefull operators.
 But they all rely on `Scheduler` so we first need to understand what a Scheduler is.

 ## 12 Scheduler

 Once again `Scheduler` is a protocol 😍 which means once again we can conform to it if it makes sense.
 It relies on two associated types :
 - SchedulerTimeType
 - SchedulerOptions
 A scheduler can be used to schedule some operations, which means it is another way for us to chose when we are sending our events.

 Looking at the function makes it clear it describes an API to schedule pieces of code like stated before. But what is really important here is to look at the conforming types, because let's be real we are not going to create our own scheduler any time soon. Among the type we find `DispatchQueue`, `OperationQueue` and `RunLoop`.

 But we also find a new type introduced by combine `ImmediateScheduler` :
 - Callout(Apple documentation):
 You can only use this scheduler for immediate actions. If you attempt to schedule actions after a specific date, this scheduler ignores the date and performs them immediately.

 Now that we understand what a scheduler is let's look into the previously mentionned operators
 */
//: [Next](@next)
