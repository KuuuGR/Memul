import SwiftUI

protocol ImageSliceCaching {
    func get(for key: String) -> [[Image]]?
    func set(_ value: [[Image]], for key: String)
    func clear()
}

final class ImageSliceCache: ImageSliceCaching {
    static let shared = ImageSliceCache()

    // In-memory cache
    private var storage: [String: [[Image]]] = [:]

    private init() {}

    func get(for key: String) -> [[Image]]? {
        storage[key]
    }

    func set(_ value: [[Image]], for key: String) {
        storage[key] = value
    }

    func clear() {
        storage.removeAll()
    }
}
