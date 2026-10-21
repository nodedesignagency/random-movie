import CoreText
import ImageIO
import SwiftUI
import UIKit

/// A photographed jewel case split into layers, so any cover can be laid into it: `shade`
/// darkens the insert where the case's plastic sits over it, `glare` holds the reflections, and
/// `base` is the case itself with a transparent window.
nonisolated struct CaseTemplate: @unchecked Sendable {   // immutable images
    let base: CGImage
    let shade: CGImage
    let glare: CGImage

    /// The cover insert's corners as fractions of the template. It's a parallelogram (the photo
    /// is isometric), so three corners pin it.
    static let insertTopLeft = CGPoint(x: 0.12593, y: 0.06776)
    static let insertTopRight = CGPoint(x: 0.90555, y: 0.25442)
    static let insertBottomLeft = CGPoint(x: 0.12593, y: 0.77030)
    static var insertBottomRight: CGPoint {
        CGPoint(x: insertTopRight.x + insertBottomLeft.x - insertTopLeft.x,
                y: insertTopRight.y + insertBottomLeft.y - insertTopLeft.y)
    }

    /// Height ÷ width of the template photo.
    static let aspect: CGFloat = 985.0 / 760.0

    static func load(from bundle: Bundle = .main) -> CaseTemplate? {
        func layer(_ name: String) -> CGImage? {
            let url = bundle.url(forResource: name, withExtension: "png")
                ?? bundle.url(forResource: name, withExtension: "png", subdirectory: "Case")
            return url.flatMap(CaseArt.loadImage)
        }
        guard let base = layer("case-base"), let shade = layer("case-shade"), let glare = layer("case-glare") else {
            return nil
        }
        return CaseTemplate(base: base, shade: shade, glare: glare)
    }
}

/// Room baked around each rendered case for its drop shadow, as fractions of the case's width.
nonisolated struct CaseMargins: Sendable {
    let side: CGFloat
    let top: CGFloat
    let bottom: CGFloat

    static let shadow = CaseMargins(side: 0.16, top: 0.06, bottom: 0.3)
}

/// Prints each film's cover and builds its case. Plain Core Graphics, so it runs off the main thread.
/// Every context here is flipped to y-down, like UIKit, so the geometry reads top to bottom.
nonisolated enum CaseArt {
    /// Pixel width of a rendered case (not counting the shadow margin).
    static let renderWidth: CGFloat = 440
    /// Side of the square cover, in pixels, before it's laid into the insert.
    static let coverSide: CGFloat = 600

    static func loadImage(_ url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    static func render(_ movie: Movie, poster: CGImage, template: CaseTemplate) -> CGImage? {
        let width = renderWidth
        let height = (width * CaseTemplate.aspect).rounded()
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        guard let cover = coverArt(for: movie, poster: poster),
              let g = canvas(CGSize(width: width, height: height)) else { return nil }

        func point(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * width, y: p.y * height) }
        let tl = point(CaseTemplate.insertTopLeft)
        let tr = point(CaseTemplate.insertTopRight)
        let bl = point(CaseTemplate.insertBottomLeft)
        let br = point(CaseTemplate.insertBottomRight)

        g.saveGState()
        g.addLines(between: [tl, tr, br, bl])
        g.closePath()
        g.clip()
        let side = coverSide
        g.concatenate(CGAffineTransform(a: (tr.x - tl.x) / side, b: (tr.y - tl.y) / side,
                                        c: (bl.x - tl.x) / side, d: (bl.y - tl.y) / side,
                                        tx: tl.x, ty: tl.y))
        draw(cover, in: CGRect(x: 0, y: 0, width: side, height: side), on: g)
        g.restoreGState()

        draw(template.shade, in: rect, on: g)
        g.setBlendMode(.screen)
        draw(template.glare, in: rect, on: g)
        g.setBlendMode(.normal)
        draw(template.base, in: rect, on: g)
        guard let bare = g.makeImage() else { return nil }

        let margins = CaseMargins.shadow
        let size = CGSize(width: width * (1 + margins.side * 2), height: height + width * (margins.top + margins.bottom))
        guard let shadowed = canvas(size) else { return nil }
        // Shadow offsets live in the bitmap's own y-up space, so "down the screen" is negative.
        shadowed.setShadow(offset: CGSize(width: 0, height: -width * 0.1), blur: width * 0.12,
                           color: CGColor(gray: 0, alpha: 0.45))
        draw(bare, in: CGRect(x: width * margins.side, y: width * margins.top, width: width, height: height), on: shadowed)
        return shadowed.makeImage()
    }

    /// The insert is square and posters are 2:3, so the poster keeps its full height on the right
    /// two thirds and the third by the hinge becomes a printed panel in the poster's own colours:
    /// the title on its side, and the year.
    static func coverArt(for movie: Movie, poster: CGImage) -> CGImage? {
        let side = coverSide
        let panel = side / 3
        guard let g = canvas(CGSize(width: side, height: side)) else { return nil }

        // A wash of the poster's left half: shrunk to a few pixels, then stretched back out.
        if let tiny = canvas(CGSize(width: 3, height: 9)) {
            tiny.interpolationQuality = .medium
            draw(poster, in: CGRect(x: 0, y: 0, width: 6, height: 9), on: tiny)
            if let wash = tiny.makeImage() {
                draw(wash, in: CGRect(x: -60, y: -60, width: panel + 120, height: side + 120), on: g)
            }
        }
        g.setFillColor(CGColor(gray: 0.025, alpha: 0.58))
        g.fill(CGRect(x: 0, y: 0, width: panel, height: side))

        // The whole poster, filling its 2:3 box from the top.
        let box = CGRect(x: panel, y: 0, width: side - panel, height: side)
        let posterSize = CGSize(width: poster.width, height: poster.height)
        let scale = max(box.width / posterSize.width, box.height / posterSize.height)
        let drawn = CGSize(width: posterSize.width * scale, height: posterSize.height * scale)
        g.saveGState()
        g.clip(to: box)
        draw(poster, in: CGRect(x: box.midX - drawn.width / 2, y: 0, width: drawn.width, height: drawn.height), on: g)
        g.restoreGState()

        g.setFillColor(CGColor(gray: 0, alpha: 0.45))
        g.fill(CGRect(x: panel, y: 0, width: 2, height: side))
        g.setFillColor(CGColor(gray: 1, alpha: 0.13))
        g.fill(CGRect(x: panel - 1.5, y: 0, width: 1.5, height: side))

        g.setFillColor(CGColor(gray: 0.96, alpha: 0.7))
        draw(TextLine(String(movie.year), font: .rounded(22, .bold)), on: g, centeredAt: CGPoint(x: panel / 2, y: side - 42))

        g.setFillColor(CGColor(gray: 0.96, alpha: 1))
        drawSpineTitle(movie.title.uppercased(), on: g, center: CGPoint(x: panel / 2 + 2, y: side / 2 - 18), length: side * 0.7)
        return g.makeImage()
    }

    /// The title set on its side, reading bottom to top; long titles break onto two lines.
    private static func drawSpineTitle(_ title: String, on g: CGContext, center: CGPoint, length: CGFloat) {
        func line(_ text: String, _ size: CGFloat) -> TextLine { TextLine(text, font: .rounded(size, .heavy), kern: 3) }

        var size: CGFloat = 42
        var lines = [title]
        let single = line(title, size).width
        if single > length {
            let split = balancedSplit(title) { line($0, size).width }
            let widest = split.map { line($0, size).width }.max() ?? single
            size = split.count > 1 ? min(38, size * length / widest) : size * length / widest
            lines = split
        }

        g.saveGState()
        g.translateBy(x: center.x, y: center.y)
        g.rotate(by: -.pi / 2)
        let lineHeight = size * 1.08
        for (index, text) in lines.enumerated() {
            let offset = (CGFloat(index) - CGFloat(lines.count - 1) / 2) * lineHeight
            draw(line(text, size), on: g, centeredAt: CGPoint(x: 0, y: offset))
        }
        g.restoreGState()
    }

    /// Splits at the space that makes the two lines most even.
    private static func balancedSplit(_ text: String, width: (String) -> CGFloat) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        guard words.count > 1 else { return [text] }
        var best = [text]
        var bestWidth = CGFloat.infinity
        for cut in 1..<words.count {
            let first = words[..<cut].joined(separator: " ")
            let second = words[cut...].joined(separator: " ")
            let widest = max(width(first), width(second))
            if widest < bestWidth {
                bestWidth = widest
                best = [first, second]
            }
        }
        return best
    }

    /// Side of the grid of colours sampled from each poster for the backdrop.
    static let swatchGrid = 4

    /// A grid of the poster's colours, row by row from the top, lifted in saturation and kept
    /// dark enough for white type, for the full-screen backdrop.
    static func swatches(of poster: CGImage) -> [RGB] {
        let side = swatchGrid
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drew = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                                          space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.interpolationQuality = .medium
            context.draw(poster, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drew else { return [] }
        return (0..<side * side).map { index in
            let (hue, saturation, brightness) = hsb(red: Double(pixels[index * 4]) / 255,
                                                    green: Double(pixels[index * 4 + 1]) / 255,
                                                    blue: Double(pixels[index * 4 + 2]) / 255)
            return rgb(hue: hue, saturation: min(1, saturation * 1.25 + 0.08), brightness: min(max(brightness * 0.78, 0.16), 0.52))
        }
    }

    private static func rgb(hue: Double, saturation: Double, brightness: Double) -> RGB {
        let sector = (hue * 6).truncatingRemainder(dividingBy: 6)
        let chroma = brightness * saturation
        let x = chroma * (1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1))
        let (r, g, b): (Double, Double, Double)
        switch Int(sector) {
        case 0: (r, g, b) = (chroma, x, 0)
        case 1: (r, g, b) = (x, chroma, 0)
        case 2: (r, g, b) = (0, chroma, x)
        case 3: (r, g, b) = (0, x, chroma)
        case 4: (r, g, b) = (x, 0, chroma)
        default: (r, g, b) = (chroma, 0, x)
        }
        let m = brightness - chroma
        return RGB(red: r + m, green: g + m, blue: b + m)
    }

    private static func hsb(red: Double, green: Double, blue: Double) -> (Double, Double, Double) {
        let high = max(red, green, blue)
        let low = min(red, green, blue)
        let chroma = high - low
        var hue = 0.0
        if chroma > 0 {
            if high == red {
                hue = ((green - blue) / chroma).truncatingRemainder(dividingBy: 6)
            } else if high == green {
                hue = (blue - red) / chroma + 2
            } else {
                hue = (red - green) / chroma + 4
            }
            hue /= 6
            if hue < 0 { hue += 1 }
        }
        return (hue, high == 0 ? 0 : chroma / high, high)
    }

    /// A transparent sRGB bitmap, flipped so y grows downward.
    private static func canvas(_ size: CGSize) -> CGContext? {
        let height = size.height.rounded()
        guard let context = CGContext(data: nil, width: Int(size.width.rounded()), height: Int(height),
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1, y: -1)
        context.interpolationQuality = .high
        return context
    }

    /// Draws an image upright into a y-down context.
    private static func draw(_ image: CGImage, in rect: CGRect, on g: CGContext) {
        g.saveGState()
        g.translateBy(x: rect.minX, y: rect.maxY)
        g.scaleBy(x: 1, y: -1)
        g.draw(image, in: CGRect(origin: .zero, size: rect.size))
        g.restoreGState()
    }

    /// Draws a line of text centred on `point`, in the context's fill colour.
    private static func draw(_ text: TextLine, on g: CGContext, centeredAt point: CGPoint) {
        g.saveGState()
        g.textMatrix = .identity
        g.translateBy(x: point.x - text.width / 2, y: point.y + (text.ascent - text.descent) / 2)
        g.scaleBy(x: 1, y: -1)
        g.textPosition = .zero
        CTLineDraw(text.line, g)
        g.restoreGState()
    }
}

/// One line of Core Text, measured.
nonisolated struct TextLine {
    let line: CTLine
    let width: CGFloat
    let ascent: CGFloat
    let descent: CGFloat

    init(_ text: String, font: UIFont, kern: CGFloat = 0) {
        // UIFont is toll-free bridged to CTFont, and these keys are the ones Core Text reads.
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: kern,
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
        self.ascent = ascent
        self.descent = descent
    }
}

extension UIFont {
    /// SF Pro Rounded at the given size and weight.
    nonisolated static func rounded(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
        let system = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = system.fontDescriptor.withDesign(.rounded) else { return system }
        return UIFont(descriptor: descriptor, size: size)
    }
}
