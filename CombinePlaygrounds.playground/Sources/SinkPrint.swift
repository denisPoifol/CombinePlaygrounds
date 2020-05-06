import Foundation
import Combine

public extension Publisher {
    func sinkPrint() -> AnyCancellable {
        print(to: Logger.shared)
        .sink(receiveCompletion: { _ in }) { _ in }
    }
}
