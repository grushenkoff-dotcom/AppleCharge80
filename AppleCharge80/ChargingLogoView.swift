import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []
    @State private var chargeStartDate: Date?

    private let sectorCount = 6
    private let disconnectTotal: TimeInterval = 3.0
    private let sectorDuration: TimeInterval = 0.6
    private let sectorStartStep: TimeInterval = 0.48

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let now = context.date
            let disconnectElapsed = disconnectStart.map {
                now.timeIntervalSince($0)
            }

            let elapsedSinceCharge = chargeStartDate.map {
                max(0, now.timeIntervalSince($0))
            } ?? 0

            // DO NOT CHANGE.
            // Current approved logo geometry.
            let logoHeight: CGFloat = 181.0
            let logoWidth: CGFloat = logoHeight * 814.0 / 1000.0

            GeometryReader { geo in
                ZStack {
                    PlantParticleField(
                        progress: clampedProgress,
                        elapsed: elapsedSinceCharge,
                        time: now.timeIntervalSinceReferenceDate,
                        active: isCharging && disconnectElapsed == nil,
                        logoWidth: logoWidth,
                        logoHeight: logoHeight
                    )
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height
                    )

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
                    .frame(
                        width: logoWidth,
                        height: logoHeight
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .onAppear {
                if isCharging {
                    if chargeStartDate == nil {
                        chargeStartDate = now
                    }
                } else if disconnectStart == nil {
                    beginDisconnect(at: now)
                }
            }
            .onChange(of: isCharging) { _, charging in
                if charging {
                    chargeStartDate = now
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

// MARK: - Apple logo fill

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

    // Original approved six colors.
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

            let completed = min(
                sectorCount,
                Int(scaled.rounded(.down))
            )

            let currentFraction =
                scaled - Double(completed)

            let leafGrowth = leafProgress

            let fullyAlive =
                progress >= 1.0 &&
                disconnectElapsed == nil

            ZStack(alignment: .topLeading) {
                ForEach(
                    Array(0..<sectorCount),
                    id: \.self
                ) { index in

                    let amount: CGFloat =
                        index < completed
                        ? 1.0
                        : (
                            index == completed &&
                            completed < sectorCount
                            ? CGFloat(
                                max(
                                    0,
                                    min(1, currentFraction)
                                )
                            )
                            : 0.0
                        )

                    let opacity = sectorOpacity(index)

                    if amount > 0 && opacity > 0 {
                        let bottomY =
                            bodyBottom -
                            CGFloat(index) * bandHeight

                        let fillHeight =
                            max(
                                0.01,
                                bandHeight * amount
                            )

                        let topY =
                            bottomY - fillHeight

                        let isCurrent =
                            index == completed &&
                            completed < sectorCount

                        // Individual breathing for each sector.
                        let breath =
                            fullyAlive
                            ? (
                                0.94 +
                                0.08 *
                                sin(
                                    time *
                                    (
                                        0.92 +
                                        Double(index) * 0.045
                                    ) +
                                    Double(index) * 1.17
                                )
                            )
                            : (
                                0.96 +
                                0.04 *
                                sin(
                                    time * 0.75 +
                                    Double(index) * 0.61
                                )
                            )

                        let shimmer =
                            0.97 +
                            0.055 *
                            sin(
                                time * 1.18 +
                                Double(index) * 0.83
                            )

                        let base = colors[index]

                        ZStack {
                            if isCurrent {
                                WavingSectorTop(
                                    width: geo.size.width,
                                    height: fillHeight,
                                    amplitude: min(
                                        5.5,
                                        max(
                                            1.4,
                                            bandHeight * 0.11
                                        )
                                    ),
                                    phase:
                                        time * 0.75 +
                                        Double(index) * 1.37
                                )
                                .fill(
                                    sectorGradient(
                                        base: base,
                                        intensity:
                                            breath * shimmer
                                    )
                                )
                            } else {
                                Rectangle()
                                    .fill(
                                        sectorGradient(
                                            base: base,
                                            intensity:
                                                breath * shimmer
                                        )
                                    )
                            }

                            // Moving internal color light after 100%.
                            if fullyAlive {
                                Rectangle()
                                    .fill(
                                        aliveHighlight(
                                            base: base,
                                            index: index,
                                            time: time
                                        )
                                    )
                                    .opacity(
                                        0.14 +
                                        0.06 *
                                        sin(
                                            time * 0.83 +
                                            Double(index)
                                        )
                                    )
                            }
                        }
                        .frame(
                            width: geo.size.width,
                            height: fillHeight
                        )
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
                // Permanent soft outer boundary blur.
                AppleBodyShape()
                    .stroke(
                        Color.white.opacity(0.16),
                        lineWidth: 0.9
                    )
                    .blur(radius: 2.1)
                    .opacity(0.78)

                // Growing stem.
                LeafBudStem(progress: leafGrowth)
                    .opacity(stemOpacity)

                // Leaf opens only after the stem has grown.
                AppleLeafShape()
                    .fill(
                        Color(
                            red: colors.last!.r,
                            green: colors.last!.g,
                            blue: colors.last!.b
                        )
                    )
                    .scaleEffect(
                        max(0.001, leafShapeScale),
                        anchor: UnitPoint(
                            x: 0.51,
                            y: 0.231
                        )
                    )
                    .opacity(leafOpacity)
            }
        }
    }

    private func sectorGradient(
        base: SectorColor,
        intensity: Double
    ) -> LinearGradient {

        let lowFactor =
            max(
                0.72,
                min(1.12, 0.87 * intensity)
            )

        let midFactor =
            max(
                0.78,
                min(1.16, 1.06 * intensity)
            )

        let highFactor =
            max(
                0.74,
                min(1.13, 0.95 * intensity)
            )

        let low = Color(
            red: min(1, base.r * lowFactor),
            green: min(1, base.g * lowFactor),
            blue: min(1, base.b * lowFactor)
        )

        let mid = Color(
            red: min(1, base.r * midFactor),
            green: min(1, base.g * midFactor),
            blue: min(1, base.b * midFactor)
        )

        let high = Color(
            red: min(1, base.r * highFactor),
            green: min(1, base.g * highFactor),
            blue: min(1, base.b * highFactor)
        )

        return LinearGradient(
            stops: [
                .init(
                    color: low,
                    location: 0.0
                ),
                .init(
                    color: mid,
                    location: 0.46
                ),
                .init(
                    color: high,
                    location: 1.0
                )
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func aliveHighlight(
        base: SectorColor,
        index: Int,
        time: TimeInterval
    ) -> LinearGradient {

        let phase =
            time *
            (
                0.55 +
                Double(index) * 0.035
            ) +
            Double(index) * 1.9

        let amount =
            0.5 +
            0.5 * sin(phase)

        let highlight = Color(
            red: min(1, base.r + 0.16),
            green: min(1, base.g + 0.16),
            blue: min(1, base.b + 0.16)
        )

        return LinearGradient(
            stops: [
                .init(
                    color: .clear,
                    location: 0.0
                ),
                .init(
                    color: highlight.opacity(
                        0.28 + 0.20 * amount
                    ),
                    location: 0.45
                ),
                .init(
                    color: .clear,
                    location: 0.78
                )
            ],
            startPoint: UnitPoint(
                x: 0.05 + amount * 0.25,
                y: 0
            ),
            endPoint: UnitPoint(
                x: 0.80 + amount * 0.15,
                y: 1
            )
        )
    }

    // Leaf growth remains deliberately long: 88% -> 100%.
    private var leafProgress: Double {
        let normal =
            max(
                0,
                min(
                    1,
                    (progress - 0.88) / 0.12
                )
            )

        guard let elapsed = disconnectElapsed else {
            return normal
        }

        if elapsed >= disconnectTotal {
            return 0
        }

        return normal *
            max(
                0,
                1.0 - elapsed / disconnectTotal
            )
    }

    // Stem grows progressively rather than appearing.
    private var stemOpacity: Double {
        let p = leafProgress

        guard p > 0 else {
            return 0
        }

        if p < 0.10 {
            return p / 0.10
        }

        return 1.0
    }

    // First the stem rises; then the leaf itself opens.
    private var leafShapeScale: Double {
        let p = leafProgress

        if p <= 0.58 {
            return 0.001
        }

        let q =
            min(
                1,
                (p - 0.58) / 0.42
            )

        let eased =
            q * q * (3.0 - 2.0 * q)

        return 0.035 + eased * 0.965
    }

    private var leafOpacity: Double {
        let p = leafProgress

        if p <= 0.58 {
            return 0
        }

        return min(
            1,
            (p - 0.58) / 0.24
        )
    }

    private func sectorOpacity(
        _ index: Int
    ) -> Double {

        guard let elapsed = disconnectElapsed else {
            return 1.0
        }

        if elapsed >= disconnectTotal {
            return 0.0
        }

        guard let position =
            disconnectOrder.firstIndex(of: index)
        else {
            return 1.0
        }

        let start =
            Double(position) * sectorStartStep

        let end =
            start + sectorDuration

        if elapsed <= start {
            return 1.0
        }

        if elapsed >= end {
            return 0.0
        }

        let t =
            (elapsed - start) /
            sectorDuration

        if t <= 0.8 {
            let u = t / 0.8
            let eased =
                u * u * (3.0 - 2.0 * u)

            return 1.0 +
                (0.20 - 1.0) * eased
        }

        let u =
            (t - 0.8) / 0.2

        let eased =
            u * u * (3.0 - 2.0 * u)

        return 0.20 *
            (1.0 - eased)
    }
}

// MARK: - Waving fill edge

private struct WavingSectorTop: Shape {
    let width: CGFloat
    let height: CGFloat
    let amplitude: CGFloat
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let a =
            min(
                amplitude,
                max(
                    0.8,
                    height * 0.20
                )
            )

        let y = rect.minY
        let x0 = rect.minX
        let x1 = rect.maxX
        let third = rect.width / 3.0

        path.move(
            to: CGPoint(
                x: x0,
                y: y +
                    CGFloat(sin(phase)) *
                    a * 0.35
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x0 + third,
                y: y +
                    CGFloat(sin(phase + 1.9)) *
                    a
            ),
            control1: CGPoint(
                x: x0 + third * 0.28,
                y: y +
                    CGFloat(sin(phase + 0.7)) *
                    a * 0.55
            ),
            control2: CGPoint(
                x: x0 + third * 0.72,
                y: y +
                    CGFloat(sin(phase + 1.35)) *
                    a * 1.15
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x0 + third * 2,
                y: y +
                    CGFloat(sin(phase + 3.2)) *
                    a * 0.72
            ),
            control1: CGPoint(
                x: x0 + third * 1.28,
                y: y +
                    CGFloat(sin(phase + 2.35)) *
                    a * 1.05
            ),
            control2: CGPoint(
                x: x0 + third * 1.72,
                y: y +
                    CGFloat(sin(phase + 2.8)) *
                    a * 0.35
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x1,
                y: y +
                    CGFloat(sin(phase + 4.8)) *
                    a * 0.35
            ),
            control1: CGPoint(
                x: x0 + third * 2.28,
                y: y +
                    CGFloat(sin(phase + 3.8)) *
                    a * 0.90
            ),
            control2: CGPoint(
                x: x0 + third * 2.70,
                y: y +
                    CGFloat(sin(phase + 4.35)) *
                    a * 0.55
            )
        )

        path.addLine(
            to: CGPoint(
                x: x1,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: x0,
                y: rect.maxY
            )
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Growing leaf stem

private struct LeafBudStem: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let x = w * 0.515
            let baseY = h * 0.245

            let p =
                min(
                    1,
                    max(0, progress)
                )

            let topY =
                baseY -
                h * 0.045 * p

            Path { path in
                path.move(
                    to: CGPoint(
                        x: x,
                        y: baseY
                    )
                )

                path.addCurve(
                    to: CGPoint(
                        x: x + w * 0.025,
                        y: topY
                    ),
                    control1: CGPoint(
                        x: x - w * 0.010,
                        y: baseY -
                            h * 0.018 * p
                    ),
                    control2: CGPoint(
                        x: x + w * 0.018,
                        y: topY +
                            h * 0.012
                    )
                )
            }
            .stroke(
                Color(
                    red: 0.42,
                    green: 0.78,
                    blue: 0.12
                ),
                style: StrokeStyle(
                    lineWidth:
                        max(
                            1.0,
                            w * 0.018
                        ),
                    lineCap: .round
                )
            )
        }
    }
}

// MARK: - Living plant field

private struct PlantParticleField: View {
    let progress: Double
    let elapsed: TimeInterval
    let time: TimeInterval
    let active: Bool
    let logoWidth: CGFloat
    let logoHeight: CGFloat

    private let ribbons: [RibbonSeed] =
        RibbonSeed.make()

    private let particles: [PlantParticle] =
        PlantParticle.make()

    var body: some View {
        Canvas { context, size in
            guard active else {
                return
            }

            // First second: the plant grows from the bottom
            // to the future lower contour of the logo.
            let growth =
                smoothstep(
                    min(
                        1,
                        max(
                            0,
                            elapsed / 1.0
                        )
                    )
                )

            // After reaching the logo, density continues to build.
            let density =
                smoothstep(
                    min(
                        1,
                        max(
                            0,
                            (elapsed - 0.75) / 2.2
                        )
                    )
                )

            let centerX =
                size.width * 0.5

            let logoBottomY =
                size.height * 0.5 +
                logoHeight * 0.5

            // Main narrow living ribbons.
            for ribbon in ribbons {
                drawRibbon(
                    &context,
                    seed: ribbon,
                    size: size,
                    centerX: centerX,
                    logoBottomY: logoBottomY,
                    logoWidth: logoWidth,
                    growth: growth,
                    density: density,
                    time: time
                )
            }

            // Very light ephemeral ribbons.
            if elapsed > 0.55 {
                for ribbon in ribbons {
                    drawEphemeralRibbon(
                        &context,
                        seed: ribbon,
                        size: size,
                        centerX: centerX,
                        logoBottomY: logoBottomY,
                        logoWidth: logoWidth,
                        growth: growth,
                        density: density,
                        time: time
                    )
                }
            }

            // Living merger at the lower Apple contour.
            drawMergingEnergy(
                &context,
                size: size,
                centerX: centerX,
                logoBottomY: logoBottomY,
                logoWidth: logoWidth,
                time: time,
                density: density
            )

            // Flowers and pollen begin only after the first growth phase.
            if elapsed > 1.0 {
                let reveal =
                    smoothstep(
                        min(
                            1,
                            max(
                                0,
                                (elapsed - 1.0) / 1.8
                            )
                        )
                    )

                for particle in particles {
                    drawMovingParticle(
                        &context,
                        particle: particle,
                        size: size,
                        centerX: centerX,
                        logoBottomY: logoBottomY,
                        logoWidth: logoWidth,
                        time: time,
                        reveal: reveal,
                        density: density
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Main ribbon

    private func drawRibbon(
        _ context: inout GraphicsContext,
        seed: RibbonSeed,
        size: CGSize,
        centerX: CGFloat,
        logoBottomY: CGFloat,
        logoWidth: CGFloat,
        growth: Double,
        density: Double,
        time: TimeInterval
    ) {
        let target =
            contourTarget(
                normalizedX: seed.targetX,
                centerX: centerX,
                logoBottomY: logoBottomY,
                logoWidth: logoWidth
            )

        let bottom =
            CGPoint(
                x: centerX +
                    seed.startX *
                    size.width * 0.11,
                y: size.height + 24
            )

        let activeLength =
            max(
                0.02,
                growth
            )

        let wave =
            CGFloat(
                sin(
                    time *
                    seed.waveSpeed +
                    seed.phase
                )
            )

        let widthPulse =
            1.0 +
            0.14 *
            sin(
                time * 0.78 +
                seed.phase * 1.7
            )

        let baseWidth =
            (
                1.7 +
                seed.width * 1.7
            ) *
            CGFloat(
                0.76 +
                density * 0.28
            ) *
            CGFloat(widthPulse)

        var left: [CGPoint] = []
        var right: [CGPoint] = []

        let samples = 28

        for i in 0...samples {
            let raw =
                Double(i) /
                Double(samples)

            let t =
                raw * activeLength

            let p =
                ribbonPoint(
                    t: t,
                    start: bottom,
                    target: target,
                    seed: seed,
                    time: time,
                    size: size,
                    wave: wave
                )

            let tangent =
                ribbonTangent(
                    t: min(1, t + 0.01),
                    start: bottom,
                    target: target,
                    seed: seed,
                    time: time,
                    size: size
                )

            let tangentLength =
                max(
                    0.001,
                    hypot(
                        tangent.x,
                        tangent.y
                    )
                )

            let nx =
                -tangent.y /
                tangentLength

            let ny =
                tangent.x /
                tangentLength

            let localWidth =
                baseWidth *
                (
                    0.82 +
                    0.18 *
                    sin(
                        raw *
                            .pi *
                            2.7 +
                        time * 0.55 +
                        seed.phase
                    )
                )

            left.append(
                CGPoint(
                    x: p.x + nx * localWidth,
                    y: p.y + ny * localWidth
                )
            )

            right.append(
                CGPoint(
                    x: p.x - nx * localWidth,
                    y: p.y - ny * localWidth
                )
            )
        }

        guard left.count > 1 else {
            return
        }

        var path = Path()

        path.move(to: left[0])

        for point in left.dropFirst() {
            path.addLine(to: point)
        }

        for point in right.reversed() {
            path.addLine(to: point)
        }

        path.closeSubpath()

        let alpha =
            (
                0.24 +
                0.20 * density
            ) *
            (
                0.82 +
                0.18 *
                sin(
                    time * 0.62 +
                    seed.phase
                )
            )

        context.opacity = alpha

        context.fill(
            path,
            with: .color(
                Color(
                    red: 0.24,
                    green: 0.92,
                    blue: 0.30
                )
            )
        )

        // Fine inner filament.
        var filament = Path()

        filament.move(
            to: left[0].interpolated(
                with: right[0],
                amount: 0.5
            )
        )

        for i in 1..<left.count {
            filament.addLine(
                to: left[i].interpolated(
                    with: right[i],
                    amount: 0.5
                )
            )
        }

        context.opacity =
            alpha * 0.32

        context.stroke(
            filament,
            with: .color(
                Color(
                    red: 0.62,
                    green: 1.0,
                    blue: 0.52
                )
            ),
            style: StrokeStyle(
                lineWidth:
                    max(
                        0.35,
                        baseWidth * 0.28
                    ),
                lineCap: .round
            )
        )
    }

    // MARK: Ephemeral ribbons

    private func drawEphemeralRibbon(
        _ context: inout GraphicsContext,
        seed: RibbonSeed,
        size: CGSize,
        centerX: CGFloat,
        logoBottomY: CGFloat,
        logoWidth: CGFloat,
        growth: Double,
        density: Double,
        time: TimeInterval
    ) {
        let target =
            contourTarget(
                normalizedX:
                    seed.targetX * 0.82 +
                    CGFloat(
                        sin(seed.phase)
                    ) * 0.035,
                centerX: centerX,
                logoBottomY: logoBottomY,
                logoWidth: logoWidth
            )

        let bottom =
            CGPoint(
                x: centerX +
                    seed.startX *
                    size.width * 0.12,
                y: size.height + 28
            )

        let sway =
            CGFloat(
                sin(
                    time * 0.42 +
                    seed.phase * 1.3
                )
            ) * 7.0

        var path = Path()

        let steps = 18

        for i in 0...steps {
            let raw =
                Double(i) /
                Double(steps)

            let t =
                raw *
                max(
                    0.05,
                    growth
                )

            let bend =
                CGFloat(
                    sin(
                        raw *
                            .pi *
                            1.35 +
                        time * 0.48 +
                        seed.phase
                    )
                ) *
                (
                    5.0 +
                    5.0 * density
                )

            let x =
                bottom.x +
                (target.x - bottom.x) *
                CGFloat(t) +
                sway *
                CGFloat(t * t) +
                bend

            let y =
                bottom.y +
                (target.y - bottom.y) *
                CGFloat(t)

            if i == 0 {
                path.move(
                    to: CGPoint(
                        x: x,
                        y: y
                    )
                )
            } else {
                path.addLine(
                    to: CGPoint(
                        x: x,
                        y: y
                    )
                )
            }
        }

        let alpha =
            0.055 +
            0.085 * density +
            0.025 *
            sin(
                time * 0.8 +
                seed.phase
            )

        context.opacity =
            max(
                0.01,
                alpha
            )

        context.stroke(
            path,
            with: .color(
                Color(
                    red: 0.42,
                    green: 1.0,
                    blue: 0.48
                )
            ),
            style: StrokeStyle(
                lineWidth:
                    1.0 +
                    density * 0.65,
                lineCap: .round
            )
        )
    }

    // MARK: Flow/logo merger

    private func drawMergingEnergy(
        _ context: inout GraphicsContext,
        size: CGSize,
        centerX: CGFloat,
        logoBottomY: CGFloat,
        logoWidth: CGFloat,
        time: TimeInterval,
        density: Double
    ) {
        guard density > 0.01 else {
            return
        }

        let pulse =
            0.5 +
            0.5 *
            sin(
                time * 1.35
            )

        let center =
            contourTarget(
                normalizedX: 0,
                centerX: centerX,
                logoBottomY: logoBottomY,
                logoWidth: logoWidth
            )

        let glowRadius =
            8.0 +
            CGFloat(pulse) * 6.0

        // Soft living cloud.
        context.opacity =
            0.035 +
            0.035 * pulse

        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: center.x - glowRadius,
                    y: center.y -
                        glowRadius * 0.60,
                    width: glowRadius * 2,
                    height: glowRadius * 1.20
                )
            ),
            with: .color(
                Color(
                    red: 0.50,
                    green: 1.0,
                    blue: 0.42
                )
            )
        )

        // Tiny particles are pulled toward the contour.
        for i in 0..<7 {
            let phase =
                time *
                (
                    0.7 +
                    Double(i) * 0.04
                ) +
                Double(i) * 0.88

            let side:
                CGFloat =
                i % 2 == 0
                ? 1
                : -1

            let x =
                center.x +
                side *
                CGFloat(
                    5 + i * 2
                ) +
                CGFloat(
                    sin(phase)
                ) * 3

            let y =
                center.y -
                CGFloat(
                    4 +
                    (i % 4) * 3
                ) +
                CGFloat(
                    cos(phase * 1.3)
                ) * 3

            let radius =
                0.7 +
                0.55 *
                CGFloat(pulse)

            context.opacity =
                0.10 +
                0.08 * pulse

            context.fill(
                Path(
                    ellipseIn: CGRect(
                        x: x - radius,
                        y: y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                ),
                with: .color(
                    Color(
                        red: 0.70,
                        green: 1.0,
                        blue: 0.60
                    )
                )
            )
        }
    }

    // MARK: Flowers / pollen

    private func drawMovingParticle(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        size: CGSize,
        centerX: CGFloat,
        logoBottomY: CGFloat,
        logoWidth: CGFloat,
        time: TimeInterval,
        reveal: Double,
        density: Double
    ) {
        let speed =
            particle.kind == .flower
            ? 0.115
            : 0.145

        var travel =
            (
                time * speed +
                particle.phase
            )
            .truncatingRemainder(
                dividingBy: 1.0
            )

        if travel < 0 {
            travel += 1.0
        }

        let streamIndex =
            particle.streamIndex % 8

        let ribbon =
            ribbons[streamIndex]

        let start =
            CGPoint(
                x: centerX +
                    ribbon.startX *
                    size.width * 0.11,
                y: size.height + 24
            )

        let target =
            contourTarget(
                normalizedX:
                    ribbon.targetX,
                centerX: centerX,
                logoBottomY: logoBottomY,
                logoWidth: logoWidth
            )

        let base =
            ribbonPoint(
                t: travel,
                start: start,
                target: target,
                seed: ribbon,
                time: time,
                size: size,
                wave:
                    CGFloat(
                        sin(
                            time *
                            ribbon.waveSpeed +
                            ribbon.phase
                        )
                    )
            )

        // Slightly sinusoidal flight with independent deviations.
        let sine1 =
            CGFloat(
                sin(
                    time *
                        particle.swaySpeed +
                    particle.seed +
                    travel * 5.4
                )
            )

        let sine2 =
            CGFloat(
                sin(
                    time * 0.31 +
                    particle.seed * 1.73 +
                    travel * 2.7
                )
            )

        let deviation =
            particle.drift *
            (
                0.70 * sine1 +
                0.30 * sine2
            )

        let x =
            base.x + deviation

        let y =
            base.y -
            CGFloat(
                sin(
                    time * 0.51 +
                    particle.seed
                )
            ) * 1.4

        let fadeNearLogo =
            smoothstep(
                min(
                    1,
                    max(
                        0,
                        (travel - 0.84) / 0.16
                    )
                )
            )

        let alpha =
            particle.opacity *
            reveal *
            (1.0 - fadeNearLogo) *
            (0.82 + 0.18 * density)

        guard alpha > 0.002 else {
            return
        }

        context.opacity = alpha

        let scale =
            particle.scale *
            CGFloat(
                1.0 -
                fadeNearLogo * 0.72
            )

        switch particle.kind {
        case .flower:
            drawFlower(
                &context,
                particle: particle,
                at: CGPoint(
                    x: x,
                    y: y
                ),
                scale: scale,
                time: time
            )

        case .pollen:
            drawPollen(
                &context,
                particle: particle,
                at: CGPoint(
                    x: x,
                    y: y
                ),
                scale: scale,
                time: time
            )
        }
    }

    private func drawPollen(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        at point: CGPoint,
        scale: CGFloat,
        time: TimeInterval
    ) {
        let pulse =
            0.65 +
            0.35 *
            sin(
                time *
                    particle.flickerSpeed +
                particle.seed
            )

        let radius =
            max(
                0.45,
                1.15 *
                scale *
                CGFloat(pulse)
            )

        let outer =
            radius * 2.1

        context.opacity *= 0.24

        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: point.x - outer,
                    y: point.y - outer,
                    width: outer * 2,
                    height: outer * 2
                )
            ),
            with: .color(
                Color(
                    red: 0.30,
                    green: 0.92,
                    blue: 0.25
                )
            )
        )

        context.opacity *= 3.4

        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: point.x - radius,
                    y: point.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
            ),
            with: .color(
                Color(
                    red: 0.60,
                    green: 1.0,
                    blue: 0.42
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
        let angle =
            CGFloat(
                time *
                    particle.rotationSpeed +
                particle.rotationPhase +
                sin(
                    time * 0.27 +
                    particle.seed
                ) * 0.35
            )

        let petalRadius =
            max(
                1.15,
                3.0 * scale
            )

        let flowerRadius =
            petalRadius * 1.45

        var flower = Path()

        for i in 0..<5 {
            let base =
                CGFloat(i) *
                .pi *
                2.0 / 5.0

            let a =
                base + angle

            let cx =
                point.x +
                cos(a) *
                flowerRadius

            let cy =
                point.y +
                sin(a) *
                flowerRadius

            flower.addEllipse(
                in: CGRect(
                    x: cx - petalRadius,
                    y: cy -
                        petalRadius * 0.82,
                    width: petalRadius * 2,
                    height: petalRadius * 1.64
                )
            )
        }

        let centerRadius =
            petalRadius * 0.70

        flower.addEllipse(
            in: CGRect(
                x: point.x -
                    centerRadius,
                y: point.y -
                    centerRadius,
                width: centerRadius * 2,
                height: centerRadius * 2
            )
        )

        let flowerColor =
            particle.flowerPink
            ? Color(
                red: 1.0,
                green: 0.58,
                blue: 0.72
            )
            : Color(
                red: 1.0,
                green: 0.96,
                blue: 0.98
            )

        context.fill(
            flower,
            with: .color(flowerColor)
        )

        let center = CGRect(
            x: point.x -
                centerRadius * 0.38,
            y: point.y -
                centerRadius * 0.38,
            width: centerRadius * 0.76,
            height: centerRadius * 0.76
        )

        context.opacity *= 0.82

        context.fill(
            Path(
                ellipseIn: center
            ),
            with: .color(
                particle.flowerPink
                ? Color(
                    red: 0.98,
                    green: 0.76,
                    blue: 0.30
                )
                : Color(
                    red: 1.0,
                    green: 0.82,
                    blue: 0.46
                )
            )
        )
    }

    // MARK: Ribbon geometry

    private func ribbonPoint(
        t: Double,
        start: CGPoint,
        target: CGPoint,
        seed: RibbonSeed,
        time: TimeInterval,
        size: CGSize,
        wave: CGFloat
    ) -> CGPoint {

        let u =
            CGFloat(
                smoothstep(t)
            )

        let eased =
            u * u *
            (3.0 - 2.0 * u)

        let bend =
            CGFloat(
                sin(
                    Double(u) *
                        .pi *
                        1.55 +
                    time *
                        seed.waveSpeed +
                    seed.phase
                ) * 7.0
            )

        let sideBend =
            CGFloat(
                sin(
                    Double(u) *
                        .pi *
                        2.8 +
                    seed.phase * 1.4
                ) * 3.0
            )

        var x =
            start.x +
            (target.x - start.x) *
            eased

        var y =
            start.y +
            (target.y - start.y) *
            eased

        // Final quarter softly merges into the curved contour.
        let absorb =
            smoothstep(
                min(
                    1,
                    max(
                        0,
                        (t - 0.76) / 0.24
                    )
                )
            )

        x +=
            (
                bend +
                sideBend +
                wave * 3.0
            ) *
            (
                1.0 -
                CGFloat(absorb) * 0.55
            )

        y +=
            CGFloat(
                sin(
                    Double(u) * .pi
                )
            ) *
            3.0 *
            (
                1.0 -
                CGFloat(absorb)
            )

        return CGPoint(
            x: x,
            y: y
        )
    }

    private func ribbonTangent(
        t: Double,
        start: CGPoint,
        target: CGPoint,
        seed: RibbonSeed,
        time: TimeInterval,
        size: CGSize
    ) -> CGPoint {

        let p0 =
            ribbonPoint(
                t: max(
                    0,
                    t - 0.018
                ),
                start: start,
                target: target,
                seed: seed,
                time: time,
                size: size,
                wave: 0
            )

        let p1 =
            ribbonPoint(
                t: min(
                    1,
                    t + 0.018
                ),
                start: start,
                target: target,
                seed: seed,
                time: time,
                size: size,
                wave: 0
            )

        return CGPoint(
            x: p1.x - p0.x,
            y: p1.y - p0.y
        )
    }

    private func contourTarget(
        normalizedX: CGFloat,
        centerX: CGFloat,
        logoBottomY: CGFloat,
        logoWidth: CGFloat
    ) -> CGPoint {

        let nx =
            max(
                -1,
                min(
                    1,
                    normalizedX
                )
            )

        // Curved lower contour.
        // The center is slightly lower than the sides.
        let curve =
            10.5 *
            (1.0 - nx * nx)

        let x =
            centerX +
            nx *
            logoWidth *
            0.34

        let y =
            logoBottomY -
            3.5 -
            curve

        return CGPoint(
            x: x,
            y: y
        )
    }

    private func smoothstep(
        _ x: Double
    ) -> Double {

        let v =
            max(
                0,
                min(
                    1,
                    x
                )
            )

        return v * v *
            (3.0 - 2.0 * v)
    }
}

// MARK: - Ribbon seeds

private struct RibbonSeed {
    let startX: CGFloat
    let targetX: CGFloat
    let width: CGFloat
    let phase: Double
    let waveSpeed: Double

    static func make() -> [RibbonSeed] {
        [
            RibbonSeed(
                startX: -0.62,
                targetX: -0.34,
                width: 0.72,
                phase: 0.2,
                waveSpeed: 0.74
            ),
            RibbonSeed(
                startX: -0.42,
                targetX: -0.23,
                width: 0.58,
                phase: 1.1,
                waveSpeed: 0.66
            ),
            RibbonSeed(
                startX: -0.24,
                targetX: -0.10,
                width: 0.82,
                phase: 2.0,
                waveSpeed: 0.81
            ),
            RibbonSeed(
                startX: -0.08,
                targetX: -0.03,
                width: 0.56,
                phase: 2.8,
                waveSpeed: 0.62
            ),
            RibbonSeed(
                startX: 0.10,
                targetX: 0.08,
                width: 0.78,
                phase: 3.7,
                waveSpeed: 0.77
            ),
            RibbonSeed(
                startX: 0.28,
                targetX: 0.18,
                width: 0.55,
                phase: 4.6,
                waveSpeed: 0.69
            ),
            RibbonSeed(
                startX: 0.47,
                targetX: 0.27,
                width: 0.74,
                phase: 5.4,
                waveSpeed: 0.84
            ),
            RibbonSeed(
                startX: 0.65,
                targetX: 0.35,
                width: 0.52,
                phase: 6.1,
                waveSpeed: 0.64
            )
        ]
    }
}

// MARK: - Particles

private struct PlantParticle {
    enum Kind {
        case flower
        case pollen
    }

    let kind: Kind
    let phase: Double
    let drift: CGFloat
    let opacity: Double
    let scale: CGFloat
    let seed: Double
    let swaySpeed: Double
    let flickerSpeed: Double
    let rotationSpeed: Double
    let rotationPhase: Double
    let flowerPink: Bool
    let streamIndex: Int

    static func make() -> [PlantParticle] {
        var result: [PlantParticle] = []

        result.reserveCapacity(150)

        // Flowers.
        for i in 0..<52 {
            result.append(
                PlantParticle(
                    kind: .flower,
                    phase:
                        fract(
                            0.07 +
                            Double(i) *
                            0.754877666
                        ),
                    drift:
                        CGFloat(
                            2.0 +
                            Double(i % 5) *
                            0.7
                        ),
                    opacity:
                        0.24 +
                        Double(i % 7) *
                        0.032,
                    scale:
                        CGFloat(
                            0.46 +
                            Double(i % 5) *
                            0.13
                        ),
                    seed:
                        Double(i) *
                        1.83 +
                        9,
                    swaySpeed:
                        0.55 +
                        Double(i % 5) *
                        0.055,
                    flickerSpeed:
                        0.60 +
                        Double(i % 4) *
                        0.12,
                    rotationSpeed:
                        0.12 +
                        Double(i % 7) *
                        0.025,
                    rotationPhase:
                        Double(i % 11) *
                        0.57,
                    flowerPink:
                        i % 3 != 0,
                    streamIndex:
                        i % 8
                )
            )
        }

        // Pollen.
        for i in 0..<96 {
            result.append(
                PlantParticle(
                    kind: .pollen,
                    phase:
                        fract(
                            0.17 +
                            Double(i) *
                            0.4142135623
                        ),
                    drift:
                        CGFloat(
                            1.8 +
                            Double(i % 6) *
                            0.45
                        ),
                    opacity:
                        0.12 +
                        Double(i % 6) *
                        0.028,
                    scale:
                        CGFloat(
                            0.45 +
                            Double(i % 5) *
                            0.14
                        ),
                    seed:
                        Double(i) *
                        2.31 +
                        17,
                    swaySpeed:
                        0.65 +
                        Double(i % 5) *
                        0.08,
                    flickerSpeed:
                        1.6 +
                        Double(i % 6) *
                        0.22,
                    rotationSpeed: 0,
                    rotationPhase: 0,
                    flowerPink: false,
                    streamIndex:
                        (i * 3) % 8
                )
            )
        }

        return result
    }

    private static func fract(
        _ x: Double
    ) -> Double {
        x - floor(x)
    }
}

// MARK: - CGPoint helper

private extension CGPoint {
    func interpolated(
        with other: CGPoint,
        amount: CGFloat
    ) -> CGPoint {

        CGPoint(
            x:
                x +
                (other.x - x) *
                amount,
            y:
                y +
                (other.y - y) *
                amount
        )
    }
}
