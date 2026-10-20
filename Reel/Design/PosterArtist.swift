import SwiftUI

/// Paints a minimalist alternative poster for a film: one graphic motif in the
/// film's palette, varied by a stable per-film seed. Pure drawing code, so it
/// runs wherever SwiftUI chooses to render a `Canvas`.
nonisolated enum PosterArtist {
    struct Inks {
        let base: Color
        let accent: Color
        let ink: Color
        let accentIsDark: Bool

        init(movie: Movie) {
            base = movie.base
            accent = movie.accent
            ink = movie.ink
            accentIsDark = Color.luminance(hex: movie.palette[1]) < 0.2
        }

        /// The accent, unless it's too dark to read as light (e.g. a black monolith).
        var vivid: Color { accentIsDark ? base.mix(with: .white, by: 0.2) : accent }
    }

    struct Geo {
        let w: CGFloat
        let h: CGFloat
        var m: CGFloat { min(w, h) }

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: w * x, y: h * y) }

        func disc(_ center: CGPoint, _ radius: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }

        func hairline(_ scale: CGFloat = 1) -> CGFloat { max(0.6, m * 0.0035 * scale) }
    }

    static func paint(_ ctx: inout GraphicsContext, size: CGSize, motif: Motif, inks: Inks, seed: UInt64) {
        guard size.width > 0, size.height > 0 else { return }
        let g = Geo(w: size.width, h: size.height)
        var rng = SplitMix64(seed: seed)

        let backdrop = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [
                inks.base.mix(with: .white, by: 0.12),
                inks.base,
                inks.base.mix(with: .black, by: 0.38),
            ]),
            startPoint: CGPoint(x: g.w * 0.2, y: 0),
            endPoint: CGPoint(x: g.w * 0.8, y: g.h)
        )
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: backdrop)

        switch motif {
        case .sun: sun(&ctx, g, inks, backdrop, &rng)
        case .orbit: orbit(&ctx, g, inks, &rng)
        case .monolith: monolith(&ctx, g, inks, &rng)
        case .horizon: horizon(&ctx, g, inks, &rng)
        case .grid: grid(&ctx, g, inks)
        case .rain: rain(&ctx, g, inks, &rng)
        case .rings: rings(&ctx, g, inks, &rng)
        case .split: split(&ctx, g, inks, &rng)
        case .stairs: stairs(&ctx, g, inks)
        case .bloom: bloom(&ctx, g, inks, &rng)
        case .wave: wave(&ctx, g, inks, &rng)
        case .eye: eye(&ctx, g, inks)
        case .arch: arch(&ctx, g, inks)
        case .shards: shards(&ctx, g, inks, &rng)
        case .stripes: stripes(&ctx, g, inks, &rng)
        case .spiral: spiral(&ctx, g, inks, &rng)
        case .halftone: halftone(&ctx, g, inks, &rng)
        case .burst: burst(&ctx, g, inks, &rng)
        }
    }

    // MARK: - Motifs

    private static func sun(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ backdrop: GraphicsContext.Shading, _ rng: inout SplitMix64) {
        let r = g.m * 0.30
        let c = g.pt(0.5, CGFloat(rng.range(0.38, 0.45)))
        ctx.fill(g.disc(c, r * 2.2), with: .radialGradient(
            Gradient(colors: [k.vivid.opacity(0.5), k.vivid.opacity(0)]),
            center: c, startRadius: r * 0.5, endRadius: r * 2.2))
        let disc = g.disc(c, r)
        ctx.fill(disc, with: .linearGradient(
            Gradient(colors: [k.ink, k.accent]),
            startPoint: CGPoint(x: c.x, y: c.y - r), endPoint: CGPoint(x: c.x, y: c.y + r)))

        var bands = ctx
        bands.clip(to: disc)
        var y = c.y + r * 0.08
        var thickness = r * 0.045
        for _ in 0..<6 {
            bands.fill(Path(CGRect(x: c.x - r, y: y, width: r * 2, height: thickness)), with: backdrop)
            y += thickness + r * 0.1
            thickness *= 1.45
        }
    }

    private static func orbit(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        var stars = Path()
        for _ in 0..<46 {
            let p = g.pt(CGFloat(rng.unit()), CGFloat(rng.range(0, 0.78)))
            let s = g.m * CGFloat(rng.range(0.003, 0.009))
            stars.addEllipse(in: CGRect(x: p.x - s, y: p.y - s, width: s * 2, height: s * 2))
        }
        ctx.fill(stars, with: .color(k.ink.opacity(0.55)))

        let c = g.pt(0.5, 0.42)
        var tilted = ctx
        tilted.translateBy(x: c.x, y: c.y)
        tilted.rotate(by: .degrees(rng.range(-28, -8)))
        for i in 0..<3 {
            let rx = g.m * (0.24 + 0.1 * CGFloat(i))
            let ry = rx * 0.36
            tilted.stroke(
                Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2)),
                with: .color(k.ink.opacity(0.42 - 0.1 * Double(i))),
                lineWidth: g.hairline(1.2))
        }
        let angle = rng.range(0, 2 * .pi)
        let moonRX = g.m * 0.44
        let moonRY = moonRX * 0.36
        tilted.fill(g.disc(CGPoint(x: CGFloat(cos(angle)) * moonRX, y: CGFloat(sin(angle)) * moonRY), g.m * 0.028), with: .color(k.ink))

        let pr = g.m * 0.13
        ctx.fill(g.disc(c, pr * 2.4), with: .radialGradient(
            Gradient(colors: [k.vivid.opacity(0.35), k.vivid.opacity(0)]),
            center: c, startRadius: pr, endRadius: pr * 2.4))
        ctx.fill(g.disc(c, pr), with: .radialGradient(
            Gradient(colors: [k.ink, k.vivid, k.vivid.mix(with: .black, by: 0.55)]),
            center: CGPoint(x: c.x - pr * 0.45, y: c.y - pr * 0.45), startRadius: 0, endRadius: pr * 1.7))
    }

    private static func monolith(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let horizon = g.h * 0.7
        ctx.fill(Path(CGRect(x: 0, y: horizon, width: g.w, height: g.h - horizon)), with: .color(.black.opacity(0.18)))
        ctx.stroke(line(from: CGPoint(x: 0, y: horizon), to: CGPoint(x: g.w, y: horizon)),
                   with: .color(k.accent.opacity(0.35)), lineWidth: g.hairline())

        let sunCenter = g.pt(CGFloat(rng.range(0.4, 0.6)), 0.17)
        ctx.fill(g.disc(sunCenter, g.m * 0.17), with: .radialGradient(
            Gradient(colors: [k.ink.opacity(0.3), k.ink.opacity(0)]),
            center: sunCenter, startRadius: 0, endRadius: g.m * 0.17))
        ctx.fill(g.disc(sunCenter, g.m * 0.03), with: .color(k.ink.opacity(0.9)))

        let slabW = g.m * 0.17
        let slabH = g.h * 0.44
        let slab = CGRect(x: g.w * 0.5 - slabW / 2, y: horizon + g.h * 0.03 - slabH, width: slabW, height: slabH)
        var shadow = Path()
        shadow.move(to: CGPoint(x: slab.minX, y: slab.maxY))
        shadow.addLine(to: CGPoint(x: slab.maxX, y: slab.maxY))
        shadow.addLine(to: CGPoint(x: g.w * 0.98, y: g.h))
        shadow.addLine(to: CGPoint(x: g.w * 0.62, y: g.h))
        shadow.closeSubpath()
        ctx.fill(shadow, with: .color(.black.opacity(0.26)))
        ctx.fill(Path(slab), with: .linearGradient(
            Gradient(colors: [k.accent.mix(with: .white, by: 0.1), k.accent]),
            startPoint: CGPoint(x: slab.minX, y: slab.minY), endPoint: CGPoint(x: slab.maxX, y: slab.maxY)))
        ctx.fill(Path(CGRect(x: slab.minX, y: slab.minY, width: slabW * 0.12, height: slabH)), with: .color(.white.opacity(0.1)))
    }

    private static func horizon(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let hy = g.h * CGFloat(rng.range(0.5, 0.58))
        ctx.fill(Path(CGRect(x: 0, y: 0, width: g.w, height: hy)), with: .linearGradient(
            Gradient(colors: [k.vivid.opacity(0), k.vivid.opacity(0.5), k.vivid.opacity(0.95)]),
            startPoint: CGPoint(x: 0, y: g.h * 0.08), endPoint: CGPoint(x: 0, y: hy)))

        let sunCenter = CGPoint(x: g.w * CGFloat(rng.range(0.3, 0.7)), y: hy)
        var sky = ctx
        sky.clip(to: Path(CGRect(x: 0, y: 0, width: g.w, height: hy)))
        sky.fill(g.disc(sunCenter, g.m * 0.16), with: .color(k.ink.opacity(0.92)))

        ctx.fill(Path(CGRect(x: 0, y: hy, width: g.w, height: g.h - hy)), with: .linearGradient(
            Gradient(colors: [k.base.mix(with: .black, by: 0.25), k.base.mix(with: .black, by: 0.7)]),
            startPoint: CGPoint(x: 0, y: hy), endPoint: CGPoint(x: 0, y: g.h)))

        var shimmer = Path()
        for i in 0..<6 {
            let y = hy + g.h * 0.028 * CGFloat(i + 1)
            let half = g.m * (0.15 - 0.02 * CGFloat(i))
            shimmer.move(to: CGPoint(x: sunCenter.x - half, y: y))
            shimmer.addLine(to: CGPoint(x: sunCenter.x + half, y: y))
        }
        ctx.stroke(shimmer, with: .color(k.ink.opacity(0.32)), lineWidth: g.hairline(1.1))
        ctx.stroke(line(from: CGPoint(x: 0, y: hy), to: CGPoint(x: g.w, y: hy)), with: .color(k.vivid), lineWidth: g.hairline(1.2))

        let fx = g.w * CGFloat(rng.range(0.18, 0.82))
        figure(&ctx, g, at: CGPoint(x: fx, y: hy), height: g.m * 0.07)
    }

    private static func grid(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks) {
        let vy = g.h * 0.47
        let vanishing = CGPoint(x: g.w * 0.5, y: vy)
        ctx.fill(g.disc(vanishing, g.m * 0.55), with: .radialGradient(
            Gradient(colors: [k.vivid.opacity(0.45), k.vivid.opacity(0)]),
            center: vanishing, startRadius: 0, endRadius: g.m * 0.55))

        var floor = ctx
        floor.clip(to: Path(CGRect(x: 0, y: vy, width: g.w, height: g.h - vy)))
        var lines = Path()
        for i in -9...9 {
            lines.move(to: vanishing)
            lines.addLine(to: CGPoint(x: g.w * 0.5 + CGFloat(i) * g.w * 0.17, y: g.h))
        }
        for j in 1...12 {
            let t = pow(CGFloat(j) / 12, 2.1)
            let y = vy + (g.h - vy) * t
            lines.move(to: CGPoint(x: 0, y: y))
            lines.addLine(to: CGPoint(x: g.w, y: y))
        }
        floor.stroke(lines, with: .color(k.accent.opacity(0.65)), lineWidth: g.hairline())
        ctx.stroke(line(from: CGPoint(x: 0, y: vy), to: CGPoint(x: g.w, y: vy)), with: .color(k.ink.opacity(0.85)), lineWidth: g.hairline(1.6))
    }

    private static func rain(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        var buckets = [Path(), Path(), Path()]
        let slant = CGFloat(rng.range(-0.14, 0.04))
        for _ in 0..<120 {
            let x = g.w * CGFloat(rng.range(-0.05, 1.05))
            let length = g.m * CGFloat(rng.range(0.04, 0.24))
            let y = g.h * CGFloat(rng.range(-0.1, 0.95))
            let roll = rng.unit()
            let bucket = roll < 0.6 ? 0 : (roll < 0.93 ? 1 : 2)
            buckets[bucket].move(to: CGPoint(x: x, y: y))
            buckets[bucket].addLine(to: CGPoint(x: x + length * slant, y: y + length))
        }
        let style = StrokeStyle(lineWidth: g.hairline(1.2), lineCap: .round)
        ctx.stroke(buckets[0], with: .color(k.accent.opacity(0.2)), style: style)
        ctx.stroke(buckets[1], with: .color(k.accent.opacity(0.5)), style: style)
        ctx.stroke(buckets[2], with: .color(k.ink.opacity(0.85)), style: style)
    }

    private static func rings(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let c = g.pt(CGFloat(rng.range(0.42, 0.58)), CGFloat(rng.range(0.36, 0.44)))
        for i in 0..<10 {
            let r = g.m * (0.04 + 0.046 * CGFloat(i))
            let heavy = i % 3 == 1
            ctx.stroke(g.disc(c, r), with: .color(k.accent.opacity(1 - Double(i) * 0.075)),
                       lineWidth: g.m * (heavy ? 0.014 : 0.004))
        }
        ctx.fill(g.disc(c, g.m * 0.022), with: .color(k.ink))
    }

    private static func split(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let c = g.pt(0.5, 0.42)
        let r = g.m * 0.28
        let tilt = g.h * CGFloat(rng.range(0.1, 0.22))
        var lower = Path()
        lower.move(to: CGPoint(x: 0, y: c.y + tilt))
        lower.addLine(to: CGPoint(x: g.w, y: c.y - tilt))
        lower.addLine(to: CGPoint(x: g.w, y: g.h))
        lower.addLine(to: CGPoint(x: 0, y: g.h))
        lower.closeSubpath()
        ctx.fill(lower, with: .color(k.accent))

        let disc = g.disc(c, r)
        var inside = ctx
        inside.clip(to: disc)
        inside.fill(Path(CGRect(x: 0, y: 0, width: g.w, height: g.h)), with: .color(k.ink))
        inside.fill(lower, with: .color(k.base.mix(with: .black, by: 0.2)))
        ctx.stroke(disc, with: .color(k.ink), lineWidth: g.m * 0.008)
    }

    private static func stairs(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks) {
        let light = g.pt(0.86, 0.06)
        ctx.fill(g.disc(light, g.m * 0.7), with: .radialGradient(
            Gradient(colors: [k.ink.opacity(0.28), k.ink.opacity(0)]),
            center: light, startRadius: 0, endRadius: g.m * 0.7))

        let steps = 7
        let run = g.w / CGFloat(steps)
        let rise = g.h * 0.062
        let floorY = g.h * 0.82
        var body = Path()
        var treads = Path()
        body.move(to: CGPoint(x: 0, y: g.h))
        for i in 0..<steps {
            let y = floorY - rise * CGFloat(i)
            body.addLine(to: CGPoint(x: run * CGFloat(i), y: y))
            body.addLine(to: CGPoint(x: run * CGFloat(i + 1), y: y))
            treads.move(to: CGPoint(x: run * CGFloat(i), y: y))
            treads.addLine(to: CGPoint(x: run * CGFloat(i + 1), y: y))
        }
        body.addLine(to: CGPoint(x: g.w, y: g.h))
        body.closeSubpath()
        ctx.fill(body, with: .linearGradient(
            Gradient(colors: [k.accent, k.accent.mix(with: .black, by: 0.45)]),
            startPoint: CGPoint(x: g.w, y: floorY - rise * CGFloat(steps)), endPoint: CGPoint(x: 0, y: g.h)))
        ctx.stroke(treads, with: .color(k.ink.opacity(0.45)), lineWidth: g.hairline(1.2))
        figure(&ctx, g, at: CGPoint(x: run * 4.5, y: floorY - rise * 4), height: g.m * 0.08)
    }

    private static func bloom(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let c = g.pt(0.5, 0.41)
        let petals = 6 + Int(rng.unit() * 5)
        let spin = rng.range(0, .pi)
        for layer in 0..<2 {
            let length = g.m * (layer == 0 ? 0.31 : 0.19)
            let width = length * 0.42
            let color = layer == 0 ? k.vivid.opacity(0.85) : k.vivid.mix(with: k.ink, by: 0.45)
            let offset = layer == 0 ? 0 : Double.pi / Double(petals)
            for i in 0..<petals {
                var petal = ctx
                petal.translateBy(x: c.x, y: c.y)
                petal.rotate(by: .radians(spin + offset + Double(i) / Double(petals) * 2 * .pi))
                petal.fill(Path(ellipseIn: CGRect(x: -width / 2, y: -length, width: width, height: length)), with: .color(color))
            }
        }
        ctx.fill(g.disc(c, g.m * 0.055), with: .color(k.ink))
    }

    private static func wave(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let moon = g.pt(CGFloat(rng.range(0.25, 0.75)), CGFloat(rng.range(0.15, 0.23)))
        ctx.fill(g.disc(moon, g.m * 0.2), with: .radialGradient(
            Gradient(colors: [k.ink.opacity(0.25), k.ink.opacity(0)]),
            center: moon, startRadius: 0, endRadius: g.m * 0.2))
        ctx.fill(g.disc(moon, g.m * 0.07), with: .color(k.ink.opacity(0.92)))

        let bands = 6
        let deep = k.base.mix(with: .black, by: 0.5)
        for i in 0..<bands {
            let baseY = g.h * (0.38 + 0.08 * CGFloat(i))
            let amplitude = g.m * (0.02 + 0.012 * CGFloat(i))
            let frequency = rng.range(1.1, 2.2)
            let phase = rng.range(0, 2 * .pi)
            var path = Path()
            path.move(to: CGPoint(x: 0, y: g.h))
            let samples = 48
            for s in 0...samples {
                let t = Double(s) / Double(samples)
                let x = g.w * CGFloat(t)
                let y = baseY + CGFloat(sin(t * frequency * 2 * .pi + phase)) * amplitude
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: g.w, y: g.h))
            path.closeSubpath()
            ctx.fill(path, with: .color(k.vivid.mix(with: deep, by: Double(i) / Double(bands - 1))))
        }
    }

    private static func eye(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks) {
        let c = g.pt(0.5, 0.42)
        let eyeWidth = g.m * 0.8
        let eyeHeight = g.m * 0.4
        var almond = Path()
        almond.move(to: CGPoint(x: c.x - eyeWidth / 2, y: c.y))
        almond.addQuadCurve(to: CGPoint(x: c.x + eyeWidth / 2, y: c.y), control: CGPoint(x: c.x, y: c.y - eyeHeight))
        almond.addQuadCurve(to: CGPoint(x: c.x - eyeWidth / 2, y: c.y), control: CGPoint(x: c.x, y: c.y + eyeHeight))
        almond.closeSubpath()

        var lashes = Path()
        for i in 0..<13 {
            let a = Double.pi * (1.12 + 0.76 * Double(i) / 12)
            let inner = eyeHeight * 0.62
            let outer = eyeHeight * (i % 2 == 0 ? 1.0 : 0.85)
            lashes.move(to: CGPoint(x: c.x + CGFloat(cos(a)) * inner * 1.45, y: c.y + CGFloat(sin(a)) * inner))
            lashes.addLine(to: CGPoint(x: c.x + CGFloat(cos(a)) * outer * 1.45, y: c.y + CGFloat(sin(a)) * outer))
        }
        ctx.stroke(lashes, with: .color(k.ink.opacity(0.7)), style: StrokeStyle(lineWidth: g.m * 0.007, lineCap: .round))

        ctx.fill(almond, with: .color(k.ink.opacity(0.95)))
        var iris = ctx
        iris.clip(to: almond)
        let ir = eyeHeight * 0.46
        iris.fill(g.disc(c, ir), with: .radialGradient(
            Gradient(colors: [k.vivid.mix(with: .white, by: 0.25), k.vivid, k.vivid.mix(with: .black, by: 0.5)]),
            center: c, startRadius: 0, endRadius: ir))
        iris.fill(g.disc(c, ir * 0.42), with: .color(.black))
        iris.fill(g.disc(CGPoint(x: c.x + ir * 0.3, y: c.y - ir * 0.3), ir * 0.14), with: .color(.white.opacity(0.85)))
        ctx.stroke(almond, with: .color(k.vivid.opacity(0.6)), lineWidth: g.hairline(1.2))
    }

    private static func arch(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks) {
        let archWidth = g.m * 0.46
        let archHeight = g.h * 0.46
        let floorY = g.h * 0.72
        let opening = CGRect(x: g.w * 0.5 - archWidth / 2, y: floorY - archHeight, width: archWidth, height: archHeight)

        var spill = Path()
        spill.move(to: CGPoint(x: opening.minX, y: floorY))
        spill.addLine(to: CGPoint(x: opening.maxX, y: floorY))
        spill.addLine(to: CGPoint(x: g.w * 0.98, y: g.h))
        spill.addLine(to: CGPoint(x: g.w * 0.02, y: g.h))
        spill.closeSubpath()
        ctx.fill(spill, with: .linearGradient(
            Gradient(colors: [k.vivid.opacity(0.55), k.vivid.opacity(0)]),
            startPoint: CGPoint(x: 0, y: floorY), endPoint: CGPoint(x: 0, y: g.h)))

        let border = g.m * 0.035
        let frame = CGRect(x: opening.minX - border, y: opening.minY - border, width: archWidth + border * 2, height: archHeight + border)
        ctx.fill(archPath(frame), with: .color(k.base.mix(with: .black, by: 0.45)))
        ctx.fill(archPath(opening), with: .linearGradient(
            Gradient(colors: [k.ink, k.vivid]),
            startPoint: CGPoint(x: 0, y: opening.minY), endPoint: CGPoint(x: 0, y: opening.maxY)))
        ctx.stroke(line(from: CGPoint(x: 0, y: floorY), to: CGPoint(x: g.w, y: floorY)), with: .color(k.ink.opacity(0.25)), lineWidth: g.hairline())
        figure(&ctx, g, at: CGPoint(x: opening.midX, y: floorY), height: archHeight * 0.3)
    }

    private static func shards(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        for i in 0..<10 {
            let c = g.pt(CGFloat(rng.range(0.1, 0.9)), CGFloat(rng.range(0.08, 0.72)))
            let size = g.m * CGFloat(rng.range(0.07, 0.3))
            let rotation = rng.range(0, 2 * .pi)
            var triangle = Path()
            for vertex in 0..<3 {
                let angle = rotation + Double(vertex) * 2.0944 + rng.range(-0.4, 0.4)
                let reach = size * CGFloat(rng.range(0.6, 1.0))
                let p = CGPoint(x: c.x + CGFloat(cos(angle)) * reach, y: c.y + CGFloat(sin(angle)) * reach)
                if vertex == 0 { triangle.move(to: p) } else { triangle.addLine(to: p) }
            }
            triangle.closeSubpath()
            let color = i % 3 == 0 ? k.ink : k.accent
            ctx.fill(triangle, with: .color(color.opacity(rng.range(0.35, 0.95))))
        }
    }

    private static func stripes(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let count = 2 * Int(rng.range(3, 6)) + 1
        let width = g.w / CGFloat(count)
        var bars = Path()
        for i in stride(from: 0, to: count, by: 2) {
            bars.addRect(CGRect(x: width * CGFloat(i), y: 0, width: width, height: g.h))
        }
        ctx.fill(bars, with: .color(k.accent.opacity(0.88)))
        let c = g.pt(0.5, 0.4)
        let r = g.m * 0.2
        ctx.fill(g.disc(c, r * 1.1), with: .color(k.base))
        ctx.fill(g.disc(c, r), with: .color(k.ink))
    }

    private static func spiral(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let c = g.pt(0.5, 0.42)
        let turns = rng.range(4.5, 6.5)
        let maxRadius = g.m * 0.42
        let phase = rng.range(0, 2 * .pi)
        var path = Path()
        let steps = 420
        for s in 0...steps {
            let t = Double(s) / Double(steps)
            let theta = t * turns * 2 * .pi + phase
            let r = maxRadius * CGFloat(t)
            let p = CGPoint(x: c.x + CGFloat(cos(theta)) * r, y: c.y + CGFloat(sin(theta)) * r)
            if s == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        ctx.stroke(path, with: .color(k.accent), style: StrokeStyle(lineWidth: g.m * 0.014, lineCap: .round, lineJoin: .round))
    }

    private static func halftone(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let focus = g.pt(CGFloat(rng.range(0.3, 0.7)), CGFloat(rng.range(0.25, 0.5)))
        let step = g.m * 0.058
        var dots = Path()
        var row = 0
        var y = step / 2
        while y < g.h * 0.82 {
            var x = step / 2 + (row % 2 == 0 ? 0 : step / 2)
            while x < g.w {
                let dx = x - focus.x
                let dy = y - focus.y
                let falloff = sqrt(dx * dx + dy * dy) / (g.m * 0.62)
                let radius = step * 0.5 * (1 - falloff)
                if radius > step * 0.06 {
                    dots.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                }
                x += step
            }
            y += step * 0.87
            row += 1
        }
        ctx.fill(dots, with: .color(k.accent))
    }

    private static func burst(_ ctx: inout GraphicsContext, _ g: Geo, _ k: Inks, _ rng: inout SplitMix64) {
        let c = g.pt(0.5, CGFloat(rng.range(0.36, 0.44)))
        let rays = 56
        var path = Path()
        for i in 0..<rays {
            let angle = Double(i) / Double(rays) * 2 * .pi
            let reach = g.m * CGFloat(i % 2 == 0 ? 0.5 : rng.range(0.24, 0.38))
            let inner = g.m * 0.09
            path.move(to: CGPoint(x: c.x + CGFloat(cos(angle)) * inner, y: c.y + CGFloat(sin(angle)) * inner))
            path.addLine(to: CGPoint(x: c.x + CGFloat(cos(angle)) * reach, y: c.y + CGFloat(sin(angle)) * reach))
        }
        ctx.stroke(path, with: .color(k.vivid.opacity(0.9)), style: StrokeStyle(lineWidth: g.m * 0.007, lineCap: .round))
        ctx.fill(g.disc(c, g.m * 0.06), with: .color(k.ink))
        ctx.stroke(g.disc(c, g.m * 0.085), with: .color(k.vivid), lineWidth: g.hairline(1.4))
    }

    // MARK: - Helpers

    private static func line(from start: CGPoint, to end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }

    private static func archPath(_ rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            topLeadingRadius: rect.width / 2,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: rect.width / 2,
            style: .circular
        ).path(in: rect)
    }

    /// A tiny standing silhouette whose feet are at `feet`.
    private static func figure(_ ctx: inout GraphicsContext, _ g: Geo, at feet: CGPoint, height: CGFloat) {
        let bodyHeight = height * 0.78
        let head = height * 0.13
        let silhouette = Color.black.opacity(0.85)
        ctx.fill(Path(roundedRect: CGRect(x: feet.x - height * 0.12, y: feet.y - bodyHeight, width: height * 0.24, height: bodyHeight),
                      cornerRadius: height * 0.08), with: .color(silhouette))
        ctx.fill(g.disc(CGPoint(x: feet.x, y: feet.y - bodyHeight - head), head), with: .color(silhouette))
    }
}
