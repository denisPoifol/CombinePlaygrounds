/*: [Previous](@previous)
 
 ## 2 Processing values over time

 In the current state of swift there are only two ways to handle asynchronous code using only the language capabilities. For anything else we need to use a framework to better manage asynchronous code such as combine.

 ### 2.1 Closures

 The idea is pretty simple if your function performs asynchronous code you require a completion from the caller, and this function is executed once your code completes.
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
Unfortunatelly there is a problem with chaining closures because we are not actualy chaining them but nesting them, which means after 3 levels of nesting, our code become hard to read and reason about.
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

  ### 2.2Protocols

  Using a protocol for this matter feels almost like delegation (which is very frequent pattern in ios developpment), the idea is to create a `protocol`that defines method to notify the caller of event in the current scope.
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
  This pattern is very frequent and not only to handle asynchronous code. When we take a closer look we can see that we are actually passing our `performOperation` function a type erased instance of an implementation of `MyDelegate` protocol that only provides one function. So we are ultimately providing one function. The main difference here is that our function is named and belong to an implementing type, which means we have more control over what function can be passed.

  But the issue remains, when we need to perform mutiple tasks one after the other, our code quickly become an unreadable mess. As an example lets chain two operations :
 */

protocol DelegateForAnotherTask {
    func myTaskDidComplete()
}

func performMyOtherTask(delegate: DelegateForAnotherTask) {
    // Some code to perform an asynchronous operation
    print("performMyOtherTask(delegate:)")
    delegate.myTaskDidComplete()
}

/// This struct on `execute()` will call `performOperation(delegate:)` and then on its completion call `performMyOtherTask(delegate:)` finaly to print "Both tasks completed"
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
 Now we do not have the callback hell issue but our code still is hard to understand and maintain : we need to chase through callsites to find out what happened after each operation. And this is a really simple case : given three operation `A`, `B`, `C` with their delegate protocols `ADelegate`, `BDelegate` and `CDelegate` if we want to execute **A -> B -> A -> C** then we need a way for our implementation of `ADelegate` to know when to perform `B` and when to perform `C`.
 Needless to say this will not end well for our codebase after a few new features and bugfixes.

 This is quite obviously why we might need to use a framework to better handle our asynchronous code, here we are going to be looking into **Combine** but there are plenty of other possibilities. For example *Foundation* provides [https://developer.apple.com/documentation/foundation/task_management](a task management API), but there are also many third party solutions you can find on github.
 */
//: [Next](@next)
