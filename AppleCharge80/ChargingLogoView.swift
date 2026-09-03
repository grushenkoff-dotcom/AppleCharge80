import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []
    @State private var chargeStart: Date?

    private let sectorCount = 6
    private let disconnectTotal: TimeInterval = 3.0
    private let sectorFadeDuration: TimeInterval = 0.60
    private let sectorFadeStep: TimeInterval = 0.48

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let now = timeline.date
            let elapsed = chargeStart.map { now.timeIntervalSince($0) } ?? 0
            let disconnectElapsed = disconnectStart.map { now.timeIntervalSince($0) }

            GeometryReader { geo in
                let logoHeight: CGFloat = 181
                let logoWidth = logoHeight * 814 / 1000
                let logoTop = max(42, geo.size.height * 0.075)

                ZStack(alignment: .top) {
                    EnergyStream(
                        progress: clampedProgress,
                        time: elapsed,
                        active: isCharging && disconnectElapsed == nil,
                        logoBottomY: logoTop + logoHeight,
                        logoWidth: logoWidth
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    AppleLogoArtwork(
                        progress: clampedProgress,
                        time: elapsed,
                        disconnectElapsed: disconnectElapsed,
                        disconnectOrder: disconnectOrder,
                        outlineProgress: outlineProgress
                    )
                    .frame(width: logoWidth, height: logoHeight)
                    .padding(.top, logoTop)
                }
            }
            .onAppear { syncState(charging: isCharging, now: now) }
            .onChange(of: isCharging) { _, charging in
                syncState(charging: charging, now: now)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    private var clampedProgress: Double {
        min(1, max(0, progress))
    }

    private func syncState(charging: Bool, now: Date) {
        if charging {
            disconnectStart = nil
            disconnectOrder.removeAll(keepingCapacity: true)
            if chargeStart == nil { chargeStart = now }
        } else {
            chargeStart = nil
            if disconnectStart == nil {
                disconnectOrder = Array(0..<sectorCount).shuffled()
                disconnectStart = now
            }
        }
    }
}

// MARK: - Logo

private struct AppleLogoArtwork: View {
    let progress: Double
    let time: TimeInterval
    let disconnectElapsed: TimeInterval?
    let disconnectOrder: [Int]
    let outlineProgress: Double

    private let sectorCount = 6
    private let fadeDuration: TimeInterval = 0.60
    private let fadeStep: TimeInterval = 0.48

    private let colors: [SectorColor] = [
        .init(r: 0.05, g: 0.42, b: 0.95),
        .init(r: 0.39, g: 0.18, b: 0.78),
        .init(r: 0.82, g: 0.05, b: 0.35),
        .init(r: 0.98, g: 0.22, b: 0.10),
        .init(r: 1.00, g: 0.52, b: 0.05),
        .init(r: 0.42, g: 0.78, b: 0.12)
    ]

    var body: some View {
        GeometryReader { geo in
            let p = min(1, max(0, progress))
            // The stream must lead the logo. Keep the silhouette faint from the start,
            // but delay the colored body until the energy has visibly risen.
            let fillProgress = smoothStep((p - 0.56) / 0.44)
            let bodyTop = geo.size.height * 0.2443
            let bodyBottom = geo.size.height * 0.9999
            let bandHeight = (bodyBottom - bodyTop) / CGFloat(sectorCount)
            let scaled = fillProgress * Double(sectorCount)
            let completed = min(sectorCount, Int(scaled.rounded(.down)))
            let fraction = completed < sectorCount ? scaled - Double(completed) : 0
            let leaf = leafProgress(fillProgress: fillProgress)

            ZStack(alignment: .topLeading) {
                ForEach(0..<sectorCount, id: \.self) { index in
                    let amount = index < completed ? 1.0 :
                        (index == completed ? fraction : 0)
                    let opacity = sectorOpacity(index)

                    if amount > 0.0001 && opacity > 0.0001 {
                        Rectangle()
                            .fill(sectorGradient(colors[index], index: index, time: time))
                            .frame(width: geo.size.width, height: bandHeight * CGFloat(amount) + 0.5)
                            .position(
                                x: geo.size.width / 2,
                                y: bodyBottom - CGFloat(index) * bandHeight
                                    - bandHeight * CGFloat(amount) / 2
                            )
                            .opacity(opacity)
                    }
                }
            }
            .mask(AppleBodyShape())
            .overlay {
                // Only the silhouette gets the soft 4–5 px glow.
                AppleBodyShape()
                    .stroke(
                        Color(red: 0.02, green: 0.12, blue: 0.025)
                            .opacity(0.78 * max(0.35, outlineProgress)),
                        lineWidth: 1.05
                    )
                    .blur(radius: 2.2)

                // Crisp dark-green contour under the glow.
                AppleBodyShape()
                    .stroke(
                        Color(red: 0.015, green: 0.07, blue: 0.02)
                            .opacity(0.92),
                        lineWidth: 0.75
                    )

                if leaf > 0 {
                    AppleLeafShape()
                        .fill(Color(red: colors[5].r, green: colors[5].g, blue: colors[5].b))
                        .opacity(leaf)
                        .mask(LeafGrowthMask(progress: leaf))
                        .overlay {
                            AppleLeafShape()
                                .stroke(
                                    Color(red: 0.02, green: 0.10, blue: 0.025)
                                        .opacity(0.85 * leaf),
                                    lineWidth: 0.7
                                )
                                .blur(radius: 2.0)
                                .mask(LeafGrowthMask(progress: leaf))
                        }
                }
            }
        }
    }

    private func leafProgress(fillProgress: Double) -> Double {
        guard disconnectElapsed == nil else { return 0 }
        // The leaf is strictly the final stage: it starts only after the body is complete.
        return smoothStep((fillProgress - 0.94) / 0.06)
    }

    private func sectorOpacity(_ index: Int) -> Double {
        guard let elapsed = disconnectElapsed else { return 1 }
        guard let position = disconnectOrder.firstIndex(of: index) else { return 1 }

        let start = Double(position) * fadeStep
        let t = (elapsed - start) / fadeDuration
        if t <= 0 { return 1 }
        if t >= 1 { return 0 }
        return 1 - smoothStep(t)
    }

    private func sectorGradient(_ base: SectorColor, index: Int, time: TimeInterval) -> LinearGradient {
        let beat = heartbeat(time, phase: Double(index) * 0.17)
        let shimmer = 0.5 + 0.5 * sin(time * 0.24 + Double(index) * 0.83)
        let light = 0.96 + 0.10 * beat + 0.035 * shimmer

        return LinearGradient(
            stops: [
                .init(color: base.color(0.90 + 0.04 * shimmer), location: 0),
                .init(color: base.color(light), location: 0.42),
                .init(color: base.color(0.98 + 0.10 * beat), location: 0.58),
                .init(color: base.color(0.91 + 0.04 * shimmer), location: 1)
            ],
            startPoint: UnitPoint(x: 0.15, y: 0),
            endPoint: UnitPoint(x: 0.85, y: 1)
        )
    }

    private func heartbeat(_ time: TimeInterval, phase: Double) -> Double {
        let cycle = (time * 1.08 + phase).truncatingRemainder(dividingBy: 1)
        let first = exp(-pow((cycle - 0.095) / 0.052, 2))
        let second = exp(-pow((cycle - 0.225) / 0.075, 2))
        return min(1, first * 0.95 + second * 0.52)
    }

    private func smoothStep(_ value: Double) -> Double {
        let t = min(1, max(0, value))
        return t * t * (3 - 2 * t)
    }
}

private struct SectorColor {
    let r: Double
    let g: Double
    let b: Double

    func color(_ multiplier: Double) -> Color {
        Color(
            red: min(1, r * multiplier),
            green: min(1, g * multiplier),
            blue: min(1, b * multiplier)
        )
    }
}

private struct LeafGrowthMask: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let p = min(1, max(0, progress))
        // Grow from the leaf base (~70% down its source geometry) toward the tip.
        let baseY = rect.minY + rect.height * 0.70
        let revealY = baseY - baseY * p
        var path = Path()
        path.addRect(
            CGRect(
                x: rect.minX - 2,
                y: revealY,
                width: rect.width + 4,
                height: rect.maxY - revealY + 2
            )
        )
        return path
    }
}

// MARK: - Energy stream

private struct EnergyStream: View {
    let progress: Double
    let time: TimeInterval
    let active: Bool
    let logoBottomY: CGFloat
    let logoWidth: CGFloat

    // One thread is visible first; the rest are introduced gradually.
    private let threads: [StreamThread] = [
        .init(birth: 0.00, offset: -0.10, amplitude: 1.00, frequency: 0.78, speed: 0.38, phase: 0.20, width: 1.65),
        .init(birth: 0.07, offset:  0.08, amplitude: 0.96, frequency: 0.86, speed: 0.34, phase: 1.70, width: 1.55),
        .init(birth: 0.14, offset: -0.22, amplitude: 0.92, frequency: 0.74, speed: 0.41, phase: 3.10, width: 1.45),
        .init(birth: 0.21, offset:  0.20, amplitude: 0.88, frequency: 0.91, speed: 0.36, phase: 4.55, width: 1.40),
        .init(birth: 0.29, offset: -0.31, amplitude: 0.82, frequency: 0.81, speed: 0.39, phase: 5.45, width: 1.35),
        .init(birth: 0.36, offset:  0.29, amplitude: 0.78, frequency: 0.88, speed: 0.33, phase: 0.85, width: 1.30),
        .init(birth: 0.43, offset: -0.14, amplitude: 0.74, frequency: 0.76, speed: 0.40, phase: 2.35, width: 1.28),
        .init(birth: 0.50, offset:  0.13, amplitude: 0.70, frequency: 0.93, speed: 0.35, phase: 3.80, width: 1.24),
        .init(birth: 0.57, offset: -0.27, amplitude: 0.66, frequency: 0.82, speed: 0.37, phase: 5.05, width: 1.20),
        .init(birth: 0.64, offset:  0.25, amplitude: 0.62, frequency: 0.89, speed: 0.32, phase: 1.15, width: 1.16),
        .init(birth: 0.71, offset: -0.08, amplitude: 0.58, frequency: 0.77, speed: 0.39, phase: 2.80, width: 1.12),
        .init(birth: 0.78, offset:  0.06, amplitude: 0.54, frequency: 0.84, speed: 0.34, phase: 4.20, width: 1.08)
    ]

    var body: some View {
        Canvas { context, size in
            guard active, progress > 0, progress < 0.92 else { return }

            let streamTop = logoBottomY - 1.0
            let streamBottom = size.height + 4.0
            let travelDistance = max(1, streamBottom - streamTop)
            let bundleHalf = min(16.0, max(10.0, size.width * 0.040))
            let travel = smoothStep(progress / 0.92)

            for (index, thread) in threads.enumerated() {
                guard progress >= thread.birth else { continue }

                let birthSpan = max(0.08, 0.88 - thread.birth)
                let local = min(1, max(0, (progress - thread.birth) / birthSpan))
                let visible = easeOut(local) * travel
                guard visible > 0.003 else { continue }

                drawThread(
                    &context,
                    size: size,
                    top: streamTop,
                    bottom: streamBottom,
                    distance: travelDistance,
                    bundleHalf: bundleHalf,
                    visible: visible,
                    thread: thread,
                    index: index
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func drawThread(
        _ context: inout GraphicsContext,
        size: CGSize,
        top: CGFloat,
        bottom: CGFloat,
        distance: CGFloat,
        bundleHalf: CGFloat,
        visible: Double,
        thread: StreamThread,
        index: Int
    ) {
        let samples = 88
        let visibleSamples = max(3, Int(Double(samples - 1) * visible) + 1)
        let centerX = size.width * 0.5
        var path = Path()
        var previous: CGPoint?

        for sample in 0..<visibleSamples {
            let u = Double(sample) / Double(samples - 1)
            let y = bottom - distance * CGFloat(u)
            let edgeTaper = 0.42 + 0.58 * sin(.pi * min(1, u))

            let wave1 = sin(time * thread.speed + thread.phase + u * .pi * 2.15 * thread.frequency)
            let wave2 = sin(time * thread.speed * 0.58 + thread.phase * 0.71 + u * .pi * 4.05 * thread.frequency + 1.2)
            let wave3 = sin(time * thread.speed * 0.31 + thread.phase * 1.37 + u * .pi * 6.7 + 2.0)
            let organic = 0.58 * wave1 + 0.27 * wave2 + 0.15 * wave3

            let staticX = thread.offset * bundleHalf
            let bend = bundleHalf * 0.92 * thread.amplitude * CGFloat(organic) * CGFloat(edgeTaper)
            let merge = smoothStep((u - 0.76) / 0.24)
            let x = centerX + (staticX + bend) * CGFloat(1 - 0.88 * merge)

            let point = CGPoint(x: x, y: y)
            if let previous {
                if sample == 1 { path.move(to: previous) }
                path.addLine(to: point)
            } else {
                path.move(to: point)
            }
            previous = point
        }

        let shimmer = 0.82 + 0.18 * sin(time * (1.2 + Double(index) * 0.04) + thread.phase)
        let pulse = 0.82 + 0.18 * shimmer
        let width = thread.width * pulse

        // Broad low-opacity halo + crisp living core.
        context.stroke(
            path,
            with: .color(Color(red: 0.16, green: 0.88, blue: 0.24).opacity(0.22)),
            style: StrokeStyle(lineWidth: width * 3.6, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            path,
            with: .color(Color(red: 0.38, green: 0.98, blue: 0.30).opacity(0.62 + 0.14 * shimmer)),
            style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        )
    }

    private func easeOut(_ value: Double) -> Double {
        let t = min(1, max(0, value))
        return 1 - pow(1 - t, 2.35)
    }

    private func smoothStep(_ value: Double) -> Double {
        let t = min(1, max(0, value))
        return t * t * (3 - 2 * t)
    }
}

private struct StreamThread {
    let birth: Double
    let offset: Double
    let amplitude: Double
    let frequency: Double
    let speed: Double
    let phase: Double
    let width: Double
}
