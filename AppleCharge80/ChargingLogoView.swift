import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []
    @State private var streamStartDate: Date?

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

            let logoHeight: CGFloat = 181.0
            let logoWidth = logoHeight * 814.0 / 1000.0

            GeometryReader { geo in
                let logoTopY = geoSafeTop(geo.size.height)
                let logoCenterY = logoTopY + logoHeight * 0.5

                ZStack {
                    PlantParticleField(
                        time: now.timeIntervalSinceReferenceDate,
                        active: isCharging && disconnectElapsed == nil,
                        streamStartDate: streamStartDate,
                        logoWidth: logoWidth,
                        logoHeight: logoHeight,
                        logoTopY: logoTopY
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
                    .position(
                        x: geo.size.width / 2,
                        y: logoCenterY
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .onAppear {
                if isCharging {
                    if streamStartDate == nil {
                        streamStartDate = now
                    }
                } else if disconnectStart == nil {
                    beginDisconnect(at: now)
                }
            }
            .onChange(of: isCharging) { _, charging in
                if charging {
                    disconnectStart = nil
                    disconnectOrder = []
                    streamStartDate = now
                } else {
                    streamStartDate = nil

                    if disconnectStart == nil {
                        beginDisconnect(at: now)
                    }
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    private func geoSafeTop(_ height: CGFloat) -> CGFloat {
        max(58.0, height * 0.10)
    }

    private var clampedProgress: Double {
        min(1.0, max(0.0, progress))
    }

    private func beginDisconnect(at date: Date) {
        disconnectOrder = Array(0..<sectorCount).shuffled()
        disconnectStart = date
    }
}

// MARK: - Apple logo

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

            let completed = min(
                sectorCount,
                Int(scaled.rounded(.down))
            )

            let currentFraction = scaled - Double(completed)
            let leafGrowth = leafProgress

            ZStack(alignment: .topLeading) {
                ForEach(
                    Array(0..<sectorCount),
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
                                    min(1, currentFraction)
                                )
                            )
                            : 0.0
                        )

                    let opacity = sectorOpacity(index)

                    if amount > 0 && opacity > 0 {
                        let bottomY =
                            bodyBottom
                            - CGFloat(index) * bandHeight

                        let fillHeight = max(
                            0.01,
                            bandHeight * amount
                        )

                        let topY = bottomY - fillHeight
                        let isCurrent =
                            index == completed &&
                            completed < sectorCount

                        let shimmer =
                            0.92
                            + 0.08
                            * sin(
                                time * 1.15
                                + Double(index) * 0.83
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
                                        time * 0.75
                                        + Double(index) * 1.37
                                )
                                .fill(
                                    sectorGradient(
                                        base: base,
                                        shimmer: shimmer
                                    )
                                )
                            } else {
                                Rectangle()
                                    .fill(
                                        sectorGradient(
                                            base: base,
                                            shimmer: shimmer
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
                        anchor: UnitPoint(
                            x: 0.51,
                            y: 0.231
                        )
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
            red: min(
                1,
                base.r * (0.86 * shimmer)
            ),
            green: min(
                1,
                base.g * (0.86 * shimmer)
            ),
            blue: min(
                1,
                base.b * (0.86 * shimmer)
            )
        )

        let mid = Color(
            red: min(
                1,
                base.r * (1.05 * shimmer)
            ),
            green: min(
                1,
                base.g * (1.05 * shimmer)
            ),
            blue: min(
                1,
                base.b * (1.05 * shimmer)
            )
        )

        let high = Color(
            red: min(
                1,
                base.r * (0.94 * shimmer)
            ),
            green: min(
                1,
                base.g * (0.94 * shimmer)
            ),
            blue: min(
                1,
                base.b * (0.94 * shimmer)
            )
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
        let normal = max(
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

        return min(
            1.0,
            p / 0.20
        )
        * max(
            0,
            min(
                1.0,
                (1.0 - p) / 0.04
            )
        )
    }

    private func sectorOpacity(_ index: Int) -> Double {
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
            (elapsed - start)
            / sectorDuration

        if t <= 0.8 {
            let u = t / 0.8
            let eased =
                u * u * (3.0 - 2.0 * u)

            return 1.0
                + (0.20 - 1.0) * eased
        } else {
            let u =
                (t - 0.8) / 0.2

            let eased =
                u * u * (3.0 - 2.0 * u)

            return 0.20
                * (1.0 - eased)
        }
    }
}

// MARK: - Animated sector top

private struct WavingSectorTop: Shape {
    let width: CGFloat
    let height: CGFloat
    let amplitude: CGFloat
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let a = min(
            amplitude,
            max(0.8, height * 0.20)
        )

        let y = rect.minY
        let x0 = rect.minX
        let x1 = rect.maxX
        let third = rect.width / 3.0

        path.move(
            to: CGPoint(
                x: x0,
                y: y
                    + CGFloat(sin(phase))
                    * a
                    * 0.35
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x0 + third,
                y: y
                    + CGFloat(
                        sin(phase + 1.9)
                    ) * a
            ),
            control1: CGPoint(
                x: x0 + third * 0.28,
                y: y
                    + CGFloat(
                        sin(phase + 0.7)
                    ) * a * 0.55
            ),
            control2: CGPoint(
                x: x0 + third * 0.72,
                y: y
                    + CGFloat(
                        sin(phase + 1.35)
                    ) * a * 1.15
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x0 + third * 2,
                y: y
                    + CGFloat(
                        sin(phase + 3.2)
                    ) * a * 0.72
            ),
            control1: CGPoint(
                x: x0 + third * 1.28,
                y: y
                    + CGFloat(
                        sin(phase + 2.35)
                    ) * a * 1.05
            ),
            control2: CGPoint(
                x: x0 + third * 1.72,
                y: y
                    + CGFloat(
                        sin(phase + 2.8)
                    ) * a * 0.35
            )
        )

        path.addCurve(
            to: CGPoint(
                x: x1,
                y: y
                    + CGFloat(
                        sin(phase + 4.8)
                    ) * a * 0.35
            ),
            control1: CGPoint(
                x: x0 + third * 2.28,
                y: y
                    + CGFloat(
                        sin(phase + 3.8)
                    ) * a * 0.90
            ),
            control2: CGPoint(
                x: x0 + third * 2.70,
                y: y
                    + CGFloat(
                        sin(phase + 4.35)
                    ) * a * 0.55
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

// MARK: - Leaf stem

private struct LeafBudStem: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let x = w * 0.515
            let baseY = h * 0.245

            let topY =
                baseY
                - h * 0.045 * progress

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
                        x: x - w * 0.01,
                        y: baseY
                            - h * 0.018
                    ),
                    control2: CGPoint(
                        x: x + w * 0.018,
                        y: topY
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
                    lineWidth: max(
                        1.0,
                        w * 0.018
                    ),
                    lineCap: .round
                )
            )
        }
    }
}

// MARK: - Living plant stream

private struct PlantParticleField: View {
    let time: TimeInterval
    let active: Bool
    let streamStartDate: Date?
    let logoWidth: CGFloat
    let logoHeight: CGFloat
    let logoTopY: CGFloat

    private let particles: [PlantParticle] =
        PlantParticle.make222()

    private let initialGrowthDuration: TimeInterval = 1.0

    var body: some View {
        Canvas { context, size in
            guard active else {
                return
            }

            guard let streamStartDate else {
                return
            }

            let elapsed =
                max(
                    0,
                    Date.timeIntervalSinceReferenceDate
                    - streamStartDate.timeIntervalSinceReferenceDate
                )

            let growth =
                max(
                    0,
                    min(
                        1,
                        elapsed / initialGrowthDuration
                    )
                )

            let logoBottomY =
                logoTopY + logoHeight

            let bottomY =
                size.height + 28.0

            let travelHeight =
                max(
                    1.0,
                    bottomY - logoBottomY
                )

            let centerX =
                size.width * 0.5

            /*
             First phase:
             several thin stems grow from the bottom
             and reach the future logo in ~1 second.

             Second phase:
             the stream remains alive and gradually
             becomes denser.
             */

            let density =
                streamDensity(
                    elapsed: elapsed
                )

            let streamParticles =
                particles.filter {
                    $0.kind == .stream
                }

            let cargoParticles =
                particles.filter {
                    $0.kind != .stream
                }

            for particle in streamParticles {
                guard
                    particle.streamOrder
                    < Int(
                        Double(streamParticles.count)
                        * density
                    )
                else {
                    continue
                }

                drawGrowingCurrent(
                    &context,
                    particle: particle,
                    size: size,
                    centerX: centerX,
                    logoBottomY: logoBottomY,
                    bottomY: bottomY,
                    travelHeight: travelHeight,
                    growth: growth,
                    elapsed: elapsed
                )
            }

            /*
             Flowers, leaves and pollen do not appear
             during the initial stem-growth phase.

             They are introduced progressively after
             the first stems have reached the logo.
             */

            guard elapsed > initialGrowthDuration else {
                return
            }

            let cargoProgress =
                max(
                    0,
                    min(
                        1,
                        (elapsed - initialGrowthDuration)
                        / 2.2
                    )
                )

            let cargoLimit =
                Int(
                    Double(cargoParticles.count)
                    * cargoProgress
                )

            for (index, particle) in
                cargoParticles.enumerated()
            {
                guard index < cargoLimit else {
                    continue
                }

                drawCargo(
                    &context,
                    particle: particle,
                    size: size,
                    centerX: centerX,
                    logoBottomY: logoBottomY,
                    bottomY: bottomY,
                    travelHeight: travelHeight,
                    logoWidth: logoWidth,
                    time: time
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func streamDensity(
        elapsed: TimeInterval
    ) -> Double {

        if elapsed <= initialGrowthDuration {
            return 0.16
        }

        let t =
            max(
                0,
                min(
                    1,
                    (elapsed - initialGrowthDuration)
                    / 2.4
                )
            )

        let eased =
            t * t * (3.0 - 2.0 * t)

        return 0.16 + 0.84 * eased
    }

    private func streamState(
        _ particle: PlantParticle,
        time: TimeInterval,
        logoBottomY: CGFloat,
        bottomY: CGFloat,
        travelHeight: CGFloat,
        centerX: CGFloat,
        size: CGSize
    ) -> (
        x: CGFloat,
        headY: CGFloat,
        phase: Double
    ) {

        let cycle = 5.4

        let raw =
            (
                time / cycle
                + particle.phase
            )
            .truncatingRemainder(
                dividingBy: 1.0
            )

        let t =
            raw < 0
            ? raw + 1.0
            : raw

        let distance =
            t * travelHeight

        let headY =
            bottomY - distance

        /*
         Narrow central stream.

         Previously this was 24% of screen width.
         It is now approximately half that.
         */

        let laneX =
            centerX
            + particle.startX
            * size.width
            * 0.115

        /*
         Several slow sine waves produce one
         continuous organic bending motion instead
         of straight vertical lines.
         */

        let sway =
            CGFloat(
                sin(
                    time * particle.flowSpeed
                    + particle.seed
                ) * 0.72
                +
                sin(
                    time * 0.39
                    + particle.seed * 1.73
                ) * 0.28
            )
            * particle.drift

        return (
            laneX + sway,
            headY,
            t
        )
    }

    private func drawGrowingCurrent(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        size: CGSize,
        centerX: CGFloat,
        logoBottomY: CGFloat,
        bottomY: CGFloat,
        travelHeight: CGFloat,
        growth: Double,
        elapsed: TimeInterval
    ) {

        /*
         During the first second the top of the
         current moves upward from the bottom to
         the bottom of the future logo.
         */

        let growthEase =
            growth
            * growth
            * (3.0 - 2.0 * growth)

        let targetHeadY =
            bottomY
            - travelHeight
            * CGFloat(growthEase)

        let laneX =
            centerX
            + particle.startX
            * size.width
            * 0.115

        let sway =
            CGFloat(
                sin(
                    elapsed * particle.flowSpeed
                    + particle.seed
                ) * 0.72
                +
                sin(
                    elapsed * 0.39
                    + particle.seed * 1.73
                ) * 0.28
            )
            * particle.drift

        let headX =
            laneX + sway

        let span =
            max(
                10,
                bottomY - targetHeadY
            )

        /*
         Only a few thin stems are visible initially.
         They are deliberately narrow.
         */

        let baseWidth =
            max(
                1.0,
                particle.scale * 1.15
            )

        var path = Path()

        path.move(
            to: CGPoint(
                x: centerX
                    + particle.startX
                    * size.width
                    * 0.055,
                y: bottomY
            )
        )

        path.addCurve(
            to: CGPoint(
                x: headX,
                y: targetHeadY
            ),
            control1: CGPoint(
                x: centerX
                    + particle.startX
                    * size.width
                    * 0.08
                    + CGFloat(
                        sin(
                            elapsed * 0.41
                            + particle.seed
                        )
                    ) * 10.0,
                y: bottomY
                    - span * 0.28
            ),
            control2: CGPoint(
                x: centerX
                    + particle.startX
                    * size.width
                    * 0.09
                    + CGFloat(
                        sin(
                            elapsed * 0.37
                            + particle.seed * 1.4
                        )
                    ) * 12.0,
                y: targetHeadY
                    + span * 0.30
            )
        )

        let fadeAtTop =
            growth < 0.98
            ? 0.72 + 0.28 * growth
            : 1.0

        context.opacity =
            particle.opacity
            * fadeAtTop

        context.stroke(
            path,
            with: .color(
                Color(
                    red: 0.20,
                    green: 0.84,
                    blue: 0.25
                )
            ),
            style: StrokeStyle(
                lineWidth: baseWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )

        /*
         After reaching the logo, add very subtle
         neighboring strands to make the plant
         become denser without creating the old
         "green vertical lines" effect.
         */

        if growth >= 0.98 {
            let density =
                min(
                    1.0,
                    max(
                        0,
                        (elapsed - 1.0) / 2.0
                    )
                )

            let secondaryCount =
                Int(
                    density * 2.0
                )

            if secondaryCount > 0 {
                for n in 0..<secondaryCount {
                    let offset =
                        CGFloat(n + 1)
                        * 1.8

                    var secondary = Path()

                    secondary.move(
                        to: CGPoint(
                            x: centerX
                                + particle.startX
                                * size.width
                                * 0.055
                                + offset,
                            y: bottomY
                        )
                    )

                    secondary.addCurve(
                        to: CGPoint(
                            x: headX
                                + offset * 0.5,
                            y: logoBottomY
                        ),
                        control1: CGPoint(
                            x: headX
                                + CGFloat(
                                    sin(
                                        elapsed
                                        + particle.seed
                                        + Double(n)
                                    )
                                ) * 8.0,
                            y: bottomY
                                - span * 0.30
                        ),
                        control2: CGPoint(
                            x: headX
                                + CGFloat(
                                    cos(
                                        elapsed * 0.7
                                        + particle.seed
                                    )
                                ) * 8.0,
                            y: logoBottomY
                                + span * 0.28
                        )
                    )

                    context.opacity =
                        particle.opacity
                        * 0.10
                        * density

                    context.stroke(
                        secondary,
                        with: .color(
                            Color(
                                red: 0.28,
                                green: 0.90,
                                blue: 0.28
                            )
                        ),
                        style: StrokeStyle(
                            lineWidth: max(
                                0.7,
                                baseWidth * 0.72
                            ),
                            lineCap: .round
                        )
                    )
                }
            }
        }
    }

    private func drawCargo(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        size: CGSize,
        centerX: CGFloat,
        logoBottomY: CGFloat,
        bottomY: CGFloat,
        travelHeight: CGFloat,
        logoWidth: CGFloat,
        time: TimeInterval
    ) {

        let streams =
            particles.filter {
                $0.kind == .stream
            }

        guard !streams.isEmpty else {
            return
        }

        let stream =
            streams[
                particle.boundStream
                % streams.count
            ]

        let state =
            streamState(
                stream,
                time: time,
                logoBottomY: logoBottomY,
                bottomY: bottomY,
                travelHeight: travelHeight,
                centerX: centerX,
                size: size
            )

        /*
         Cargo remains inside the stream.
         It is never distributed horizontally
         across the entire screen.
         */

        var x =
            state.x
            + CGFloat(
                sin(
                    time * 0.55
                    + particle.seed
                )
            )
            * particle.drift

        var y =
            state.headY
            - travelHeight
            * 0.35
            * particle.cargoOffset

        /*
         Near the logo the particles gently
         converge toward the lower logo region.
         */

        let distanceToLogo =
            y - logoBottomY

        if distanceToLogo < 80.0 {
            let q =
                max(
                    0.0,
                    min(
                        1.0,
                        1.0
                            - distanceToLogo
                            / 80.0
                    )
                )

            let ease =
                q * q * (3.0 - 2.0 * q)

            let targetX =
                centerX
                + particle.targetX
                * logoWidth
                * 0.20

            x +=
                (targetX - x)
                * ease

            y =
                logoBottomY
                + max(
                    0.0,
                    distanceToLogo
                )
                * (1.0 - ease)
        }

        /*
         Never let decorative particles enter
         the logo itself.
         */

        guard y >= logoBottomY else {
            return
        }

        let fade =
            max(
                0.0,
                min(
                    1.0,
                    (y - logoBottomY) / 22.0
                )
            )

        context.opacity =
            particle.opacity
            * (0.25 + 0.75 * fade)

        switch particle.kind {
        case .flower:
            drawFlower(
                &context,
                particle: particle,
                at: CGPoint(
                    x: x,
                    y: y
                ),
                scale: particle.scale,
                time: time
            )

        case .leaf:
            drawLeaf(
                &context,
                particle: particle,
                at: CGPoint(
                    x: x,
                    y: y
                ),
                scale: particle.scale,
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
                scale: particle.scale,
                time: time
            )

        case .stream:
            break
        }
    }

    private func drawLeaf(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        at point: CGPoint,
        scale: CGFloat,
        time: TimeInterval
    ) {

        let angle =
            CGFloat(
                time
                * particle.rotationSpeed
                + particle.rotationPhase
                + sin(
                    time * 0.31
                    + particle.seed
                ) * 0.22
            )

        let w =
            8.0 * scale

        let h =
            14.0 * scale

        var leaf = Path()

        leaf.move(
            to: CGPoint(
                x: point.x,
                y: point.y - h * 0.5
            )
        )

        leaf.addCurve(
            to: CGPoint(
                x: point.x + w * 0.52,
                y: point.y + h * 0.36
            ),
            control1: CGPoint(
                x: point.x + w * 0.72,
                y: point.y - h * 0.28
            ),
            control2: CGPoint(
                x: point.x + w * 0.75,
                y: point.y + h * 0.22
            )
        )

        leaf.addCurve(
            to: CGPoint(
                x: point.x,
                y: point.y - h * 0.5
            ),
            control1: CGPoint(
                x: point.x - w * 0.16,
                y: point.y + h * 0.24
            ),
            control2: CGPoint(
                x: point.x - w * 0.30,
                y: point.y - h * 0.10
            )
        )

        leaf.closeSubpath()

        context.drawLayer { layer in
            layer.translateBy(
                x: point.x,
                y: point.y
            )

            layer.rotate(
                by: Angle(
                    radians: Double(angle)
                )
            )

            layer.translateBy(
                x: -point.x,
                y: -point.y
            )

            layer.fill(
                leaf,
                with: .color(
                    Color(
                        red: 0.42,
                        green: 0.78,
                        blue: 0.12
                    )
                )
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
            0.65
            + 0.35
            * sin(
                time
                * particle.flickerSpeed
                + particle.seed
            )

        let radius =
            max(
                0.45,
                1.25 * scale * pulse
            )

        let outerRadius =
            radius * 2.1

        context.opacity *= 0.22

        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: point.x - outerRadius,
                    y: point.y - outerRadius,
                    width: outerRadius * 2,
                    height: outerRadius * 2
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

        context.opacity *= 3.8

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
                time
                * particle.rotationSpeed
                + particle.rotationPhase
                + sin(
                    time * 0.27
                    + particle.seed
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
            let a =
                CGFloat(i)
                * .pi
                * 2.0
                / 5.0
                + angle

            let cx =
                point.x
                + cos(a)
                * flowerRadius

            let cy =
                point.y
                + sin(a)
                * flowerRadius

            flower.addEllipse(
                in: CGRect(
                    x: cx - petalRadius,
                    y: cy - petalRadius * 0.82,
                    width: petalRadius * 2,
                    height: petalRadius * 1.64
                )
            )
        }

        let centerRadius =
            petalRadius * 0.70

        flower.addEllipse(
            in: CGRect(
                x: point.x - centerRadius,
                y: point.y - centerRadius,
                width: centerRadius * 2,
                height: centerRadius * 2
            )
        )

        let flowerColor: Color =
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

        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: point.x
                        - centerRadius * 0.38,
                    y: point.y
                        - centerRadius * 0.38,
                    width: centerRadius * 0.76,
                    height: centerRadius * 0.76
                )
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
}

// MARK: - Particle model

private struct PlantParticle {
    enum Kind {
        case stream
        case leaf
        case flower
        case pollen
    }

    let kind: Kind
    let phase: Double
    let startX: CGFloat
    let targetX: CGFloat
    let drift: CGFloat
    let opacity: Double
    let scale: CGFloat
    let length: CGFloat
    let seed: Double
    let flowSpeed: Double
    let flickerSpeed: Double
    let rotationSpeed: Double
    let rotationPhase: Double
    let flowerPink: Bool
    let boundStream: Int
    let cargoOffset: CGFloat

    /*
     Used only for the initial stream.

     Lower values appear first.
     This lets the first second consist of
     several clearly defined growing stems.
     */

    let streamOrder: Int

    static func make222() -> [PlantParticle] {
        var result: [PlantParticle] = []

        result.reserveCapacity(294)

        // MARK: 42 basic currents

        for i in 0..<42 {
            result.append(
                PlantParticle(
                    kind: .stream,
                    phase:
                        fract(
                            Double(i)
                            * 0.6180339887
                        ),
                    startX:
                        signedUnit(
                            i * 17 + 3
                        ),
                    targetX:
                        signedUnit(
                            i * 11 + 7
                        ) * 0.80,
                    drift:
                        CGFloat(
                            3.0
                            + Double(i % 7)
                        ),
                    opacity:
                        0.48
                        + Double(i % 7)
                        * 0.025,
                    scale:
                        CGFloat(
                            0.85
                            + Double(i % 5)
                            * 0.10
                        ),
                    length:
                        CGFloat(
                            30
                            + i % 28
                        ),
                    seed:
                        Double(i) * 1.17,
                    flowSpeed:
                        0.42
                        + Double(i % 5)
                        * 0.055,
                    flickerSpeed:
                        1.0
                        + Double(i % 4)
                        * 0.18,
                    rotationSpeed: 0,
                    rotationPhase: 0,
                    flowerPink: false,
                    boundStream: i,
                    cargoOffset: 0,
                    streamOrder: i
                )
            )
        }

        // MARK: Flowers

        for i in 0..<70 {
            let stream =
                (i * 7 + 11) % 42

            let streamParticle =
                result[stream]

            result.append(
                PlantParticle(
                    kind: .flower,
                    phase:
                        streamParticle.phase,
                    startX:
                        streamParticle.startX,
                    targetX:
                        streamParticle.targetX,
                    drift:
                        CGFloat(
                            1.5
                            + Double(i % 5)
                        ),
                    opacity:
                        0.26
                        + Double(i % 6)
                        * 0.035,
                    scale:
                        CGFloat(
                            0.46
                            + Double(i % 5)
                            * 0.13
                        ),
                    length: 0,
                    seed:
                        streamParticle.seed
                        + Double(i) * 0.13,
                    flowSpeed:
                        streamParticle.flowSpeed,
                    flickerSpeed:
                        0.60
                        + Double(i % 4)
                        * 0.12,
                    rotationSpeed:
                        0.12
                        + Double(i % 7)
                        * 0.025,
                    rotationPhase:
                        Double(i % 11)
                        * 0.57,
                    flowerPink:
                        i % 3 != 0,
                    boundStream: stream,
                    cargoOffset:
                        CGFloat(
                            0.20
                            + Double(i % 7)
                            * 0.105
                        ),
                    streamOrder: 0
                )
            )
        }

        // MARK: Leaves

        for i in 0..<72 {
            let stream =
                (i * 11 + 5) % 42

            let streamParticle =
                result[stream]

            result.append(
                PlantParticle(
                    kind: .leaf,
                    phase:
                        streamParticle.phase,
                    startX:
                        streamParticle.startX,
                    targetX:
                        streamParticle.targetX,
                    drift:
                        CGFloat(
                            1.4
                            + Double(i % 5)
                        ),
                    opacity:
                        0.22
                        + Double(i % 6)
                        * 0.03,
                    scale:
                        CGFloat(
                            0.45
                            + Double(i % 5)
                            * 0.11
                        ),
                    length: 0,
                    seed:
                        streamParticle.seed
                        + Double(i) * 0.21
                        + 33,
                    flowSpeed:
                        streamParticle.flowSpeed,
                    flickerSpeed: 0.8,
                    rotationSpeed:
                        0.10
                        + Double(i % 6)
                        * 0.02,
                    rotationPhase:
                        Double(i % 9)
                        * 0.61,
                    flowerPink: false,
                    boundStream: stream,
                    cargoOffset:
                        CGFloat(
                            0.27
                            + Double(i % 6)
                            * 0.10
                        ),
                    streamOrder: 0
                )
            )
        }

        // MARK: Pollen

        for i in 0..<110 {
            let stream =
                (i * 13 + 3) % 42

            let streamParticle =
                result[stream]

            result.append(
                PlantParticle(
                    kind: .pollen,
                    phase:
                        streamParticle.phase,
                    startX:
                        streamParticle.startX,
                    targetX:
                        streamParticle.targetX,
                    drift:
                        CGFloat(
                            1.0
                            + Double(i % 5)
                        ),
                    opacity:
                        0.13
                        + Double(i % 6)
                        * 0.028,
                    scale:
                        CGFloat(
                            0.45
                            + Double(i % 5)
                            * 0.14
                        ),
                    length: 0,
                    seed:
                        streamParticle.seed
                        + Double(i) * 0.31
                        + 70,
                    flowSpeed:
                        streamParticle.flowSpeed,
                    flickerSpeed:
                        1.6
                        + Double(i % 6)
                        * 0.22,
                    rotationSpeed: 0,
                    rotationPhase: 0,
                    flowerPink: false,
                    boundStream: stream,
                    cargoOffset:
                        CGFloat(
                            0.12
                            + Double(i % 8)
                            * 0.11
                        ),
                    streamOrder: 0
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
