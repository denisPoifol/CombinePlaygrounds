import Foundation

public class Logger: TextOutputStream, CustomPlaygroundDisplayConvertible {

    public static var shared = Logger()

    var logs: [String] = []

    public func write(_ string: String) {
        guard !string.isEmpty && string.contains(where: { $0 != "\n" }) else { return }
        print(string)
        logs.append(string)
    }

    public var playgroundDescription: Any {
        return logs
    }

    public func returnLogs() -> [String] {
        let loggedStrings = logs
        logs.removeAll()
        print("\n")
        return loggedStrings
    }
}
