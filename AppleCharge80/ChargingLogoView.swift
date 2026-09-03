import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []
    @State private var chargeStartDate: Date?

    private let sectorCount = 6
    private let sectorDuration: TimeInterval = 0.6
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

            let chargeElapsed =
                chargeStartDate.map {
                    max(0, now.timeIntervalSince($0))
                } ?? 0

            let logoHeight: CGFloat = 181
            let logoWidth =
                logoHeight * 814.0 / 1000.0

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

    // Исходные цвета и исходный порядок сохранены.
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
                bodyHeight / CGFloat(sectorCount)

            let normalizedProgress =
                max(
                    0,
                    min(1, progress)
                )

            // =================================================
            // СЕКТОРЫ ФОРМИРУЮТСЯ ОТ 0 ДО 88%
            // =================================================
            //
            // Все шесть секторов полностью готовы к 88%.
            // С 88% начинается исключительно рост листа.
            //
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
                : scaled - Double(completed)

            let leafGrowth =
                leafProgress

            let alive =
                normalizedProgress >= 1 &&
                disconnectElapsed == nil

            ZStack {

                // =================================================
                // COLOR LAYER
                // =================================================

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

                // =================================================
                // CONTACT / MERGE GLOW
                // =================================================
                //
                // Небольшая локальная зона слияния.
                // Никакой зеленой полосы внутри Apple.
                //
                if normalizedProgress > 0.72 &&
                    disconnectElapsed == nil {

                    let contact =
                        smoothStep(
                            (normalizedProgress - 0.72) / 0.28
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

                // =================================================
                // EXTERNAL SOFT EDGE
                // =================================================
                //
                // Только внешний мягкий край.
                // Внутри логотип остается резким.
                //
                AppleBodyShape()
                    .stroke(
                        Color.white.opacity(
                            alive ? 0.27 : 0.20
                        ),
                        lineWidth: 1.05
                    )
                    .blur(radius: 4.0)
                    .opacity(
                        alive ? 0.85 : 0.65
                    )

                // =================================================
                // LEAF
                // =================================================
                //
                // ВАЖНО:
                // никакого outline / trim / stroke.
                // Лист полностью заполнен зеленым цветом.
                //
                // Рост:
                // 88% -> 100%.
                //
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

                        // Мягкий внешний ореол листа.
                        // Само заполнение остается резким.
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

    // MARK: - Sector Visibility

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

        let start =
            Double(position) *
            sectorStartStep

        let local =
            elapsed - start

        if local <= 0 {
            return 1
        }

        if local >= sectorDuration {
            return 0
        }

        let t =
            local / sectorDuration

        return 1 -
            smoothStep(t)
    }

    // MARK: - Leaf Progress

    private var leafProgress: Double {

        guard disconnectElapsed == nil else {
            return 0
        }

        guard progress >= 0.88 else {
            return 0
        }

        let t =
            (progress - 0.88) / 0.12

        return smoothStep(
            max(
                0,
                min(1, t)
            )
        )
    }

    // MARK: - Smooth Step

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

    // MARK: - Heartbeat

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

    // MARK: - Sector Gradient

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
                x: 0.03 + 0.10 * pulse,
                y: 0
            ),
            endPoint: UnitPoint(
                x: 0.87 - 0.08 * pulse,
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

        var path = Path()

        // Лист раскрывается снизу вверх.
        // В финале маска полностью совпадает с областью Shape.
        let revealBottom =
            rect.minY +
            rect.height * (1 - p)

        path.addRect(
            CGRect(
                x: rect.minX - 2,
                y: revealBottom,
                width: rect.width + 4,
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
            red: min(1, r * factor),
            green: min(1, g * factor),
            blue: min(1, b * factor)
        )
    }
}

// MARK: - Plant Particle Field

private struct PlantParticleField: View {

    let progress: Double
    let isCharging: Bool
    let time: TimeInterval
    let logoHeight: CGFloat

    var body: some View {

        Canvas { context, canvasSize in

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

    // MARK: - Growing Multi Thread Flow

    private func drawFlow(
        context: inout GraphicsContext,
        canvasSize: CGSize
    ) {

        guard isCharging else {
            return
        }

        guard progress > 0 else {
            return
        }

        let logoTopY =
            max(
                42,
                canvasSize.height * 0.075
            )

        let logoBottomY =
            logoTopY +
            logoHeight

        // =====================================================
        // FLOW GROWTH
        // =====================================================
        //
        // Поток идет от самого нижнего края.
        // В начале существует только одна нить.
        // Затем число нитей постепенно увеличивается.
        //
        let growth =
            smoothStep(
                min(
                    1,
                    progress / 0.88
                )
            )

        let startY =
            canvasSize.height + 2

        let targetY =
            logoBottomY + 1

        let travel =
            min(
                1,
                progress * 1.12
            )

        let easedTravel =
            easeOut(travel)

        let headY =
            startY -
            (
                startY -
                targetY
            ) *
            CGFloat(easedTravel)

        let centerX =
            canvasSize.width * 0.5

        // =====================================================
        // ОБЩАЯ ШИРИНА ПУЧКА
        // =====================================================
        //
        // Приблизительно 5–9 мм визуальной ширины
        // на современном iPhone.
        //
        let bundleWidth =
            min(
                17.0,
                max(
                    10.0,
                    canvasSize.width * 0.026
                )
            )

        let halfBundle =
            bundleWidth * 0.5

        // =====================================================
        // ЧИСЛО НИТЕЙ
        // =====================================================

        let maximumThreads = 11

        let visibleThreads =
            max(
                1,
                min(
                    maximumThreads,
                    Int(
                        floor(
                            1 +
                            growth *
                            Double(maximumThreads - 1)
                        )
                    )
                )
            )

        for index in 0..<visibleThreads {

            let seed =
                Double(index) * 13.731 + 4.17

            let phase =
                seed.truncatingRemainder(
                    dividingBy: 6.283185307
                )

            let speed =
                0.78 +
                (
                    seed
                        .truncatingRemainder(
                            dividingBy: 1.0
                        )
                ) *
                0.42

            let frequency =
                1.55 +
                (
                    seed * 0.37
                )
                .truncatingRemainder(
                    dividingBy: 1.0
                ) *
                1.25

            let amplitudeFactor =
                0.55 +
                (
                    seed * 0.19
                )
                .truncatingRemainder(
                    dividingBy: 1.0
                ) *
                0.55

            let phaseMotion =
                time *
                speed

            let normalizedIndex =
                visibleThreads == 1
                ? 0.5
                : Double(index) /
                    Double(visibleThreads - 1)

            // Нити распределяются по пучку,
            // но не образуют одинаковые параллельные линии.
            let staticOffset =
                (
                    normalizedIndex - 0.5
                ) *
                bundleWidth *
                0.72

            let threadOpacity =
                smoothStep(
                    min(
                        1,
                        growth *
                        (
                            1.15 -
                            Double(index) *
                            0.035
                        )
                    )
                )

            drawThread(
                context: &context,
                canvasSize: canvasSize,
                centerX: centerX,
                startY: startY,
                headY: headY,
                targetY: targetY,
                halfBundle: halfBundle,
                staticOffset: staticOffset,
                phase: phase,
                phaseMotion: phaseMotion,
                frequency: frequency,
                amplitudeFactor: amplitudeFactor,
                opacity: threadOpacity,
                index: index
            )
        }

        // =====================================================
        // МЯГКОЕ СЛИЯНИЕ В НИЖНЕЙ ТОЧКЕ
        // =====================================================

        let mergeStrength =
            smoothStep(
                min(
                    1,
                    progress / 0.78
                )
            )

        let mergePulse =
            heartbeat(
                time,
                phase: 0
            )

        let mergeRadius =
            bundleWidth *
            (
                0.95 +
                0.30 * mergePulse
            )

        let mergeRect =
            CGRect(
                x:
                    centerX -
                    mergeRadius,
                y:
                    targetY -
                    mergeRadius * 0.72,
                width:
                    mergeRadius * 2,
                height:
                    mergeRadius * 1.44
            )

        context.fill(
            Path(
                ellipseIn: mergeRect
            ),
            with: .color(
                Color(
                    red: 0.55,
                    green: 1.0,
                    blue: 0.40
                )
                .opacity(
                    0.10 *
                    mergeStrength *
                    (0.70 + 0.30 * mergePulse)
                )
            )
        )
    }

    // MARK: - Individual Living Thread

    private func drawThread(
        context: inout GraphicsContext,
        canvasSize: CGSize,
        centerX: CGFloat,
        startY: CGFloat,
        headY: CGFloat,
        targetY: CGFloat,
        halfBundle: CGFloat,
        staticOffset: CGFloat,
        phase: Double,
        phaseMotion: Double,
        frequency: Double,
        amplitudeFactor: Double,
        opacity: Double,
        index: Int
    ) {

        let totalDistance =
            max(
                1,
                startY - headY
            )

        let steps = 42

        var previousPoint:
            CGPoint?

        for step in 0..<steps {

            let u =
                Double(step) /
                Double(steps - 1)

            let y =
                startY -
                totalDistance *
                CGFloat(u)

            // Амплитуда меньше у нижнего начала
            // и мягко меняется по высоте.
            let envelope =
                sin(
                    Double(u) *
                    .pi
                )

            let localAmplitude =
                halfBundle *
                0.62 *
                amplitudeFactor *
                CGFloat(
                    0.28 +
                    0.72 * envelope
                )

            let wave1 =
                sin(
                    phase +
                    phaseMotion +
                    Double(u) *
                    frequency *
                    6.0
                )

            let wave2 =
                sin(
                    phase * 0.61 +
                    phaseMotion * 0.72 +
                    Double(u) *
                    frequency *
                    11.0 +
                    1.7
                )

            let wave3 =
                sin(
                    phase * 1.37 +
                    phaseMotion * 0.43 +
                    Double(u) *
                    17.0
                )

            let organicWave =
                0.58 * wave1 +
                0.27 * wave2 +
                0.15 * wave3

            var x =
                centerX +
                staticOffset +
                localAmplitude *
                CGFloat(organicWave)

            // Все нити мягко собираются в одну
            // локальную зону перед входом в Apple.
            let mergeFactor =
                smoothStep(
                    max(
                        0,
                        min(
                            1,
                            (u - 0.78) / 0.22
                        )
                    )
                )

            let mergeOffset =
                staticOffset *
                CGFloat(
                    1 -
                    mergeFactor * 0.88
                )

            x =
                centerX +
                mergeOffset +
                localAmplitude *
                CGFloat(
                    organicWave *
                    (1 - mergeFactor * 0.78)
                )

            let point =
                CGPoint(
                    x: x,
                    y: y
                )

            if let previousPoint {

                let segmentProgress =
                    u

                // Небольшое дыхание ширины.
                let widthWave =
                    sin(
                        time * 2.0 +
                        phase +
                        Double(step) * 0.43
                    )

                let lineWidth =
                    max(
                        0.55,
                        min(
                            1.15,
                            0.70 +
                            0.20 * widthWave
                        )
                    )

                // Нить становится мягче непосредственно
                // перед слиянием.
                let fadeAtHead =
                    1 -
                    smoothStep(
                        max(
                            0,
                            min(
                                1,
                                (segmentProgress - 0.80) /
                                0.20
                            )
                        )
                    )

                let segmentOpacity =
                    opacity *
                    (
                        0.38 +
                        0.62 * fadeAtHead
                    )

                var segment =
                    Path()

                segment.move(
                    to: previousPoint
                )

                segment.addLine(
                    to: point
                )

                // Мягкий внешний свет.
                context.stroke(
                    segment,
                    with: .color(
                        Color(
                            red: 0.42,
                            green: 0.92,
                            blue: 0.32
                        )
                        .opacity(
                            segmentOpacity * 0.16
                        )
                    ),
                    style: StrokeStyle(
                        lineWidth:
                            lineWidth * 3.0,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                // Основная живая нить.
                context.stroke(
                    segment,
                    with: .color(
                        Color(
                            red: 0.42,
                            green: 0.92,
                            blue: 0.32
                        )
                        .opacity(
                            segmentOpacity * 0.54
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

            previousPoint = point
        }

        // Небольшой светящийся кончик каждой нити.
        let headPhase =
            heartbeat(
                time,
                phase: phase
            )

        let headRadius =
            1.0 +
            0.55 * headPhase

        let headX =
            centerX +
            staticOffset *
            0.12

        let tipRect =
            CGRect(
                x:
                    headX -
                    headRadius,
                y:
                    headY -
                    headRadius,
                width:
                    headRadius * 2,
                height:
                    headRadius * 2
            )

        context.fill(
            Path(
                ellipseIn: tipRect
            ),
            with: .color(
                Color(
                    red: 0.55,
                    green: 1.0,
                    blue: 0.40
                )
                .opacity(
                    opacity *
                    0.25 *
                    (0.70 + 0.30 * headPhase)
                )
            )
        )
    }

    // MARK: - Pollen

    private func drawPollen(
        context: inout GraphicsContext,
        canvasSize: CGSize
    ) {

        guard isCharging else {
            return
        }

        guard progress > 0.04 else {
            return
        }

        let logoTopY =
            max(
                42,
                canvasSize.height * 0.075
            )

        let logoBottomY =
            logoTopY +
            logoHeight

        let startY =
            canvasSize.height + 2

        let targetY =
            logoBottomY + 1

        let flowProgress =
            min(
                1,
                progress * 1.12
            )

        let travel =
            easeOut(flowProgress)

        let currentHeadY =
            startY -
            (
                startY -
                targetY
            ) *
            CGFloat(travel)

        let centerX =
            canvasSize.width * 0.5

        let bundleWidth =
            min(
                17.0,
                max(
                    10.0,
                    canvasSize.width * 0.026
                )
            )

        // Частиц меньше, чем раньше,
        // и они находятся около живого потока.
        let count = 24

        for index in 0..<count {

            let seed =
                Double(index) * 19.173 + 2.81

            let phase =
                seed.truncatingRemainder(
                    dividingBy: 6.283185307
                )

            let speed =
                0.22 +
                (
                    seed * 0.17
                )
                .truncatingRemainder(
                    dividingBy: 0.18
                )

            let cycle =
                (
                    time * speed +
                    phase
                )
                .truncatingRemainder(
                    dividingBy: 1
                )

            // Частицы движутся снизу вверх.
            let vertical =
                CGFloat(
                    cycle
                )

            let y =
                startY -
                (
                    startY -
                    currentHeadY
                ) *
                vertical

            let spread =
                CGFloat(
                    0.28 +
                    0.72 *
                    sin(
                        vertical * .pi
                    )
                )

            let side =
                (
                    seed * 0.73
                )
                .truncatingRemainder(
                    dividingBy: 1
                ) -
                0.5

            let wave =
                sin(
                    time * 1.2 +
                    phase +
                    Double(vertical) * 8.0
                )

            let x =
                centerX +
                (
                    CGFloat(side) *
                    bundleWidth *
                    0.85 *
                    spread
                ) +
                (
                    CGFloat(wave) *
                    bundleWidth *
                    0.28
                )

            let radius =
                0.45 +
                (
                    seed
                        .truncatingRemainder(
                            dividingBy: 1
                        )
                ) *
                0.75

            let pulse =
                heartbeat(
                    time,
                    phase: phase
                )

            let opacity =
                0.055 +
                0.10 * pulse

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

    // MARK: - Ease Out

    private func easeOut(
        _ value: Double
    ) -> Double {

        let t =
            max(
                0,
                min(1, value)
            )

        return 1 -
            pow(
                1 - t,
                3
            )
    }

    // MARK: - Smooth Step

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

    // MARK: - Heartbeat

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
