import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double // Kept for compatibility; no outline is drawn.
    let isCharging: Bool

    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []

    private let sectorCount = 6
    private let disconnectTotal: TimeInterval = 3.0
    private let sectorDuration: TimeInterval = 0.6
    private let sectorStartStep: TimeInterval = 0.48 // next starts when previous is 80% gone

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let now = context.date
            let disconnectElapsed = disconnectStart.map { now.timeIntervalSince($0) }
            let logoHeight: CGFloat = 181.0
            let logoWidth: CGFloat = logoHeight * 814.0 / 1000.0

            GeometryReader { geo in
                ZStack {
                    AppleLogoFill(
                        progress: clampedProgress,
                        time: now.timeIntervalSinceReferenceDate,
                        disconnectElapsed: disconnectElapsed,
                        disconnectOrder: disconnectOrder,
                        sectorCount: sectorCount,
                        sectorDuration: sectorDuration,
                        sectorStartStep: sectorStartStep,
                        disconnectTotal: disconnectTotal
                    )
                    .frame(width: logoWidth, height: logoHeight)

                    PlantParticleField(
                        progress: clampedProgress,
                        time: now.timeIntervalSinceReferenceDate,
                        active: isCharging && disconnectElapsed == nil,
                        logoWidth: logoWidth,
                        logoHeight: logoHeight
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                if !isCharging && disconnectStart == nil {
                    beginDisconnect(at: now)
                }
            }
            .onChange(of: isCharging) { _, charging in
                if charging {
                    disconnectStart = nil
                    disconnectOrder = []
                } else if disconnectStart == nil {
                    beginDisconnect(at: now)
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    private var clampedProgress: Double {
        min(1.0, max(0.0, progress))
    }

    private func beginDisconnect(at date: Date) {
        disconnectOrder = Array(0..<sectorCount).shuffled()
        disconnectStart = date
    }
}

// MARK: - Exact Apple logo fill

private struct AppleLogoFill: View {
    let progress: Double
    let time: TimeInterval
    let disconnectElapsed: TimeInterval?
    let disconnectOrder: [Int]
    let sectorCount: Int
    let sectorDuration: TimeInterval
    let sectorStartStep: TimeInterval
    let disconnectTotal: TimeInterval

    private struct SectorColor {
        let r: Double
        let g: Double
        let b: Double
    }

    private let colors: [SectorColor] = [
        SectorColor(r: 0.05, g: 0.42, b: 0.95),
        SectorColor(r: 0.39, g: 0.18, b: 0.78),
        SectorColor(r: 0.82, g: 0.05, b: 0.35),
        SectorColor(r: 0.98, g: 0.22, b: 0.10),
        SectorColor(r: 1.00, g: 0.52, b: 0.05),
        SectorColor(r: 0.42, g: 0.78, b: 0.12)
    ]

    var body: some View {
        GeometryReader { geo in
            let bodyTop = geo.size.height * 0.2443
            let bodyBottom = geo.size.height * 0.9999
            let bodyHeight = bodyBottom - bodyTop
            let bandHeight = bodyHeight / CGFloat(sectorCount)
            let scaled = progress * Double(sectorCount)
            let completed = min(sectorCount, Int(scaled.rounded(.down)))
            let currentFraction = scaled - Double(completed)
            let leafGrowth = leafProgress

            ZStack(alignment: .topLeading) {
                ForEach(Array(0..<sectorCount), id: \.self) { index in
                    let amount: CGFloat = index < completed
                        ? 1.0
                        : (index == completed
                           ? CGFloat(max(0, min(1, currentFraction)))
                           : 0.0)

                    let opacity = sectorOpacity(index)

                    if amount > 0 && opacity > 0 {
                        let bottomY = bodyBottom - CGFloat(index) * bandHeight
                        let fillHeight = max(0.01, bandHeight * amount)
                        let topY = bottomY - fillHeight
                        let isCurrent = index == completed && completed < sectorCount
                        let shimmer = 0.92 + 0.08 * sin(time * 1.15 + Double(index) * 0.83)
                        let base = colors[index]

                        ZStack {
                            if isCurrent {
                                WavingSectorTop(
                                    width: geo.size.width,
                                    height: fillHeight,
                                    amplitude: min(5.5, max(1.4, bandHeight * 0.11)),
                                    phase: time * 0.75 + Double(index) * 1.37
                                )
                                .fill(
                                    sectorGradient(base: base, shimmer: shimmer)
                                )
                            } else {
                                Rectangle()
                                    .fill(sectorGradient(base: base, shimmer: shimmer))
                            }
                        }
                        .frame(width: geo.size.width, height: fillHeight)
                        .position(
                            x: geo.size.width / 2,
                            y: (topY + bottomY) / 2
                        )
                        .opacity(opacity)
                    }
                }
            }
            .mask(AppleBodyShape())
            .overlay {
                LeafBudStem(progress: leafGrowth)
                    .opacity(stemOpacity)

                AppleLeafShape()
                    .fill(
                        Color(
                            red: colors.last!.r,
                            green: colors.last!.g,
                            blue: colors.last!.b
                        )
                    )
                    .scaleEffect(
                        max(0.035, leafGrowth),
                        anchor: UnitPoint(x: 0.51, y: 0.231)
                    )
                    .opacity(leafGrowth)
            }
        }
    }

    private func sectorGradient(
        base: SectorColor,
        shimmer: Double
    ) -> LinearGradient {
        let low = Color(
            red: min(1, base.r * (0.86 * shimmer)),
            green: min(1, base.g * (0.86 * shimmer)),
            blue: min(1, base.b * (0.86 * shimmer))
        )
        let mid = Color(
            red: min(1, base.r * (1.05 * shimmer)),
            green: min(1, base.g * (1.05 * shimmer)),
            blue: min(1, base.b * (1.05 * shimmer))
        )
        let high = Color(
            red: min(1, base.r * (0.94 * shimmer)),
            green: min(1, base.g * (0.94 * shimmer)),
            blue: min(1, base.b * (0.94 * shimmer))
        )

        return LinearGradient(
            stops: [
                .init(color: low, location: 0.0),
                .init(color: mid, location: 0.48),
                .init(color: high, location: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var leafProgress: Double {
        let normal = max(0, min(1, (progress - 0.88) / 0.12))
        guard let elapsed = disconnectElapsed else { return normal }
        if elapsed >= 3.0 { return 0 }
        return normal * max(0, 1.0 - elapsed / disconnectTotal)
    }

    private var stemOpacity: Double {
        let p = leafProgress
        return min(1.0, p / 0.20) * max(0, min(1, (1.0 - p) / 0.04))
    }

    private func sectorOpacity(_ index: Int) -> Double {
        guard let elapsed = disconnectElapsed else { return 1.0 }
        if elapsed >= disconnectTotal { return 0.0 }

        guard let position = disconnectOrder.firstIndex(of: index) else { return 1.0 }
        let start = Double(position) * sectorStartStep
        let end = start + sectorDuration

        if elapsed <= start { return 1.0 }
        if elapsed >= end { return 0.0 }

        let t = (elapsed - start) / sectorDuration
        if t <= 0.8 {
            let u = t / 0.8
            let eased = u * u * (3.0 - 2.0 * u)
            return 1.0 + (0.20 - 1.0) * eased
        } else {
            let u = (t - 0.8) / 0.2
            let eased = u * u * (3.0 - 2.0 * u)
            return 0.20 * (1.0 - eased)
        }
    }
}

// Only the top edge of the sector moves.
// The other three edges remain perfectly straight.
private struct WavingSectorTop: Shape {
    let width: CGFloat
    let height: CGFloat
    let amplitude: CGFloat
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let a = min(amplitude, max(0.8, height * 0.20))
        let y = rect.minY
        let x0 = rect.minX
        let x1 = rect.maxX
        let third = rect.width / 3.0

        path.move(
            to: CGPoint(
                x: x0,
                y: y + CGFloat(sin(phase)) * a * 0.35
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x0 + third,
                y: y + CGFloat(sin(phase + 1.9)) * a
            ),
            control1: CGPoint(
                x: x0 + third * 0.28,
                y: y + CGFloat(sin(phase + 0.7)) * a * 0.55
            ),
            control2: CGPoint(
                x: x0 + third * 0.72,
                y: y + CGFloat(sin(phase + 1.35)) * a * 1.15
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x0 + third * 2,
                y: y + CGFloat(sin(phase + 3.2)) * a * 0.72
            ),
            control1: CGPoint(
                x: x0 + third * 1.28,
                y: y + CGFloat(sin(phase + 2.35)) * a * 1.05
            ),
            control2: CGPoint(
                x: x0 + third * 1.72,
                y: y + CGFloat(sin(phase + 2.8)) * a * 0.35
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x1,
                y: y + CGFloat(sin(phase + 4.8)) * a * 0.35
            ),
            control1: CGPoint(
                x: x0 + third * 2.28,
                y: y + CGFloat(sin(phase + 3.8)) * a * 0.90
            ),
            control2: CGPoint(
                x: x0 + third * 2.70,
                y: y + CGFloat(sin(phase + 4.35)) * a * 0.55
            )
        )

        path.addLine(to: CGPoint(x: x1, y: rect.maxY))
        path.addLine(to: CGPoint(x: x0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct LeafBudStem: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let x = w * 0.515
            let baseY = h * 0.245
            let topY = baseY - h * 0.045 * progress

            Path { path in
                path.move(to: CGPoint(x: x, y: baseY))
                path.addCurve(
                    to: CGPoint(x: x + w * 0.025, y: topY),
                    control1: CGPoint(
                        x: x - w * 0.01,
                        y: baseY - h * 0.018
                    ),
                    control2: CGPoint(
                        x: x + w * 0.018,
                        y: topY + h * 0.012
                    )
                )
            }
            .stroke(
                Color(red: 0.42, green: 0.78, blue: 0.12),
                style: StrokeStyle(
                    lineWidth: max(1.0, w * 0.018),
                    lineCap: .round
                )
            )
        }
    }
}

// MARK: - Living plant stream

private struct PlantParticleField: View {
    let progress: Double
    let time: TimeInterval
    let active: Bool
    let logoWidth: CGFloat
    let logoHeight: CGFloat

    // Green currents + pollen + white/pink apple blossoms.
    private let particles: [PlantParticle] = PlantParticle.make222()

    var body: some View {
        Canvas { context, size in
            guard active && progress > 0.0 && progress < 1.0 else { return }

            // The stream exists below the logo. Its destination is exactly
            // the lower edge of the logo, never above it.
            let logoBottomY = size.height / 2.0 + logoHeight / 2.0
            let centerX = size.width / 2.0

            // The stream becomes increasingly concentrated toward the logo
            // during the last 8% of filling.
            let concentration = progress >= 0.92
                ? max(0.35, (1.0 - progress) / 0.08)
                : 1.0

            for particle in particles {
                let cycle = particle.kind == .stream ? 4.8 : 4.2
                let raw = (time / cycle + particle.phase)
                    .truncatingRemainder(dividingBy: 1.0)
                let t = raw < 0 ? raw + 1.0 : raw

                // Smooth upward flow.
                let eased = t * t * (3.0 - 2.0 * t)

                let startX = centerX
                    + particle.startX * size.width * 0.24
                let startY = size.height
                    * particle.startY

                // Targets sit just BELOW the physical logo boundary.
                // The final absorption happens over the last part of the path.
                let targetX = centerX
                    + particle.targetX * logoWidth * 0.34
                let targetY = logoBottomY - 0.8

                let currentX = startX
                    + (targetX - startX) * eased

                let streamSway = CGFloat(
                    sin(
                        time * particle.flowSpeed
                        + particle.seed
                        + Double(t) * .pi * 2.0
                    )
                )

                let x = currentX
                    + streamSway * particle.drift * concentration

                let y = startY
                    + (targetY - startY) * eased

                // Last part of the path is an absorption zone:
                // particles shrink/fade into the lower edge and never cross it.
                let absorbStart = 0.84
                let absorbT = t > absorbStart
                    ? min(1.0, (t - absorbStart) / 0.16)
                    : 0.0
                let absorbEase = absorbT * absorbT * (3.0 - 2.0 * absorbT)

                let edgePull = absorbEase * absorbEase
                let pulledX = x + (targetX - x) * edgePull
                let safeY = min(
                    logoBottomY - 0.35,
                    y + max(0, targetY - y) * edgePull
                )

                let flicker = 0.72
                    + 0.28 * sin(
                        time * particle.flickerSpeed
                        + particle.seed * 1.7
                    )

                let alpha = particle.opacity
                    * flicker
                    * max(0.0, 1.0 - absorbEase)

                let scale = particle.scale
                    * max(0.035, 1.0 - absorbEase * 0.90)

                guard alpha > 0.002 else { continue }

                context.opacity = alpha

                switch particle.kind {
                case .stream:
                    drawGreenCurrent(
                        &context,
                        particle: particle,
                        at: CGPoint(x: pulledX, y: safeY),
                        scale: scale,
                        time: time,
                        size: size
                    )

                case .flower:
                    drawFlower(
                        &context,
                        particle: particle,
                        at: CGPoint(x: pulledX, y: safeY),
                        scale: scale,
                        time: time
                    )

                case .pollen:
                    drawPollen(
                        &context,
                        particle: particle,
                        at: CGPoint(x: pulledX, y: safeY),
                        scale: scale,
                        time: time
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawGreenCurrent(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        at point: CGPoint,
        scale: CGFloat,
        time: TimeInterval,
        size: CGSize
    ) {
        var current = Path()
        current.move(to: CGPoint(
            x: point.x - particle.length * 0.48 * scale,
            y: point.y + particle.length * 0.22 * scale
        ))

        let bend = CGFloat(
            sin(time * 0.75 + particle.seed) * 7.0
        )

        current.addCurve(
            to: CGPoint(
                x: point.x + particle.length * 0.50 * scale,
                y: point.y - particle.length * 0.78 * scale
            ),
            control1: CGPoint(
                x: point.x - particle.length * 0.25 * scale + bend,
                y: point.y - particle.length * 0.18 * scale
            ),
            control2: CGPoint(
                x: point.x + particle.length * 0.30 * scale - bend * 0.5,
                y: point.y - particle.length * 0.52 * scale
            )
        )

        let glow = 0.72
            + 0.28 * sin(time * 1.4 + particle.seed)

        context.stroke(
            current,
            with: .color(
                Color(
                    red: 0.20,
                    green: min(1.0, 0.70 + 0.18 * glow),
                    blue: 0.16
                )
            ),
            style: StrokeStyle(
                lineWidth: max(0.65, 1.25 * scale),
                lineCap: .round
            )
        )

        // A second, dimmer filament gives the current a soft living depth.
        var filament = Path()
        filament.move(to: CGPoint(
            x: point.x + particle.length * 0.18 * scale,
            y: point.y + particle.length * 0.30 * scale
        ))
        filament.addCurve(
            to: CGPoint(
                x: point.x - particle.length * 0.12 * scale,
                y: point.y - particle.length * 0.62 * scale
            ),
            control1: CGPoint(
                x: point.x + particle.length * 0.40 * scale,
                y: point.y - particle.length * 0.05 * scale
            ),
            control2: CGPoint(
                x: point.x - particle.length * 0.38 * scale,
                y: point.y - particle.length * 0.35 * scale
            )
        )

        context.opacity *= 0.38
        context.stroke(
            filament,
            with: .color(Color(red: 0.36, green: 0.92, blue: 0.28)),
            style: StrokeStyle(
                lineWidth: max(0.4, 0.72 * scale),
                lineCap: .round
            )
        )
    }

    private func drawPollen(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        at point: CGPoint,
        scale: CGFloat,
        time: TimeInterval
    ) {
        let pulse = 0.70
            + 0.30 * sin(
                time * particle.flickerSpeed
                + particle.seed
            )

        let r = max(0.55, 1.35 * scale * pulse)

        let glowRect = CGRect(
            x: point.x - r * 1.8,
            y: point.y - r * 1.8,
            width: r * 3.6,
            height: r * 3.6
        )
        context.fill(
            Path(ellipseIn: glowRect),
            with: .color(
                Color(
                    red: 0.44,
                    green: 0.96,
                    blue: 0.38
                )
            )
        )

        let coreRect = CGRect(
            x: point.x - r * 0.55,
            y: point.y - r * 0.55,
            width: r * 1.1,
            height: r * 1.1
        )
        context.opacity *= 0.92
        context.fill(
            Path(ellipseIn: coreRect),
            with: .color(
                Color(
                    red: 0.72,
                    green: 1.0,
                    blue: 0.58
                )
            )
        )
    }

    private func drawFlower(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        at point: CGPoint,
        scale: CGFloat,
        time: TimeInterval
    ) {
        // Slow, deliberately irregular rotation.
        let angle = CGFloat(
            time * particle.rotationSpeed
            + particle.seed
            + sin(time * 0.31 + particle.seed * 0.7) * 0.42
        )

        let petalRadius = max(1.15, 3.1 * scale)
        let flowerRadius = petalRadius * 1.55

        var flower = Path()

        for i in 0..<5 {
            let base = CGFloat(i) * .pi * 2.0 / 5.0
            let a = base + angle

            let cx = point.x + cos(a) * flowerRadius
            let cy = point.y + sin(a) * flowerRadius

            let petal = CGRect(
                x: cx - petalRadius,
                y: cy - petalRadius * 0.82,
                width: petalRadius * 2.0,
                height: petalRadius * 1.64
            )

            flower.addEllipse(in: petal)
        }

        let centerRadius = petalRadius * 0.72
        flower.addEllipse(
            in: CGRect(
                x: point.x - centerRadius,
                y: point.y - centerRadius,
                width: centerRadius * 2.0,
                height: centerRadius * 2.0
            )
        )

        // White and pink blossoms; no yellow flowers.
        let pink = particle.flowerPink
        let flowerColor = pink
            ? Color(red: 1.0, green: 0.60, blue: 0.74)
            : Color(red: 1.0, green: 0.96, blue: 0.98)

        context.fill(flower, with: .color(flowerColor))

        let center = CGRect(
            x: point.x - centerRadius * 0.38,
            y: point.y - centerRadius * 0.38,
            width: centerRadius * 0.76,
            height: centerRadius * 0.76
        )

        context.opacity *= 0.82
        context.fill(
            Path(ellipseIn: center),
            with: .color(
                pink
                    ? Color(red: 0.98, green: 0.76, blue: 0.30)
                    : Color(red: 1.0, green: 0.82, blue: 0.46)
            )
        )
    }
}

private struct PlantParticle {
    enum Kind {
        case stream
        case flower
        case pollen
    }

    let kind: Kind
    let phase: Double
    let startX: CGFloat
    let startY: CGFloat
    let targetX: CGFloat
    let drift: CGFloat
    let opacity: Double
    let scale: CGFloat
    let length: CGFloat
    let seed: Double
    let flowSpeed: Double
    let flickerSpeed: Double
    let rotationSpeed: Double
    let flowerPink: Bool

    static func make222() -> [PlantParticle] {
        var result: [PlantParticle] = []
        result.reserveCapacity(222)

        // 42 soft green currents.
        for i in 0..<42 {
            result.append(
                PlantParticle(
                    kind: .stream,
                    phase: fract(Double(i) * 0.6180339887),
                    startX: signedUnit(i * 17 + 3),
                    startY: 0.61 + fract(Double(i) * 0.173) * 0.25,
                    targetX: signedUnit(i * 11 + 7) * 0.82,
                    drift: CGFloat(3.0 + Double(i % 6)),
                    opacity: 0.16 + Double(i % 7) * 0.022,
                    scale: CGFloat(0.75 + Double(i % 5) * 0.10),
                    length: CGFloat(12 + i % 15),
                    seed: Double(i) * 1.17,
                    flowSpeed: 0.48 + Double(i % 5) * 0.06,
                    flickerSpeed: 1.15 + Double(i % 4) * 0.18,
                    rotationSpeed: 0,
                    flowerPink: false
                )
            )
        }

        // 70 white/pink apple blossoms.
        for i in 0..<70 {
            result.append(
                PlantParticle(
                    kind: .flower,
                    phase: fract(0.31 + Double(i) * 0.754877666),
                    startX: signedUnit(i * 23 + 5),
                    startY: 0.66 + fract(Double(i) * 0.211) * 0.18,
                    targetX: signedUnit(i * 13 + 2) * 0.84,
                    drift: CGFloat(2.0 + Double(i % 6)),
                    opacity: 0.28 + Double(i % 7) * 0.035,
                    scale: CGFloat(0.46 + Double(i % 5) * 0.13),
                    length: 0,
                    seed: Double(i) * 1.83 + 9,
                    flowSpeed: 0.52 + Double(i % 5) * 0.055,
                    flickerSpeed: 0.65 + Double(i % 4) * 0.12,
                    rotationSpeed: 0.16 + Double(i % 7) * 0.025,
                    flowerPink: i % 3 != 0
                )
            )
        }

        // 110 fine green pollen motes.
        for i in 0..<110 {
            result.append(
                PlantParticle(
                    kind: .pollen,
                    phase: fract(0.17 + Double(i) * 0.4142135623),
                    startX: signedUnit(i * 29 + 1),
                    startY: 0.59 + fract(Double(i) * 0.139) * 0.29,
                    targetX: signedUnit(i * 19 + 4) * 0.88,
                    drift: CGFloat(2.0 + Double(i % 5)),
                    opacity: 0.14 + Double(i % 6) * 0.035,
                    scale: CGFloat(0.50 + Double(i % 4) * 0.14),
                    length: 0,
                    seed: Double(i) * 2.31 + 17,
                    flowSpeed: 0.72 + Double(i % 5) * 0.08,
                    flickerSpeed: 1.7 + Double(i % 6) * 0.22,
                    rotationSpeed: 0,
                    flowerPink: false
                )
            )
        }

        return result
    }

    private static func fract(_ x: Double) -> Double {
        x - floor(x)
    }

    private static func signedUnit(_ x: Int) -> CGFloat {
        let v = sin(Double(x) * 12.9898) * 43758.5453
        return CGFloat((v - floor(v)) * 2.0 - 1.0)
    }
}
