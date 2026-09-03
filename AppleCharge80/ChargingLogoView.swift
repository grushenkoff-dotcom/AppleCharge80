import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []
    @State private var chargeStart: Date?

    private let sectorCount = 6
    private let sectorFadeDuration: TimeInterval = 0.60
    private let sectorFadeStep: TimeInterval = 0.48

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let now = timeline.date
            let elapsed = chargeStart.map { max(0, now.timeIntervalSince($0)) } ?? 0
            let disconnectElapsed = disconnectStart.map { max(0, now.timeIntervalSince($0)) }

            GeometryReader { geo in
                let logoHeight: CGFloat = 181
                let logoWidth = logoHeight * 814.0 / 1000.0
                let logoTop = max(42, geo.size.height * 0.075)
                let logoBottom = logoTop + logoHeight

                ZStack(alignment: .top) {
                    EnergyStream(
                        progress: clampedProgress,
                        time: elapsed,
                        active: isCharging && disconnectElapsed == nil,
                        logoBottomY: logoBottom
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
            if chargeStart == nil {
                chargeStart = now
            }
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

    private let colors: [SectorColor] = [
        .init(r: 0.05, g: 0.42, b: 0.95),
        .init(r: 0.39, g: 0.18, b: 0.78),
        .init(r: 0.82, g: 0.05, b: 0.35),
        .init(r: 0.98, g: 0.22, b: 0.10),
        .init(r: 1.00, g: 0.52, b: 0.05),
        .init(r: 0.42, g: 0.78, b: 0.12)
    ]

    // The stream reaches the imaginary lower edge first.
    // Only then is the logo allowed to fill.
    private let streamArrivalProgress = 0.31
    private let bodyCompletionProgress = 0.94

    var body: some View {
        GeometryReader { geo in
            let p = min(1, max(0, progress))
            let fillProgress = logoFillProgress(p)
            let bodyTop = geo.size.height * 0.2443
            let bodyBottom = geo.size.height * 0.9999
            let bodyHeight = bodyBottom - bodyTop
            let bandHeight = bodyHeight / CGFloat(sectorCount)
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
                            .frame(
                                width: geo.size.width,
                                height: bandHeight * CGFloat(amount) + 0.5
                            )
                            .position(
                                x: geo.size.width / 2,
                                y: bodyBottom
                                    - CGFloat(index) * bandHeight
                                    - bandHeight * CGFloat(amount) / 2
                            )
                            .opacity(opacity)
                    }
                }
            }
            .mask(AppleBodyShape())
            .overlay {
                // Keep the interior crisp. Only the outside contour is softened.
                AppleBodyShape()
                    .stroke(
                        Color(red: 0.015, green: 0.11, blue: 0.025)
                            .opacity(0.86 * max(0.35, outlineProgress)),
                        lineWidth: 1.0
                    )
                    .blur(radius: 2.3)

                AppleBodyShape()
                    .stroke(
                        Color(red: 0.008, green: 0.055, blue: 0.015)
                            .opacity(0.92),
                        lineWidth: 0.72
                    )

                if leaf > 0 {
                    AppleLeafShape()
                        .fill(Color(red: colors[5].r, green: colors[5].g, blue: colors[5].b))
                        .opacity(leaf)
                        .mask(LeafGrowthMask(progress: leaf))
                        .overlay {
                            AppleLeafShape()
                                .stroke(
                                    Color(red: 0.015, green: 0.10, blue: 0.025)
                                        .opacity(0.80 * leaf),
                                    lineWidth: 0.7
                                )
                                .blur(radius: 2.1)
                                .mask(LeafGrowthMask(progress: leaf))
                        }
                }
            }
        }
    }

    private func logoFillProgress(_ p: Double) -> Double {
        guard disconnectElapsed == nil else { return 0 }
        guard p >= streamArrivalProgress else { return 0 }
        return smoothStep((p - streamArrivalProgress) / (1.0 - streamArrivalProgress))
    }

    private func leafProgress(fillProgress: Double) -> Double {
        guard disconnectElapsed == nil else { return 0 }
        // Body must be completely filled before the leaf begins.
        return smoothStep((fillProgress - bodyCompletionProgress) / (1.0 - bodyCompletionProgress))
    }

    private func sectorOpacity(_ index: Int) -> Double {
        guard let elapsed = disconnectElapsed else { return 1 }
        guard let position = disconnectOrder.firstIndex(of: index) else { return 1 }

        let start = Double(position) * 0.48
        let t = (elapsed - start) / 0.60
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

    // Width is created by more individual energy filaments, not by thickening one line.
    // The resulting bundle is approximately 7 mm on an iPhone-sized display.
    private let bundleWidthRatio: CGFloat = 0.0975
    private let maxBundleWidth: CGFloat = 40.0
    private let travelDurationProgress: Double = 0.31

    // One living thread starts the stream; more filaments appear gradually.
    // Their phases, frequencies, speeds and amplitudes are intentionally different.
    private let threads: [StreamThread] = [
        .init(birth: 0.00, offset: -0.16, amplitude: 0.82, frequency: 0.72, speed: 0.38, phase: 0.20, width: 1.25),
        .init(birth: 0.018, offset: 0.05, amplitude: 0.90, frequency: 0.81, speed: 0.34, phase: 1.70, width: 1.20),
        .init(birth: 0.036, offset: -0.34, amplitude: 0.76, frequency: 0.67, speed: 0.41, phase: 3.10, width: 1.15),
        .init(birth: 0.055, offset: 0.31, amplitude: 0.86, frequency: 0.86, speed: 0.36, phase: 4.55, width: 1.15),
        .init(birth: 0.074, offset: -0.52, amplitude: 0.70, frequency: 0.75, speed: 0.39, phase: 5.45, width: 1.10),
        .init(birth: 0.094, offset: 0.47, amplitude: 0.78, frequency: 0.88, speed: 0.33, phase: 0.85, width: 1.10),
        .init(birth: 0.116, offset: -0.24, amplitude: 0.74, frequency: 0.69, speed: 0.40, phase: 2.35, width: 1.05),
        .init(birth: 0.140, offset: 0.22, amplitude: 0.68, frequency: 0.91, speed: 0.35, phase: 3.80, width: 1.05),
        .init(birth: 0.165, offset: -0.42, amplitude: 0.64, frequency: 0.77, speed: 0.37, phase: 5.05, width: 1.00),
        .init(birth: 0.192, offset: 0.39, amplitude: 0.60, frequency: 0.84, speed: 0.32, phase: 1.15, width: 1.00),
        .init(birth: 0.220, offset: -0.13, amplitude: 0.56, frequency: 0.71, speed: 0.39, phase: 2.80, width: 0.95),
        .init(birth: 0.248, offset: 0.10, amplitude: 0.52, frequency: 0.80, speed: 0.34, phase: 4.20, width: 0.95),
        .init(birth: 0.270, offset: -0.27, amplitude: 0.48, frequency: 0.74, speed: 0.37, phase: 0.62, width: 0.92),
        .init(birth: 0.292, offset: 0.28, amplitude: 0.44, frequency: 0.82, speed: 0.35, phase: 2.14, width: 0.90)
    ]

    var body: some View {
        Canvas { context, size in
            guard active, progress > 0 else { return }

            let streamTop = logoBottomY - 1.0
            let streamBottom = size.height + 4.0
            let distance = max(1, streamBottom - streamTop)

            // Exactly 3× the previous v2 arrival speed: the head reaches the
            // imaginary lower edge at progress 0.31 instead of 0.92.
            let travel = easeOut(min(1, progress / travelDurationProgress))
            let bundleWidth = min(maxBundleWidth, max(34.0, size.width * bundleWidthRatio))
            let halfBundle = bundleWidth * 0.5

            for (index, thread) in threads.enumerated() {
                guard progress >= thread.birth else { continue }

                // Every filament that has been born is allowed to catch the head.
                // This keeps the stream dense by the time it reaches the logo.
                let local = min(1, max(0, (progress - thread.birth) / max(0.0001, travelDurationProgress - thread.birth)))
                let visible = easeOut(local)
                guard visible > 0.003 else { continue }

                drawThread(
                    &context,
                    size: size,
                    top: streamTop,
                    bottom: streamBottom,
                    distance: distance,
                    halfBundle: halfBundle,
                    visible: visible,
                    travel: travel,
                    thread: thread,
                    index: index
                )
            }

            drawBlackHoleContact(
                context: &context,
                centerX: size.width * 0.5,
                targetY: streamTop,
                width: bundleWidth,
                strength: contactStrength(progress: progress, travel: travel)
            )
        }
        .allowsHitTesting(false)
    }

    private func drawThread(
        _ context: inout GraphicsContext,
        size: CGSize,
        top: CGFloat,
        bottom: CGFloat,
        distance: CGFloat,
        halfBundle: CGFloat,
        visible: Double,
        travel: Double,
        thread: StreamThread,
        index: Int
    ) {
        let samples = 96
        let visibleSamples = max(3, Int(Double(samples - 1) * visible) + 1)
        let centerX = size.width * 0.5
        var path = Path()
        var previous: CGPoint?

        for sample in 0..<visibleSamples {
            let u = Double(sample) / Double(samples - 1)
            let y = bottom - distance * CGFloat(u)

            // Full bundle at mid-height; soft taper only at the extreme ends.
            let edgeTaper = 0.58 + 0.42 * sin(.pi * min(1, u))

            let wave1 = sin(time * thread.speed + thread.phase + u * .pi * 2.10 * thread.frequency)
            let wave2 = sin(time * thread.speed * 0.56 + thread.phase * 0.71 + u * .pi * 3.80 * thread.frequency + 1.2)
            let wave3 = sin(time * thread.speed * 0.30 + thread.phase * 1.31 + u * .pi * 6.20 + 2.0)
            let organic = 0.57 * wave1 + 0.28 * wave2 + 0.15 * wave3

            let staticX = thread.offset * halfBundle
            let bend = halfBundle * 0.94 * thread.amplitude * CGFloat(organic) * CGFloat(edgeTaper)

            // The stream becomes a little more coherent near the contact point,
            // but never collapses into one straight line.
            let merge = smoothStep((u - 0.82) / 0.18)
            let x = centerX + (staticX + bend) * CGFloat(1.0 - 0.48 * merge)

            let point = CGPoint(x: x, y: y)
            if let previous {
                path.addLine(to: point)
            } else {
                path.move(to: point)
            }
            previous = point
        }

        let shimmer = 0.82 + 0.18 * sin(time * (1.15 + Double(index) * 0.035) + thread.phase)
        let pulse = 0.86 + 0.14 * shimmer
        let width = thread.width * pulse

        // A restrained halo supplies volume; the core remains sharp.
        context.stroke(
            path,
            with: .color(Color(red: 0.12, green: 0.72, blue: 0.18).opacity(0.18)),
            style: StrokeStyle(lineWidth: width * 3.8, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            path,
            with: .color(Color(red: 0.36, green: 0.98, blue: 0.28).opacity(0.56 + 0.16 * shimmer)),
            style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        )

        // Moving luminous head. It is intentionally separate from the trail.
        let headU = visible
        let headY = bottom - distance * CGFloat(headU)
        let headWave = sin(time * thread.speed * 1.4 + thread.phase)
        let headX = centerX + thread.offset * halfBundle + CGFloat(headWave) * halfBundle * 0.12
        let radius = CGFloat(0.85 + 0.30 * heartbeat(time, phase: thread.phase))

        context.fill(
            Path(ellipseIn: CGRect(
                x: headX - radius,
                y: headY - radius,
                width: radius * 2,
                height: radius * 2
            )),
            with: .color(Color(red: 0.50, green: 1.0, blue: 0.36).opacity(0.52))
        )
    }

    // Interstellar-inspired gravitational-looking contact distortion.
    // It is implemented as concentric dark/green rings, not a copied film asset.
    private func drawBlackHoleContact(
        context: inout GraphicsContext,
        centerX: CGFloat,
        targetY: CGFloat,
        width: CGFloat,
        strength: Double
    ) {
        guard strength > 0.001 else { return }

        let pulse = heartbeat(time, phase: 0)
        let baseRadius = width * (0.24 + 0.10 * pulse)

        for ring in 0..<5 {
            let r = baseRadius * (0.65 + CGFloat(ring) * 0.28)
            let alpha = strength * (0.24 - Double(ring) * 0.034)
            guard alpha > 0 else { continue }

            context.stroke(
                Path(ellipseIn: CGRect(
                    x: centerX - r,
                    y: targetY - r * 0.42,
                    width: r * 2,
                    height: r * 0.84
                )),
                with: .color(Color(red: 0.02, green: 0.16, blue: 0.025).opacity(alpha)),
                style: StrokeStyle(lineWidth: CGFloat(1.0 + Double(ring) * 0.65), lineCap: .round)
            )
        }

        let core = baseRadius * 0.42
        context.fill(
            Path(ellipseIn: CGRect(
                x: centerX - core,
                y: targetY - core * 0.34,
                width: core * 2,
                height: core * 0.68
            )),
            with: .color(Color.black.opacity(0.72 * strength))
        )

        context.stroke(
            Path(ellipseIn: CGRect(
                x: centerX - baseRadius * 1.35,
                y: targetY - baseRadius * 0.57,
                width: baseRadius * 2.7,
                height: baseRadius * 1.14
            )),
            with: .color(Color(red: 0.30, green: 0.90, blue: 0.20).opacity(0.20 * strength * (0.7 + 0.3 * pulse))),
            style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
        )
    }

    private func contactStrength(progress: Double, travel: Double) -> Double {
        guard progress >= travelDurationProgress * 0.72 else { return 0 }
        return smoothStep((progress - travelDurationProgress * 0.72) / (travelDurationProgress * 0.28)) * travel
    }

    private func heartbeat(_ time: TimeInterval, phase: Double) -> Double {
        let cycle = (time * 1.08 + phase).truncatingRemainder(dividingBy: 1)
        let first = exp(-pow((cycle - 0.095) / 0.052, 2))
        let second = exp(-pow((cycle - 0.225) / 0.075, 2))
        return min(1, first * 0.95 + second * 0.52)
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
