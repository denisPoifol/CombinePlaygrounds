/*: [Previous](@previous)
 
 ## 2 Processing values over time

 In the current state of swift there are only two ways to handle asynchronous code, using only the language capabilities. When the raw language features come short for what you are tying to achieve, you have to turn to a framework, to better manage asynchronous code such as **Combine**.

 First we might want to see what the language offers.

 ### 2.1 Closures

 The idea is pretty simple, if your function performs asynchronous code you require a completion from the caller, and this completion is executed once your function completes.
 */
func doSomething(completion: () -> Void) {
    // Some code performing an asynchronous task
    print("doing something")
    completion()
}

func doSomethingElse(completion: () -> Void) {
    // Some code performing an asynchronous task
    print("doing something else")
    completion()
}
/*:
Unfortunatelly there is a problem with chaining closures because we are not actualy chaining them but nesting them, which means after 3 levels of nesting, our code becomes hard to read and reason about.
*/
doSomething {
    doSomething {
        doSomethingElse {
            // ect...
            print("done")
            print("\n")
        }
    }
}
/*:
 This well known issue is called callback hell.

  ### 2.2 Protocols

  Using a protocol for this matter feels almost like delegation (which is a very frequent pattern in iOS development), the idea is to create a `protocol` that defines one (or more) method(s) to notify the caller of event in the current scope.
 */
 protocol MyDelegate {
     func operationDidComplete()
 }

 func performOperation(delegate: MyDelegate) {
     // Some code to perform an asynchronous operation
    print("performOperation(delegate:)")
    delegate.operationDidComplete()
}
/*:
 This pattern is very frequent and not only to handle asynchronous code.

 When we take a closer look we can see that we are actually passing our `performOperation` function, a type erased instance of an implementation of `MyDelegate` protocol. `MyDelegate`that only offers one function. So we are ultimately providing one function. The main difference here is that our function is named and belong to an implementing type, which means we have more control over what function can be passed, but less on what is doing that function.

 But the issue remains, when we need to perform mutiple tasks one after the other, our code quickly become an unreadable mess. As an example let's chain two operations :
 */
protocol DelegateForAnotherTask {
    func myTaskDidComplete()
}

func performMyOtherTask(delegate: DelegateForAnotherTask) {
    // Some code to perform an asynchronous operation
    print("performMyOtherTask(delegate:)")
    delegate.myTaskDidComplete()
}
//: The following struct on `execute()` will call `performOperation(delegate:)` and then on its completion call `performMyOtherTask(delegate:)` finally to print "Both tasks completed"
struct MyChainOfOperation: MyDelegate, DelegateForAnotherTask {

    func execute() {
        performOperation(delegate: self)
    }

    // MARK: - MyDelegate

    func operationDidComplete() {
        performMyOtherTask(delegate: self)
    }

    // MARK: - DelegateForAnotherTask

    func myTaskDidComplete() {
        print("Both tasks completed")
        print("\n")
    }
}

MyChainOfOperation().execute()
/*:
 We are not facing the callback hell issue, but our code is still hard to understand and maintain : we need to chase through callsites to find out what happened after each operation.

 And this is a really simple case, let's look at something a tiny bit more complicated : given three operation `A`, `B`, `C` with their delegate protocols `ADelegate`, `BDelegate` and `CDelegate` if we want to execute **A -> B -> A -> C** then we need a way for our implementation of `ADelegate` to know when to perform `B` and when to perform `C`.
 Needless to say this will not end well for our codebase after a few new features and bugfixes.

 This is quite obviously why we might need to use a framework to better handle our asynchronous code, here we are going to be looking into **Combine** but there are plenty of other possibilities. For example **Foundation** provides [a task management API](https://developer.apple.com/documentation/foundation/task_management), but there are also many third party solutions you can find on github.
 */
//: [Next](@next)
