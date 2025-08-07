import SwiftUI
@testable import Memul

final class MockImageSliceCache: ImageSliceCaching {
    var store: [String: [[Image]]] = [:]
    func get(for key: String) -> [[Image]]? { store[key] }
    func set(_ value: [[Image]], for key: String) { store[key] = value }
    func clear() { store.removeAll() }
}
