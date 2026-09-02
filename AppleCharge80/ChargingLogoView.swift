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

        // Always start visually from zero.
        animatedProgress = 0

        // The animation itself is deliberately independent
        // from the first rendered frame.
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
                geo.size.height * 0.
