import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []
    @State private var chargeStartDate: Date?

    private let sectorCount = 6

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 60.0,
                paused: !isCharging && disconnectStart == nil
            )
        ) { context in

            let now = context.date

            let disconnectElapsed = disconnectStart.map {
                now.timeIntervalSince($0)
            }

            let chargeElapsed = chargeStartDate.map {
                max(0, now.timeIntervalSince($0))
            } ?? 0

            let logoHeight: CGFloat = 181
            let logoWidth = logoHeight * 814.0 / 1000.0

            GeometryReader { geo in

                ZStack(alignment: .top) {

                    PlantParticleField(
                        progress: progress,
                        isCharging: isCharging,
                        time: chargeElapsed,
                        logoHeight: logoHeight
                    )
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height
                    )

                    AppleLogoFill(
                        progress: progress,
                        time: chargeElapsed,
                        disconnectElapsed: disconnectElapsed,
                        disconnectOrder: disconnectOrder
                    )
                    .frame(
                        width: logoWidth,
                        height: logoHeight
                    )
                    .padding(
                        .top,
                        max(
                            42,
                            geo.size.height * 0.075
                        )
                    )
                }
                .frame(
                    width: geo.size.width,
                    height: geo.size.height,
                    alignment: .top
                )
            }
            .onAppear {
                updateState(
                    charging: isCharging,
                    now: now
                )
            }
            .onChange(of: isCharging) { _, charging in
                updateState(
                    charging: charging,
                    now: now
                )
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    private func updateState(
        charging: Bool,
        now: Date
    ) {
        if charging {
            disconnectStart = nil
            disconnectOrder.removeAll()
            chargeStartDate = now
        } else {

            if disconnectStart == nil {
                disconnectStart = now
            }

            if disconnectOrder.isEmpty {
                disconnectOrder =
                    Array(0..<sectorCount).shuffled()
            }
        }
    }
}

// MARK: - Apple Logo

private struct AppleLogoFill: View {

    let progress: Double
    let time: TimeInterval
    let disconnectElapsed: TimeInterval?
    let disconnectOrder: [Int]

    private let sectorCount = 6

    private let sectorDuration: TimeInterval = 0.6
    private let sectorStartStep: TimeInterval = 0.48

    private let sectorCompletionProgress = 0.88

    // Исходные цвета и порядок сохранены.
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

            let bodyTop =
                geo.size.height * 0.2443

            let bodyBottom =
                geo.size.height * 0.9999

            let bodyHeight =
                bodyBottom - bodyTop

            let bandHeight =
                bodyHeight /
                CGFloat(sectorCount)

            let normalizedProgress =
                max(
                    0,
                    min(1, progress)
                )

            let sectorProgress =
                min(
                    1,
                    normalizedProgress /
                    sectorCompletionProgress
                )

            let scaled =
                sectorProgress *
                Double(sectorCount)

            let completed =
                min(
                    sectorCount,
                    Int(scaled)
                )

            let currentFraction =
                completed >= sectorCount
                ? 0
                : scaled -
                  Double(completed)

            let leafGrowth =
                leafProgress

            let alive =
                normalizedProgress >= 1 &&
                disconnectElapsed == nil

            ZStack {

                // MARK: Color Layer

                ZStack(alignment: .top) {

                    ForEach(
                        0..<sectorCount,
                        id: \.self
                    ) { index in

                        let visibility =
                            sectorVisibility(
                                index: index,
                                completed: completed,
                                currentFraction: currentFraction,
                                disconnectElapsed: disconnectElapsed
                            )

                        if visibility > 0.001 {

                            let pulse =
                                heartbeat(
                                    time,
                                    phase:
                                        Double(index) * 0.035
                                )

                            let intensity =
                                0.94 +
                                0.10 * pulse

                            Rectangle()
                                .fill(
                                    sectorGradient(
                                        base: colors[index],
                                        index: index,
                                        time: time,
                                        intensity: intensity
                                    )
                                )
                                .frame(
                                    width: geo.size.width,
                                    height: bandHeight + 1
                                )
                                .offset(
                                    y:
                                        bodyTop +
                                        CGFloat(index) *
                                        bandHeight
                                )
                                .opacity(
                                    visibility
                                )
                        }
                    }
                }
                .clipShape(
                    AppleBodyShape()
                )

                // MARK: Contact / Merge Glow

                if normalizedProgress > 0.72 &&
                    disconnectElapsed == nil {

                    let contact =
                        smoothStep(
                            (normalizedProgress - 0.72) /
                            0.28
                        )

                    let pulse =
                        heartbeat(
                            time,
                            phase: 0
                        )

                    RadialGradient(
                        colors: [
                            Color(
                                red: 0.52,
                                green: 1.0,
                                blue: 0.38
                            )
                            .opacity(
                                0.20 *
                                contact *
                                (0.55 + 0.45 * pulse)
                            ),

                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius:
                            geo.size.width * 0.055
                    )
                    .frame(
                        width:
                            geo.size.width * 0.16,
                        height:
                            geo.size.height * 0.075
                    )
                    .position(
                        x:
                            geo.size.width * 0.5,
                        y:
                            bodyBottom - 1
                    )
                    .blur(radius: 2.2)
                    .clipShape(
                        AppleBodyShape()
                    )
                }

                // MARK: External Soft Edge

                AppleBodyShape()
                    .stroke(
                        Color.white.opacity(
                            alive
                            ? 0.27
                            : 0.20
                        ),
                        lineWidth: 1.05
                    )
                    .blur(radius: 4.0)
                    .opacity(
                        alive
                        ? 0.85
                        : 0.65
                    )

                // MARK: Leaf

                if leafGrowth > 0 {

                    AppleLeafShape()
                        .fill(
                            Color(
                                red: 0.42,
                                green: 0.78,
                                blue: 0.12
                            )
                        )
                        .opacity(
                            min(
                                1,
                                leafGrowth * 1.15
                            )
                        )
                        .overlay {

                            AppleLeafShape()
                                .fill(
                                    Color(
                                        red: 0.42,
                                        green: 0.78,
                                        blue: 0.12
                                    )
                                )
                                .blur(radius: 4.0)
                                .opacity(
                                    0.55 *
                                    leafGrowth
                                )
                        }
                        .clipShape(
                            AppleLeafGrowthMask(
                                progress: leafGrowth
                            )
                        )
                }
            }
        }
    }

    // MARK: Sector Visibility

    private func sectorVisibility(
        index: Int,
        completed: Int,
        currentFraction: Double,
        disconnectElapsed: TimeInterval?
    ) -> Double {

        guard let elapsed = disconnectElapsed else {

            if index < completed {
                return 1
            }

            if index == completed &&
                completed < sectorCount {

                return smoothStep(
                    currentFraction
                )
            }

            return 0
        }

        guard
            let position =
                disconnectOrder.firstIndex(
                    of: index
                )
        else {
            return 1
        }

        let local =
            elapsed -
            Double(position) *
            sectorStartStep

        if local <= 0 {
            return 1
        }

        if local >= sectorDuration {
            return 0
        }

        return 1 -
            smoothStep(
                local / sectorDuration
            )
    }

    // MARK: Leaf Progress

    private var leafProgress: Double {

        guard
            disconnectElapsed == nil,
            progress >= 0.88
        else {
            return 0
        }

        let t =
            (progress - 0.88) /
            0.12

        return smoothStep(
            max(
                0,
                min(1, t)
            )
        )
    }

    // MARK: Smooth Step

    private func smoothStep(
        _ value: Double
    ) -> Double {

        let t =
            max(
                0,
                min(1, value)
            )

        return
            t * t *
            (3 - 2 * t)
    }

    // MARK: Heartbeat

    private func heartbeat(
        _ time: TimeInterval,
        phase: Double
    ) -> Double {

        let cycle =
            (time * 1.08 + phase)
                .truncatingRemainder(
                    dividingBy: 1
                )

        let first =
            exp(
                -pow(
                    (cycle - 0.095) / 0.052,
                    2
                )
            )

        let second =
            exp(
                -pow(
                    (cycle - 0.225) / 0.075,
                    2
                )
            )

        return min(
            1,
            first * 0.95 +
            second * 0.52
        )
    }

    // MARK: Sector Gradient

    private func sectorGradient(
        base: SectorColor,
        index: Int,
        time: TimeInterval,
        intensity: Double
    ) -> LinearGradient {

        let pulse =
            heartbeat(
                time,
                phase:
                    Double(index) * 0.035
            )

        let drift =
            0.5 +
            0.5 *
            sin(
                time * 0.72 +
                Double(index) * 0.85
            )

        let dark =
            base.color(
                multipliedBy:
                    0.82 +
                    0.08 * pulse +
                    0.035 * drift
            )

        let mid =
            base.color(
                multipliedBy:
                    intensity +
                    0.045 * drift
            )

        let bright =
            base.color(
                multipliedBy:
                    0.91 +
                    0.14 * pulse +
                    0.035 * drift
            )

        return LinearGradient(
            stops: [
                .init(
                    color: dark,
                    location: 0
                ),
                .init(
                    color: mid,
                    location: 0.32
                ),
                .init(
                    color: bright,
                    location: 0.55
                ),
                .init(
                    color: mid,
                    location: 0.76
                ),
                .init(
                    color: dark,
                    location: 1
                )
            ],
            startPoint: UnitPoint(
                x:
                    0.03 +
                    0.10 * pulse,
                y: 0
            ),
            endPoint: UnitPoint(
                x:
                    0.87 -
                    0.08 * pulse,
                y: 1
            )
        )
    }
}

// MARK: - Leaf Growth Mask

private struct AppleLeafGrowthMask: Shape {

    let progress: Double

    func path(
        in rect: CGRect
    ) -> Path {

        let p =
            max(
                0,
                min(1, progress)
            )

        let revealBottom =
            rect.minY +
            rect.height *
            (1 - p)

        var path = Path()

        path.addRect(
            CGRect(
                x:
                    rect.minX - 2,
                y:
                    revealBottom,
                width:
                    rect.width + 4,
                height:
                    rect.maxY -
                    revealBottom +
                    2
            )
        )

        return path
    }
}

// MARK: - Sector Color

private struct SectorColor {

    let r: Double
    let g: Double
    let b: Double

    func color(
        multipliedBy factor: Double
    ) -> Color {

        Color(
            red:
                min(
                    1,
                    r * factor
                ),
            green:
                min(
                    1,
                    g * factor
                ),
            blue:
                min(
                    1,
                    b * factor
                )
        )
    }
}

// MARK: - Plant Particle Field

private struct PlantParticleField: View {

    let progress: Double
    let isCharging: Bool
    let time: TimeInterval
    let logoHeight: CGFloat

    // MARK: Thread Configuration

    private struct ThreadSpec {

        let phase: Double
        let speed: Double
        let frequency: Double
        let amplitude: Double
        let offset: Double
        let birth: Double
    }

    /*
     Fixed deterministic configuration.

     Никаких случайных вычислений каждый кадр.
     Каждая нить имеет собственную жизнь:
     phase / speed / frequency / amplitude / birth.
     */

    private static let threads: [ThreadSpec] = [

        ThreadSpec(
            phase: 0.20,
            speed: 0.82,
            frequency: 1.00,
            amplitude: 0.70,
            offset: -0.05,
            birth: 0.00
        ),

        ThreadSpec(
            phase: 2.10,
            speed: 0.97,
            frequency: 1.18,
            amplitude: 0.82,
            offset: 0.18,
            birth: 0.15
        ),

        ThreadSpec(
            phase: 4.35,
            speed: 0.74,
            frequency: 0.92,
            amplitude: 0.76,
            offset: -0.22,
            birth: 0.29
        ),

        ThreadSpec(
            phase: 1.25,
            speed: 1.08,
            frequency: 1.30,
            amplitude: 0.66,
            offset: 0.31,
            birth: 0.43
        ),

        ThreadSpec(
            phase: 3.55,
            speed: 0.88,
            frequency: 1.08,
            amplitude: 0.88,
            offset: -0.34,
            birth: 0.57
        ),

        ThreadSpec(
            phase: 5.15,
            speed: 1.02,
            frequency: 1.22,
            amplitude: 0.72,
            offset: 0.09,
            birth: 0.70
        ),

        ThreadSpec(
            phase: 0.95,
            speed: 0.79,
            frequency: 1.38,
            amplitude: 0.60,
            offset: -0.12,
            birth: 0.80
        )
    ]

    var body: some View {

        Canvas { context, canvasSize in

            guard
                isCharging,
                progress > 0
            else {
                return
            }

            drawFlow(
                context: &context,
                canvasSize: canvasSize
            )

            drawPollen(
                context: &context,
                canvasSize: canvasSize
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: Growing Flow

    private func drawFlow(
        context: inout GraphicsContext,
        canvasSize: CGSize
    ) {

        let logoTopY =
            max(
                42,
                canvasSize.height * 0.075
            )

        let targetY =
            logoTopY +
            logoHeight +
            1

        let startY =
            canvasSize.height +
            2

        let centerX =
            canvasSize.width *
            0.5

        // 0...1 corresponds to the actual
        // growth phase before the leaf.
        let growth =
            smoothStep(
                min(
                    1,
                    progress / 0.88
                )
            )

        let travel =
            easeOut(
                min(
                    1,
                    progress * 1.12
                )
            )

        let headY =
            startY -
            (
                startY -
                targetY
            ) *
            CGFloat(travel)

        /*
         Approx. 5–9 mm visual width.

         The important difference from the old version:
         this is the width of the whole living bundle,
         not an artificial set of long parallel lines.
         */

        let bundleWidth =
            min(
                16.0,
                max(
                    10.0,
                    canvasSize.width * 0.024
                )
            )

        for spec in Self.threads {

            guard
                growth >= spec.birth
            else {
                continue
            }

            /*
             New threads do not appear instantly.
             They fade into existence over part of the growth.
             */

            let birthFade =
                smoothStep(
                    min(
                        1,
                        (growth - spec.birth) /
                        0.12
                    )
                )

            drawThread(
                context: &context,
                centerX: centerX,
                startY: startY,
                headY: headY,
                bundleWidth: bundleWidth,
                spec: spec,
                time: time,
                opacity: birthFade
            )
        }

        // MARK: Merge Point

        let mergeStrength =
            smoothStep(
                min(
                    1,
                    progress / 0.78
                )
            )

        let pulse =
            heartbeat(
                time,
                phase: 0
            )

        let radius =
            bundleWidth *
            (
                0.62 +
                0.10 * pulse
            )

        let rect =
            CGRect(
                x:
                    centerX -
                    radius,
                y:
                    targetY -
                    radius * 0.52,
                width:
                    radius * 2,
                height:
                    radius * 1.04
            )

        context.fill(
            Path(
                ellipseIn: rect
            ),
            with: .color(
                Color(
                    red: 0.55,
                    green: 1.0,
                    blue: 0.40
                )
                .opacity(
                    0.055 *
                    mergeStrength
                )
            )
        )
    }

    // MARK: Individual Living Thread

    private func drawThread(
        context: inout GraphicsContext,
        centerX: CGFloat,
        startY: CGFloat,
        headY: CGFloat,
        bundleWidth: CGFloat,
        spec: ThreadSpec,
        time: TimeInterval,
        opacity: Double
    ) {

        let distance =
            max(
                1,
                startY - headY
            )

        /*
         Fewer samples than the old 42-point version,
         while still being smooth at this scale.
         */

        let steps = 30

        var previousPoint:
            CGPoint?

        let maxOffset =
            bundleWidth *
            0.34

        let staticOffset =
            CGFloat(spec.offset) *
            maxOffset

        let phaseTime =
            time *
            spec.speed

        for step in 0..<steps {

            let u =
                Double(step) /
                Double(steps - 1)

            let y =
                startY -
                distance *
                CGFloat(u)

            /*
             Narrow at the beginning and near the
             Apple contact point, widest in the middle.
             */

            let envelope =
                sin(
                    u * .pi
                )

            let amplitude =
                bundleWidth *
                0.26 *
                spec.amplitude *
                CGFloat(
                    0.35 +
                    0.65 * envelope
                )

            /*
             Two harmonics instead of three.

             They have different frequencies and phases,
             so the result does not look like a rigid
             repeating sinusoid.
             */

            let wave =
                0.68 *
                sin(
                    spec.phase +
                    phaseTime +
                    u *
                    .pi *
                    2.0 *
                    spec.frequency
                )
                +
                0.32 *
                sin(
                    spec.phase *
                    0.61 +
                    phaseTime *
                    0.67 +
                    u *
                    .pi *
                    4.7 *
                    spec.frequency +
                    1.4
                )

            /*
             Very slow common movement.
             This makes the whole stream breathe as one
             living structure without synchronizing
             individual threads.
             */

            let bundleDrift =
                CGFloat(
                    sin(
                        time * 0.34 +
                        u * 2.1
                    )
                    *
                    Double(bundleWidth)
                    *
                    0.045
                )

            /*
             Final part of every thread gently converges
             into the Apple contact point.
             */

            let merge =
                smoothStep(
                    max(
                        0,
                        min(
                            1,
                            (u - 0.76) /
                            0.24
                        )
                    )
                )

            let x =
                centerX +
                staticOffset *
                CGFloat(
                    1 -
                    0.82 * merge
                )
                +
                amplitude *
                CGFloat(wave) *
                CGFloat(
                    1 -
                    0.72 * merge
                )
                +
                bundleDrift

            let point =
                CGPoint(
                    x: x,
                    y: y
                )

            if let previousPoint {

                /*
                 Small independent width breathing.
                 It changes the apparent thread width
                 without making the whole stream thicker.
                 */

                let widthPulse =
                    0.86 +
                    0.16 *
                    sin(
                        time * 1.7 +
                        spec.phase +
                        u * 4.0
                    )

                let lineWidth =
                    max(
                        0.65,
                        min(
                            1.15,
                            0.82 *
                            widthPulse
                        )
                    )

                /*
                 Fade slightly near the Apple contact.
                 No bright dot / head is added.
                 */

                let headFade =
                    1 -
                    smoothStep(
                        max(
                            0,
                            min(
                                1,
                                (u - 0.84) /
                                0.16
                            )
                        )
                    )

                let segmentOpacity =
                    opacity *
                    (
                        0.48 +
                        0.52 * headFade
                    )

                var segment =
                    Path()

                segment.move(
                    to: previousPoint
                )

                segment.addLine(
                    to: point
                )

                // Very subtle external light.

                context.stroke(
                    segment,
                    with: .color(
                        Color(
                            red: 0.42,
                            green: 0.92,
                            blue: 0.32
                        )
                        .opacity(
                            segmentOpacity *
                            0.13
                        )
                    ),
                    style: StrokeStyle(
                        lineWidth:
                            lineWidth *
                            2.5,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                // Sharp living core.

                context.stroke(
                    segment,
                    with: .color(
                        Color(
                            red: 0.42,
                            green: 0.92,
                            blue: 0.32
                        )
                        .opacity(
                            segmentOpacity *
                            0.62
                        )
                    ),
                    style: StrokeStyle(
                        lineWidth:
                            lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }

            previousPoint =
                point
        }
    }

    // MARK: Pollen

    private func drawPollen(
        context: inout GraphicsContext,
        canvasSize: CGSize
    ) {

        guard
            isCharging,
            progress > 0.10
        else {
            return
        }

        let logoTopY =
            max(
                42,
                canvasSize.height * 0.075
            )

        let targetY =
            logoTopY +
            logoHeight +
            1

        let startY =
            canvasSize.height +
            2

        let travel =
            easeOut(
                min(
                    1,
                    progress * 1.12
                )
            )

        let headY =
            startY -
            (
                startY -
                targetY
            ) *
            CGFloat(travel)

        let centerX =
            canvasSize.width *
            0.5

        let bundleWidth =
            min(
                16.0,
                max(
                    10.0,
                    canvasSize.width * 0.024
                )
            )

        /*
         Only 10 particles.

         They are supplementary to the stream,
         not a second particle stream.
         */

        let count = 10

        for index in 0..<count {

            let seed =
                Double(index) *
                1.731 +
                0.37

            let phase =
                seed *
                4.7

            let cycle =
                (
                    time *
                    (
                        0.18 +
                        seed.truncatingRemainder(
                            dividingBy: 0.12
                        )
                    )
                    +
                    phase
                )
                .truncatingRemainder(
                    dividingBy: 1
                )

            let vertical =
                CGFloat(cycle)

            let y =
                startY -
                (
                    startY -
                    headY
                ) *
                vertical

            let spread =
                CGFloat(
                    0.20 +
                    0.80 *
                    sin(
                        vertical * .pi
                    )
                )

            let side =
                CGFloat(
                    sin(
                        seed * 9.17
                    )
                )

            let drift =
                CGFloat(
                    sin(
                        time * 0.55 +
                        phase +
                        Double(vertical) * 5.0
                    )
                )

            let x =
                centerX +
                side *
                bundleWidth *
                0.38 *
                spread
                +
                drift *
                bundleWidth *
                0.08

            let radius =
                0.45 +
                CGFloat(
                    seed.truncatingRemainder(
                        dividingBy: 0.45
                    )
                )

            let pulse =
                heartbeat(
                    time,
                    phase: phase
                )

            let opacity =
                0.035 +
                0.07 * pulse

            let rect =
                CGRect(
                    x:
                        x -
                        radius,
                    y:
                        y -
                        radius,
                    width:
                        radius * 2,
                    height:
                        radius * 2
                )

            context.fill(
                Path(
                    ellipseIn: rect
                ),
                with: .color(
                    Color(
                        red: 0.46,
                        green: 0.88,
                        blue: 0.32
                    )
                    .opacity(
                        opacity
                    )
                )
            )
        }
    }

    // MARK: Ease Out

    private func easeOut(
        _ value: Double
    ) -> Double {

        let t =
            max(
                0,
                min(1, value)
            )

        return
            1 -
            pow(
                1 - t,
                3
            )
    }

    // MARK: Smooth Step

    private func smoothStep(
        _ value: Double
    ) -> Double {

        let t =
            max(
                0,
                min(1, value)
            )

        return
            t * t *
            (3 - 2 * t)
    }

    // MARK: Heartbeat

    private func heartbeat(
        _ time: TimeInterval,
        phase: Double
    ) -> Double {

        let cycle =
            (time * 1.08 + phase)
                .truncatingRemainder(
                    dividingBy: 1
                )

        let first =
            exp(
                -pow(
                    (cycle - 0.095) / 0.052,
                    2
                )
            )

        let second =
            exp(
                -pow(
                    (cycle - 0.225) / 0.075,
                    2
                )
            )

        return min(
            1,
            first * 0.95 +
            second * 0.52
        )
    }
}
