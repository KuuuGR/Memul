import SwiftUI

protocol ImageSliceCaching {
    func get(for key: String) -> [[Image]]?
    func set(_ value: [[Image]], for key: String)
    func clear()
}

final class ImageSliceCache: ImageSliceCaching {
    static let shared = ImageSliceCache()

    // Use NSCache to be memory-bound and auto-purged under pressure
    private let cache = NSCache<NSString, SliceWrapper>()

    private init() {
        // Optional: set limits
        cache.countLimit = 20 // tweak as needed
        cache.totalCostLimit = 50 * 1024 * 1024 // rough limit in bytes; not exact for SwiftUI Images
    }

    func get(for key: String) -> [[Image]]? {
        cache.object(forKey: key as NSString)?.value
    }

    func set(_ value: [[Image]], for key: String) {
        cache.setObject(SliceWrapper(value), forKey: key as NSString)
    }

    func clear() {
        cache.removeAllObjects()
    }

    // Wrapper, because NSCache requires NSObject subclass
    private final class SliceWrapper: NSObject {
        let value: [[Image]]
        init(_ value: [[Image]]) {
            self.value = value
        }
    }
}
