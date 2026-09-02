import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []
    @State private var animatedProgress: Double = 0

    private let sectorCount = 6
    private let disconnectTotal: TimeInterval = 3.0
    private let sectorDuration: TimeInterval = 0.6
    private let sectorStartStep: TimeInterval = 0.48

    var body: some View {
        TimelineView(
            .animation(minimumInterval: 1.0 / 60.0, paused: false)
        ) { context in

            let now = context.date
            let disconnectElapsed = disconnectStart.map {
                now.timeIntervalSince($0)
            }

            let logoHeight: CGFloat = 181.0
            let logoWidth = logoHeight * 814.0 / 1000.0

            GeometryReader { geo in
                ZStack {
                    AppleLogoFill(
                        progress: animatedProgress,
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

                    PlantParticleField(
                        progress: animatedProgress,
                        time: now.timeIntervalSinceReferenceDate,
                        active: isCharging && disconnectElapsed == nil,
                        logoWidth: logoWidth,
                        logoHeight: logoHeight
                    )
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .onAppear {
                animatedProgress = 0

                if isCharging {
                    animateProgressTowardBatteryLevel()
                } else if disconnectStart == nil {
                    beginDisconnect(at: now)
                }
            }
            .onChange(of: progress) { _, _ in
                if isCharging && disconnectStart == nil {
                    animateProgressTowardBatteryLevel()
                }
            }
            .onChange(of: isCharging) { _, charging in
                if charging {
                    disconnectStart = nil
                    disconnectOrder = []
                    animateProgressTowardBatteryLevel()
                } else if disconnectStart == nil {
                    beginDisconnect(at: now)
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    // MARK: - Progress

    private var normalizedProgress: Double {
        let raw = progress

        // Supports both:
        // 0.00 ... 1.00
        // and
        // 0 ... 100
        let value = raw > 1.0 ? raw / 100.0 : raw

        return min(
            1.0,
            max(0.0, value)
        )
    }

    private func animateProgressTowardBatteryLevel() {
        let target = normalizedProgress
        let distance = abs(target - animatedProgress)

        let duration = min(
            8.0,
            max(
                0.35,
                distance * 4.0
            )
        )

        withAnimation(
            .easeInOut(duration: duration)
        ) {
            animatedProgress = target
        }
    }

    // MARK: - Disconnect

    private func beginDisconnect(at date: Date) {
        disconnectOrder = Array(
            0..<sectorCount
        ).shuffled()

        disconnectStart = date
    }
}

// MARK: - Apple Logo Fill

private struct AppleLogoFill: View {
    let progress: Double
    let time: TimeInterval
    let disconnectElapsed: TimeInterval?
    let disconnectOrder: [Int]
    let sectorCount: Int
    let sectorDuration: TimeInterval
    let sectorStartStep: TimeInterval
    let disconnectTotal: TimeInterval

    // Classic 1980s Apple rainbow.
    // Bottom -> top.
    private let colors: [Color] = [
        Color(
            red: 0.12,
            green: 0.36,
            blue: 0.86
        ), // blue

        Color(
            red: 0.42,
            green: 0.22,
            blue: 0.72
        ), // purple

        Color(
            red: 0.88,
            green: 0.12,
            blue: 0.16
        ), // red

        Color(
            red: 0.98,
            green: 0.42,
            blue: 0.08
        ), // orange

        Color(
            red: 0.98,
            green: 0.78,
            blue: 0.08
        ), // yellow

        Color(
            red: 0.22,
            green: 0.68,
            blue: 0.20
        )  // green
    ]

    var body: some View {
        GeometryReader { geo in

            let bodyTop =
                geo.size.height * 0.2443

            let bodyBottom =
                geo.size.height * 0.9999

            let bodyHeight =
                bodyBottom - bodyTop

            let bandHeight =
                bodyHeight / CGFloat(sectorCount)

            // Body reaches 100% of its six sectors
            // at 88% battery.
            let bodyProgress =
                min(
                    1.0,
                    progress / 0.88
                )

            let scaled =
                bodyProgress * Double(sectorCount)

            let completed =
                min(
                    sectorCount,
                    Int(scaled.rounded(.down))
                )

            let currentFraction =
                min(
                    1.0,
                    max(
                        0.0,
                        scaled - Double(completed)
                    )
                )

            let leafGrowth =
                leafProgress

            ZStack(alignment: .topLeading) {

                ForEach(
                    0..<sectorCount,
                    id: \.self
                ) { index in

                    let amount: CGFloat =
                        index < completed
                        ? 1.0
                        : (
                            index == completed
                            ? CGFloat(
                                max(
                                    0,
                                    min(
                                        1,
                                        currentFraction
                                    )
                                )
                            )
                            : 0.0
                        )

                    let opacity =
                        sectorOpacity(index)

                    if amount > 0 && opacity > 0 {

                        let bottomY =
                            bodyBottom
                            - CGFloat(index)
                            * bandHeight

                        let fillHeight =
                            max(
                                0.01,
                                bandHeight * amount
                            )

                        let topY =
                            bottomY - fillHeight

                        LiquidSector(
                            width: geo.size.width,
                            height: fillHeight,
                            amplitude: min(
                                9.0,
                                max(
                                    4.0,
                                    bandHeight * 0.18
                                )
                            ),
                            phase:
                                time
                                * (
                                    0.55
                                    + Double(index)
                                    * 0.035
                                )
                                + Double(index) * 1.37
                        )
                        .fill(colors[index])
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
            .mask(
                AppleBodyShape()
            )
            .overlay {

                LeafBudStem(
                    progress: leafGrowth
                )
                .opacity(stemOpacity)

                AppleLeafShape()
                    .fill(colors.last!)
                    .scaleEffect(
                        max(
                            0.035,
                            leafGrowth
                        ),
                        anchor: UnitPoint(
                            x: 0.51,
                            y: 0.231
                        )
                    )
                    .opacity(leafGrowth)
            }
        }
    }

    // MARK: - Leaf

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

        return normal
            * max(
                0,
                1.0 - elapsed / disconnectTotal
            )
    }

    private var stemOpacity: Double {
        let p = leafProgress

        let appear =
            min(
                1.0,
                p / 0.20
            )

        let disappear =
            max(
                0,
                min(
                    1,
                    (1.0 - p) / 0.04
                )
            )

        return appear * disappear
    }

    // MARK: - Random Disconnect

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
                disconnectOrder.firstIndex(
                    of: index
                )
        else {
            return 1.0
        }

        let start =
            Double(position)
            * sectorStartStep

        let end =
            start + sectorDuration

        if elapsed <= start {
            return 1.0
        }

        if elapsed >= end {
            return 0.0
        }

        let t =
            (elapsed - start)
            / sectorDuration

        if t <= 0.8 {

            let u =
                t / 0.8

            let eased =
                u * u * (3.0 - 2.0 * u)

            return
                1.0
                + (
                    0.20 - 1.0
                ) * eased

        } else {

            let u =
                (t - 0.8)
                / 0.2

            let eased =
                u * u * (3.0 - 2.0 * u)

            return
                0.20
                * (1.0 - eased)
        }
    }
}

// MARK: - Liquid Wave

private struct LiquidSector: Shape {

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

        path.move(
            to: CGPoint(
                x: x0,
                y:
                    y
                    + sin(phase)
                    * a
                    * 0.15
            )
        )

        path.addCurve(
            to: CGPoint(
                x: mid,
                y:
                    y
                    + sin(
                        phase + 1.7
                    ) * a
            ),
            control1: CGPoint(
                x: width * 0.17,
                y: y - a * 0.35
            ),
            control2: CGPoint(
                x: width * 0.34,
                y: y + a * 1.15
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x1,
                y:
                    y
                    + sin(
                        phase + 3.2
                    ) * a * 0.55
            ),
            control1: CGPoint(
                x: width * 0.66,
                y: y - a * 1.10
            ),
            control2: CGPoint(
                x: width * 0.84,
                y: y + a * 0.85
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

// MARK: - Leaf Bud / Stem

private struct LeafBudStem: View {

    let progress: Double

    var body: some View {

        GeometryReader { geo in

            let w =
                geo.size.width

            let h =
                geo.size.height

            let x =
                w * 0.515

            let baseY =
                h * 0.245

            let topY =
                baseY
                - h * 0.045
                * progress

            Path { path in

                path.move(
                    to: CGPoint(
                        x: x,
                        y: baseY
                    )
                )

                path.addCurve(
                    to: CGPoint(
                        x:
                            x
                            + w * 0.025,
                        y: topY
                    ),
                    control1: CGPoint(
                        x:
                            x
                            - w * 0.01,
                        y:
                            baseY
                            - h * 0.018
                    ),
                    control2: CGPoint(
                        x:
                            x
                            + w * 0.018,
                        y:
                            topY
                            + h * 0.012
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

// MARK: - Exactly 222 Particles

private struct PlantParticleField: View {

    let progress: Double
    let time: TimeInterval
    let active: Bool
    let logoWidth: CGFloat
    let logoHeight: CGFloat

    // EXACTLY 222:
    // 82 leaves
    // 60 flowers
    // 80 pollen threads
    private let particles: [PlantParticle] =
        PlantParticle.make222()

    var body: some View {

        Canvas { context, size in

            guard
                active,
                progress > 0.0,
                progress < 1.0
            else {
                return
            }

            let strength: Double =
                progress >= 0.92
                ? max(
                    0,
                    (1.0 - progress) / 0.08
                )
                : 1.0

            let centerX =
                size.width / 2

            let targetY =
                size.height / 2
                + logoHeight * 0.20

            for particle in particles {

                let cycle = 3.8

                let phase =
                    (
                        time / cycle
                        + particle.phase
                    )
                    .truncatingRemainder(
                        dividingBy: 1.0
                    )

                let t =
                    phase < 0
                    ? phase + 1.0
                    : phase

                let eased =
                    t * t * (3.0 - 2.0 * t)

                let startX =
                    centerX
                    + particle.startX
                    * size.width
                    * 0.22

                let startY =
                    size.height
                    * particle.startY

                let targetX =
                    centerX
                    + particle.targetX
                    * logoWidth
                    * 0.34

                let x =
                    startX
                    + (
                        targetX
                        - startX
                    ) * eased
                    + sin(
                        t * .pi * 4
                        + particle.seed
                    )
                    * particle.drift

                let y =
                    startY
                    + (
                        targetY
                        - startY
                    ) * eased

                let absorb =
                    t > 0.88
                    ? max(
                        0,
                        (1.0 - t) / 0.12
                    )
                    : 1.0

                let alpha =
                    particle.opacity
                    * strength
                    * absorb

                let scale =
                    particle.scale
                    * (
                        t > 0.82
                        ? max(
                            0.05,
                            (1.0 - t) / 0.18
                        )
                        : 1.0
                    )

                context.opacity = alpha

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

        case .leaf:

            var leaf = Path()

            leaf.move(
                to: CGPoint(
                    x: point.x,
                    y: point.y
                        + 5 * scale
                )
            )

            leaf.addQuadCurve(
                to: CGPoint(
                    x:
                        point.x
                        + 8 * scale,
                    y:
                        point.y
                        - 5 * scale
                ),
                control: CGPoint(
                    x:
                        point.x
                        + 2 * scale,
                    y:
                        point.y
                        - 7 * scale
                )
            )

            leaf.addQuadCurve(
                to: CGPoint(
                    x: point.x,
                    y:
                        point.y
                        + 5 * scale
                ),
                control: CGPoint(
                    x:
                        point.x
                        + 1 * scale,
                    y:
                        point.y
                        + 1 * scale
                )
            )

            context.fill(
                leaf,
                with: .color(
                    Color(
                        red: 0.42,
                        green: 0.78,
                        blue: 0.12
                    )
                )
            )

        case .flower:

            let r =
                2.4 * scale

            var flower = Path()

            for i in 0..<5 {

                let a =
                    CGFloat(i)
                    * .pi
                    * 2
                    / 5

                let c =
                    CGPoint(
                        x:
                            point.x
                            + cos(a)
                            * r
                            * 1.5,
                        y:
                            point.y
                            + sin(a)
                            * r
                            * 1.5
                    )

                flower.addEllipse(
                    in: CGRect(
                        x: c.x - r,
                        y: c.y - r,
                        width: r * 2,
                        height: r * 2
                    )
                )
            }

            flower.addEllipse(
                in: CGRect(
                    x:
                        point.x
                        - r * 0.75,
                    y:
                        point.y
                        - r * 0.75,
                    width: r * 1.5,
                    height: r * 1.5
                )
            )

            context.fill(
                flower,
                with: .color(
                    Color(
                        red: 1.0,
                        green: 0.80,
                        blue: 0.20
                    )
                )
            )

        case .pollen:

            let length =
                particle.length
                * (
                    0.78
                    + 0.22
                    * sin(
                        time * 2.1
                        + particle.seed
                    )
                )

            var thread = Path()

            thread.move(
                to: CGPoint(
                    x: point.x,
                    y: point.y
                )
            )

            thread.addCurve(
                to: CGPoint(
                    x:
                        point.x
                        + particle.threadDX
                        * length,
                    y:
                        point.y
                        - length
                ),
                control1: CGPoint(
                    x:
                        point.x
                        - particle.threadDX
                        * length
                        * 0.35,
                    y:
                        point.y
                        - length
                        * 0.35
                ),
                control2: CGPoint(
                    x:
                        point.x
                        + particle.threadDX
                        * length
                        * 0.80,
                    y:
                        point.y
                        - length
                        * 0.68
                )
            )

            context.stroke(
                thread,
                with: .color(
                    Color(
                        red: 0.35,
                        green: 0.95,
                        blue: 0.35
                    )
                ),
                style: StrokeStyle(
                    lineWidth:
                        max(
                            0.45,
                            0.75 * scale
                        ),
                    lineCap: .round
                )
            )
        }
    }
}

// MARK: - Particle Data

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

    static func make222()
        -> [PlantParticle] {

        var result: [PlantParticle] = []

        result.reserveCapacity(222)

        // 82 leaves
        for i in 0..<82 {

            result.append(
                PlantParticle(
                    kind: .leaf,
                    phase:
                        fract(
                            Double(i)
                            * 0.6180339887
                        ),
                    startX:
                        signedUnit(
                            i * 17 + 3
                        ),
                    startY:
                        0.62
                        + fract(
                            Double(i)
                            * 0.173
                        ) * 0.23,
                    targetX:
                        signedUnit(
                            i * 11 + 7
                        ),
                    drift:
                        CGFloat(
                            4 + (i % 7)
                        ),
                    opacity:
                        0.28
                        + Double(i % 8)
                        * 0.045,
                    scale:
                        CGFloat(
                            0.55
                            + Double(i % 6)
                            * 0.10
                        ),
                    length: 0,
                    threadDX: 0,
                    seed:
                        Double(i) * 1.17
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
                            0.31
                            + Double(i)
                            * 0.754877666
                        ),
                    startX:
                        signedUnit(
                            i * 23 + 5
                        ),
                    startY:
                        0.67
                        + fract(
                            Double(i)
                            * 0.211
                        ) * 0.17,
                    targetX:
                        signedUnit(
                            i * 13 + 2
                        ),
                    drift:
                        CGFloat(
                            3 + (i % 6)
                        ),
                    opacity:
                        0.24
                        + Double(i % 7)
                        * 0.05,
                    scale:
                        CGFloat(
                            0.45
                            + Double(i % 5)
                            * 0.12
                        ),
                    length: 0,
                    threadDX: 0,
                    seed:
                        Double(i) * 1.83
                        + 9
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
                            0.17
                            + Double(i)
                            * 0.4142135623
                        ),
                    startX:
                        signedUnit(
                            i * 29 + 1
                        ),
                    startY:
                        0.60
                        + fract(
                            Double(i)
                            * 0.139
                        ) * 0.27,
                    targetX:
                        signedUnit(
                            i * 19 + 4
                        ),
                    drift:
                        CGFloat(
                            2 + (i % 5)
                        ),
                    opacity:
                        0.16
                        + Double(i % 6)
                        * 0.045,
                    scale:
                        CGFloat(
                            0.60
                            + Double(i % 4)
                            * 0.12
                        ),
                    length:
                        CGFloat(
                            5 + i % 12
                        ),
                    threadDX:
                        CGFloat(
                            -0.55
                            + Double(i % 12)
                            * 0.10
                        ),
                    seed:
                        Double(i) * 2.31
                        + 17
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

        let v =
            sin(
                Double(x)
                * 12.9898
            )
            * 43758.5453

        return CGFloat(
            (v - floor(v))
            * 2.0
            - 1.0
        )
    }
}
