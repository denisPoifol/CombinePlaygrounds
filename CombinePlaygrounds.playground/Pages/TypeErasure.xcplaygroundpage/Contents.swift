import Combine
/*:
 [Previous](@previous)

 ## 3 Type erased publisher

 We have seen that the publisher operators proposed by **Combine** relies heavily on generic implementations of the `Publisher` protocol which can make us end up manipulating monstruously long types.
 In the previous section we ended up with a `Map<MergeMany<Sequence<Array<Int>, Never>>, Int>` which makes it hard to understand what type of values are published and what type of error can be sent.
 Moreover it leaks implementation details that are not needed by the user of our publisher and can cause some type mismatching issues.

 Let's say I want to define a protocol that exposes a publisher, I need a type for this publisher, here is what I can do:
 - **hard code one** : but it's sometimes almost impossible to conform to it since the type can be really specific like the one above.
 - **use an associated type for my protocol** but my protocol will not have an existencial type (ex `let myVar: ProtocolName`)

 None of these solutions are good enough, that's why Combine provides type erasure for publishers.
 */
let myPublisher: AnyPublisher<Int, Never>
let aPublisher = (1...5).publisher
myPublisher = aPublisher.eraseToAnyPublisher()
/*:
 This is very important because it allows us to create clean APIs that focus on how they can be used rather than how they are implemented.

 This also makes it way easier for us to manipulate publishers
 */
func doubleOrMerge(publisher: AnyPublisher<Int, Never>,
                   condition: Bool,
                   array: [Int]) -> AnyPublisher<Int, Never> {
    if condition {
        return publisher.map { $0 * 2 }.eraseToAnyPublisher()
    } else {
        return publisher.merge(with: array.publisher).eraseToAnyPublisher()
    }
}
/*:
 This function could not have been implemented if we did not have a way to erase the type of our publishers, because `Publishers.Map<AnyPublisher<Int, Never>, T>` and `Merge<AnyPublisher<Int, Never>, Publishers.Sequence<[Int], Never>>` are definitely different types and our function should not have different return types depending on the values it receives.

 > This function is not much of any help but if you do create a function like this one to easily modify your publishers you should declare it as an extension on `Publisher` in order to keep the same coding style provided by **Combine**
 */
extension Publisher where Output == Int, Failure == Never {
    func doubleOrMerge(condition: Bool,
                       array: [Int]) -> AnyPublisher<Int, Never> {
        if condition {
            return map { $0 * 2 }.eraseToAnyPublisher()
        } else {
            return merge(with: array.publisher).eraseToAnyPublisher()
        }
    }
}

// do not do this
doubleOrMerge(publisher: (1...5).publisher.eraseToAnyPublisher(), condition: true, array: [1, 2, 3])
// do this 🤩
(1...5).publisher
    .doubleOrMerge(condition: true, array: [1, 2, 3])
/*:
 This coding style enables us to keep a declarative approach and it is way easier to read, so even if it is for a single use somewhere in your codebase you should always favor an extension. You even can make it private if you do not want it to be used elsewhere.

 >Type erasure comes at a cost, we saw earlier the developpers of the framework thought `map(_:)` on a `Publishers.Sequence<Array<Int>, Never>` should return a value of the same type instead of `Publishers.Map<Publishers.Sequence<Array<Int>, Never>, Int>` (probably for performance reasons) which means `eraseToAnyPublisher()` should not be abused. And like most things in programming, type erasing is a trade of, it should be thought through.

 [Next](@next)
 */
