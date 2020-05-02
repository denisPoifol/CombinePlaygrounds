import Combine
import Foundation
//: [Previous](@previous)
/*:
But before going into how we can handle back pressure with **Combine** let's talk about what it is.

 ## 3 Back pressure

 ### 3.1 Definition

 - Callout(Apple documentation):
 This concept of controlling flow by signaling a subscriber’s readiness to receive elements is called back pressure.

 So back pressure is the mechanism of requesting values from a subscriber using `Subscribers.Demand`. Wether it's by requesting demand directly to the subscription it keeps or by returning a demand after receiving a value.

 ### 3.2 Usage

 Why do we need this mechanisme ?

 We did saw a reason of this mechanism earlier, sometimes the publisher can produce values really fast and so fast that it does not make any sens to let the publisher decide of the rate at which it publishes values.

 For example using `Sink` applies no back pressure at all and let the publisher publish as fast as it can.
 For this reason the following code result as an infinite loop.
 */
let infinitePrint = (1...).publisher
    .sinkPrint() // comment me
Logger.shared.returnLogs()
/*:
 ### 3.3 Managing back pressure

 To manage back pressure there are two tools available :
 - use a subscriber that applies back pressure, which means creating a custom subscriber because both `Sink` and `Assign` request for unlimited values at subscription.
 - use back pressure operators.

 It is worth mentionning that back pressure operator do not apply back pressure, they are tools to help you better manage it.
 When you do apply back pressure most of the time this means along the line some publisher will be dropping values.
 That is were back pressure operators come into play, they help to avoid dropping too many values or choose which values should be dropped.

 Among those operator we can recognize some we already saw earlier such as `debounce` or `throttle`
 But there are also some operator we have not run into yet : like `buffer` and `collect`

 For `debounce` and `throttle`, we define which values should be dropped in order to reduce the number received by our subscriber without the need to get our hands on the back pressure mechanism which would require to create our custom subscriber.

 Next we are going to take this opportunity to look a bit closer at `buffer` and `collect`
 */
//: [Next](@next)
