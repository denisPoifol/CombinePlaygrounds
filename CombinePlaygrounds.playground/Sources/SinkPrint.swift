import Foundation
import Combine

public extension Publisher {
    func sinkPrint() -> AnyCancellable {
        print()
        .sink(receiveCompletion: { _ in }) { _ in }
    }
}
