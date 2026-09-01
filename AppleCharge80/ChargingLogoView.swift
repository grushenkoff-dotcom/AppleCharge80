import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isCharging)) { context in
            ZStack {
                AppleLogoShape()
                    .stroke(
                        Color.white.opacity(0.20 * outlineProgress),
                        style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round)
                    )
                    .drawingGroup()

                AppleBodyFill(progress: progress, time: context.date.timeIntervalSinceReferenceDate)

                AppleLeafView(
                    progress: progress,
                    outlineProgress: outlineProgress,
                    time: context.date.timeIntervalSinceReferenceDate
                )

                PlantParticleView(
                    progress: progress,
                    time: context.date.timeIntervalSinceReferenceDate
                )
            }
        }
        .aspectRatio(814.0 / 1000.0, contentMode: .fit)
    }
}

private struct AppleBodyFill: View {
    let progress: Double
    let time: TimeInterval

    private let colors: [Color] = [
        Color(red: 0.05, green: 0.42, blue: 0.95), // blue
        Color(red: 0.39, green: 0.18, blue: 0.78), // violet
        Color(red: 0.82, green: 0.05, blue: 0.35), // magenta/red
        Color(red: 0.98, green: 0.22, blue: 0.10), // red-orange
        Color(red: 1.00, green: 0.52, blue: 0.05), // orange
        Color(red: 1.00, green: 0.78, blue: 0.10)  // yellow
    ]

    var body: some View {
        GeometryReader { geo in
            let bodyTop = geo.size.height * 0.241
            let bodyBottom = geo.size.height
            let bodyHeight = bodyBottom - bodyTop
            let bandHeight = bodyHeight / CGFloat(colors.count)
            let scaled = max(0, min(1, progress)) * Double(colors.count)
            let completed = min(colors.count, Int(scaled.rounded(.down)))
            let currentFraction = scaled - Double(completed)

            ZStack(alignment: .topLeading) {
                ForEach(0..<colors.count, id: \.self) { index in
                    let amount: CGFloat =
                        index < completed ? 1.0 :
                        (index == completed ? CGFloat(currentFraction) : 0.0)

                    if amount > 0 {
                        let fillHeight = max(0.5, bandHeight * amount)
                        let bottomY = bodyBottom - CGFloat(index) * bandHeight
                        let centerY = bottomY - fillHeight / 2

                        Rectangle()
                            .fill(colors[index])
                            .frame(width: geo.size.width, height: fillHeight)
                            .position(x: geo.size.width / 2, y: centerY)
                            .clipShape(
                                WaveFillShape(
                                    amplitude: index == completed ? max(3, bandHeight * 0.11) : 0,
                                    phase: time * 0.70 + Double(index) * 1.7
                                )
                            )
                    }
                }
            }
            .mask(AppleBodyShape())
        }
    }
}

private struct WaveFillShape: Shape {
    var amplitude: CGFloat
    var phase: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let samples = 24
        let top = 0.0

        p.move(to: CGPoint(x: 0, y: top))

        for i in 0...samples {
            let x = rect.width * CGFloat(i) / CGFloat(samples)
            let t = Double(i) / Double(samples)
            let wave = amplitude == 0 ? 0 :
                sin(t * .pi * 2.0 * 1.25 + phase) * amplitude +
                sin(t * .pi * 2.0 * 0.63 - phase * 0.57) * amplitude * 0.45
            p.addLine(to: CGPoint(x: x, y: top + wave))
        }

        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}

private struct AppleLeafView: View {
    let progress: Double
    let outlineProgress: Double
    let time: TimeInterval

    var body: some View {
        GeometryReader { geo in
            let leafProgress = max(0, min(1, (progress - 0.78) / 0.22))
            let outlineOpacity = outlineProgress * (1 - leafProgress * 0.9)

            ZStack {
                AppleLeafShape()
                    .stroke(
                        Color.white.opacity(0.20 * outlineOpacity),
                        style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round)
                    )

                if leafProgress > 0 {
                    StemAndLeafMorph(progress: leafProgress, time: time)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct StemAndLeafMorph: View {
    let progress: Double
    let time: TimeInterval

    var body: some View {
        GeometryReader { geo in
            let stem = max(0, min(1, progress / 0.28))
            let leaf = max(0, min(1, (progress - 0.20) / 0.80))

            Path { path in
                let base = CGPoint(x: geo.size.width * 0.56, y: geo.size.height * 0.242)
                let top = CGPoint(
                    x: base.x + geo.size.width * 0.025 * sin(time * 0.8),
                    y: base.y - geo.size.height * 0.055 * stem
                )
                path.move(to: base)
                path.addCurve(
                    to: top,
                    control1: CGPoint(x: base.x - geo.size.width * 0.008, y: base.y - geo.size.height * 0.02),
                    control2: CGPoint(x: top.x - geo.size.width * 0.01, y: top.y + geo.size.height * 0.02)
                )
            }
            .stroke(Color.green.opacity(0.95), style: StrokeStyle(lineWidth: max(1, geo.size.width * 0.018), lineCap: .round))
            .opacity(stem)

            AppleLeafShape()
                .fill(Color.green)
                .scaleEffect(
                    x: 0.08 + 0.92 * leaf,
                    y: 0.08 + 0.92 * leaf,
                    anchor: UnitPoint(x: 0.50, y: 0.23)
                )
                .opacity(leaf)
        }
    }
}

private struct PlantParticleView: View {
    let progress: Double
    let time: TimeInterval

    private let particles = PlantParticle.all

    var body: some View {
        Canvas { context, size in
            let fade = max(0, min(1, (1.0 - progress) / 0.25))

            guard fade > 0.001 else { return }

            for particle in particles {
                let cycle = 5.2 + particle.speed
                let phase = (time / cycle + particle.offset).truncatingRemainder(dividingBy: 1.0)

                // Particles originate near the lower centre of the screen,
                // then rise into the bottom of the logo.
                let eased = phase * phase * (3 - 2 * phase)
                let xWave =
                    sin((phase * 2.0 * .pi) + particle.phase) * particle.drift +
                    sin((phase * 4.0 * .pi) - particle.phase * 0.7) * particle.drift * 0.28

                let x = size.width * (0.50 + particle.startX) + xWave
                let y = size.height * (1.02 - eased * 0.72)

                let absorption = phase > 0.82 ? (1 - (phase - 0.82) / 0.18) : 1
                let alpha = fade * absorption * particle.opacity

                var particleContext = context
                particleContext.opacity = alpha

                drawParticle(
                    particle,
                    at: CGPoint(x: x, y: y),
                    in: &particleContext
                )
            }
        }
    }

    private func drawParticle(
        _ particle: PlantParticle,
        at point: CGPoint,
        in context: inout GraphicsContext
    ) {
        let s = particle.size

        switch particle.kind {
        case .leaf:
            var path = Path()
            path.move(to: CGPoint(x: point.x, y: point.y + s))
            path.addCurve(
                to: CGPoint(x: point.x + s * 0.8, y: point.y - s * 0.35),
                control1: CGPoint(x: point.x + s * 0.05, y: point.y + s * 0.15),
                control2: CGPoint(x: point.x + s * 0.70, y: point.y - s * 0.10)
            )
            path.addCurve(
                to: CGPoint(x: point.x, y: point.y + s),
                control1: CGPoint(x: point.x + s * 0.40, y: point.y + s * 0.05),
                control2: CGPoint(x: point.x + s * 0.08, y: point.y + s * 0.55)
            )
            context.fill(path, with: .color(particle.color))

        case .flower:
            var path = Path()
            for i in 0..<5 {
                let a = CGFloat(i) * (.pi * 2 / 5)
                let x = point.x + cos(a) * s * 0.55
                let y = point.y + sin(a) * s * 0.55
                path.addEllipse(
                    in: CGRect(x: x - s * 0.22, y: y - s * 0.22, width: s * 0.44, height: s * 0.44)
                )
            }
            path.addEllipse(
                in: CGRect(x: point.x - s * 0.18, y: point.y - s * 0.18, width: s * 0.36, height: s * 0.36)
            )
            context.fill(path, with: .color(particle.color))

        case .twig:
            var path = Path()
            path.move(to: CGPoint(x: point.x, y: point.y + s))
            path.addLine(to: CGPoint(x: point.x + s * 0.45, y: point.y - s))
            path.move(to: CGPoint(x: point.x + s * 0.20, y: point.y + s * 0.15))
            path.addLine(to: CGPoint(x: point.x + s * 0.65, y: point.y - s * 0.05))
            context.stroke(
                path,
                with: .color(particle.color),
                style: StrokeStyle(lineWidth: max(0.8, s * 0.13), lineCap: .round)
            )
        }
    }
}

private struct PlantParticle {
    enum Kind {
        case leaf, flower, twig
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

        return (0..<34).map { i in
            let seed = Double((i * 37 + 11) % 101) / 101.0
            let kind: Kind = {
                switch i % 3 {
                case 0: return .leaf
                case 1: return .flower
                default: return .twig
                }
            }()

            return PlantParticle(
                kind: kind,
                startX: CGFloat(seed - 0.5) * 0.30,
                speed: 0.2 + seed * 1.4,
                offset: seed * 0.97,
                phase: seed * 10.0,
                drift: 8 + CGFloat(seed) * 17,
                size: 3.5 + CGFloat(seed) * 6.5,
                opacity: 0.45 + seed * 0.5,
                color: palette[i % palette.count]
            )
        }
    }()
}
