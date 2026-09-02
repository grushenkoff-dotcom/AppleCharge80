import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var animatedProgress: Double = 0
    @State private var chargingStart: Date?
    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []

    private let sectorCount = 6

    // Full charging animation.
    private let chargeDuration: TimeInterval = 8.0

    // Complete disappearance after unplugging.
    private let disconnectTotal: TimeInterval = 3.0

    // Each sector fades for 0.60 s.
    private let sectorDuration: TimeInterval = 0.60

    // Next sector starts when previous one is 80% gone.
    private let sectorStartStep: TimeInterval = 0.48

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 60.0,
                paused: false
            )
        ) { context in

            let now = context.date

            let disconnectElapsed =
                disconnectStart.map {
                    now.timeIntervalSince($0)
                }

            GeometryReader { geo in

                let logoHeight =
                    min(
                        CGFloat(181.0),
                        geo.size.height * 0.24
                    )

                let logoWidth =
                    logoHeight * 814.0 / 1000.0

                let targetProgress =
                    normalizedProgress

                let currentProgress =
                    resolvedProgress(
                        now: now,
                        target: targetProgress
                    )

                ZStack {

                    // MARK: Apple logo

                    LogoArtwork(
                        progress: currentProgress,
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
                    .position(
                        x: geo.size.width / 2,
                        y: geo.size.height * 0.52
                    )

                    // MARK: Flying leaves / flowers / pollen

                    ParticleStream(
                        time: now.timeIntervalSinceReferenceDate,
                        progress: currentProgress,
                        active:
                            isCharging &&
                            disconnectElapsed == nil,
                        logoWidth: logoWidth,
                        logoHeight: logoHeight,
                        logoCenter: CGPoint(
                            x: geo.size.width / 2,
                            y: geo.size.height * 0.52
                        )
                    )
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height
                    )
                }
            }

            .onAppear {

                if isCharging {
                    startCharging(at: now)
                } else if disconnectStart == nil {
                    beginDisconnect(at: now)
                }
            }

            .onChange(of: isCharging) { _, charging in

                if charging {
                    startCharging(at: now)
                } else {
                    beginDisconnect(at: now)
                }
            }
        }

        .background(Color.black)
        .ignoresSafeArea()
    }

    // MARK: - Progress

    private var normalizedProgress: Double {
        let value =
            progress > 1.0
            ? progress / 100.0
            : progress

        return min(
            1.0,
            max(0.0, value)
        )
    }

    private func resolvedProgress(
        now: Date,
        target: Double
    ) -> Double {

        // Charging:
        // always starts from zero and grows toward
        // the actual battery level.

        if let start = chargingStart,
           isCharging {

            let elapsed =
                now.timeIntervalSince(start)

            let t =
                min(
                    1.0,
                    max(
                        0.0,
                        elapsed / chargeDuration
                    )
                )

            return target * smoothStep(t)
        }

        // Disconnect:
        // keep the charged state while the random
        // sector disappearance animation runs.

        if let start = disconnectStart {

            let elapsed =
                now.timeIntervalSince(start)

            if elapsed >= disconnectTotal {
                return 0
            }
        }

        return animatedProgress
    }

    // MARK: - Charging

    private func startCharging(at date: Date) {

        disconnectStart = nil
        disconnectOrder = []

        animatedProgress = 0
        chargingStart = date
    }

    // MARK: - Disconnect

    private func beginDisconnect(at date: Date) {

        chargingStart = nil

        disconnectOrder =
            Array(0..<sectorCount).shuffled()

        disconnectStart = date

        animatedProgress =
            normalizedProgress
    }

    // MARK: - Smooth timing

    private func smoothStep(
        _ t: Double
    ) -> Double {

        let x =
            min(
                1.0,
                max(0.0, t)
            )

        return
            x * x * (3.0 - 2.0 * x)
    }
}


// MARK: - Apple logo

private struct LogoArtwork: View {

    let progress: Double
    let time: TimeInterval

    let disconnectElapsed: TimeInterval?
    let disconnectOrder: [Int]

    let sectorCount: Int

    let sectorDuration: TimeInterval
    let sectorStartStep: TimeInterval
    let disconnectTotal: TimeInterval

    // Bottom -> top.
    private let colors: [Color] = [

        Color(
            red: 0.05,
            green: 0.42,
            blue: 0.95
        ),

        Color(
            red: 0.39,
            green: 0.18,
            blue: 0.78
        ),

        Color(
            red: 0.82,
            green: 0.05,
            blue: 0.35
        ),

        Color(
            red: 0.98,
            green: 0.22,
            blue: 0.10
        ),

        Color(
            red: 1.00,
            green: 0.52,
            blue: 0.05
        ),

        Color(
            red: 0.42,
            green: 0.78,
            blue: 0.12
        )
    ]

    var body: some View {

        GeometryReader { geo in

            // Exact body area of the supplied SVG.
            let bodyTop =
                geo.size.height * 0.2443

            let bodyBottom =
                geo.size.height * 0.9999

            let bodyHeight =
                bodyBottom - bodyTop

            let bandHeight =
                bodyHeight / CGFloat(sectorCount)

            // 0...88% = Apple body.
            let bodyProgress =
                min(
                    1.0,
                    progress / 0.88
                )

            let scaled =
                bodyProgress *
                Double(sectorCount)

            let completed =
                min(
                    sectorCount,
                    Int(
                        scaled.rounded(.down)
                    )
                )

            let currentFraction =
                min(
                    1.0,
                    max(
                        0.0,
                        scaled -
                        Double(completed)
                    )
                )

            ZStack(
                alignment: .topLeading
            ) {

                ForEach(
                    0..<sectorCount,
                    id: \.self
                ) { index in

                    let amount: CGFloat

                    if index < completed {

                        amount = 1.0

                    } else if
                        index == completed &&
                        completed < sectorCount
                    {

                        amount =
                            CGFloat(
                                currentFraction
                            )

                    } else {

                        amount = 0.0
                    }

                    let opacity =
                        sectorOpacity(index)

                    if
                        amount > 0.0001 &&
                        opacity > 0.0001
                    {

                        let bottomY =
                            bodyBottom -
                            CGFloat(index) *
                            bandHeight

                        let fillHeight =
                            max(
                                0.5,
                                bandHeight * amount
                            )

                        let topY =
                            bottomY -
                            fillHeight

                        LiquidSector(
                            height: fillHeight,
                            amplitude:
                                min(
                                    11.0,
                                    max(
                                        5.0,
                                        bandHeight * 0.24
                                    )
                                ),
                            phase:
                                time *
                                (
                                    0.42 +
                                    Double(index) *
                                    0.035
                                )
                                +
                                Double(index) *
                                1.41
                        )
                        .fill(colors[index])
                        .frame(
                            width: geo.size.width,
                            height: fillHeight
                        )
                        .position(
                            x: geo.size.width / 2,
                            y:
                                (topY + bottomY) / 2
                        )
                        .opacity(opacity)
                    }
                }
            }

            // Exact supplied Apple body geometry.
            .mask(
                AppleBodyShape()
            )

            // Leaf is NOT a separate stem/branch.
            // It grows from the original leaf geometry.
            .overlay {

                LeafMorph(
                    progress: leafProgress,
                    color: colors[5]
                )
            }
        }
    }

    // MARK: - Leaf 88% -> 100%

    private var leafProgress: Double {

        let normal =
            min(
                1.0,
                max(
                    0.0,
                    (progress - 0.88) / 0.12
                )
            )

        guard
            let elapsed = disconnectElapsed
        else {
            return normal
        }

        return
            normal *
            max(
                0.0,
                1.0 -
                elapsed / disconnectTotal
            )
    }

    // MARK: - Random sector disappearance

    private func sectorOpacity(
        _ index: Int
    ) -> Double {

        guard
            let elapsed = disconnectElapsed
        else {
            return 1.0
        }

        if elapsed >= disconnectTotal {
            return 0.0
        }

        guard
            let position =
                disconnectOrder.firstIndex(
                    of: index
                )
        else {
            return 1.0
        }

        let start =
            Double(position) *
            sectorStartStep

        let end =
            start +
            sectorDuration

        if elapsed <= start {
            return 1.0
        }

        if elapsed >= end {
            return 0.0
        }

        let t =
            (elapsed - start) /
            sectorDuration

        // At 80% of the sector's own
        // disappearance time it is exactly 20%.
        if t <= 0.8 {

            return
                1.0 -
                0.8 *
                smoothStep(
                    t / 0.8
                )
        }

        return
            0.2 *
            (
                1.0 -
                smoothStep(
                    (t - 0.8) / 0.2
                )
            )
    }

    private func smoothStep(
        _ t: Double
    ) -> Double {

        let x =
            min(
                1.0,
                max(0.0, t)
            )

        return
            x * x *
            (3.0 - 2.0 * x)
    }
}


// MARK: - Organic liquid boundary

private struct LiquidSector: Shape {

    let height: CGFloat
    let amplitude: CGFloat
    let phase: Double

    func path(
        in rect: CGRect
    ) -> Path {

        var path = Path()

        let a =
            min(
                amplitude,
                max(
                    1.0,
                    height * 0.45
                )
            )

        let y =
            rect.minY

        let x0 =
            rect.minX

        let x1 =
            rect.maxX

        let mid =
            rect.midX

        // Large smooth organic wave.
        path.move(
            to: CGPoint(
                x: x0,
                y:
                    y +
                    sin(phase) *
                    a *
                    0.18
            )
        )

        path.addCurve(
            to: CGPoint(
                x: mid,
                y:
                    y +
                    sin(phase + 1.65) *
                    a
            ),

            control1: CGPoint(
                x: rect.width * 0.16,
                y: y - a * 0.40
            ),

            control2: CGPoint(
                x: rect.width * 0.36,
                y: y + a * 1.12
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x1,
                y:
                    y +
                    sin(phase + 3.05) *
                    a *
                    0.58
            ),

            control1: CGPoint(
                x: rect.width * 0.64,
                y: y - a * 1.08
            ),

            control2: CGPoint(
                x: rect.width * 0.84,
                y: y + a * 0.82
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


// MARK: - Leaf morph

private struct LeafMorph: View {

    let progress: Double
    let color: Color

    var body: some View {

        GeometryReader { geo in

            let p =
                min(
                    1.0,
                    max(0.0, progress)
                )

            let eased =
                p * p *
                (3.0 - 2.0 * p)

            // Starts as a compact bud-like form.
            let scaleX =
                0.10 +
                0.90 * eased

            let scaleY =
                0.08 +
                0.92 * eased

            // Slightly tilted while growing,
            // then settles into the exact leaf orientation.
            let rotation =
                14.0 *
                (1.0 - eased)

            let opacity =
                p > 0
                ? min(
                    1.0,
                    p / 0.12
                )
                : 0.0

            AppleLeafShape()
                .fill(color)
                .frame(
                    width: geo.size.width,
                    height: geo.size.height
                )
                .scaleEffect(
                    x: scaleX,
                    y: scaleY,
                    anchor:
                        UnitPoint(
                            x: 0.51,
                            y: 0.231
                        )
                )
                .rotationEffect(
                    .degrees(rotation),
                    anchor:
                        UnitPoint(
                            x: 0.51,
                            y: 0.231
                        )
                )
                .opacity(opacity)
        }
    }
}


// MARK: - 222 particles

private struct ParticleStream: View {

    let time: TimeInterval
    let progress: Double
    let active: Bool

    let logoWidth: CGFloat
    let logoHeight: CGFloat

    let logoCenter: CGPoint

    // EXACTLY 222:
    // 82 leaves
    // 60 flowers
    // 80 pollen threads
    private let particles =
        PlantParticle.make222()

    var body: some View {

        Canvas { context, size in

            guard
                active,
                progress > 0.02,
                progress < 0.995
            else {
                return
            }

            // Stream weakens as 100% is reached.
            let fade =
                progress > 0.92
                ? max(
                    0.0,
                    (1.0 - progress) / 0.08
                )
                : 1.0

            // Lower part of Apple is the absorption zone.
            let targetY =
                logoCenter.y +
                logoHeight * 0.24

            for particle in particles {

                let cycle =
                    4.2

                let phase =
                    (
                        time / cycle +
                        particle.phase
                    )
                    .truncatingRemainder(
                        dividingBy: 1.0
                    )

                let t =
                    phase < 0
                    ? phase + 1.0
                    : phase

                let travel =
                    t * t *
                    (3.0 - 2.0 * t)

                let startX =
                    size.width *
                    (
                        0.5 +
                        particle.startX *
                        0.22
                    )

                let startY =
                    size.height *
                    particle.startY

                let targetX =
                    logoCenter.x +
                    particle.targetX *
                    logoWidth *
                    0.38

                let x =
                    startX +
                    (
                        targetX -
                        startX
                    ) *
                    travel
                    +
                    sin(
                        t *
                        .pi *
                        4.0 +
                        particle.seed
                    ) *
                    particle.drift

                let y =
                    startY +
                    (
                        targetY -
                        startY
                    ) *
                    travel

                // Absorption happens only when
                // the particle reaches the logo.
                let absorption =
                    t > 0.90
                    ? max(
                        0.0,
                        (1.0 - t) / 0.10
                    )
                    : 1.0

                let alpha =
                    particle.opacity *
                    fade *
                    absorption

                let scale =
                    particle.scale *
                    (
                        t > 0.94
                        ? max(
                            0.18,
                            (1.0 - t) / 0.06
                        )
                        : 1.0
                    )

                context.opacity =
                    alpha

                drawParticle(
                    &context,
                    particle,
                    at: CGPoint(
                        x: x,
                        y: y
                    ),
                    scale: scale,
                    time: time
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func drawParticle(
        _ context: inout GraphicsContext,
        _ particle: PlantParticle,
        at point: CGPoint,
        scale: CGFloat,
        time: TimeInterval
    ) {

        switch particle.kind {

        // MARK: Leaf

        case .leaf:

            var leaf = Path()

            leaf.move(
                to: CGPoint(
                    x: point.x,
                    y: point.y + 5 * scale
                )
            )

            leaf.addQuadCurve(
                to: CGPoint(
                    x: point.x + 8 * scale,
                    y: point.y - 5 * scale
                ),
                control:
                    CGPoint(
                        x: point.x + 2 * scale,
                        y: point.y - 7 * scale
                    )
            )

            leaf.addQuadCurve(
                to: CGPoint(
                    x: point.x,
                    y: point.y + 5 * scale
                ),
                control:
                    CGPoint(
                        x: point.x + 1 * scale,
                        y: point.y + 1 * scale
                    )
            )

            context.fill(
                leaf,
                with:
                    .color(
                        Color(
                            red: 0.42,
                            green: 0.78,
                            blue: 0.12
                        )
                    )
            )

        // MARK: Flower

        case .flower:

            let r =
                2.4 * scale

            var flower = Path()

            for i in 0..<5 {

                let angle =
                    CGFloat(i) *
                    .pi *
                    2.0 /
                    5.0

                let center =
                    CGPoint(
                        x:
                            point.x +
                            cos(angle) *
                            r *
                            1.5,

                        y:
                            point.y +
                            sin(angle) *
                            r *
                            1.5
                    )

                flower.addEllipse(
                    in:
                        CGRect(
                            x:
                                center.x - r,
                            y:
                                center.y - r,
                            width:
                                r * 2,
                            height:
                                r * 2
                        )
                )
            }

            flower.addEllipse(
                in:
                    CGRect(
                        x:
                            point.x -
                            r * 0.75,

                        y:
                            point.y -
                            r * 0.75,

                        width:
                            r * 1.5,

                        height:
                            r * 1.5
                    )
            )

            context.fill(
                flower,
                with:
                    .color(
                        Color(
                            red: 1.0,
                            green: 0.80,
                            blue: 0.20
                        )
                    )
            )

        // MARK: Green pollen thread

        case .pollen:

            let length =
                particle.length *
                (
                    0.78 +
                    0.22 *
                    sin(
                        time * 2.1 +
                        particle.seed
                    )
                )

            var thread = Path()

            thread.move(
                to: point
            )

            thread.addCurve(
                to:
                    CGPoint(
                        x:
                            point.x +
                            particle.threadDX *
                            length,

                        y:
                            point.y -
                            length
                    ),

                control1:
                    CGPoint(
                        x:
                            point.x -
                            particle.threadDX *
                            length *
                            0.35,

                        y:
                            point.y -
                            length *
                            0.35
                    ),

                control2:
                    CGPoint(
                        x:
                            point.x +
                            particle.threadDX *
                            length *
                            0.80,

                        y:
                            point.y -
                            length *
                            0.68
                    )
            )

            // Soft green shimmer.
            let shimmer =
                0.70 +
                0.30 *
                sin(
                    time * 3.0 +
                    particle.seed
                )

            context.stroke(
                thread,
                with:
                    .color(
                        Color(
                            red:
                                0.35 +
                                0.15 *
                                shimmer,

                            green:
                                0.90 +
                                0.08 *
                                shimmer,

                            blue:
                                0.30 +
                                0.10 *
                                shimmer
                        )
                    ),
                style:
                    StrokeStyle(
                        lineWidth:
                            max(
                                0.45,
                                0.75 *
                                scale
                            ),
                        lineCap:
                            .round
                    )
            )
        }
    }
}


// MARK: - Particle model

private struct PlantParticle {

    enum Kind {
        case leaf
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
    let threadDX: CGFloat

    let seed: Double

    // EXACTLY 222 PARTICLES.
    static func make222()
        -> [PlantParticle]
    {
        var result:
            [PlantParticle] = []

        result.reserveCapacity(222)

        // 82 leaves
        for i in 0..<82 {

            result.append(
                PlantParticle(
                    kind: .leaf,

                    phase:
                        fract(
                            Double(i) *
                            0.6180339887
                        ),

                    startX:
                        signedUnit(
                            i * 17 + 3
                        ),

                    startY:
                        0.62 +
                        fract(
                            Double(i) *
                            0.173
                        ) *
                        0.23,

                    targetX:
                        signedUnit(
                            i * 11 + 7
                        ),

                    drift:
                        CGFloat(
                            3 +
                            (i % 7)
                        ),

                    opacity:
                        0.34 +
                        Double(i % 8) *
                        0.035,

                    scale:
                        CGFloat(
                            0.60 +
                            Double(i % 6) *
                            0.10
                        ),

                    length: 0,

                    threadDX: 0,

                    seed:
                        Double(i) *
                        1.17
                )
            )
        }

        // 60 flowers
        for i in 0..<60 {

            result.append(
                PlantParticle(
                    kind: .flower,

                    phase:
                        fract(
                            0.31 +
                            Double(i) *
                            0.754877666
                        ),

                    startX:
                        signedUnit(
                            i * 23 + 5
                        ),

                    startY:
                        0.67 +
                        fract(
                            Double(i) *
                            0.211
                        ) *
                        0.17,

                    targetX:
                        signedUnit(
                            i * 13 + 2
                        ),

                    drift:
                        CGFloat(
                            2 +
                            (i % 6)
                        ),

                    opacity:
                        0.28 +
                        Double(i % 7) *
                        0.045,

                    scale:
                        CGFloat(
                            0.48 +
                            Double(i % 5) *
                            0.12
                        ),

                    length: 0,

                    threadDX: 0,

                    seed:
                        Double(i) *
                        1.83 +
                        9
                )
            )
        }

        // 80 pollen threads
        for i in 0..<80 {

            result.append(
                PlantParticle(
                    kind: .pollen,

                    phase:
                        fract(
                            0.17 +
                            Double(i) *
                            0.4142135623
                        ),

                    startX:
                        signedUnit(
                            i * 29 + 1
                        ),

                    startY:
                        0.60 +
                        fract(
                            Double(i) *
                            0.139
                        ) *
                        0.27,

                    targetX:
                        signedUnit(
                            i * 19 + 4
                        ),

                    drift:
                        CGFloat(
                            1.5 +
                            Double(i % 5)
                        ),

                    opacity:
                        0.20 +
                        Double(i % 6) *
                        0.04,

                    scale:
                        CGFloat(
                            0.60 +
                            Double(i % 4) *
                            0.12
                        ),

                    length:
                        CGFloat(
                            5 +
                            i % 12
                        ),

                    threadDX:
                        CGFloat(
                            -0.55 +
                            Double(i % 12) *
                            0.10
                        ),

                    seed:
                        Double(i) *
                        2.31 +
                        17
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

    private static func signedUnit(
        _ x: Int
    ) -> CGFloat {

        let value =
            sin(
                Double(x) *
                12.9898
            ) *
            43758.5453

        return CGFloat(
            (
                value -
                floor(value)
            ) *
            2.0 -
            1.0
        )
    }
}
