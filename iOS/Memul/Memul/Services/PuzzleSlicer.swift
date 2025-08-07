import SwiftUI
import UIKit

protocol PuzzleSlicing {
    func slice(imageNamed name: String, grid size: Int) -> [[Image]]
}

final class PuzzleSlicer: PuzzleSlicing {
    private let cache: ImageSliceCaching

    init(cache: ImageSliceCaching = ImageSliceCache.shared) {
        self.cache = cache
    }

    func slice(imageNamed name: String, grid size: Int) -> [[Image]] {
        let key = "\(name)_\(size)"
        if let cached = cache.get(for: key) {
            return cached
        }

        guard let uiImage = UIImage(named: name) else {
            return []
        }

        let imageSize = uiImage.size
        let pieceWidth = imageSize.width / CGFloat(size)
        let pieceHeight = imageSize.height / CGFloat(size)

        var pieces: [[Image]] = []
        for row in 0..<size {
            var rowPieces: [Image] = []
            for col in 0..<size {
                let cropRect = CGRect(
                    x: CGFloat(col) * pieceWidth,
                    y: CGFloat(row) * pieceHeight,
                    width: pieceWidth,
                    height: pieceHeight
                ).integral

                if let cg = uiImage.cgImage?.cropping(to: cropRect) {
                    rowPieces.append(Image(uiImage: UIImage(cgImage: cg)))
                } else {
                    rowPieces.append(Image(systemName: "questionmark.square"))
                }
            }
            pieces.append(rowPieces)
        }

        cache.set(pieces, for: key)
        return pieces
    }
}
