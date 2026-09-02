import SwiftUI

struct ChargingLogoView: View {

    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    private let sectorCount = 6

    @State private var disconnectOrder: [Int] = []
    @State private var disconnectStart: Date?
    @State private var disconnectGeneration = 0

    var body: some View {

        TimelineView(
            .animation(
                minimumInterval: 1.0 / 60.0,
                paused: false
            )
        ) { context in

            let now = context.date.timeIntervalSinceReferenceDate

            GeometryReader { geometry in

                let logoSize = min(
                    geometry.size.width,
                    geometry.size.height
                )

                // 30 мм ≈ 181 pt на iPhone с плотностью около 460 ppi / 3x.
                // Ограничиваем размер, чтобы логотип не становился чрезмерным.
                let actualSize = min(
                    logoSize,
                    181
                )

                ZStack {

                    // MARK: Exact Apple logo

                    AppleLogoFill(
                        progress: effectiveProgress(
                            now: now
                        ),
                        time: now,
                        disconnectOrder: disconnectOrder,
                        disconnectStart: disconnectStart,
                        sectorCount: sectorCount
                    )
                    .frame(
                        width: actualSize,
                        height: actualSize * 1000.0 / 814.0
                    )

                    // MARK: Flying plant particles

                    if effectiveProgress(now: now) > 0.0001 {
                        PlantParticleField(
                            progress: effectiveProgress(
                                now: now
                            ),
                            time: now,
                            isDisconnecting: isDisconnecting(now: now)
                        )
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .allowsHitTesting(false)
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
            }
        }
        .onAppear {
            if !isCharging && progress > 0 {
                beginDisconnect()
            }
        }
        .onChange(of: isCharging) { _, charging in

            if charging {
                disconnectGeneration += 1
                disconnectStart = nil
                disconnectOrder = []
            } else {
                beginDisconnect()
            }
        }
    }

    // MARK: - Progress

    private func effectiveProgress(now: TimeInterval) -> Double {

        guard !isDisconnecting(now: now) else {

            guard let start = disconnectStart else {
                return clamped(progress)
            }

            let elapsed = now - start

            if elapsed >= 3.0 {
                return 0
            }

            // Сохраняем исходный уровень как базу,
            // пока случайные сектора исчезают.
            return clamped(progress)
        }

        return clamped(progress)
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }

    // MARK: - Disconnect

    private func beginDisconnect() {

        disconnectGeneration += 1

        disconnectStart = Date()
        disconnectOrder = Array(0..<sectorCount).shuffled()

        let generation = disconnectGeneration

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 3.0
        ) {
            guard generation == disconnectGeneration else {
                return
            }

            disconnectStart = nil
            disconnectOrder = []
        }
    }

    private func isDisconnecting(now: TimeInterval) -> Bool {

        guard let start = disconnectStart else {
            return false
        }

        return now - start < 3.0
    }
}

// MARK: - Apple fill

private struct AppleLogoFill: View {

    let progress: Double
    let time: TimeInterval

    let disconnectOrder: [Int]
    let disconnectStart: Date?

    let sectorCount: Int

    private let colors: [Color] = [

        // bottom → top
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
            red: 0.12,
            green: 0.72,
            blue: 0.28
        )
    ]

    var body: some View {

        GeometryReader { geometry in

            let bodyRect = CGRect(
                x: 0,
                y: 0,
                width: geometry.size.width,
                height: geometry.size.height
            )

            let bodyTop = bodyRect.height * 0.245
            let bodyBottom = bodyRect.height
            let bodyHeight = bodyBottom - bodyTop

            let bandHeight =
                bodyHeight / CGFloat(sectorCount)

            let normalized =
                min(max(progress / 100.0, 0), 1)

            let scaled =
                normalized * Double(sectorCount)

            let completed =
                min(
                    sectorCount,
                    Int(floor(scaled))
                )

            let currentFraction =
                min(
                    max(
                        scaled - Double(completed),
                        0
                    ),
                    1
                )

            ZStack {

                // MARK: Body sectors

                ForEach(
                    0..<sectorCount,
                    id: \.self
                ) { index in

                    let fillAmount: CGFloat = {

                        if index < completed {
                            return 1
                        }

                        if index == completed {
                            return CGFloat(currentFraction)
                        }

                        return 0
                    }()

                    if fillAmount > 0 {

                        LiquidSector(
                            color: colors[index],
                            index: index,
                            fillAmount: fillAmount,
                            bandHeight: bandHeight,
                            bodyTop: bodyTop,
                            bodyBottom: bodyBottom,
                            time: time
                        )
                    }
                }
            }
            .mask(
                AppleBodyShape()
            )
            .opacity(
                globalOpacity()
            )

            // MARK: Leaf

            LeafGrowth(
                progress: normalized,
                disconnectStart: disconnectStart,
                time: time
            )
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
    }

    // MARK: - Sector opacity during disconnect

    private func globalOpacity() -> Double {

        guard let start = disconnectStart else {
            return 1
        }

        let elapsed =
            Date().timeIntervalSince(start)

        if elapsed >= 3.0 {
            return 0
        }

        return 1
    }
}

// MARK: - Liquid sector

private struct LiquidSector: View {

    let color: Color
    let index: Int
    let fillAmount: CGFloat
    let bandHeight: CGFloat
    let bodyTop: CGFloat
    let bodyBottom: CGFloat
    let time: TimeInterval

    var body: some View {

        let height =
            max(
                0.5,
                bandHeight * fillAmount
            )

        let sectorBottom =
            bodyBottom
            - CGFloat(index) * bandHeight

        let centerY =
            sectorBottom
            - height / 2

        let largeWave =
            sin(
                time * 0.82
                + Double(index) * 1.37
            )

        let secondWave =
            sin(
                time * 0.47
                + Double(index) * 2.41
            )

        let xOffset =
            CGFloat(
                largeWave * 2.8
                + secondWave * 1.7
            )

        let yOffset =
            CGFloat(
                sin(
                    time * 0.63
                    + Double(index) * 1.91
                )
                * bandHeight
                * 0.035
            )

        Rectangle()
            .fill(color)
            .frame(
                maxWidth: .infinity,
                height: height
            )
            .position(
                x: xOffset
                    + UIScreen.main.bounds.width / 2,
                y: centerY + yOffset
            )
            .clipShape(
                LiquidWaveShape(
                    amplitude:
                        max(
                            3,
                            bandHeight * 0.16
                        ),
                    phase:
                        time * 0.75
                        + Double(index) * 1.83
                )
            )
    }
}

// MARK: - Large organic wave

private struct LiquidWaveShape: Shape {

    let amplitude: CGFloat
    let phase: Double

    func path(in rect: CGRect) -> Path {

        var path = Path()

        let samples = 48

        path.move(
            to: CGPoint(
                x: 0,
                y: rect.height
            )
        )

        for i in 0...samples {

            let t =
                Double(i)
                / Double(samples)

            let x =
                rect.width
                * CGFloat(t)

            let wave1 =
                sin(
                    t * .pi * 2.0 * 0.72
                    + phase
                )

            let wave2 =
                sin(
                    t * .pi * 2.0 * 1.31
                    - phase * 0.63
                )

            let wave3 =
                sin(
                    t * .pi * 2.0 * 0.37
                    + phase * 0.41
                )

            let y =
                amplitude * (
                    wave1
                    + wave2 * 0.42
                    + wave3 * 0.23
                )

            path.addLine(
                to: CGPoint(
                    x: x,
                    y: y
                )
            )
        }

        path.addLine(
            to: CGPoint(
                x: rect.width,
                y: rect.height
            )
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Leaf growth 88 → 100%

private struct LeafGrowth: View {

    let progress: Double
    let disconnectStart: Date?
    let time: TimeInterval

    var body: some View {

        let growth = leafGrowth

        AppleLeafShape()
            .fill(
                Color(
                    red: 0.12,
                    green: 0.72,
                    blue: 0.28
                )
            )
            .scaleEffect(
                x: 0.10 + growth * 0.90,
                y: 0.10 + growth * 0.90,
                anchor: UnitPoint(
                    x: 0.52,
                    y: 0.20
                )
            )
            .rotationEffect(
                .degrees(
                    -7.0 + growth * 7.0
                ),
                anchor: UnitPoint(
                    x: 0.52,
                    y: 0.20
                )
            )
            .opacity(
                growth > 0
                    ? min(1, growth * 1.25)
                    : 0
            )
    }

    private var leafGrowth: Double {

        if let disconnectStart {

            let elapsed =
                Date().timeIntervalSince(
                    disconnectStart
                )

            if elapsed >= 3.0 {
                return 0
            }

            // Полностью сформированный лист
            // постепенно возвращается к бутону
            // за те же 3 секунды.
            let retract =
                min(
                    max(elapsed / 3.0, 0),
                    1
                )

            return max(
                0,
                1 - retract
            )
        }

        // Лист начинается только с 88%.
        guard progress >= 0.88 else {
            return 0
        }

        return min(
            max(
                (progress - 0.88) / 0.12,
                0
            ),
            1
        )
    }
}

// MARK: - 222 plant particles

private struct PlantParticleField: View {

    let progress: Double
    let time: TimeInterval
    let isDisconnecting: Bool

    private let particles =
        PlantParticle.all

    var body: some View {

        Canvas { context, size in

            guard progress >= 0.88 else {
                return
            }

            // Поток начинает слабеть после 96%.
            let streamStrength: Double = {

                if progress >= 1.0 {
                    return 0
                }

                let p =
                    min(
                        max(
                            (progress - 0.88) / 0.12,
                            0
                        ),
                        1
                    )

                return 0.95 - p * 0.95
            }()

            guard streamStrength > 0 else {
                return
            }

            for particle in particles {

                let cycle =
                    3.8 + particle.speed

                let rawPhase =
                    (
                        time / cycle
                        + particle.offset
                    )
                    .truncatingRemainder(
                        dividingBy: 1
                    )

                let phase =
                    rawPhase < 0
                    ? rawPhase + 1
                    : rawPhase

                let eased =
                    phase * phase
                    * (3 - 2 * phase)

                // Старт в нижней/средней зоне экрана.
                // Все частицы движутся к нижней части логотипа.
                let startY =
                    size.height * (
                        0.62
                        + particle.startY
                    )

                let targetY =
                    size.height * 0.48

                let y =
                    startY
                    + (targetY - startY)
                    * CGFloat(eased)

                let drift =
                    sin(
                        phase * .pi * 2
                        + particle.phase
                    )
                    * particle.drift

                let x =
                    size.width * (
                        0.50
                        + particle.startX
                    )
                    + drift

                // Последние 18% цикла —
                // визуальное поглощение в логотип.
                let absorption: Double

                if phase < 0.82 {
                    absorption = 1
                } else {
                    absorption =
                        max(
                            0,
                            1
                            - (
                                phase - 0.82
                            ) / 0.18
                        )
                }

                var particleContext = context

                particleContext.opacity =
                    streamStrength
                    * absorption
                    * particle.opacity

                draw(
                    particle,
                    at: CGPoint(
                        x: x,
                        y: y
                    ),
                    context: &particleContext,
                    time: time
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(
        _ particle: PlantParticle,
        at point: CGPoint,
        context: inout GraphicsContext,
        time: TimeInterval
    ) {

        switch particle.kind {

        case .leaf:

            var path = Path()

            let s = particle.size

            path.move(
                to: CGPoint(
                    x: point.x,
                    y: point.y + s
                )
            )

            path.addCurve(
                to: CGPoint(
                    x: point.x + s * 0.85,
                    y: point.y - s * 0.35
                ),
                control1: CGPoint(
                    x: point.x + s * 0.05,
                    y: point.y + s * 0.20
                ),
                control2: CGPoint(
                    x: point.x + s * 0.70,
                    y: point.y - s * 0.05
                )
            )

            path.addCurve(
                to: CGPoint(
                    x: point.x,
                    y: point.y + s
                ),
                control1: CGPoint(
                    x: point.x + s * 0.45,
                    y: point.y + s * 0.05
                ),
                control2: CGPoint(
                    x: point.x + s * 0.10,
                    y: point.y + s * 0.55
                )
            )

            path.closeSubpath()

            context.fill(
                path,
                with: .color(
                    particle.color
                )
            )

        case .flower:

            let s = particle.size

            var path = Path()

            for i in 0..<5 {

                let angle =
                    CGFloat(i)
                    * (.pi * 2 / 5)

                let px =
                    point.x
                    + cos(angle) * s * 0.52

                let py =
                    point.y
                    + sin(angle) * s * 0.52

                path.addEllipse(
                    in: CGRect(
                        x: px - s * 0.22,
                        y: py - s * 0.22,
                        width: s * 0.44,
                        height: s * 0.44
                    )
                )
            }

            path.addEllipse(
                in: CGRect(
                    x: point.x - s * 0.18,
                    y: point.y - s * 0.18,
                    width: s * 0.36,
                    height: s * 0.36
                )
            )

            context.fill(
                path,
                with: .color(
                    particle.color
                )
            )

        case .pollen:

            // Тонкая зелёная нить.
            // Длина и траектория различаются.
            let length =
                particle.size
                * (
                    1.8
                    + 1.4
                    * (
                        0.5
                        + 0.5
                        * sin(
                            time * 1.7
                            + particle.phase
                        )
                    )
                )

            let sway =
                sin(
                    time * 1.15
                    + particle.phase
                ) * 4.0

            var path = Path()

            path.move(
                to: CGPoint(
                    x: point.x,
                    y: point.y + length
                )
            )

            path.addCurve(
                to: CGPoint(
                    x: point.x + sway,
                    y: point.y - length
                ),
                control1: CGPoint(
                    x: point.x - sway * 0.7,
                    y: point.y + length * 0.35
                ),
                control2: CGPoint(
                    x: point.x + sway * 0.8,
                    y: point.y - length * 0.35
                )
            )

            // Мягкое зелёное мерцание,
            // без резкого blinking.
            let shimmer =
                0.5
                + 0.5
                * sin(
                    time * 2.2
                    + particle.phase
                )

            let green =
                Color(
                    red: 0.08,
                    green:
                        0.52
                        + 0.28 * shimmer,
                    blue:
                        0.18
                        + 0.12 * shimmer
                )

            context.stroke(
                path,
                with: .color(green),
                style: StrokeStyle(
                    lineWidth: 0.65,
                    lineCap: .round
                )
            )
        }
    }
}

// MARK: - Particle model
//
// РОВНО 222 частицы:
// 82 листа
// 60 цветов
// 80 зелёных нитей-пыльцы
//
// Никаких веток.

private struct PlantParticle {

    enum Kind {
        case leaf
        case flower
        case pollen
    }

    let kind: Kind

    let startX: CGFloat
    let startY: CGFloat

    let speed: Double
    let offset: Double
    let phase: Double
    let drift: CGFloat

    let size: CGFloat
    let opacity: Double

    let color: Color

    static let all: [PlantParticle] = {

        var result: [PlantParticle] = []

        // 82 leaves
        for i in 0..<82 {

            let seed =
                Double(
                    (i * 37 + 11) % 101
                ) / 101.0

            result.append(
                PlantParticle(
                    kind: .leaf,
                    startX:
                        CGFloat(seed - 0.5)
                        * 0.62,
                    startY:
                        CGFloat(
                            (i * 17 % 31)
                        ) / 100.0,
                    speed:
                        0.25
                        + seed * 1.20,
                    offset:
                        seed * 0.97,
                    phase:
                        seed * 10.0,
                    drift:
                        5
                        + CGFloat(seed) * 19,
                    size:
                        3.8
                        + CGFloat(seed) * 5.8,
                    opacity:
                        0.42
                        + seed * 0.48,
                    color:
                        Color(
                            red:
                                0.10
                                + seed * 0.08,
                            green:
                                0.48
                                + seed * 0.28,
                            blue:
                                0.12
                                + seed * 0.12
                        )
                )
            )
        }

        // 60 flowers
        for i in 0..<60 {

            let seed =
                Double(
                    (i * 53 + 7) % 97
                ) / 97.0

            result.append(
                PlantParticle(
                    kind: .flower,
                    startX:
                        CGFloat(seed - 0.5)
                        * 0.66,
                    startY:
                        CGFloat(
                            (i * 13 % 27)
                        ) / 100.0,
                    speed:
                        0.30
                        + seed * 1.30,
                    offset:
                        seed * 0.91,
                    phase:
                        seed * 8.7,
                    drift:
                        6
                        + CGFloat(seed) * 18,
                    size:
                        4.0
                        + CGFloat(seed) * 5.0,
                    opacity:
                        0.45
                        + seed * 0.45,
                    color:
                        Color(
                            red:
                                0.68
                                + seed * 0.26,
                            green:
                                0.58
                                + seed * 0.24,
                            blue:
                                0.10
                                + seed * 0.35
                        )
                )
            )
        }

        // 80 pollen threads
        for i in 0..<80 {

            let seed =
                Double(
                    (i * 61 + 19) % 103
                ) / 103.0

            result.append(
                PlantParticle(
                    kind: .pollen,
                    startX:
                        CGFloat(seed - 0.5)
                        * 0.72,
                    startY:
                        CGFloat(
                            (i * 19 % 34)
                        ) / 100.0,
                    speed:
                        0.20
                        + seed * 1.50,
                    offset:
                        seed * 0.83,
                    phase:
                        seed * 11.0,
                    drift:
                        4
                        + CGFloat(seed) * 20,
                    size:
                        4.0
                        + CGFloat(seed) * 8.0,
                    opacity:
                        0.25
                        + seed * 0.55,
                    color:
                        Color(
                            red: 0.08,
                            green:
                                0.55
                                + seed * 0.25,
                            blue:
                                0.16
                                + seed * 0.12
                        )
                )
            )
        }

        return result
    }()
}
