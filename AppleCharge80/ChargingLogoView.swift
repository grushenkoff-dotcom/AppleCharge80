import SwiftUI
import UIKit

/// Полноэкранный слой анимации зарядки.
/// Внешний ContentView больше не ограничивает этот View рамкой логотипа:
/// благодаря этому поток частиц действительно идёт от нижнего края экрана.
struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double   // оставлен для совместимости с ContentView
    let isCharging: Bool

    @State private var logoOpacity: Double = 0

    private let sectorColors: [Color] = [
        Color(red: 0.05, green: 0.42, blue: 0.95),
        Color(red: 0.39, green: 0.18, blue: 0.78),
        Color(red: 0.82, green: 0.05, blue: 0.35),
        Color(red: 0.98, green: 0.22, blue: 0.10),
        Color(red: 1.00, green: 0.52, blue: 0.05),
        Color(red: 1.00, green: 0.78, blue: 0.10)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { geo in
                let logoWidth = min(geo.size.width * 0.41, 180)
                let logoHeight = logoWidth * 1000.0 / 814.0
                let logoCenterX = geo.size.width / 2
                let logoCenterY = geo.size.height * 0.29
                let logoTop = logoCenterY - logoHeight / 2

                ZStack {
                    if isCharging && progress < 1.0 {
                        FormationParticles(
                            progress: progress,
                            time: time,
                            logoFrame: CGRect(
                                x: logoCenterX - logoWidth / 2,
                                y: logoTop,
                                width: logoWidth,
                                height: logoHeight
                            ),
                            colors: sectorColors
                        )
                        .opacity(logoOpacity)
                    }

                    LogoArtwork(
                        progress: progress,
                        time: time,
                        finished: progress >= 0.999,
                        colors: sectorColors
                    )
                    .frame(width: logoWidth, height: logoHeight)
                    .position(x: logoCenterX, y: logoCenterY)
                    .opacity(logoOpacity)
                }
            }
            .ignoresSafeArea()
            .onChange(of: isCharging) { _, charging in
                withAnimation(.easeInOut(duration: charging ? 0.55 : 0.85)) {
                    logoOpacity = charging ? 1 : 0
                }
            }
            .onAppear {
                logoOpacity = isCharging ? 1 : 0
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct LogoArtwork: View {
    let progress: Double
    let time: TimeInterval
    let finished: Bool
    let colors: [Color]

    var body: some View {
        GeometryReader { geo in
            let p = min(max(progress, 0), 1)
            let bodyHeight = geo.size.height * 0.759
            let bodyTop = geo.size.height * 0.241
            let bandHeight = bodyHeight / CGFloat(colors.count)

            ZStack {
                SequentialBodyFill(
                    progress: p,
                    time: time,
                    colors: colors
                )

                // Верхний лист появляется только в самом конце.
                AppleLeafShape()
                    .fill(
                        leafColor(time: time, finished: finished)
                    )
                    .mask(
                        Rectangle()
                            .frame(
                                width: geo.size.width,
                                height: geo.size.height * leafReveal(p)
                            )
                            .offset(y: -geo.size.height * (1 - leafReveal(p)) * 0.15)
                    )

                // Никаких белых контуров/бликов.
                Color.clear
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .overlay(alignment: .top) {
                Color.clear
                    .frame(height: bodyTop + bandHeight * 0)
            }
        }
    }

    private func leafReveal(_ p: Double) -> CGFloat {
        CGFloat(smoothStep((p - 0.94) / 0.06))
    }

    private func leafColor(time: TimeInterval, finished: Bool) -> Color {
        let base = Color(red: 1.00, green: 0.78, blue: 0.10)
        guard finished else { return base }

        // Очень слабое цветовое дыхание, без белого блика.
        let s = 0.5 + 0.5 * sin(time * 0.20)
        return base.mix(
            with: Color(red: 1.00, green: 0.62, blue: 0.03),
            by: 0.06 + s * 0.05
        )
    }
}

private struct SequentialBodyFill: View {
    let progress: Double
    let time: TimeInterval
    let colors: [Color]

    var body: some View {
        GeometryReader { geo in
            let bodyTop = geo.size.height * 0.241
            let bodyBottom = geo.size.height
            let bodyHeight = bodyBottom - bodyTop
            let bandHeight = bodyHeight / CGFloat(colors.count)
            let scaled = progress * Double(colors.count)
            let completed = min(colors.count, Int(floor(scaled)))
            let current = min(1, max(0, scaled - Double(completed)))

            ZStack {
                ForEach(0..<colors.count, id: \.self) { index in
                    let amount: CGFloat = index < completed
                        ? 1
                        : (index == completed ? CGFloat(current) : 0)

                    if amount > 0 {
                        AnimatedSector(
                            index: index,
                            amount: amount,
                            bandHeight: bandHeight,
                            bodyBottom: bodyBottom,
                            time: time,
                            color: colors[index],
                            isCurrent: index == completed && completed < colors.count,
                            finished: progress >= 0.999
                        )
                    }
                }
            }
            .mask(AppleBodyShape())
        }
    }
}

private struct AnimatedSector: View {
    let index: Int
    let amount: CGFloat
    let bandHeight: CGFloat
    let bodyBottom: CGFloat
    let time: TimeInterval
    let color: Color
    let isCurrent: Bool
    let finished: Bool

    var body: some View {
        let fillHeight = max(0.5, bandHeight * amount)
        let sectorBottom = bodyBottom - CGFloat(index) * bandHeight
        let baseTop = sectorBottom - fillHeight

        // Именно текущая граница получает заметное, но мягкое движение.
        // Уже заполненные полосы почти не двигаются.
        let motion = finished ? 0 : (isCurrent ? 1.0 : 0.16)
        let waveAmplitude = bandHeight * 0.115 * motion
        let phase = time * (1.05 + Double(index) * 0.035) + Double(index) * 1.37
        let drift = sin(time * 0.72 + Double(index) * 1.91) * bandHeight * 0.045 * motion

        WaveSectorShape(
            top: baseTop + drift,
            bottom: sectorBottom,
            amplitude: waveAmplitude,
            phase: phase
        )
        .fill(animatedColor)
        .clipped()
    }

    private var animatedColor: Color {
        guard finished else { return color }

        let s = 0.5 + 0.5 * sin(time * 0.18 + Double(index) * 0.71)
        let neighbour = Color(
            hue: min(1, 0.58 + Double(index) * 0.035),
            saturation: 0.92,
            brightness: 0.96
        )
        return color.mix(with: neighbour, by: 0.025 + s * 0.025)
    }
}

private struct WaveSectorShape: Shape {
    let top: CGFloat
    let bottom: CGFloat
    let amplitude: CGFloat
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let samples = 28

        func wave(_ x: CGFloat) -> CGFloat {
            guard amplitude > 0 else { return 0 }
            let t = Double(x / max(rect.width, 1))
            return CGFloat(
                sin(t * .pi * 2.0 * 1.15 + phase) * Double(amplitude)
                + sin(t * .pi * 2.0 * 0.52 - phase * 0.61) * Double(amplitude * 0.42)
            )
        }

        path.move(to: CGPoint(x: 0, y: top + wave(0)))

        for i in 1...samples {
            let x = rect.width * CGFloat(i) / CGFloat(samples)
            path.addLine(to: CGPoint(x: x, y: top + wave(x)))
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: bottom + 2))
        path.addLine(to: CGPoint(x: 0, y: bottom + 2))
        path.closeSubpath()
        return path
    }
}

private struct FormationParticles: View {
    let progress: Double
    let time: TimeInterval
    let logoFrame: CGRect
    let colors: [Color]

    private let particles = Particle.all

    var body: some View {
        Canvas { context, size in
            let p = min(max(progress, 0), 1)
            let streamFade = 1 - smoothStep((p - 0.94) / 0.06)
            guard streamFade > 0 else { return }

            let sectorCount = colors.count
            let scaled = p * Double(sectorCount)
            let currentSector = min(sectorCount - 1, Int(floor(scaled)))
            let sectorFraction = min(1, max(0, scaled - Double(currentSector)))
            let bandHeight = (logoFrame.height * 0.759) / CGFloat(sectorCount)
            let bodyBottom = logoFrame.maxY
            let targetBottom = bodyBottom - CGFloat(currentSector) * bandHeight
            let targetBaseY = targetBottom - sectorFraction * bandHeight * 0.78

            for particle in particles {
                let cycle = 1.65 + particle.duration
                let phase = (time / cycle + particle.offset).truncatingRemainder(dividingBy: 1)
                let travel = smoothStep(phase)

                let startX = size.width * 0.5 + particle.startOffset
                let targetSpread = logoFrame.width * (0.18 - CGFloat(currentSector) * 0.008)
                let targetX = logoFrame.midX + targetSpread * CGFloat(particle.targetOffset)

                let xLinear = startX + (targetX - startX) * CGFloat(travel)
                let sway = sin(
                    time * 2.15 + particle.phase + phase * .pi * 2
                ) * particle.drift * (1 - CGFloat(travel) * 0.55)
                let x = xLinear + sway

                let y = size.height + 12
                    + (targetBaseY - (size.height + 12)) * CGFloat(travel)
                    + sin(time * 1.35 + particle.phase) * 3.0

                let absorption = phase > 0.80
                    ? 1 - smoothStep((phase - 0.80) / 0.20)
                    : 1

                var particleContext = context
                particleContext.opacity = particle.opacity * absorption * streamFade

                draw(
                    particle,
                    at: CGPoint(x: x, y: y),
                    in: &particleContext
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private func draw(
        _ particle: Particle,
        at point: CGPoint,
        in context: inout GraphicsContext
    ) {
        let s = particle.size

        switch particle.kind {
        case .leaf:
            var path = Path()
            path.move(to: CGPoint(x: point.x, y: point.y + s * 0.75))
            path.addCurve(
                to: CGPoint(x: point.x + s * 0.75, y: point.y - s * 0.30),
                control1: CGPoint(x: point.x + s * 0.10, y: point.y + s * 0.15),
                control2: CGPoint(x: point.x + s * 0.62, y: point.y - s * 0.08)
            )
            path.addCurve(
                to: CGPoint(x: point.x, y: point.y + s * 0.75),
                control1: CGPoint(x: point.x + s * 0.43, y: point.y + s * 0.02),
                control2: CGPoint(x: point.x + s * 0.10, y: point.y + s * 0.48)
            )
            context.fill(path, with: .color(particle.color))

        case .flower:
            var path = Path()
            for i in 0..<5 {
                let angle = CGFloat(i) * (.pi * 2 / 5)
                let cx = point.x + cos(angle) * s * 0.46
                let cy = point.y + sin(angle) * s * 0.46
                path.addEllipse(
                    in: CGRect(
                        x: cx - s * 0.19,
                        y: cy - s * 0.19,
                        width: s * 0.38,
                        height: s * 0.38
                    )
                )
            }
            path.addEllipse(
                in: CGRect(
                    x: point.x - s * 0.17,
                    y: point.y - s * 0.17,
                    width: s * 0.34,
                    height: s * 0.34
                )
            )
            context.fill(path, with: .color(particle.color))
        }
    }
}

private struct Particle {
    enum Kind {
        case leaf
        case flower
    }

    let kind: Kind
    let startOffset: CGFloat
    let targetOffset: CGFloat
    let duration: Double
    let offset: Double
    let phase: Double
    let drift: CGFloat
    let size: CGFloat
    let opacity: Double
    let color: Color

    static let all: [Particle] = {
        let palette: [Color] = [
            Color(red: 0.15, green: 0.75, blue: 0.95),
            Color(red: 0.52, green: 0.32, blue: 0.95),
            Color(red: 0.95, green: 0.25, blue: 0.48),
            Color(red: 1.00, green: 0.42, blue: 0.12),
            Color(red: 1.00, green: 0.76, blue: 0.16)
        ]

        return (0..<44).map { i in
            let seed = Double((i * 37 + 11) % 101) / 101.0
            let kind: Kind = i % 4 == 0 ? .flower : .leaf

            return Particle(
                kind: kind,
                startOffset: CGFloat(seed - 0.5) * 34,
                targetOffset: CGFloat(((i * 29 + 7) % 101)) / 50.5 - 1,
                duration: 0.05 + seed * 0.75,
                offset: Double(i) / 44.0,
                phase: seed * 12.0,
                drift: 5 + CGFloat(seed) * 11,
                size: 3.4 + CGFloat(seed) * 3.6,
                opacity: 0.42 + seed * 0.34,
                color: palette[i % palette.count]
            )
        }
    }()
}

private func smoothStep(_ value: Double) -> Double {
    let x = min(1, max(0, value))
    return x * x * (3 - 2 * x)
}

private extension Color {
    func mix(with other: Color, by amount: Double) -> Color {
        let t = min(1, max(0, amount))
        let c1 = UIColor(self)
        let c2 = UIColor(other)

        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return Color(
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t),
            opacity: Double(a1 + (a2 - a1) * t)
        )
    }
}
