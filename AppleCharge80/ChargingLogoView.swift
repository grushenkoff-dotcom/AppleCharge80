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
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let now = context.date
            let disconnectElapsed = disconnectStart.map { now.timeIntervalSince($0) }
            let chargeElapsed = chargeStartDate.map { max(0, now.timeIntervalSince($0)) } ?? 0

            GeometryReader { geo in
                let logoHeight: CGFloat = 181
                let logoWidth = logoHeight * 814.0 / 1000.0
                let logoTop = max(42, geo.size.height * 0.075)
                let visualLogoHeight = logoHeight * 0.60

                ZStack(alignment: .top) {
                    PlantParticleField(
                        progress: progress,
                        isCharging: isCharging,
                        time: chargeElapsed,
                        logoTop: logoTop,
                        logoHeight: visualLogoHeight
                    )
                    .frame(width: geo.size.width, height: geo.size.height)

                    AppleLogoFill(
                        progress: progress,
                        time: chargeElapsed,
                        disconnectElapsed: disconnectElapsed,
                        disconnectOrder: disconnectOrder
                    )
                    .frame(width: logoWidth, height: logoHeight)
                    .scaleEffect(0.60, anchor: .top)
                    .padding(.top, logoTop)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
            .onAppear { updateState(charging: isCharging, now: now) }
            .onChange(of: isCharging) { _, charging in
                updateState(charging: charging, now: now)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    private func updateState(charging: Bool, now: Date) {
        if charging {
            disconnectStart = nil
            disconnectOrder.removeAll(keepingCapacity: true)
            if chargeStartDate == nil {
                chargeStartDate = now
            }
        } else {
            chargeStartDate = nil
            if disconnectStart == nil {
                disconnectStart = now
                disconnectOrder = Array(0..<sectorCount).shuffled()
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
            let p = progress.clamped01
            let sectorProgress = min(1, p / sectorCompletionProgress)
            let scaled = sectorProgress * Double(sectorCount)
            let completed = min(sectorCount, Int(scaled))
            let currentFraction = completed >= sectorCount ? 0 : scaled - Double(completed)
            let leaf = leafProgress
            let alive = p >= 1 && disconnectElapsed == nil

            ZStack {
                ZStack(alignment: .top) {
                    ForEach(0..<sectorCount, id: \.self) { index in
                        let visibility = sectorVisibility(
                            index: index,
                            completed: completed,
                            currentFraction: currentFraction,
                            disconnectElapsed: disconnectElapsed
                        )

                        if visibility > 0.001 {
                            let pulse = heartbeat(time, phase: Double(index) * 0.035)
                            let intensity = 0.94 + 0.10 * pulse

                            Rectangle()
                                .fill(sectorGradient(base: colors[index], index: index, time: time, intensity: intensity))
                                .frame(width: geo.size.width, height: bandHeight + 1)
                                .offset(y: bodyTop + CGFloat(index) * bandHeight)
                                .opacity(visibility)
                        }
                    }
                }
                .clipShape(AppleBodyShape())

                if p > 0.72 && disconnectElapsed == nil {
                    let contact = smoothStep((p - 0.72) / 0.28)
                    let pulse = heartbeat(time, phase: 0)
                    RadialGradient(
                        colors: [
                            Color(red: 0.52, green: 1.0, blue: 0.38)
                                .opacity(0.20 * contact * (0.55 + 0.45 * pulse)),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geo.size.width * 0.055
                    )
                    .frame(width: geo.size.width * 0.16, height: geo.size.height * 0.075)
                    .position(x: geo.size.width * 0.5, y: bodyBottom - 1)
                    .blur(radius: 2.2)
                    .clipShape(AppleBodyShape())
                }

                AppleBodyShape()
                    .stroke(Color.white.opacity(alive ? 0.27 : 0.20), lineWidth: 1.05)
                    .blur(radius: 4.0)
                    .opacity(alive ? 0.85 : 0.65)

                if leaf > 0 {
                    AppleLeafShape()
                        .fill(Color(red: 0.42, green: 0.78, blue: 0.12))
                        .opacity(min(1, leaf * 1.15))
                        .overlay {
                            AppleLeafShape()
                                .fill(Color(red: 0.42, green: 0.78, blue: 0.12))
                                .blur(radius: 4.0)
                                .opacity(0.55 * leaf)
                        }
                        .clipShape(AppleLeafGrowthMask(progress: leaf))
                }
            }
        }
    }

    private func sectorVisibility(index: Int, completed: Int, currentFraction: Double, disconnectElapsed: TimeInterval?) -> Double {
        guard let elapsed = disconnectElapsed else {
            if index < completed { return 1 }
            if index == completed && completed < sectorCount { return smoothStep(currentFraction) }
            return 0
        }

        guard let position = disconnectOrder.firstIndex(of: index) else { return 1 }
        let local = elapsed - Double(position) * sectorStartStep
        if local <= 0 { return 1 }
        if local >= sectorDuration { return 0 }
        return 1 - smoothStep(local / sectorDuration)
    }

    private var leafProgress: Double {
        guard disconnectElapsed == nil, progress >= 0.88 else { return 0 }
        return smoothStep((progress - 0.88) / 0.12)
    }

    private func sectorGradient(base: SectorColor, index: Int, time: TimeInterval, intensity: Double) -> LinearGradient {
        let pulse = heartbeat(time, phase: Double(index) * 0.035)
        let drift = 0.5 + 0.5 * sin(time * 0.72 + Double(index) * 0.85)
        let dark = base.color(multipliedBy: 0.82 + 0.08 * pulse + 0.035 * drift)
        let mid = base.color(multipliedBy: intensity + 0.045 * drift)
        let bright = base.color(multipliedBy: 0.91 + 0.14 * pulse + 0.035 * drift)

        return LinearGradient(
            stops: [
                .init(color: dark, location: 0),
                .init(color: mid, location: 0.32),
                .init(color: bright, location: 0.55),
                .init(color: mid, location: 0.76),
                .init(color: dark, location: 1)
            ],
            startPoint: UnitPoint(x: 0.03 + 0.10 * pulse, y: 0),
            endPoint: UnitPoint(x: 0.87 - 0.08 * pulse, y: 1)
        )
    }

    private func heartbeat(_ time: TimeInterval, phase: Double) -> Double {
        let cycle = (time * 1.08 + phase).truncatingRemainder(dividingBy: 1)
        let first = exp(-pow((cycle - 0.095) / 0.052, 2))
        let second = exp(-pow((cycle - 0.225) / 0.075, 2))
        return min(1, first * 0.95 + second * 0.52)
    }

    private func smoothStep(_ value: Double) -> Double {
        let t = value.clamped01
        return t * t * (3 - 2 * t)
    }
}

// MARK: - Leaf Growth Mask

private struct AppleLeafGrowthMask: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let p = progress.clamped01
        let revealBottom = rect.minY + rect.height * (1 - p)
        var path = Path()
        path.addRect(CGRect(x: rect.minX - 2, y: revealBottom, width: rect.width + 4, height: rect.maxY - revealBottom + 2))
        return path
    }
}

// MARK: - Sector Color

private struct SectorColor {
    let r: Double
    let g: Double
    let b: Double

    func color(multipliedBy factor: Double) -> Color {
        Color(red: min(1, r * factor), green: min(1, g * factor), blue: min(1, b * factor))
    }
}

// MARK: - Energy Flow

private struct PlantParticleField: View {
    let progress: Double
    let isCharging: Bool
    let time: TimeInterval
    let logoTop: CGFloat
    let logoHeight: CGFloat

    private let threadCount = 9
    private let specs: [ThreadSpec] = [
        ThreadSpec(birth: 0.00, offset: -0.05, amplitude: 0.95, frequency: 1.00, speed: 0.88, phase: 0.00),
        ThreadSpec(birth: 0.09, offset:  0.18, amplitude: 0.72, frequency: 1.19, speed: 1.03, phase: 1.43),
        ThreadSpec(birth: 0.18, offset: -0.22, amplitude: 0.86, frequency: 0.83, speed: 0.77, phase: 2.71),
        ThreadSpec(birth: 0.28, offset:  0.34, amplitude: 0.62, frequency: 1.31, speed: 1.12, phase: 3.62),
        ThreadSpec(birth: 0.38, offset: -0.37, amplitude: 0.78, frequency: 0.91, speed: 0.94, phase: 4.41),
        ThreadSpec(birth: 0.48, offset:  0.27, amplitude: 0.66, frequency: 1.42, speed: 1.18, phase: 5.17),
        ThreadSpec(birth: 0.58, offset: -0.30, amplitude: 0.71, frequency: 1.07, speed: 0.82, phase: 0.91),
        ThreadSpec(birth: 0.68, offset:  0.14, amplitude: 0.58, frequency: 1.24, speed: 1.09, phase: 2.08),
        ThreadSpec(birth: 0.76, offset: -0.12, amplitude: 0.54, frequency: 0.97, speed: 0.91, phase: 4.83)
    ]

    var body: some View {
        Canvas { context, size in
            guard isCharging, progress > 0 else { return }
            drawEnergy(in: &context, size: size)
        }
        .allowsHitTesting(false)
    }

    private func drawEnergy(in context: inout GraphicsContext, size: CGSize) {
        let p = progress.clamped01
        let globalTravel = easeOut(min(1, p / 0.88))
        let startY = size.height + 4
        let targetY = logoTop + logoHeight - 1
        let centerX = size.width * 0.5

        // 5–9 mm visual envelope on a modern iPhone, with a hard cap.
        let bundleWidth = min(32, max(22, size.width * 0.070))
        let halfBundle = bundleWidth * 0.5

        for index in 0..<min(threadCount, specs.count) {
            let spec = specs[index]
            guard p >= spec.birth else { continue }

            let local = ((p - spec.birth) / max(0.0001, 0.88 - spec.birth)).clamped01
            let travel = easeOut(local) * globalTravel
            guard travel > 0.001 else { continue }

            drawThread(
                context: &context,
                size: size,
                centerX: centerX,
                startY: startY,
                targetY: targetY,
                halfBundle: halfBundle,
                travel: travel,
                spec: spec,
                time: time,
                index: index
            )
        }

        drawContactGlow(context: &context, centerX: centerX, targetY: targetY, width: bundleWidth, progress: p)
    }

    private func drawThread(
        context: inout GraphicsContext,
        size: CGSize,
        centerX: CGFloat,
        startY: CGFloat,
        targetY: CGFloat,
        halfBundle: CGFloat,
        travel: Double,
        spec: ThreadSpec,
        time: TimeInterval,
        index: Int
    ) {
        let distance = max(1, startY - targetY)
        let steps = 56
        let visibleSteps = max(2, Int(ceil(Double(steps - 1) * travel)) + 1)
        var previous: CGPoint?

        for step in 0..<visibleSteps {
            let u = Double(step) / Double(steps - 1)
            let y = startY - distance * CGFloat(u)
            let envelope = sin(Double.pi * min(1, u))
            let taper = 0.32 + 0.68 * envelope

            let drift = sin(time * spec.speed + spec.phase)
            let wave1 = sin(spec.phase + time * spec.speed + u * Double.pi * 2.2 * spec.frequency)
            let wave2 = sin(spec.phase * 0.61 + time * spec.speed * 0.63 + u * Double.pi * 5.1 * spec.frequency + 1.4)
            let wave3 = sin(spec.phase * 1.37 + time * spec.speed * 0.39 + u * Double.pi * 8.3 + 2.1)
            let organic = 0.54 * wave1 + 0.30 * wave2 + 0.16 * wave3

            let maxOffset = halfBundle * 0.68
            let staticOffset = spec.offset * maxOffset
            let dynamicOffset = maxOffset * 0.78 * spec.amplitude * CGFloat(organic) * CGFloat(taper)

            // The stream remains narrow but bends enough to read as a living stem.
            let merge = smoothStep((u - 0.80) / 0.20)
            let x = centerX + (staticOffset + dynamicOffset) * CGFloat(1 - 0.72 * merge)

            let point = CGPoint(x: x, y: y)
            if let previous {
                let widthPulse = 0.78 + 0.18 * sin(time * 2.2 + spec.phase + Double(step) * 0.11)
                let lineWidth = CGFloat(max(0.65, min(1.35, widthPulse)))
                let headFade = 1 - smoothStep((u - 0.84) / 0.16)
                let alpha = 0.34 + 0.66 * headFade
                let opacity = 0.46 * alpha

                var path = Path()
                path.move(to: previous)
                path.addLine(to: point)

                context.stroke(
                    path,
                    with: .color(Color(red: 0.42, green: 0.92, blue: 0.32).opacity(opacity * 0.15)),
                    style: StrokeStyle(lineWidth: lineWidth * 3.0, lineCap: .round, lineJoin: .round)
                )
                context.stroke(
                    path,
                    with: .color(Color(red: 0.42, green: 0.92, blue: 0.32).opacity(opacity)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
            previous = point
        }

        let headU = min(1, travel)
        let headY = startY - distance * CGFloat(headU)
        let headWave = sin(time * spec.speed * 1.4 + spec.phase)
        let headX = centerX + spec.offset * halfBundle * 0.45 + CGFloat(headWave) * halfBundle * 0.18
        let radius = 1.0 + 0.45 * heartbeat(time, phase: spec.phase)

        context.fill(
            Path(ellipseIn: CGRect(x: headX - radius, y: headY - radius, width: radius * 2, height: radius * 2)),
            with: .color(Color(red: 0.55, green: 1.0, blue: 0.40).opacity(0.28))
        )
    }

    private func drawContactGlow(context: inout GraphicsContext, centerX: CGFloat, targetY: CGFloat, width: CGFloat, progress: Double) {
        let strength = smoothStep((progress - 0.68) / 0.32)
        guard strength > 0 else { return }
        let pulse = heartbeat(time, phase: 0)
        let radius = width * (0.34 + 0.10 * pulse)
        let rect = CGRect(x: centerX - radius, y: targetY - radius * 0.55, width: radius * 2, height: radius * 1.1)

        context.fill(
            Path(ellipseIn: rect),
            with: .color(Color(red: 0.55, green: 1.0, blue: 0.40).opacity(0.08 * strength * (0.7 + 0.3 * pulse)))
        )
    }

    private func heartbeat(_ time: TimeInterval, phase: Double) -> Double {
        let cycle = (time * 1.08 + phase).truncatingRemainder(dividingBy: 1)
        let first = exp(-pow((cycle - 0.095) / 0.052, 2))
        let second = exp(-pow((cycle - 0.225) / 0.075, 2))
        return min(1, first * 0.95 + second * 0.52)
    }

    private func smoothStep(_ value: Double) -> Double {
        let t = value.clamped01
        return t * t * (3 - 2 * t)
    }

    private func easeOut(_ value: Double) -> Double {
        let t = value.clamped01
        return 1 - pow(1 - t, 3)
    }
}

private struct ThreadSpec {
    let birth: Double
    let offset: Double
    let amplitude: Double
    let frequency: Double
    let speed: Double
    let phase: Double
}

private extension Double {
    var clamped01: Double { min(1, max(0, self)) }
}
