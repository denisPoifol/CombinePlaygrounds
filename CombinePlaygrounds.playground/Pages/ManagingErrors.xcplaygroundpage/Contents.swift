import Combine
//: [Previous](@previous)
/*:
 ## 15 Managing errors

 Managing errors is really important since everytime a publisher sends an error it stops streaming any more events, so you might want to react accordingly.

 Fortunately `Combine` comes with many operators to handle those errors.
*/
let record = Record<Int, MyError>(output: [1, 2, 3], completion: .failure(MyError.fail))
/*:
 ### 15.1 Catch

 Let's start with `catch`, it enables to react to an error and return a new publisher to replace the one that failed.
 */
let catched = record
    .catch { (error: MyError) -> Just<Int> in
        switch error {
        case .fail:
            return Just(4)
        case .fail1:
            return Just(5)
        case .fail2:
            return Just(6)
        }
    }
    .append(7)
    .sinkPrint()
print("\n")
/*:
 The replacing publisher benefits from the same operators applied after the catch.
 The good news is that since publishers have a `Failure` associated type we know what kind of error we are dealing with.

 > Since the replacing publisher also benefits from the next operators we have to provide a publisher that returns the same Output.
 */
let catched1 = record
    .catch { _ in Just(4) }
    .eraseToAnyPublisher()
print(type(of: catched1))
print("\n")
/*:
 We also notice that the publisher returned by `catch` do not need to match the `Failure` type of the calling publisher. Indeed whatever error the publisher produces is never going to get passed our catch, so the next operator should not expect and error from the "parent" publisher. But since catch returns a different publisher if an error is sent, then that new publisher could himself in time produce an error but that error is free of any constraint.

 ### 15.2 TryCatch

 `TryCatch` does almost exactly the same as `Catch` the subtle but important difference is that `TryCatch` can throw an error in its closure.

 - Callout(Your brain):
 Why not always use `TryCatch`, if you can move mountains you can move molehills.

 Well here again the problem comes from a limitation of the language : anything that conforms to `Error` can be thrown and there is no language feature to limit what can be thrown in a given context. Which means we cannot be sure of the type of `Failure` we will end up with. This means that using `tryCatch` will erase the `Failure` of a publisher.

 > For the exact same reason `map` cannot throw errors and if you want to throw one you should `tryMap`, this is true for every closure based operator. But keep in mind that throwing will erase the `Failure` type.
 */
let tryCatched = record
    .tryCatch { (error: MyError) -> Just<Int> in
        if case .fail = error {
            throw OtherError.error
        }
        return Just(6)
    }
print(type(of: tryCatched.eraseToAnyPublisher()))
print("\n")

/*:
 ### 15.3 Retry

 This one is self explanatory, when retry receives an error it recreates the "parent" publisher and tries again, limited to the number of trials you provide him.
 */
let retried = record
    .retry(2)
    .sinkPrint()
print("\n")
/*:
 It's easy to get confused here, the number you provide to retry is not the number of trials but the number of retrial. In the previous example the record is played 3 times and not 2.

 ### 15.4 AssertNoFailure

 Sometimes you might have a publiser that specifies a specific `Failure` type, but you are confident that no error will be sent. This is when `assertNoFailure` comes handy. It simply changes your publisher's `Failure` type to `Never`.

 Of course if you were wrongly thinking no error can be sent you are exposing yourself to a crash.
 */
let assertNoFailure = (1...3).publisher
    .setFailureType(to: MyError.self)
    .assertNoFailure()
print(type(of: assertNoFailure.eraseToAnyPublisher()))
print("\n")

/*:
 ### 15.5 ReplacingError

 Replacing an error with a value is quite straight forward, it's however worth noticing that this will not allow your publisher to continue as if no error were sent.

 Instead of sending an error, the publisher sends a value but immediately finishes after.
 */
let replacedError = record
    .replaceError(with: -1)
    .sinkPrint()
print("\n")

/*:
 Now we are able to handle errors sent by our publishers, let's look into debugging. Because we have tools to create some fairly complicated publishers and that always comes with fairly complicated bugs. Not to mention working with data streams can be hard to grasp but even harder to debug without the right tools.
 */

//: [Next](@next)
