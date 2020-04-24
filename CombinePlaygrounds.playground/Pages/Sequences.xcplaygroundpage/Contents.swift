import Combine
/*: [Previous](@previous)

 ## 2 Sequences

 We have seen that `Just` creates a stream for each of his `Subscriber` and publish its stored value, then a completion.

 But now we want more, we want to have a stream that publishes more than one value. Fortunately for us there is an extension on `Swift.Sequence` that does just what we want.
 We can turn any `Sequence` into a publisher that will publish the values contained in the sequence.
*/
let array = [1, 2, 3, 4, 5]
array.publisher
    .sinkPrint()
print("\n")
(1...10).publisher
    .sinkPrint()
//: I have to say this reminds me of `forEach(_:)`, I'll be damned if there is not a `map(_:)` waiting around the corner!
array.publisher
    .map { $0 * 2 }
    .sinkPrint()
print("\n")
/*:
 Here it is! And it makes sense too.

 In a `Collection` when you `map(_:)` you iterate through the values to transform them. If you think about it `Collection` defines a way to go through a dimension (that is the memory addresses) and get values. While a data stream defines a way to go through another dimension which is time an get values. So it makes a lot of sense that we can map the same way through a data stream or a collection.

 - Callout(Your brain):
 😤 You just told me that a publisher and a data stream are not the same thing and should not be confused.

 You definitely got a point here but it still works trust me.

 What we described above is a way to map through a data stream.

 Now if we want to map through a publisher, all we have to do is for each data stream it initiates with its subscriber, map through it and that's it!

 In fact since we can easily see a sequence as a publisher and a publisher as a way to handle a sequence we can apply any Sequence function to a publisher
 */
let publisher = array.publisher
    .filter { $0 % 2 == 0 }
    .map { $0 * 2 }
    .append(array)
publisher.sinkPrint()
type(of: publisher)
print("\n")
/*:
 This is even hinted to us by the type of our publisher, while we apply Sequence functions we have a `Publishers.Sequence<Array<Int>, Never>`.
 >Under the hood Combine is probably lazyly applying function to the sequence to finaly turn it into a publisher in order to reduce overhaed.

 What makes us think that the treatment is specific is when applying modifiers, most of the time the type of or publisher changes to become more complex.
 */
let aPublisher = array.publisher
    .merge(with: array.publisher)
print(type(of: aPublisher))
let bPublisher = aPublisher
    .map { $0 * 2 }
print(type(of: bPublisher))

//: [Next](@next)
