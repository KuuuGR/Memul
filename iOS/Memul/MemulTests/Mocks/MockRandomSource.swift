import Foundation
@testable import Memul

final class MockRandomSource: RandomSourcing {
    var ints: [Int] = []
    var elements: [Any] = []

    func int(in range: ClosedRange<Int>) -> Int {
        if !ints.isEmpty { return ints.removeFirst() }
        return range.lowerBound
    }

    func element<C: Collection>(from collection: C) -> C.Element? where C.Index == Int {
        guard !collection.isEmpty else { return nil }
        if !elements.isEmpty, let next = elements.removeFirst() as? C.Element {
            return next
        }
        // Default: first
        return collection[collection.startIndex]
    }
}
