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
        TimelineView(
            .animation(minimumInterval: 1.0 / 60.0, paused: false)
        ) { context in
            let now = context.date
            let disconnectElapsed =
                disconnectStart.map {
                    now.timeIntervalSince($0)
                }
            let elapsedSinceCharge =
                chargeStartDate.map {
                    max(0, now.timeIntervalSince($0))
                } ?? 0
            // ВАЖНО:
            // Геометрия логотипа не меняется.
            let logoHeight: CGFloat = 181.0
            let logoWidth: CGFloat =
                logoHeight * 814.0 / 1000.0
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    PlantParticleField(
                        progress: progress,
                        isCharging: isCharging,
                        time: elapsedSinceCharge,
                        size: geo.size,
                        logoHeight: logoHeight
                    )
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height
                    )
                    AppleLogoFill(
                        progress: progress,
                        isCharging: isCharging,
                        time: elapsedSinceCharge,
                        disconnectElapsed: disconnectElapsed,
                        disconnectOrder: disconnectOrder,
                        logoHeight: logoHeight
                    )
                    .frame(
                        width: logoWidth,
                        height: logoHeight
                    )
                    .padding(
                        .top,
                        max(42, geo.size.height * 0.075)
                    )
                }
                .frame(
                    width: geo.size.width,
                    height: geo.size.height,
                    alignment: .top
                )
            }
            .onAppear {
                if isCharging {
                    if chargeStartDate == nil {
                        chargeStartDate = now
                    }
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
            .onChange(of: isCharging) { _, charging in
                if charging {
                    disconnectStart = nil
                    disconnectOrder.removeAll()
                    chargeStartDate = now
                } else {
                    disconnectStart = now
                    disconnectOrder =
                        Array(0..<sectorCount).shuffled()
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}
// MARK: - Apple Logo
private struct AppleLogoFill: View {
    let progress: Double
    let isCharging: Bool
    let time: TimeInterval
    let disconnectElapsed: TimeInterval?
    let disconnectOrder: [Int]
    let logoHeight: CGFloat
    private let sectorCount = 6
    private let disconnectTotal: TimeInterval = 3.0
    private let sectorDuration: TimeInterval = 0.6
    private let sectorStartStep: TimeInterval = 0.48
    private let colors: [SectorColor] = [
        // 1
        SectorColor(
            r: 0.05,
            g: 0.42,
            b: 0.95
        ),
        // 2
        SectorColor(
            r: 0.39,
            g: 0.18,
            b: 0.78
        ),
        // 3
        SectorColor(
            r: 0.82,
            g: 0.05,
            b: 0.35
        ),
        // 4
        SectorColor(
            r: 0.98,
            g: 0.22,
            b: 0.10
        ),
        // 5
        SectorColor(
            r: 1.00,
            g: 0.52,
            b: 0.05
        ),
        // 6
        SectorColor(
            r: 0.42,
            g: 0.78,
            b: 0.12
        )
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
            let scaled =
                progress * Double(sectorCount)
            let completed =
                min(
                    sectorCount,
                    Int(scaled.rounded(.down))
                )
            let currentFraction =
                scaled - Double(completed)
            let leafGrowth =
                leafProgress
            let fullyAlive =
                progress >= 1.0 &&
                disconnectElapsed == nil
            ZStack {
                // -------------------------------------------------
                // 1. ВНЕШНИЙ МЯГКИЙ КОНТУР
                //
                // Только здесь есть blur.
                // Радиус 4.5 px.
                //
                // Сами сектора ниже НЕ размываются.
                // -------------------------------------------------
                AppleBodyShape()
                    .stroke(
                        Color.white.opacity(
                            fullyAlive ? 0.28 : 0.20
                        ),
                        lineWidth: 1.1
                    )
                    .blur(radius: 4.5)
                    .opacity(
                        fullyAlive ? 0.85 : 0.65
                    )
                // -------------------------------------------------
                // 2. ОСНОВНЫЕ СЕКТОРА
                //
                // Резкие.
                // НИКАКОГО blur здесь нет.
                // -------------------------------------------------
                ForEach(
                    Array(0..<sectorCount),
                    id: \.self
                ) { index in
                    let sectorVisible =
                        sectorVisibility(
                            index: index,
                            completed: completed,
                            currentFraction: currentFraction,
                            disconnectElapsed: disconnectElapsed
                        )
                    if sectorVisible > 0 {
                        let pulse =
                            heartbeat(
                                time,
                                phase: Double(index) * 0.035
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
                                    CGFloat(index) * bandHeight
                            )
                            .opacity(
                                sectorVisible
                            )
                            .mask(
                                AppleBodyShape()
                            )
                    }
                }
                // -------------------------------------------------
                // 3. МЯГКОЕ ДЫХАНИЕ КРАЯ
                //
                // Очень слабый внешний контур.
                // Внутреннюю резкость не затрагивает.
                // -------------------------------------------------
                AppleBodyShape()
                    .stroke(
                        Color.white.opacity(
                            0.08 +
                            0.06 * heartbeat(time, phase: 0)
                        ),
                        lineWidth: 0.55
                    )
                // -------------------------------------------------
                // 4. ЛИСТ
                //
                // Рост только после 88%.
                // 88 -> 100% растянут по времени.
                // -------------------------------------------------
                if leafGrowth > 0 {
                    AppleLeafShape()
                        .trim(
                            from: 0,
                            to: leafGrowth
                        )
                        .stroke(
                            Color(
                                red: 0.42,
                                green: 0.78,
                                blue: 0.12
                            ),
                            style: StrokeStyle(
                                lineWidth: 5.0,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .opacity(
                            min(
                                1.0,
                                leafGrowth * 1.15
                            )
                        )
                }
            }
        }
    }
    // MARK: Sector visibility
    private func sectorVisibility(
        index: Int,
        completed: Int,
        currentFraction: Double,
        disconnectElapsed: TimeInterval?
    ) -> Double {
        // ---------------------------------------------------------
        // Зарядка
        // ---------------------------------------------------------
        if disconnectElapsed == nil {
            if index < completed {
                return 1.0
            }
            if index == completed &&
                completed < sectorCount {
                return currentFraction
            }
            return 0.0
        }
        // ---------------------------------------------------------
        // Отключение:
        // сектора исчезают в случайном порядке.
        // ---------------------------------------------------------
        guard
            let elapsed = disconnectElapsed,
            let position =
                disconnectOrder.firstIndex(of: index)
        else {
            return 1.0
        }
        let start =
            Double(position) * sectorStartStep
        let local =
            elapsed - start
        if local <= 0 {
            return 1.0
        }
        if local >= sectorDuration {
            return 0.0
        }
        let t =
            max(
                0,
                min(
                    1,
                    local / sectorDuration
                )
            )
        let eased =
            1.0 -
            (
                t * t *
                (3.0 - 2.0 * t)
            )
        return eased
    }
    // MARK: Leaf progress
    private var leafProgress: Double {
        guard disconnectElapsed == nil else {
            return 0.0
        }
        // Лист начинает расти только после 88%.
        guard progress >= 0.88 else {
            return 0.0
        }
        let normalized =
            (progress - 0.88) / 0.12
        // Плавный slow-in / slow-out.
        let clamped =
            max(
                0.0,
                min(1.0, normalized)
            )
        return clamped * clamped *
            (3.0 - 2.0 * clamped)
    }
    // MARK: Heartbeat
    private func heartbeat(
        _ time: TimeInterval,
        phase: Double
    ) -> Double {
        // Примерно 65 BPM.
        let cycle =
            (time * 1.08 + phase)
                .truncatingRemainder(
                    dividingBy: 1.0
                )
        // Первый, более сильный удар.
        let first =
            exp(
                -pow(
                    (cycle - 0.095) / 0.052,
                    2
                )
            )
        // Второй, более мягкий удар.
        let second =
            exp(
                -pow(
                    (cycle - 0.225) / 0.075,
                    2
                )
            )
        return min(
            1.0,
            first * 0.95 +
            second * 0.52
        )
    }
    // MARK: Sector gradient
    private func sectorGradient(
        base: SectorColor,
        index: Int,
        time: TimeInterval,
        intensity: Double
    ) -> LinearGradient {
        let pulse =
            heartbeat(
                time,
                phase: Double(index) * 0.035
            )
        // Очень медленное внутреннее переливание.
        let drift =
            0.5 +
            0.5 *
            sin(
                time * 0.72 +
                Double(index) * 0.85
            )
        let darkFactor =
            0.82 +
            0.08 * pulse +
            0.035 * drift
        let midFactor =
            intensity +
            0.045 * drift
        let brightFactor =
            0.91 +
            0.14 * pulse +
            0.035 * drift
        let dark =
            base.color(
                multipliedBy: darkFactor
            )
        let mid =
            base.color(
                multipliedBy: midFactor
            )
        let bright =
            base.color(
                multipliedBy: brightFactor
            )
        let startX =
            0.03 +
            0.10 * pulse
        let endX =
            0.87 -
            0.08 * pulse
        return LinearGradient(
            stops: [
                Gradient.Stop(
                    color: dark,
                    location: 0.0
                ),
                Gradient.Stop(
                    color: mid,
                    location: 0.32
                ),
                Gradient.Stop(
                    color: bright,
                    location: 0.55
                ),
                Gradient.Stop(
                    color: mid,
                    location: 0.76
                ),
                Gradient.Stop(
                    color: dark,
                    location: 1.0
                )
            ],
            startPoint: UnitPoint(
                x: startX,
                y: 0
            ),
            endPoint: UnitPoint(
                x: endX,
                y: 1
            )
        )
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
            red: min(1.0, r * factor),
            green: min(1.0, g * factor),
            blue: min(1.0, b * factor)
        )
    }
}
// MARK: - Plant Particle Field
private struct PlantParticleField: View {
    let progress: Double
    let isCharging: Bool
    let time: TimeInterval
    let size: CGSize
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
    private func drawFlow(
        context: inout GraphicsContext,
        canvasSize: CGSize
    ) {
        // Узкий поток, который появляется снизу.
        let width =
            max(
                2.2,
                canvasSize.width * 0.0032
            )
        let logoTopY =
            max(
                42,
                canvasSize.height * 0.075
            )
        let logoBottomY =
            logoTopY +
            logoHeight
        let targetY =
            logoBottomY -
            12
        let startY =
            canvasSize.height + 25
        let travel =
            max(
                0,
                min(
                    1,
                    (progress * 1.28)
                )
            )
        let y =
            startY -
            (startY - targetY) *
            CGFloat(
                easeOut(travel)
            )
        let centerX =
            canvasSize.width * 0.50
        let wave =
            sin(
                time * 1.45
            ) * canvasSize.width * 0.015
        let wave2 =
            sin(
                time * 0.83 + 1.7
            ) * canvasSize.width * 0.009
        var path = Path()
        path.move(
            to: CGPoint(
                x: centerX + wave,
                y: startY
            )
        )
        path.addCurve(
            to: CGPoint(
                x: centerX + wave + wave2,
                y: y
            ),
            control1:
                CGPoint(
                    x: centerX -
                        canvasSize.width * 0.018,
                    y:
                        startY -
                        (startY - y) * 0.30
                ),
            control2:
                CGPoint(
                    x: centerX +
                        canvasSize.width * 0.024,
                    y:
                        startY -
                        (startY - y) * 0.72
                )
        )
        let opacity =
            0.10 +
            0.16 *
            travel
        context.stroke(
            path,
            with: .color(
                Color(
                    red: 0.38,
                    green: 0.90,
                    blue: 0.30
                )
                .opacity(opacity)
            ),
            style: StrokeStyle(
                lineWidth: width,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
    private func drawPollen(
        context: inout GraphicsContext,
        canvasSize: CGSize
    ) {
        guard progress > 0.05 else {
            return
        }
        let count = 28
        for index in 0..<count {
            let seed =
                Double(index) * 17.31
            let phase =
                seed.truncatingRemainder(
                    dividingBy: 6.28318
                )
            let speed =
                0.18 +
                (
                    seed
                        .truncatingRemainder(
                            dividingBy: 100
                        ) / 100
                ) * 0.22
            let t =
                (
                    time * speed +
                    phase
                )
                .truncatingRemainder(
                    dividingBy: 1.0
                )
            let xBase =
                (
                    seed * 7.17
                )
                .truncatingRemainder(
                    dividingBy: 1.0
                )
            let x =
                canvasSize.width *
                (
                    0.22 +
                    0.56 * xBase
                )
            let y =
                canvasSize.height *
                (
                    0.92 -
                    0.68 * t
                )
            let radius =
                0.65 +
                (
                    seed
                        .truncatingRemainder(
                            dividingBy: 100
                        ) / 100
                ) * 1.2
            let pulse =
                heartbeat(
                    time,
                    phase: phase
                )
            let opacity =
                0.08 +
                0.13 * pulse
            let rect =
                CGRect(
                    x: x - radius,
                    y: y - radius,
                    width: radius * 2,
                    height: radius * 2
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
                    .opacity(opacity)
                )
            )
        }
    }
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
    private func heartbeat(
        _ time: TimeInterval,
        phase: Double
    ) -> Double {
        let cycle =
            (time * 1.08 + phase)
                .truncatingRemainder(
                    dividingBy: 1.0
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
            1.0,
            first * 0.95 +
            second * 0.52
        )
    }
}
