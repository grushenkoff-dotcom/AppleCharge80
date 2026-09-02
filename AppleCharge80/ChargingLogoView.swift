import SwiftUI

struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var displayedProgress: Double = 0
    @State private var leafProgress: Double = 0
    @State private var disappearedSegments: Set<Int> = []
    @State private var isDischargingAnimation = false
    @State private var generation = 0

    private let segmentCount = 8

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { _ in
            ZStack {
                AppleChargeLogo(
                    progress: displayedProgress,
                    outlineProgress: outlineProgress,
                    disappearedSegments: disappearedSegments
                )

                LeafShape()
                    .trim(from: 0, to: leafProgress)
                    .stroke(
                        Color(red: 0.20, green: 0.78, blue: 0.38),
                        style: StrokeStyle(
                            lineWidth: 4.5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .opacity(leafProgress > 0 ? 1 : 0)
            }
            .frame(width: 118, height: 118)
        }
        .onAppear {
            displayedProgress = clamped(progress)
            updateLeaf(for: displayedProgress, animated: false)
        }
        .onChange(of: progress) { _, newValue in
            guard isCharging else { return }

            displayedProgress = clamped(newValue)
            updateLeaf(for: displayedProgress, animated: true)
        }
        .onChange(of: isCharging) { _, charging in
            if charging {
                startCharging()
            } else {
                startDischarging()
            }
        }
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }

    private func updateLeaf(for value: Double, animated: Bool) {
        let target: Double

        if value < 88 {
            target = 0
        } else {
            target = min(max((value - 88) / 12, 0), 1)
        }

        if animated {
            withAnimation(.linear(duration: 0.08)) {
                leafProgress = target
            }
        } else {
            leafProgress = target
        }
    }

    private func startCharging() {
        generation += 1
        isDischargingAnimation = false
        disappearedSegments.removeAll()

        displayedProgress = clamped(progress)
        updateLeaf(for: displayedProgress, animated: true)
    }

    private func startDischarging() {
        generation += 1
        let currentGeneration = generation

        isDischargingAnimation = true
        leafProgress = 0
        disappearedSegments.removeAll()

        let order = Array(0..<segmentCount).shuffled()

        for (offset, segment) in order.enumerated() {
            let delay = 0.10 * Double(offset)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard currentGeneration == generation,
                      isDischargingAnimation else { return }

                withAnimation(.easeOut(duration: 0.12)) {
                    disappearedSegments.insert(segment)
                }

                if offset == order.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                        guard currentGeneration == generation else { return }

                        displayedProgress = 0
                        isDischargingAnimation = false
                    }
                }
            }
        }
    }
}

private struct AppleChargeLogo: View {
    let progress: Double
    let outlineProgress: Double
    let disappearedSegments: Set<Int>

    private let segmentCount = 8

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                Circle()
                    .trim(from: 0, to: min(max(outlineProgress, 0), 1))
                    .stroke(
                        Color.white.opacity(0.85),
                        style: StrokeStyle(
                            lineWidth: 1.5,
                            lineCap: .round
                        )
                    )
                    .frame(width: size * 0.72, height: size * 0.72)
                    .rotationEffect(.degrees(-90))

                ForEach(0..<segmentCount, id: \.self) { index in
                    let visible = isSegmentVisible(index)

                    ChargeSegment(
                        index: index,
                        count: segmentCount,
                        radius: size * 0.36,
                        thickness: size * 0.105
                    )
                    .fill(Color(red: 0.25, green: 0.82, blue: 0.38))
                    .opacity(visible ? 1 : 0)
                    .scaleEffect(visible ? 1 : 0.82)
                    .animation(.easeOut(duration: 0.12), value: visible)
                }

                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(progress > 0 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func isSegmentVisible(_ index: Int) -> Bool {
        guard !disappearedSegments.contains(index) else {
            return false
        }

        let fraction = min(max(progress / 100, 0), 1)
        let visibleCount = Int(ceil(fraction * Double(segmentCount)))

        return index < visibleCount
    }
}

private struct ChargeSegment: Shape {
    let index: Int
    let count: Int
    let radius: CGFloat
    let thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = radius
        let innerRadius = radius - thickness

        let fullSegment = 2 * CGFloat.pi / CGFloat(count)
        let gap = CGFloat.pi / 180 * 4

        let start = -CGFloat.pi / 2 + CGFloat(index) * fullSegment + gap / 2
        let end = -CGFloat.pi / 2 + CGFloat(index + 1) * fullSegment - gap / 2

        var path = Path()

        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: Angle(radians: Double(start)),
            endAngle: Angle(radians: Double(end)),
            clockwise: false
        )

        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: Angle(radians: Double(end)),
            endAngle: Angle(radians: Double(start)),
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        var path = Path()

        path.move(to: CGPoint(x: w * 0.58, y: h * 0.28))

        path.addCurve(
            to: CGPoint(x: w * 0.69, y: h * 0.08),
            control1: CGPoint(x: w * 0.59, y: h * 0.18),
            control2: CGPoint(x: w * 0.65, y: h * 0.11)
        )

        path.move(to: CGPoint(x: w * 0.64, y: h * 0.16))

        path.addCurve(
            to: CGPoint(x: w * 0.88, y: h * 0.08),
            control1: CGPoint(x: w * 0.74, y: h * 0.08),
            control2: CGPoint(x: w * 0.84, y: h * 0.05)
        )

        path.addCurve(
            to: CGPoint(x: w * 0.69, y: h * 0.28),
            control1: CGPoint(x: w * 0.87, y: h * 0.21),
            control2: CGPoint(x: w * 0.76, y: h * 0.27)
        )

        path.addCurve(
            to: CGPoint(x: w * 0.64, y: h * 0.16),
            control1: CGPoint(x: w * 0.67, y: h * 0.24),
            control2: CGPoint(x: w * 0.64, y: h * 0.19)
        )

        return path
    }
}
