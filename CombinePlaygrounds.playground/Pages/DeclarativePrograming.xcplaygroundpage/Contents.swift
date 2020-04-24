/*:
 [Previous](@previous)
## 1 Declarative programming

 Declarative programming is a way to express code that focus on the logic of a computation rather than on the details of the control flow, by opposition to imperative programming.
 Let's see an example of the two. We want to compute the sum of all pair numbers in an array :
*/
func imperativeSum(array: [Int]) -> Int {
    var sum: Int = 0
    for value in array {
        if value % 2 != 0 { continue }
        sum += value
    }
    return sum
}

func declarativeSum(array: [Int]) -> Int {
    return array
        .filter { $0 % 2 == 0 }
        .reduce(0,+)
}
/*:
 The declarative approach is descriptive of the general idea behind your algorithm and relies on functions to implement the actual computing, while the imperative approach is a detailled explanation of how the data is processed to reach the expected result.

 - Callout(TLDR):
 Declarative programming is focused on what we do with our array while imperative is more focused on how we do it.
 
 [Next](@next)
 */
