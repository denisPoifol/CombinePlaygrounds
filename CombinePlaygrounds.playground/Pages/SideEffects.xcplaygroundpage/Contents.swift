import Combine
//: [Previous](@previous)
/*:
 Before going into how to decide when and how your publisher is publishing its event let's look at one of the resons it might be important.

 So we are going to talk a bit about side effects. **Combine** is a reactive programming frameworks which means at some point we had to talk a bit about functional programming.

 ## 9 Side effects

 Functional programming relies on the idea that a function is a first class citizen. What it means is that I can store a function in a variable or as a parameter of another function. Swift allows all that.

 Now side effect is roughly when a function is changing something outside of its scope.
 */
func double(x: Int) -> Int {
    2 * x
}
//: `double(x:) here is what we call a pure function, which means it has no side effect. And if you provide it with a parameter the result will always be the same if the parameter is the same.
var counter = 0
func incrementCount() {
    counter += 1
}
/*:
 On the other hand, incrementCount has a side effect which is incrementing the counter variable.

 How is this relevent to us ?

 If your publisher is doing some work with side effects it might be important to decide when this work is executed.
 Let's consider the following.
 */
func printCounter() {
    Swift.print("counter", counter)
}

func resetCounter() {
    counter = 0
}

let increment = Future(incrementCount)
let print = Future(printCounter)
let reset = Future(resetCounter)

increment
    .then(resetCounter)
    .then(printCounter)
/*:
 😱 what happened here this does not make any sense!

 Well it quite simple in fact : our `Future` are executed once created, let's go through the code step by step to understand.
 ```
 // we create a Future which means its executed immediately and our counter increments to 1
 let increment = Future(incrementCount)
 // we create another Future which prints the counter value
 let print = Future(printCounter)
 // we create a last Future which reset the counter to 0
 let reset = Future(resetCounter)

 // By the time we reach this point we are chaining a Publisher that has already sent a completion to other calls which means it won't do any work.
 increment
     .then(resetCounter)
     .then(printCounter)
 ```
 The solution here is simple do not create `let print = Future(printCounter)` and `let reset = Future(resetCounter)` which are not needed anyway.
 But also directly chain `Future(incrementCount)` to the rest if we want the remaining operations to be executed.
 Or we can also wrapp our `Future(incrementCount)` into a `Deferred`

 Well this is quite basic and feels like there might not need to go on and on about it, but like I said before there are other reason you might want to define when your `Publisher` starts publishing.
*/
//: [Next](@next)
