import SwiftUI
import UIKit

/// A tiling film-grain texture, generated once.
enum Grain {
    static let tile: Image = {
        let side = 160
        var pixels = [UInt8](repeating: 255, count: side * side * 4)
        var rng = SplitMix64(seed: 0xF11A_6EA1)
        for i in 0..<(side * side) {
            let value = UInt8(truncatingIfNeeded: rng.next() >> 56)
            pixels[i * 4] = value
            pixels[i * 4 + 1] = value
            pixels[i * 4 + 2] = value
        }
        guard
            let provider = CGDataProvider(data: Data(pixels) as CFData),
            let image = CGImage(
                width: side, height: side,
                bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else { return Image(uiImage: UIImage()) }
        return Image(decorative: image, scale: 2)
    }()
}

struct GrainOverlay: View {
    var opacity = 0.07

    var body: some View {
        Grain.tile
            .resizable(resizingMode: .tile)
            .opacity(opacity)
            .blendMode(.overlay)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
