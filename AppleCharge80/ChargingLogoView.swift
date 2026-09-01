import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var plantStartDate: Date?
    @State private var plantFinished = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            ZStack {
                AppleLogoShape()
                    .stroke(
                        Color.white.opacity(0.20 * outlineProgress),
                        style: StrokeStyle(
                            lineWidth: 0.8,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .drawingGroup()

                AppleBodyFill(
                    progress: progress,
                    time: time,
                    frozen: plantFinished
                )

                // Лист/растение существует только после полного заполнения.
                if progress >= 0.999 {
                    GrowingApplePlant(
                        time: time,
                        startDate: plantStartDate,
                        finished: plantFinished
                    )
                    .onAppear {
                        if plantStartDate == nil {
                            plantStartDate = Date()
                        }
                    }
                }

                // Пыль и частицы становятся особенно заметны после завершения роста.
                PlantParticleView(
                    progress: progress,
                    time: time,
                    plantFinished: plantFinished
                )

                // Волны остаются живыми во время зарядки.
                ChargingWaves(
                    progress: progress,
                    time: time,
                    active: isCharging
                )
            }
            .onChange(of: progress) { _, newValue in
                if newValue < 0.999 {
                    plantStartDate = nil
                    plantFinished = false
                } else if plantStartDate == nil {
                    plantStartDate = Date()
                }
            }
            .onChange(of: plantStartDate) { _, newDate in
                guard let newDate else { return }

                // 5.8 секунды — ускоренный природный рост.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.8) {
                    guard plantStartDate == newDate else { return }
                    withAnimation(.easeInOut(duration: 0.8)) {
                        plantFinished = true
                    }
                }
            }
        }
        .aspectRatio(814.0 / 1000.0, contentMode: .fit)
    }
}

// MARK: - Apple body / sequential sectors

private struct AppleBodyFill: View {
    let progress: Double
    let time: TimeInterval
    let frozen: Bool

    private let colors: [Color] = [
        Color(red: 0.05, green: 0.42, blue: 0.95),
        Color(red: 0.39, green: 0.18, blue: 0.78),
        Color(red: 0.82, green: 0.05, blue: 0.35),
        Color(red: 0.98, green: 0.22, blue: 0.10),
        Color(red: 1.00, green: 0.52, blue: 0.05),
        Color(red: 1.00, green: 0.78, blue: 0.10)
    ]

    var body: some View {
        GeometryReader { geo in
            AppleBandStack(
                progress: progress,
                time: time,
                frozen: frozen,
                colors: colors,
                size: geo.size
            )
            .mask(AppleBodyShape())
        }
    }
}

private struct AppleBandStack: View {
    let progress: Double
    let time: TimeInterval
    let frozen: Bool
    let colors: [Color]
    let size: CGSize

    var body: some View {
        let count = colors.count
        let scaled = max(0.0, min(1.0, progress)) * Double(count)
        let completed = min(count, Int(scaled.rounded(.down)))
        let fraction = max(0.0, min(1.0, scaled - Double(completed)))
        let top = size.height * 0.241
        let bottom = size.height
        let bandHeight = (bottom - top) / CGFloat(count)

        ZStack(alignment: .topLeading) {
            ForEach(0..<count, id: \.self) { index in
                AppleBand(
                    index: index,
                    count: count,
                    completed: completed,
                    fraction: fraction,
                    time: time,
                    frozen: frozen,
                    color: colors[index],
                    width: size.width,
                    bandHeight: bandHeight,
                    bottom: bottom
                )
            }
        }
    }
}

private struct AppleBand: View {
    let index: Int
    let count: Int
    let completed: Int
    let fraction: Double
    let time: TimeInterval
    let frozen: Bool
    let color: Color
    let width: CGFloat
    let bandHeight: CGFloat
    let bottom: CGFloat

    var body: some View {
        let amount = amountForBand()
        let fillHeight = max(0.5, bandHeight * CGFloat(amount))
        let bottomY = bottom - CGFloat(index) * bandHeight
        let centerY = bottomY - fillHeight / 2.0
        let depth = max(count - index, 1)
        let movement = frozen ? 0.0 : 1.0 / Double(depth)
        let x = wobbleX(movement)
        let y = wobbleY(movement)
        let amplitude = index == completed && !frozen ? max(3.0, bandHeight * 0.11) : 0.0

        if amount > 0.0 {
            Rectangle()
                .fill(displayColor())
                .frame(width: width, height: fillHeight)
                .position(x: width / 2.0 + x, y: centerY + y)
                .clipShape(WaveFillShape(amplitude: amplitude, phase: time * 0.70 + Double(index) * 1.7))
        }
    }

    private func amountForBand() -> Double {
        if index < completed { return 1.0 }
        if index == completed { return fraction }
        return 0.0
    }

    private func wobbleX(_ movement: Double) -> CGFloat {
        CGFloat(sin(time * (0.72 + Double(index) * 0.035) + Double(index) * 1.71) * Double(width) * 0.010 * movement)
    }

    private func wobbleY(_ movement: Double) -> CGFloat {
        CGFloat(cos(time * (0.61 + Double(index) * 0.027) + Double(index) * 2.13) * Double(bandHeight) * 0.055 * movement)
    }

    private func displayColor() -> Color {
        guard frozen else { return color }
        let shimmer = 0.5 + 0.5 * sin(time * 0.20 + Double(index) * 0.73)
        return color.mix(with: .white, by: 0.05 + shimmer * 0.10)
    }
}

private extension Color {
    func mix(with other: Color, by amount: Double) -> Color {
        let t = max(0.0, min(1.0, amount))
        #if os(iOS)
        let a = UIColor(self)
        let b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        guard a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }
        return Color(
            red: Double(r1 + (r2 - r1) * CGFloat(t)),
            green: Double(g1 + (g2 - g1) * CGFloat(t)),
            blue: Double(b1 + (b2 - b1) * CGFloat(t)),
            opacity: Double(a1 + (a2 - a1) * CGFloat(t))
        )
        #else
        return self
        #endif
    }
}

private struct WaveFillShape: Shape {
    let amplitude: CGFloat
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let samples = 24
        path.move(to: CGPoint(x: 0, y: 0))
        for i in 0...samples {
            let x = rect.width * CGFloat(i) / CGFloat(samples)
            let t = Double(i) / Double(samples)
            let wave = amplitude == 0.0 ? 0.0 :
                sin(t * .pi * 2.0 * 1.25 + phase) * amplitude +
                sin(t * .pi * 2.0 * 0.63 - phase * 0.57) * amplitude * 0.45
            path.addLine(to: CGPoint(x: x, y: wave))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Natural plant growth

private struct GrowingApplePlant: View {
    let time: TimeInterval
    let startDate: Date?
    let finished: Bool

    private var growth: Double {
        guard let startDate else { return 0 }

        let elapsed = time - startDate.timeIntervalSinceReferenceDate

        let raw = max(0, min(1, elapsed / 5.8))

        // Быстрый рывок → замедление → раскрытие.
        return 1 - pow(1 - raw, 2.55)
    }

    var body: some View {
        GeometryReader { geo in
            let g = finished ? 1.0 : growth

            ZStack {
                NaturalStem(progress: g)
                    .stroke(
                        Color(red: 0.29, green: 0.18, blue: 0.07),
                        style: StrokeStyle(
                            lineWidth: max(1.5, geo.size.width * 0.009),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                NaturalBranch(
                    progress: max(0, min(1, (g - 0.18) / 0.82)),
                    side: -1,
                    y: 0.38
                )

                NaturalBranch(
                    progress: max(0, min(1, (g - 0.34) / 0.66)),
                    side: 1,
                    y: 0.31
                )

                NaturalBranch(
                    progress: max(0, min(1, (g - 0.50) / 0.50)),
                    side: -1,
                    y: 0.23
                )

                NaturalBranch(
                    progress: max(0, min(1, (g - 0.63) / 0.37)),
                    side: 1,
                    y: 0.17
                )

                NaturalFlower(
                    progress: max(0, min(1, (g - 0.77) / 0.23)),
                    x: 0.60,
                    y: 0.15
                )

                NaturalFlower(
                    progress: max(0, min(1, (g - 0.86) / 0.14)),
                    x: 0.39,
                    y: 0.22
                )
            }
        }
    }
}

private struct NaturalStem: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let x = rect.midX
        let bottom = rect.height * 0.70
        let top = rect.height * (0.24 - 0.08 * progress)

        var path = Path()
        path.move(to: CGPoint(x: x, y: bottom))

        path.addCurve(
            to: CGPoint(
                x: x + rect.width * 0.025 * progress,
                y: top
            ),
            control1: CGPoint(
                x: x - rect.width * 0.06 * progress,
                y: bottom - rect.height * 0.22 * progress
            ),
            control2: CGPoint(
                x: x + rect.width * 0.08 * progress,
                y: bottom - rect.height * 0.48 * progress
            )
        )

        return path
    }
}

private struct NaturalBranch: View {
    let progress: Double
    let side: CGFloat
    let y: CGFloat

    var body: some View {
        GeometryReader { geo in
            let p = min(1, max(0, progress))
            let baseX = geo.size.width / 2
            let baseY = geo.size.height * y
            let length = geo.size.width * 0.16 * p

            let endX = baseX + side * length
            let endY = baseY - geo.size.height * 0.055 * p

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: baseX, y: baseY))
                    path.addCurve(
                        to: CGPoint(x: endX, y: endY),
                        control1: CGPoint(
                            x: baseX + side * length * 0.35,
                            y: baseY - geo.size.height * 0.015
                        ),
                        control2: CGPoint(
                            x: baseX + side * length * 0.72,
                            y: endY + geo.size.height * 0.025
                        )
                    )
                }
                .stroke(
                    Color(red: 0.30, green: 0.19, blue: 0.075),
                    style: StrokeStyle(
                        lineWidth: max(1.1, geo.size.width * 0.007),
                        lineCap: .round
                    )
                )

                NaturalLeaf(
                    progress: p,
                    x: endX,
                    y: endY,
                    angle: side * 28
                )

                NaturalLeaf(
                    progress: max(0, p - 0.16),
                    x: baseX + side * length * 0.52,
                    y: baseY - geo.size.height * 0.025 * p,
                    angle: -side * 42
                )
            }
        }
    }
}

private struct NaturalLeaf: View {
    let progress: Double
    let x: CGFloat
    let y: CGFloat
    let angle: CGFloat

    var body: some View {
        let p = min(1, max(0, progress))
        let size = 7 + 15 * p

        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.38, green: 0.70, blue: 0.22),
                        Color(red: 0.14, green: 0.38, blue: 0.09)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size, height: size * 0.52)
            .rotationEffect(.degrees(Double(angle)))
            .scaleEffect(
                x: 0.08 + 0.92 * p,
                y: 0.08 + 0.92 * p
            )
            .opacity(p)
            .position(x: x, y: y)
    }
}

private struct NaturalFlower: View {
    let progress: Double
    let x: CGFloat
    let y: CGFloat

    var body: some View {
        let p = min(1, max(0, progress))
        let size = 7 + 8 * p

        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(
                        Color(
                            red: 0.84,
                            green: 0.92,
                            blue: 0.55
                        )
                    )
                    .frame(
                        width: size * 0.50,
                        height: size * 0.50
                    )
                    .offset(
                        x: cos(Double(index) * .pi * 2 / 5) * size * 0.24,
                        y: sin(Double(index) * .pi * 2 / 5) * size * 0.24
                    )
            }

            Circle()
                .fill(
                    Color(
                        red: 0.96,
                        green: 0.70,
                        blue: 0.20
                    )
                )
                .frame(
                    width: size * 0.30,
                    height: size * 0.30
                )
        }
        .scaleEffect(p)
        .opacity(p)
        .position(
            x: x * 0 + x * 1,
            y: y * 1
        )
    }
}

// MARK: - Waves

private struct ChargingWaves: View {
    let progress: Double
    let time: TimeInterval
    let active: Bool

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let strength = progress >= 0.999 ? 0.34 : 0.20

            if active {
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        let phase = time * 0.42 + Double(index) * 1.55
                        let pulse = 0.5 + 0.5 * sin(phase)

                        Circle()
                            .stroke(
                                .white.opacity(
                                    strength * (0.45 - Double(index) * 0.09)
                                ),
                                lineWidth: 1.1
                            )
                            .frame(
                                width: size * (0.52 + 0.15 * pulse),
                                height: size * (0.52 + 0.15 * pulse)
                            )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Dust + leaves + twigs + flowers

private struct PlantParticleView: View {
    let progress: Double
    let time: TimeInterval
    let plantFinished: Bool

    private let particles = PlantParticle.all

    var body: some View {
        Canvas { context, size in
            // До 100% растение ещё не существует.
            // Во время роста частицы появляются постепенно.
            let growthFade: Double
            if progress < 0.999 {
                growthFade = 0
            } else if plantFinished {
                growthFade = 1
            } else {
                growthFade = 0.55
            }

            guard growthFade > 0 else { return }

            for particle in particles {
                let cycle = 5.2 + particle.speed
                let phase = (
                    time / cycle + particle.offset
                )
                .truncatingRemainder(dividingBy: 1.0)

                let eased = phase * phase * (3 - 2 * phase)

                let xWave =
                    sin(
                        phase * 2 * .pi +
                        particle.phase
                    ) * particle.drift
                    +
                    sin(
                        phase * 4 * .pi -
                        particle.phase * 0.7
                    ) * particle.drift * 0.28

                let x = size.width * (0.50 + particle.startX) + xWave
                let y = size.height * (1.02 - eased * 0.72)

                let absorption = phase > 0.82
                    ? 1 - (phase - 0.82) / 0.18
                    : 1

                let alpha =
                    growthFade *
                    absorption *
                    particle.opacity

                var particleContext = context
                particleContext.opacity = alpha

                drawParticle(
                    particle,
                    at: CGPoint(x: x, y: y),
                    in: &particleContext
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func drawParticle(
        _ particle: PlantParticle,
        at point: CGPoint,
        in context: inout GraphicsContext
    ) {
        let s = particle.size

        switch particle.kind {
        case .dust:
            let r = max(0.35, s * 0.20)

            context.fill(
                Path(
                    ellipseIn: CGRect(
                        x: point.x - r,
                        y: point.y - r,
                        width: r * 2,
                        height: r * 2
                    )
                ),
                with: .color(.white)
            )

        case .leaf:
            var path = Path()
            path.move(to: CGPoint(x: point.x, y: point.y + s))
            path.addCurve(
                to: CGPoint(
                    x: point.x + s * 0.8,
                    y: point.y - s * 0.35
                ),
                control1: CGPoint(
                    x: point.x + s * 0.05,
                    y: point.y + s * 0.15
                ),
                control2: CGPoint(
                    x: point.x + s * 0.70,
                    y: point.y - s * 0.10
                )
            )
            path.addCurve(
                to: CGPoint(x: point.x, y: point.y + s),
                control1: CGPoint(
                    x: point.x + s * 0.40,
                    y: point.y + s * 0.05
                ),
                control2: CGPoint(
                    x: point.x + s * 0.08,
                    y: point.y + s * 0.55
                )
            )

            context.fill(path, with: .color(particle.color))

        case .flower:
            var path = Path()

            for i in 0..<5 {
                let angle = CGFloat(i) * (.pi * 2 / 5)
                let x = point.x + cos(angle) * s * 0.55
                let y = point.y + sin(angle) * s * 0.55

                path.addEllipse(
                    in: CGRect(
                        x: x - s * 0.22,
                        y: y - s * 0.22,
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

            context.fill(path, with: .color(particle.color))

        case .twig:
            var path = Path()
            path.move(
                to: CGPoint(
                    x: point.x,
                    y: point.y + s
                )
            )
            path.addLine(
                to: CGPoint(
                    x: point.x + s * 0.45,
                    y: point.y - s
                )
            )
            path.move(
                to: CGPoint(
                    x: point.x + s * 0.20,
                    y: point.y + s * 0.15
                )
            )
            path.addLine(
                to: CGPoint(
                    x: point.x + s * 0.65,
                    y: point.y - s * 0.05
                )
            )

            context.stroke(
                path,
                with: .color(particle.color),
                style: StrokeStyle(
                    lineWidth: max(0.7, s * 0.13),
                    lineCap: .round
                )
            )
        }
    }
}

private struct PlantParticle {
    enum Kind {
        case dust
        case leaf
        case flower
        case twig
    }

    let kind: Kind
    let startX: CGFloat
    let speed: Double
    let offset: Double
    let phase: Double
    let drift: CGFloat
    let size: CGFloat
    let opacity: Double
    let color: Color

    static let all: [PlantParticle] = {
        let palette: [Color] = [
            .green,
            .mint,
            .yellow,
            .orange,
            .pink,
            .blue,
            .purple
        ]

        return (0..<82).map { i in
            let seed = Double((i * 37 + 11) % 101) / 101.0

            let kind: Kind = {
                // Большинство — именно мелкая пыль.
                if i < 48 {
                    return .dust
                }

                switch i % 3 {
                case 0: return .leaf
                case 1: return .flower
                default: return .twig
                }
            }()

            let size: CGFloat = kind == .dust
                ? 1.0 + CGFloat(seed) * 2.8
                : 3.5 + CGFloat(seed) * 6.5

            return PlantParticle(
                kind: kind,
                startX: CGFloat(seed - 0.5) * 0.30,
                speed: 0.2 + seed * 1.4,
                offset: seed * 0.97,
                phase: seed * 10.0,
                drift: 5 + CGFloat(seed) * 17,
                size: size,
                opacity: kind == .dust
                    ? 0.08 + seed * 0.42
                    : 0.35 + seed * 0.50,
                color: kind == .twig
                    ? Color(red: 0.30, green: 0.19, blue: 0.075)
                    : palette[i % palette.count]
            )
        }
    }()
}
