import Combine
/*: [Previous](@previous)

 ## 6 @Published

 @Published is a [property wrapper](https://docs.swift.org/swift-book/LanguageGuide/Properties.html) that enables to create easily a publisher.
 */
class ValueWrapper {
    @Published var value = 1
}

let valueWrapper = ValueWrapper()
let cancellable = valueWrapper.$value
    .sinkPrint()
valueWrapper.value = 13
print("\n")
/*:
🤔 This looks a lot like what we just saw with `CurrentValueSubject`. Let's try to reimplement it!
 */
@propertyWrapper
struct MyPublished<Value> {
    // Our implementation is relying on subject that is going to do all the work for us.
    private let subject: CurrentValueSubject<Value, Never>

    init(_ initialValue: Value) {
        subject = CurrentValueSubject<Value, Never>(initialValue)
    }
    // The wrapped value is simply our currentValueSubject's value.
    var wrappedValue: Value {
        get { subject.value }
        set { subject.value = newValue }
    }
    // The projected value is the subject erased to a publisher.
    var projectedValue: AnyPublisher<Value, Never> {
        return subject.eraseToAnyPublisher()
    }
}

class MyValueWrapper {
    @MyPublished(1) var value: Int
}

let myValueWrapper = MyValueWrapper()
myValueWrapper.$value
    .sinkPrint()
myValueWrapper.value = 13
print("\n")
/*:
 The is definitely not the exact implementation from **Combine** but it works as expected.
 If we wanted to create a completely identical implementation we would have to recreate a custom publisher, and fix the initialization.

 Well at least it give us a better idea of how @Published works under the hood.

 Let's keep exploring what is provided by **Combine** we would not want too missed out on a hidden gem.
*/
//: [Next](@next)
