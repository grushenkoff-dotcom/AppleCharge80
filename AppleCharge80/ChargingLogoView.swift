import SwiftUI
struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool
    @State private var disconnectStart: Date?
    @State private var disconnectOrder: [Int] = []
    @State private var animatedProgress: Double = 0
    private let sectorCount = 6
    private let disconnectTotal: TimeInterval = 3.0
    private let sectorDuration: TimeInterval = 0.6
    private let sectorStartStep: TimeInterval = 0.48
    var body: some View {
        TimelineView(
            .animation(minimumInterval: 1.0 / 60.0)
        ) { context in
            let now = context.date
            let disconnectElapsed = disconnectStart.map {
                now.timeIntervalSince($0)
            }
            GeometryReader { geo in
                ZStack {
                    AppleLogoFill(
                        progress: animatedProgress,
                        time: now.timeIntervalSinceReferenceDate,
                        disconnectElapsed: disconnectElapsed,
                        disconnectOrder: disconnectOrder,
                        sectorCount: sectorCount,
                        sectorDuration: sectorDuration,
                        sectorStartStep: sectorStartStep,
                        disconnectTotal: disconnectTotal
                    )
                    PlantParticleField(
                        progress: animatedProgress,
                        time: now.timeIntervalSinceReferenceDate,
                        active: isCharging && disconnectElapsed == nil,
                        logoWidth: geo.size.width * 0.30,
                        logoHeight: geo.size.width * 0.30 * 1000.0 / 814.0
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .onAppear {
                animatedProgress = 0
                if isCharging {
                    startChargingAnimation()
                } else {
                    beginDisconnect(at: now)
                }
            }
            .onChange(of: progress) { _, _ in
                if isCharging && disconnectStart == nil {
                    startChargingAnimation()
                }
            }
            .onChange(of: isCharging) { _, charging in
                if charging {
                    disconnectStart = nil
                    disconnectOrder = []
                    animatedProgress = 0
                    startChargingAnimation()
                } else if disconnectStart == nil {
                    beginDisconnect(at: now)
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
    // MARK: - Progress
    private var normalizedProgress: Double {
        let value = progress > 1.0
            ? progress / 100.0
            : progress
        return min(1.0, max(0.0, value))
    }
    private func startChargingAnimation() {
        let target = normalizedProgress
        animatedProgress = 0
        withAnimation(
            .easeInOut(duration: 8.0)
        ) {
            animatedProgress = target
        }
    }
    // MARK: - Disconnect
    private func beginDisconnect(at date: Date) {
        disconnectOrder = Array(0..<sectorCount).shuffled()
        disconnectStart = date
    }
}
// MARK: - Apple Logo
private struct AppleLogoFill: View {
    let progress: Double
    let time: TimeInterval
    let disconnectElapsed: TimeInterval?
    let disconnectOrder: [Int]
    let sectorCount: Int
    let sectorDuration: TimeInterval
    let sectorStartStep: TimeInterval
    let disconnectTotal: TimeInterval
    // Classic 1980s Apple order, bottom -> top.
    private let colors: [Color] = [
        Color(red: 0.12, green: 0.36, blue: 0.86),
        Color(red: 0.42, green: 0.22, blue: 0.72),
        Color(red: 0.88, green: 0.12, blue: 0.16),
        Color(red: 0.98, green: 0.42, blue: 0.08),
        Color(red: 0.98, green: 0.78, blue: 0.08),
        Color(red: 0.22, green: 0.68, blue: 0.20)
    ]
    var body: some View {
        GeometryReader { geo in
            let logoHeight = min(
                CGFloat(181),
                geo.size.height * 0.60
            )
            let logoWidth = logoHeight * 814.0 / 1000.0
            ZStack {
                ForEach(0..<sectorCount, id: \.self) { index in
                    let visibility = sectorVisibility(for: index)
                    if visibility > 0 {
                        Rectangle()
                            .fill(colors[index % colors.count])
                            .frame(
                                width: logoWidth,
                                height: logoHeight
                            )
                            .mask {
                                AppleShape()
                                    .frame(
                                        width: logoWidth,
                                        height: logoHeight
                                    )
                            }
                            .opacity(visibility)
                    }
                }
            }
            .frame(
                width: logoWidth,
                height: logoHeight
            )
            .scaleEffect(0.60)
            .position(
                x: geo.size.width / 2,
                y: geo.size.height / 2
            )
        }
    }
    private func sectorVisibility(for index: Int) -> Double {
        // ---------------------------------------------------------
        // CHARGING
        // ---------------------------------------------------------
        if disconnectElapsed == nil {
            let sectorStart =
                Double(index) / Double(sectorCount)
            let sectorEnd =
                Double(index + 1) / Double(sectorCount)
            if progress <= sectorStart {
                return 0
            }
            if progress >= sectorEnd {
                return 1
            }
            return (
                progress - sectorStart
            ) / (
                sectorEnd - sectorStart
            )
        }
        // ---------------------------------------------------------
        // DISCONNECT
        // ---------------------------------------------------------
        guard let elapsed = disconnectElapsed else {
            return 1
        }
        guard disconnectOrder.count == sectorCount else {
            return 1
        }
        guard let orderPosition =
                disconnectOrder.firstIndex(of: index) else {
            return 1
        }
        let start =
            Double(orderPosition) * sectorStartStep
        let localTime =
            elapsed - start
        if localTime <= 0 {
            return 1
        }
        if localTime >= sectorDuration {
            return 0
        }
        return 1.0 -
            localTime / sectorDuration
    }
}
// MARK: - Apple Shape
private struct AppleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Apple logo proportions.
        let x = w / 814.0
        let y = h / 1000.0
        func point(
            _ px: CGFloat,
            _ py: CGFloat
        ) -> CGPoint {
            CGPoint(
                x: px * x,
                y: py * y
            )
        }
        // Main body.
        path.move(
            to: point(407, 145)
        )
        path.addCurve(
            to: point(245, 190),
            control1: point(330, 130),
            control2: point(275, 155)
        )
        path.addCurve(
            to: point(115, 365),
            control1: point(170, 220),
            control2: point(120, 295)
        )
        path.addCurve(
            to: point(165, 650),
            control1: point(105, 500),
            control2: point(125, 590)
        )
        path.addCurve(
            to: point(300, 875),
            control1: point(205, 780),
            control2: point(255, 865)
        )
        path.addCurve(
            to: point(407, 820),
            control1: point(345, 895),
            control2: point(375, 840)
        )
        path.addCurve(
            to: point(515, 875),
            control1: point(440, 840),
            control2: point(470, 895)
        )
        path.addCurve(
            to: point(650, 650),
            control1: point(560, 865),
            control2: point(610, 780)
        )
        path.addCurve(
            to: point(700, 365),
            control1: point(685, 590),
            control2: point(715, 500)
        )
        path.addCurve(
            to: point(570, 190),
            control1: point(690, 295),
            control2: point(635, 220)
        )
        path.addCurve(
            to: point(407, 145),
            control1: point(515, 150),
            control2: point(455, 130)
        )
        path.closeSubpath()
        // Leaf.
        path.move(
            to: point(407, 145)
        )
        path.addCurve(
            to: point(525, 35),
            control1: point(430, 115),
            control2: point(500, 65)
        )
        path.addCurve(
            to: point(540, 0),
            control1: point(535, 20),
            control2: point(540, 8)
        )
        path.addCurve(
            to: point(425, 38),
            control1: point(500, 5),
            control2: point(455, 20)
        )
        path.addCurve(
            to: point(407, 145),
            control1: point(400, 90),
            control2: point(400, 120)
        )
        path.closeSubpath()
        return path
    }
}
// MARK: - Plant
private struct PlantParticleField: View {
    let progress: Double
    let time: TimeInterval
    let active: Bool
    let logoWidth: CGFloat
    let logoHeight: CGFloat
    var body: some View {
        Canvas { context, size in
            guard active else {
                return
            }
            // The plant must remain completely hidden
            // until charging reaches 88%.
            guard progress >= 0.88 else {
                return
            }
            // 88% -> 100%.
            let plantProgress = min(
                1.0,
                max(
                    0.0,
                    (progress - 0.88) / 0.12
                )
            )
            let centerX = size.width / 2
            let baseY =
                size.height / 2
                - logoHeight * 0.20
            let stemHeight =
                logoHeight * 0.30
                * plantProgress
            let topY =
                baseY - stemHeight
            // Stem.
            var stem = Path()
            stem.move(
                to: CGPoint(
                    x: centerX,
                    y: baseY
                )
            )
            stem.addCurve(
                to: CGPoint(
                    x: centerX,
                    y: topY
                ),
                control1: CGPoint(
                    x: centerX - logoWidth * 0.025,
                    y: baseY - stemHeight * 0.45
                ),
                control2: CGPoint(
                    x: centerX + logoWidth * 0.025,
                    y: topY + stemHeight * 0.25
                )
            )
            context.stroke(
                stem,
                with: .color(.green),
                lineWidth: max(
                    1.5,
                    logoWidth * 0.018
                )
            )
            // Leaf grows during the same 88% -> 100% interval.
            let leafWidth =
                logoWidth * 0.16 * plantProgress
            let leafHeight =
                logoHeight * 0.08 * plantProgress
            var leaf = Path()
            let start = CGPoint(
                x: centerX,
                y: topY
            )
            let tip = CGPoint(
                x: centerX + leafWidth,
                y: topY - leafHeight
            )
            leaf.move(to: start)
            leaf.addCurve(
                to: tip,
                control1: CGPoint(
                    x: centerX + leafWidth * 0.25,
                    y: topY - leafHeight * 0.15
                ),
                control2: CGPoint(
                    x: centerX + leafWidth * 0.75,
                    y: topY - leafHeight * 0.90
                )
            )
            leaf.addCurve(
                to: start,
                control1: CGPoint(
                    x: centerX + leafWidth * 0.65,
                    y: topY + leafHeight * 0.10
                ),
                control2: CGPoint(
                    x: centerX + leafWidth * 0.20,
                    y: topY + leafHeight * 0.10
                )
            )
            leaf.closeSubpath()
            context.fill(
                leaf,
                with: .color(
                    .green.opacity(0.95)
                )
            )
        }
        .allowsHitTesting(false)
    }
}
