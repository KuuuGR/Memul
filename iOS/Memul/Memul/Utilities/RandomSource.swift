import Foundation

protocol RandomSourcing {
    // Int in a closed range
    func int(in range: ClosedRange<Int>) -> Int
    // Pick a random element from a collection
    func element<C: Collection>(from collection: C) -> C.Element? where C.Index == Int
}

// Default, non-deterministic implementation
final class SystemRandomSource: RandomSourcing {
    func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range)
    }

    func element<C: Collection>(from collection: C) -> C.Element? where C.Index == Int {
        guard !collection.isEmpty else { return nil }
        let idx = Int.random(in: 0...(collection.count - 1))
        return collection[collection.index(collection.startIndex, offsetBy: idx)]
    }
}

// Deterministic, seedable implementation for tests
final class SeededRandomSource: RandomSourcing {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed != 0 ? seed : 0xDEADBEEFCAFEBABE
    }

    // XorShift64*
    private func nextUInt64() -> UInt64 {
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }

    private func nextDouble() -> Double {
        // [0, 1)
        let v = nextUInt64() >> 11 // 53 bits
        return Double(v) / Double(1 << 53)
    }

    func int(in range: ClosedRange<Int>) -> Int {
        let lower = range.lowerBound
        let upper = range.upperBound
        guard upper >= lower else { return lower }
        let width = upper - lower + 1
        let r = Int(floor(nextDouble() * Double(width)))
        return lower + max(0, min(width - 1, r))
    }

    func element<C: Collection>(from collection: C) -> C.Element? where C.Index == Int {
        guard !collection.isEmpty else { return nil }
        let idx = int(in: 0...(collection.count - 1))
        return collection[collection.index(collection.startIndex, offsetBy: idx)]
    }
}
