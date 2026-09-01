import SwiftUI
import UIKit

// MARK: - Charging Logo

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var logoOpacity: Double = 0.0

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 60.0,
                paused: false
            )
        ) { context in

            let time = context.date.timeIntervalSinceReferenceDate
            let p = max(0.0, min(1.0, progress))

            ZStack {
                // Цветное тело логотипа.
                // Сектора заполняются снизу вверх.
                AppleBodyFill(
                    progress: p,
                    time: time
                )

                // Верхний лист появляется последним.
                AppleLeafReveal(
                    progress: p
                )

                // Поток только из листиков и цветков.
                // Ветки, стебли, twig и пыль отсутствуют.
                FormationParticles(
                    progress: p,
                    time: time
                )
            }
            .opacity(logoOpacity)
        }
        .aspectRatio(
            814.0 / 1000.0,
            contentMode: .fit
        )
        .onAppear {
            logoOpacity = isCharging ? 1.0 : 0.0
        }
        .onChange(of: isCharging) { _, charging in

            if charging {
                // Новая зарядка.
                logoOpacity = 0.0

                withAnimation(
                    .easeOut(duration: 0.35)
                ) {
                    logoOpacity = 1.0
                }

            } else {

                // Отключение кабеля:
                // плавное растворение.
                withAnimation(
                    .easeInOut(duration: 1.35)
                ) {
                    logoOpacity = 0.0
                }
            }
        }
    }
}


// MARK: - Apple Body

private struct AppleBodyFill: View {

    let progress: Double
    let time: TimeInterval

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
            red: 1.00,
            green: 0.78,
            blue: 0.10
        )
    ]

    var body: some View {

        GeometryReader { geo in

            AppleSectorStack(
                progress: progress,
                time: time,
                colors: colors,
                size: geo.size
            )
            .mask(
                AppleBodyShape()
            )
        }
    }
}


// MARK: - Sequential Sectors

private struct AppleSectorStack: View {

    let progress: Double
    let time: TimeInterval
    let colors: [Color]
    let size: CGSize

    var body: some View {

        let count = colors.count

        // 0...1 превращается в 0...6.
        let scaled =
            progress *
            Double(count)

        let completed =
            min(
                count,
                Int(
                    floor(scaled)
                )
            )

        let fraction =
            min(
                1.0,
                max(
                    0.0,
                    scaled -
                    Double(completed)
                )
            )

        let top =
            size.height *
            0.241

        let bottom =
            size.height

        let bandHeight =
            (bottom - top) /
            CGFloat(count)

        ZStack(
            alignment: .topLeading
        ) {

            ForEach(
                0..<count,
                id: \.self
            ) { index in

                AppleSector(
                    index: index,
                    count: count,
                    completed: completed,
                    fraction: fraction,
                    time: time,
                    color: colors[index],

                    // ВАЖНО:
                    // передаём весь массив цветов.
                    colors: colors,

                    width: size.width,
                    bandHeight: bandHeight,
                    bottom: bottom
                )
            }
        }
    }
}


// MARK: - Apple Sector

private struct AppleSector: View {

    let index: Int
    let count: Int
    let completed: Int
    let fraction: Double
    let time: TimeInterval
    let color: Color

    // ИСПРАВЛЕНИЕ:
    // neighboringColor() использует этот массив.
    let colors: [Color]

    let width: CGFloat
    let bandHeight: CGFloat
    let bottom: CGFloat

    var body: some View {

        let amount =
            amountForSector()

        if amount > 0.0 {

            let fillHeight =
                max(
                    0.5,
                    bandHeight *
                    CGFloat(amount)
                )

            let bottomY =
                bottom -
                CGFloat(index) *
                bandHeight

            let centerY =
                bottomY -
                fillHeight / 2.0

            // Колышется только граница
            // сектора, который сейчас формируется.
            let active =
                index == completed &&
                completed < count

            let waveAmplitude =
                active
                ? max(
                    2.0,
                    bandHeight * 0.075
                )
                : 0.0

            let phase =
                time * 0.72 +
                Double(index) * 1.83

            let xWobble =
                active
                ? sin(
                    time * 0.55 +
                    Double(index) * 1.37
                ) *
                width *
                0.004
                : 0.0

            Rectangle()
                .fill(
                    animatedColor(
                        base: color,
                        index: index,
                        time: time
                    )
                )
                .frame(
                    width: width,
                    height: fillHeight
                )
                .position(
                    x:
                        width / 2.0 +
                        xWobble,

                    y:
                        centerY
                )
                .clipShape(
                    SectorWaveShape(
                        amplitude:
                            waveAmplitude,

                        phase:
                            phase
                    )
                )
        }
    }

    // MARK: Sector Amount

    private func amountForSector() -> Double {

        // index 0 — нижний сектор.
        // Поэтому заполнение идёт снизу вверх.

        if index < completed {
            return 1.0
        }

        if index == completed {
            return fraction
        }

        return 0.0
    }

    // MARK: Animated Color

    private func animatedColor(
        base: Color,
        index: Int,
        time: TimeInterval
    ) -> Color {

        let wave =
            0.5 +
            0.5 *
            sin(
                time * 0.22 +
                Double(index) * 0.82
            )

        let amount =
            0.035 +
            wave * 0.055

        return base.mix(
            with: neighboringColor(index),
            by: amount
        )
    }

    // MARK: Neighboring Color

    private func neighboringColor(
        _ index: Int
    ) -> Color {

        guard !colors.isEmpty else {
            return color
        }

        let next =
            min(
                colors.count - 1,
                index + 1
            )

        return colors[next]
    }
}


// MARK: - Top Leaf

private struct AppleLeafReveal: View {

    let progress: Double

    var body: some View {

        let leafProgress =
            smoothStep(
                (progress - 0.90) /
                0.10
            )

        AppleLeafShape()
            .fill(
                Color(
                    red: 0.39,
                    green: 0.72,
                    blue: 0.22
                )
            )
            .opacity(
                leafProgress
            )
            .scaleEffect(
                x:
                    0.78 +
                    0.22 *
                    leafProgress,

                y:
                    0.78 +
                    0.22 *
                    leafProgress,

                anchor: .bottom
            )
    }
}


// MARK: - Formation Particles

private struct FormationParticles: View {

    let progress: Double
    let time: TimeInterval

    private let particles =
        FormationParticle.all

    var body: some View {

        Canvas { context, size in

            // После появления верхнего листа
            // поток полностью прекращается.
            guard progress < 0.985 else {
                return
            }

            let sectorCount = 6

            let scaled =
                progress *
                Double(sectorCount)

            let currentSector =
                min(
                    sectorCount - 1,
                    Int(
                        floor(scaled)
                    )
                )

            let sectorFraction =
                scaled -
                Double(currentSector)

            for particle in particles {

                let cycle =
                    particle.duration

                let rawPhase =
                    (
                        time / cycle +
                        particle.offset
                    )
                    .truncatingRemainder(
                        dividingBy: 1.0
                    )

                let phase =
                    smoothStep(
                        rawPhase
                    )

                // ---------------------------------------------------------
                // Начало потока.
                //
                // Центр нижней части экрана.
                // ---------------------------------------------------------

                let startX =
                    size.width * 0.5 +
                    particle.startOffset

                let startY =
                    size.height * 1.03

                // ---------------------------------------------------------
                // Цель.
                //
                // Текущий сектор.
                // ---------------------------------------------------------

                let sectorHeight =
                    size.height * 0.126

                let targetY =
                    size.height * 0.94 -
                    CGFloat(currentSector) *
                    sectorHeight -
                    sectorFraction *
                    sectorHeight *
                    0.72

                // ---------------------------------------------------------
                // Лёгкое колыхание.
                // ---------------------------------------------------------

                let sway =
                    sin(
                        phase *
                        .pi *
                        2.0 +
                        particle.phase
                    ) *
                    particle.drift

                let secondarySway =
                    sin(
                        phase *
                        .pi *
                        4.0 -
                        particle.phase *
                        0.6
                    ) *
                    particle.drift *
                    0.30

                let x =
                    startX +
                    sway +
                    secondarySway

                // Плавное движение к логотипу.
                let yProgress =
                    easeOutCubic(
                        phase
                    )

                let y =
                    startY +
                    (
                        targetY -
                        startY
                    ) *
                    CGFloat(
                        yProgress
                    )

                // ---------------------------------------------------------
                // Поглощение.
                //
                // Перед попаданием в сектор частица
                // постепенно исчезает.
                // ---------------------------------------------------------

                let absorptionStart =
                    0.78

                let absorption: Double

                if phase <
                    absorptionStart {

                    absorption = 1.0

                } else {

                    absorption =
                        max(
                            0.0,
                            1.0 -
                            (
                                phase -
                                absorptionStart
                            ) /
                            (
                                1.0 -
                                absorptionStart
                            )
                        )
                }

                let alpha =
                    particle.opacity *
                    absorption

                guard alpha > 0.01 else {
                    continue
                }

                var particleContext =
                    context

                particleContext.opacity =
                    alpha

                drawParticle(
                    particle,
                    at:
                        CGPoint(
                            x: x,
                            y: y
                        ),
                    in:
                        &particleContext
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Draw Particle

    private func drawParticle(
        _ particle: FormationParticle,
        at point: CGPoint,
        in context: inout GraphicsContext
    ) {

        let s =
            particle.size

        switch particle.kind {

        case .leaf:

            drawLeaf(
                at: point,
                size: s,
                color: particle.color,
                context: &context
            )

        case .flower:

            drawFlower(
                at: point,
                size: s,
                color: particle.color,
                context: &context
            )
        }
    }

    // MARK: Leaf

    private func drawLeaf(
        at point: CGPoint,
        size: CGFloat,
        color: Color,
        context: inout GraphicsContext
    ) {

        var path = Path()

        path.move(
            to:
                CGPoint(
                    x: point.x,
                    y: point.y + size
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x:
                        point.x +
                        size * 0.82,

                    y:
                        point.y -
                        size * 0.35
                ),

            control1:
                CGPoint(
                    x:
                        point.x +
                        size * 0.10,

                    y:
                        point.y +
                        size * 0.20
                ),

            control2:
                CGPoint(
                    x:
                        point.x +
                        size * 0.68,

                    y:
                        point.y -
                        size * 0.08
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x: point.x,
                    y:
                        point.y + size
                ),

            control1:
                CGPoint(
                    x:
                        point.x +
                        size * 0.40,

                    y:
                        point.y +
                        size * 0.05
                ),

            control2:
                CGPoint(
                    x:
                        point.x +
                        size * 0.08,

                    y:
                        point.y +
                        size * 0.58
                )
        )

        context.fill(
            path,
            with:
                .color(color)
        )
    }

    // MARK: Flower

    private func drawFlower(
        at point: CGPoint,
        size: CGFloat,
        color: Color,
        context: inout GraphicsContext
    ) {

        var path = Path()

        for i in 0..<5 {

            let angle =
                CGFloat(i) *
                (
                    .pi * 2.0 /
                    5.0
                )

            let x =
                point.x +
                cos(angle) *
                size *
                0.55

            let y =
                point.y +
                sin(angle) *
                size *
                0.55

            path.addEllipse(
                in:
                    CGRect(
                        x:
                            x -
                            size * 0.22,

                        y:
                            y -
                            size * 0.22,

                        width:
                            size * 0.44,

                        height:
                            size * 0.44
                    )
            )
        }

        path.addEllipse(
            in:
                CGRect(
                    x:
                        point.x -
                        size * 0.18,

                    y:
                        point.y -
                        size * 0.18,

                    width:
                        size * 0.36,

                    height:
                        size * 0.36
                )
        )

        context.fill(
            path,
            with:
                .color(color)
        )
    }
}


// MARK: - Particle Model

private struct FormationParticle {

    enum Kind {
        case leaf
        case flower
    }

    let kind: Kind

    let startOffset: CGFloat
    let duration: Double
    let offset: Double
    let phase: Double
    let drift: CGFloat
    let size: CGFloat
    let opacity: Double
    let color: Color

    static let all: [FormationParticle] = {

        let palette: [Color] = [

            Color(
                red: 0.38,
                green: 0.78,
                blue: 0.26
            ),

            Color(
                red: 0.30,
                green: 0.68,
                blue: 0.92
            ),

            Color(
                red: 0.98,
                green: 0.72,
                blue: 0.18
            ),

            Color(
                red: 0.98,
                green: 0.32,
                blue: 0.22
            ),

            Color(
                red: 0.90,
                green: 0.30,
                blue: 0.62
            ),

            Color(
                red: 0.62,
                green: 0.38,
                blue: 0.92
            )
        ]

        // Умеренно плотный поток.
        // Не слишком густой.
        return (0..<42).map { i in

            let seed =
                Double(
                    (
                        i * 37 +
                        11
                    ) % 101
                ) / 101.0

            let kind: Kind =
                i % 3 == 0
                ? .flower
                : .leaf

            return FormationParticle(

                kind:
                    kind,

                // Источник расположен
                // в центральной нижней области.
                startOffset:
                    CGFloat(
                        seed - 0.5
                    ) *
                    34.0,

                duration:
                    2.05 +
                    seed * 0.85,

                offset:
                    seed * 0.97,

                phase:
                    seed * 12.0,

                drift:
                    7.0 +
                    CGFloat(seed) *
                    18.0,

                size:
                    kind == .flower
                    ? 4.2 +
                        CGFloat(seed) *
                        3.2
                    : 4.0 +
                        CGFloat(seed) *
                        4.0,

                opacity:
                    0.48 +
                    seed * 0.38,

                color:
                    palette[
                        i %
                        palette.count
                    ]
            )
        }
    }()
}


// MARK: - Sector Wave

private struct SectorWaveShape: Shape {

    let amplitude: CGFloat
    let phase: Double

    func path(
        in rect: CGRect
    ) -> Path {

        var path = Path()

        let samples = 28

        path.move(
            to:
                CGPoint(
                    x: 0,
                    y: 0
                )
        )

        for i in 0...samples {

            let x =
                rect.width *
                CGFloat(i) /
                CGFloat(samples)

            let t =
                Double(i) /
                Double(samples)

            let wave: CGFloat

            if amplitude == 0 {

                wave = 0.0

            } else {

                wave =
                    sin(
                        t *
                        .pi *
                        2.0 *
                        1.15 +
                        phase
                    ) *
                    amplitude

                +
                    sin(
                        t *
                        .pi *
                        2.0 *
                        0.57 -
                        phase *
                        0.52
                    ) *
                    amplitude *
                    0.42
            }

            path.addLine(
                to:
                    CGPoint(
                        x: x,
                        y: wave
                    )
            )
        }

        path.addLine(
            to:
                CGPoint(
                    x: rect.width,
                    y: rect.height
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: 0,
                    y: rect.height
                )
        )

        path.closeSubpath()

        return path
    }
}


// MARK: - Color Helpers

private extension Color {

    func mix(
        with other: Color,
        by amount: Double
    ) -> Color {

        let t =
            max(
                0.0,
                min(
                    1.0,
                    amount
                )
            )

        let a = UIColor(self)
        let b = UIColor(other)

        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0

        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        guard
            a.getRed(
                &r1,
                green: &g1,
                blue: &b1,
                alpha: &a1
            ),
            b.getRed(
                &r2,
                green: &g2,
                blue: &b2,
                alpha: &a2
            )
        else {
            return self
        }

        return Color(
            red:
                Double(
                    r1 +
                    (r2 - r1) *
                    CGFloat(t)
                ),

            green:
                Double(
                    g1 +
                    (g2 - g1) *
                    CGFloat(t)
                ),

            blue:
                Double(
                    b1 +
                    (b2 - b1) *
                    CGFloat(t)
                ),

            opacity:
                Double(
                    a1 +
                    (a2 - a1) *
                    CGFloat(t)
                )
        )
    }
}


// MARK: - Math

private func smoothStep(
    _ value: Double
) -> Double {

    let x =
        max(
            0.0,
            min(
                1.0,
                value
            )
        )

    return
        x *
        x *
        (
            3.0 -
            2.0 * x
        )
}


private func easeOutCubic(
    _ value: Double
) -> Double {

    let x =
        max(
            0.0,
            min(
                1.0,
                value
            )
        )

    return
        1.0 -
        pow(
            1.0 - x,
            3.0
        )
}
