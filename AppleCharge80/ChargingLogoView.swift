import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double // Kept for compatibility; no outline is drawn.
    let isCharging: Bool

    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []

    private let sectorCount = 6
    private let disconnectTotal: TimeInterval = 3.0
    private let sectorDuration: TimeInterval = 0.6
    private let sectorStartStep: TimeInterval = 0.48

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let now = context.date
            let disconnectElapsed = disconnectStart.map { now.timeIntervalSince($0) }
            let logoHeight: CGFloat = 181.0
            let logoWidth: CGFloat = logoHeight * 814.0 / 1000.0

            GeometryReader { geo in
                let logoTopY = geoSafeTop(geo.size.height)
                let logoCenterY = logoTopY + logoHeight * 0.5

                ZStack {
                    // The living stream is deliberately behind the logo.
                    PlantParticleField(
                        progress: clampedProgress,
                        time: now.timeIntervalSinceReferenceDate,
                        active: isCharging && disconnectElapsed == nil,
                        logoWidth: logoWidth,
                        logoHeight: logoHeight,
                        logoTopY: logoTopY
                    )
                    .frame(width: geo.size.width, height: geo.size.height)

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
                    .frame(width: logoWidth, height: logoHeight)
                    .position(x: geo.size.width / 2, y: logoCenterY)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                if !isCharging && disconnectStart == nil {
                    beginDisconnect(at: now)
                }
            }
            .onChange(of: isCharging) { _, charging in
                if charging {
                    disconnectStart = nil
                    disconnectOrder = []
                } else if disconnectStart == nil {
                    beginDisconnect(at: now)
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

// MARK: - Exact Apple logo fill

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
            let completed = min(sectorCount, Int(scaled.rounded(.down)))
            let currentFraction = scaled - Double(completed)
            let leafGrowth = leafProgress

            ZStack(alignment: .topLeading) {
                ForEach(Array(0..<sectorCount), id: \.self) { index in
                    let amount: CGFloat = index < completed
                        ? 1.0
                        : (index == completed
                           ? CGFloat(max(0, min(1, currentFraction)))
                           : 0.0)

                    let opacity = sectorOpacity(index)

                    if amount > 0 && opacity > 0 {
                        let bottomY = bodyBottom - CGFloat(index) * bandHeight
                        let fillHeight = max(0.01, bandHeight * amount)
                        let topY = bottomY - fillHeight
                        let isCurrent = index == completed && completed < sectorCount
                        let shimmer = 0.92 + 0.08 * sin(time * 1.15 + Double(index) * 0.83)
                        let base = colors[index]

                        ZStack {
                            if isCurrent {
                                WavingSectorTop(
                                    width: geo.size.width,
                                    height: fillHeight,
                                    amplitude: min(5.5, max(1.4, bandHeight * 0.11)),
                                    phase: time * 0.75 + Double(index) * 1.37
                                )
                                .fill(sectorGradient(base: base, shimmer: shimmer))
                            } else {
                                Rectangle()
                                    .fill(sectorGradient(base: base, shimmer: shimmer))
                            }
                        }
                        .frame(width: geo.size.width, height: fillHeight)
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
                        anchor: UnitPoint(x: 0.51, y: 0.231)
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
            red: min(1, base.r * (0.86 * shimmer)),
            green: min(1, base.g * (0.86 * shimmer)),
            blue: min(1, base.b * (0.86 * shimmer))
        )
        let mid = Color(
            red: min(1, base.r * (1.05 * shimmer)),
            green: min(1, base.g * (1.05 * shimmer)),
            blue: min(1, base.b * (1.05 * shimmer))
        )
        let high = Color(
            red: min(1, base.r * (0.94 * shimmer)),
            green: min(1, base.g * (0.94 * shimmer)),
            blue: min(1, base.b * (0.94 * shimmer))
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
        let normal = max(0, min(1, (progress - 0.88) / 0.12))
        guard let elapsed = disconnectElapsed else { return normal }
        if elapsed >= 3.0 { return 0 }
        return normal * max(0, 1.0 - elapsed / disconnectTotal)
    }

    private var stemOpacity: Double {
        let p = leafProgress
        return min(1.0, p / 0.20) * max(0, min(1.0, (1.0 - p) / 0.04))
    }

    private func sectorOpacity(_ index: Int) -> Double {
        guard let elapsed = disconnectElapsed else { return 1.0 }
        if elapsed >= disconnectTotal { return 0.0 }

        guard let position = disconnectOrder.firstIndex(of: index) else { return 1.0 }
        let start = Double(position) * sectorStartStep
        let end = start + sectorDuration

        if elapsed <= start { return 1.0 }
        if elapsed >= end { return 0.0 }

        let t = (elapsed - start) / sectorDuration
        if t <= 0.8 {
            let u = t / 0.8
            let eased = u * u * (3.0 - 2.0 * u)
            return 1.0 + (0.20 - 1.0) * eased
        } else {
            let u = (t - 0.8) / 0.2
            let eased = u * u * (3.0 - 2.0 * u)
            return 0.20 * (1.0 - eased)
        }
    }
}

// Only the top edge of the current sector moves.
private struct WavingSectorTop: Shape {
    let width: CGFloat
    let height: CGFloat
    let amplitude: CGFloat
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let a = min(amplitude, max(0.8, height * 0.20))
        let y = rect.minY
        let x0 = rect.minX
        let x1 = rect.maxX
        let third = rect.width / 3.0

        path.move(to: CGPoint(x: x0, y: y + CGFloat(sin(phase)) * a * 0.35))

        path.addCurve(
            to: CGPoint(x: x0 + third, y: y + CGFloat(sin(phase + 1.9)) * a),
            control1: CGPoint(x: x0 + third * 0.28, y: y + CGFloat(sin(phase + 0.7)) * a * 0.55),
            control2: CGPoint(x: x0 + third * 0.72, y: y + CGFloat(sin(phase + 1.35)) * a * 1.15)
        )

        path.addCurve(
            to: CGPoint(x: x0 + third * 2, y: y + CGFloat(sin(phase + 3.2)) * a * 0.72),
            control1: CGPoint(x: x0 + third * 1.28, y: y + CGFloat(sin(phase + 2.35)) * a * 1.05),
            control2: CGPoint(x: x0 + third * 1.72, y: y + CGFloat(sin(phase + 2.8)) * a * 0.35)
        )

        path.addCurve(
            to: CGPoint(x: x1, y: y + CGFloat(sin(phase + 4.8)) * a * 0.35),
            control1: CGPoint(x: x0 + third * 2.28, y: y + CGFloat(sin(phase + 3.8)) * a * 0.90),
            control2: CGPoint(x: x0 + third * 2.70, y: y + CGFloat(sin(phase + 4.35)) * a * 0.55)
        )

        path.addLine(to: CGPoint(x: x1, y: rect.maxY))
        path.addLine(to: CGPoint(x: x0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct LeafBudStem: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let x = w * 0.515
            let baseY = h * 0.245
            let topY = baseY - h * 0.045 * progress

            Path { path in
                path.move(to: CGPoint(x: x, y: baseY))
                path.addCurve(
                    to: CGPoint(x: x + w * 0.025, y: topY),
                    control1: CGPoint(x: x - w * 0.01, y: baseY - h * 0.018),
                    control2: CGPoint(x: x + w * 0.018, y: topY + h * 0.012)
                )
            }
            .stroke(
                Color(red: 0.42, green: 0.78, blue: 0.12),
                style: StrokeStyle(lineWidth: max(1.0, w * 0.018), lineCap: .round)
            )
        }
    }
}

// MARK: - Vertical living plant stream

private struct PlantParticleField: View {
    let progress: Double
    let time: TimeInterval
    let active: Bool
    let logoWidth: CGFloat
    let logoHeight: CGFloat
    let logoTopY: CGFloat

    // 42 coherent fluid currents. Each current is rendered in 7 soft layers
    // so the field is dense without becoming hundreds of worm-like lines.
    private let particles: [PlantParticle] = PlantParticle.make222()

    var body: some View {
        Canvas { context, size in
            guard active && progress > 0.0 && progress < 1.0 else { return }

            let logoBottomY = logoTopY + logoHeight
            let bottomY = size.height + 30.0
            let topY = logoBottomY
            let travelHeight = max(1.0, bottomY - topY)

            // The currents occupy only the space BELOW the Apple. They never
            // enter the logo and never exist above its lower boundary.
            let streamParticles = particles.filter { $0.kind == .stream }
            let cargoParticles = particles.filter { $0.kind != .stream }

            for particle in streamParticles {
                drawFluidCurrent(
                    &context,
                    particle: particle,
                    size: size,
                    centerX: size.width * 0.5,
                    topY: topY,
                    bottomY: bottomY,
                    travelHeight: travelHeight,
                    time: time
                )
            }

            for particle in cargoParticles {
                drawCargo(
                    &context,
                    particle: particle,
                    size: size,
                    centerX: size.width * 0.5,
                    topY: topY,
                    bottomY: bottomY,
                    travelHeight: travelHeight,
                    logoWidth: logoWidth,
                    time: time
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func streamState(
        _ particle: PlantParticle,
        time: TimeInterval,
        topY: CGFloat,
        bottomY: CGFloat,
        travelHeight: CGFloat,
        centerX: CGFloat,
        size: CGSize
    ) -> (x: CGFloat, headY: CGFloat, length: CGFloat, phase: Double) {
        let cycle = 5.4
        let raw = (time / cycle + particle.phase).truncatingRemainder(dividingBy: 1.0)
        let t = raw < 0 ? raw + 1.0 : raw
        let distance = t * travelHeight
        let headY = bottomY - distance

        let laneX = centerX + particle.startX * size.width * 0.24
        let sway = CGFloat(
            sin(time * particle.flowSpeed + particle.seed) * 0.75
            + sin(time * 0.39 + particle.seed * 1.73) * 0.25
        ) * particle.drift

        return (laneX + sway, headY, max(150.0, particle.length * 5.0), t)
    }

    private func drawFluidCurrent(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        size: CGSize,
        centerX: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        travelHeight: CGFloat,
        time: TimeInterval
    ) {
        let state = streamState(
            particle,
            time: time,
            topY: topY,
            bottomY: bottomY,
            travelHeight: travelHeight,
            centerX: centerX,
            size: size
        )

        let top = max(topY, state.headY - state.length)
        let bottom = min(bottomY, state.headY)
        guard bottom - top > 3 else { return }

        let span = bottom - top
        let baseWidth = max(2.0, particle.scale * 2.2)
        let distanceFromLogo = top - topY
        let absorption = max(0.0, min(1.0, distanceFromLogo / 28.0))
        let alpha = particle.opacity
            * (0.72 + 0.28 * sin(time * particle.flickerSpeed + particle.seed))
            * absorption

        // Seven close, soft layers = a single thick fluid/gas current rather
        // than seven separate filaments. Their paths share the same flow.
        for layer in 0..<7 {
            let f = CGFloat(layer - 3) / 3.0
            let offset = f * baseWidth * 1.15
            let bend = 7.0 + CGFloat(layer % 3) * 2.0

            var path = Path()
            path.move(to: CGPoint(x: state.x + offset, y: bottom))
            path.addCurve(
                to: CGPoint(x: state.x + offset * 0.45, y: top),
                control1: CGPoint(
                    x: state.x + offset + CGFloat(sin(time * 0.55 + particle.seed + Double(layer))) * bend,
                    y: bottom - span * 0.30
                ),
                control2: CGPoint(
                    x: state.x + offset * 0.20 + CGFloat(sin(time * 0.43 + particle.seed * 1.7 + Double(layer))) * bend,
                    y: top + span * 0.30
                )
            )

            context.opacity = max(0.008, alpha * (0.075 - Double(abs(layer - 3)) * 0.006))
            context.stroke(
                path,
                with: .color(Color(red: 0.20, green: 0.84, blue: 0.25)),
                style: StrokeStyle(
                    lineWidth: baseWidth * (2.8 - CGFloat(abs(layer - 3)) * 0.25),
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }

        // A broad translucent body unifies the seven layers into gas/liquid.
        var body = Path()
        body.move(to: CGPoint(x: state.x, y: bottom))
        body.addCurve(
            to: CGPoint(x: state.x - 1.0, y: top),
            control1: CGPoint(x: state.x + 9.0, y: bottom - span * 0.34),
            control2: CGPoint(x: state.x - 8.0, y: top + span * 0.32)
        )
        context.opacity = alpha * 0.075
        context.stroke(
            body,
            with: .color(Color(red: 0.35, green: 0.96, blue: 0.32)),
            style: StrokeStyle(lineWidth: baseWidth * 7.0, lineCap: .round)
        )
    }

    private func drawCargo(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        size: CGSize,
        centerX: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        travelHeight: CGFloat,
        logoWidth: CGFloat,
        time: TimeInterval
    ) {
        // Every flower/leaf is assigned to one of the 42 actual currents.
        // It inherits that current's phase, speed and lane. This is the key
        // rule that prevents horizontal swarming at the Apple boundary.
        let streamIndex: Int
        switch particle.kind {
        case .flower:
            streamIndex = particle.boundStream
        case .leaf:
            streamIndex = particle.boundStream
        case .pollen:
            streamIndex = particle.boundStream
        case .stream:
            return
        }

        let streams = particles.filter { $0.kind == .stream }
        guard !streams.isEmpty else { return }
        let stream = streams[streamIndex % streams.count]
        let state = streamState(
            stream,
            time: time,
            topY: topY,
            bottomY: bottomY,
            travelHeight: travelHeight,
            centerX: centerX,
            size: size
        )

        // Cargo sits at a fixed position inside the moving current. The
        // current therefore carries it upward instead of merely passing by.
        let relative = particle.cargoOffset
        var x = state.x + CGFloat(sin(time * 0.55 + particle.seed)) * particle.drift
        var y = state.headY - state.length * relative

        // Only the final approach is attracted to the exact Apple boundary.
        // Until then, the cargo follows its current without a sideways target.
        let distanceToLogo = y - topY
        if distanceToLogo < 80.0 {
            let q = max(0.0, min(1.0, 1.0 - distanceToLogo / 80.0))
            let ease = q * q * (3.0 - 2.0 * q)
            let targetX = centerX + particle.targetX * logoWidth * 0.22
            x += (targetX - x) * ease
            y = topY + max(0.0, distanceToLogo) * (1.0 - ease)
        }

        // Never render cargo above the Apple boundary.
        guard y >= topY else { return }

        let fade = max(0.0, min(1.0, (y - topY) / 22.0))
        context.opacity = particle.opacity * (0.25 + 0.75 * fade)

        switch particle.kind {
        case .flower:
            drawFlower(
                &context,
                particle: particle,
                at: CGPoint(x: x, y: y),
                scale: particle.scale,
                time: time
            )
        case .leaf:
            drawLeaf(
                &context,
                particle: particle,
                at: CGPoint(x: x, y: y),
                scale: particle.scale,
                time: time
            )
        case .pollen:
            drawPollen(
                &context,
                particle: particle,
                at: CGPoint(x: x, y: y),
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
        let angle = CGFloat(time * particle.rotationSpeed + particle.rotationPhase + sin(time * 0.31 + particle.seed) * 0.22)
        let w = 8.0 * scale
        let h = 14.0 * scale

        var leaf = Path()
        leaf.move(to: CGPoint(x: point.x, y: point.y - h * 0.5))
        leaf.addCurve(
            to: CGPoint(x: point.x + w * 0.52, y: point.y + h * 0.36),
            control1: CGPoint(x: point.x + w * 0.72, y: point.y - h * 0.28),
            control2: CGPoint(x: point.x + w * 0.75, y: point.y + h * 0.22)
        )
        leaf.addCurve(
            to: CGPoint(x: point.x, y: point.y - h * 0.5),
            control1: CGPoint(x: point.x - w * 0.16, y: point.y + h * 0.24),
            control2: CGPoint(x: point.x - w * 0.30, y: point.y - h * 0.10)
        )
        leaf.closeSubpath()

        context.drawLayer { layer in
            layer.translateBy(x: point.x, y: point.y)
            layer.rotate(by: Angle(radians: Double(angle)))
            layer.translateBy(x: -point.x, y: -point.y)
            layer.fill(leaf, with: .color(Color(red: 0.42, green: 0.78, blue: 0.12)))
        }
    }

    private func drawPollen(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        at point: CGPoint,
        scale: CGFloat,
        time: TimeInterval
    ) {
        let pulse = 0.65 + 0.35 * sin(time * particle.flickerSpeed + particle.seed)
        let radius = max(0.45, 1.25 * scale * pulse)
        let outerRadius = radius * 2.1

        context.opacity *= 0.22
        context.fill(
            Path(ellipseIn: CGRect(x: point.x - outerRadius, y: point.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)),
            with: .color(Color(red: 0.30, green: 0.92, blue: 0.25))
        )
        context.opacity *= 3.8
        context.fill(
            Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(Color(red: 0.60, green: 1.0, blue: 0.42))
        )
    }

    private func drawFlower(
        _ context: inout GraphicsContext,
        particle: PlantParticle,
        at point: CGPoint,
        scale: CGFloat,
        time: TimeInterval
    ) {
        let angle = CGFloat(time * particle.rotationSpeed + particle.rotationPhase + sin(time * 0.27 + particle.seed) * 0.35)
        let petalRadius = max(1.15, 3.0 * scale)
        let flowerRadius = petalRadius * 1.45
        var flower = Path()

        for i in 0..<5 {
            let a = CGFloat(i) * .pi * 2.0 / 5.0 + angle
            let cx = point.x + cos(a) * flowerRadius
            let cy = point.y + sin(a) * flowerRadius
            flower.addEllipse(in: CGRect(x: cx - petalRadius, y: cy - petalRadius * 0.82, width: petalRadius * 2, height: petalRadius * 1.64))
        }

        let centerRadius = petalRadius * 0.70
        flower.addEllipse(in: CGRect(x: point.x - centerRadius, y: point.y - centerRadius, width: centerRadius * 2, height: centerRadius * 2))

        let flowerColor: Color = particle.flowerPink
            ? Color(red: 1.0, green: 0.58, blue: 0.72)
            : Color(red: 1.0, green: 0.96, blue: 0.98)
        context.fill(flower, with: .color(flowerColor))

        context.fill(
            Path(ellipseIn: CGRect(x: point.x - centerRadius * 0.38, y: point.y - centerRadius * 0.38, width: centerRadius * 0.76, height: centerRadius * 0.76)),
            with: .color(particle.flowerPink ? Color(red: 0.98, green: 0.76, blue: 0.30) : Color(red: 1.0, green: 0.82, blue: 0.46))
        )
    }
}
private struct PlantParticle {
    enum Kind { case stream, leaf, flower, pollen }

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

    static func make222() -> [PlantParticle] {
        var result: [PlantParticle] = []
        result.reserveCapacity(294)

        for i in 0..<42 {
            result.append(PlantParticle(
                kind: .stream,
                phase: fract(Double(i) * 0.6180339887),
                startX: signedUnit(i * 17 + 3),
                targetX: signedUnit(i * 11 + 7) * 0.80,
                drift: CGFloat(3.0 + Double(i % 7)),
                opacity: 0.48 + Double(i % 7) * 0.025,
                scale: CGFloat(0.85 + Double(i % 5) * 0.10),
                length: CGFloat(30 + i % 28),
                seed: Double(i) * 1.17,
                flowSpeed: 0.42 + Double(i % 5) * 0.055,
                flickerSpeed: 1.0 + Double(i % 4) * 0.18,
                rotationSpeed: 0,
                rotationPhase: 0,
                flowerPink: false,
                boundStream: i,
                cargoOffset: 0
            ))
        }

        for i in 0..<70 {
            let stream = (i * 7 + 11) % 42
            let streamParticle = result[stream]
            result.append(PlantParticle(
                kind: .flower,
                phase: streamParticle.phase,
                startX: streamParticle.startX,
                targetX: streamParticle.targetX,
                drift: CGFloat(1.5 + Double(i % 5)),
                opacity: 0.26 + Double(i % 6) * 0.035,
                scale: CGFloat(0.46 + Double(i % 5) * 0.13),
                length: 0,
                seed: streamParticle.seed + Double(i) * 0.13,
                flowSpeed: streamParticle.flowSpeed,
                flickerSpeed: 0.60 + Double(i % 4) * 0.12,
                rotationSpeed: 0.12 + Double(i % 7) * 0.025,
                rotationPhase: Double(i % 11) * 0.57,
                flowerPink: i % 3 != 0,
                boundStream: stream,
                cargoOffset: CGFloat(0.20 + Double(i % 7) * 0.105)
            ))
        }

        for i in 0..<72 {
            let stream = (i * 11 + 5) % 42
            let streamParticle = result[stream]
            result.append(PlantParticle(
                kind: .leaf,
                phase: streamParticle.phase,
                startX: streamParticle.startX,
                targetX: streamParticle.targetX,
                drift: CGFloat(1.4 + Double(i % 5)),
                opacity: 0.22 + Double(i % 6) * 0.03,
                scale: CGFloat(0.45 + Double(i % 5) * 0.11),
                length: 0,
                seed: streamParticle.seed + Double(i) * 0.21 + 33,
                flowSpeed: streamParticle.flowSpeed,
                flickerSpeed: 0.8,
                rotationSpeed: 0.10 + Double(i % 6) * 0.02,
                rotationPhase: Double(i % 9) * 0.61,
                flowerPink: false,
                boundStream: stream,
                cargoOffset: CGFloat(0.27 + Double(i % 6) * 0.10)
            ))
        }

        for i in 0..<110 {
            let stream = (i * 13 + 3) % 42
            let streamParticle = result[stream]
            result.append(PlantParticle(
                kind: .pollen,
                phase: streamParticle.phase,
                startX: streamParticle.startX,
                targetX: streamParticle.targetX,
                drift: CGFloat(1.0 + Double(i % 5)),
                opacity: 0.13 + Double(i % 6) * 0.028,
                scale: CGFloat(0.45 + Double(i % 5) * 0.14),
                length: 0,
                seed: streamParticle.seed + Double(i) * 0.31 + 70,
                flowSpeed: streamParticle.flowSpeed,
                flickerSpeed: 1.6 + Double(i % 6) * 0.22,
                rotationSpeed: 0,
                rotationPhase: 0,
                flowerPink: false,
                boundStream: stream,
                cargoOffset: CGFloat(0.12 + Double(i % 8) * 0.11)
            ))
        }
        return result
    }

    private static func fract(_ x: Double) -> Double { x - floor(x) }

    private static func signedUnit(_ x: Int) -> CGFloat {
        let v = sin(Double(x) * 12.9898) * 43758.5453
        return CGFloat((v - floor(v)) * 2.0 - 1.0)
    }
}
