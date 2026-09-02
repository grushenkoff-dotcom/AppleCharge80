import SwiftUI
struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool
    @State private var displayedProgress: Double = 0
    @State private var plantProgress: Double = 0
    @State private var isDischargingAnimation = false
    @State private var randomOrder: [Int] = Array(0..<8)
    @State private var disappearedSegments: Set<Int> = []
    private let segmentCount = 8
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let now = context.date
            ZStack {
                // MARK: - Main logo
                AppleChargeLogo(
                    progress: displayedProgress,
                    outlineProgress: outlineProgress,
                    disappearedSegments: disappearedSegments
                )
                .frame(width: 118, height: 118)
                // MARK: - Growing leaf
                LeafShape()
                    .trim(from: 0, to: plantProgress)
                    .stroke(
                        Color(red: 0.20, green: 0.78, blue: 0.38),
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 118, height: 118)
                    .opacity(plantProgress > 0 ? 1 : 0)
                    .animation(
                        .easeInOut(duration: 0.08),
                        value: plantProgress
                    )
            }
            .onChange(of: isCharging) { _, charging in
                if charging {
                    startChargingAnimation()
                } else {
                    startDischargingAnimation()
                }
            }
            .onChange(of: progress) { _, newValue in
                updateProgress(newValue)
            }
            .onAppear {
                displayedProgress = max(0, min(100, progress))
                updatePlantProgress()
            }
        }
    }
    // MARK: - Charging
    private func startChargingAnimation() {
        isDischargingAnimation = false
        disappearedSegments.removeAll()
        randomOrder = Array(0..<segmentCount).shuffled()
        withAnimation(.easeOut(duration: 0.25)) {
            displayedProgress = max(0, min(100, progress))
        }
        updatePlantProgress()
    }
    private func updateProgress(_ value: Double) {
        guard !isDischargingAnimation else { return }
        let newProgress = max(0, min(100, value))
        withAnimation(.linear(duration: 0.12)) {
            displayedProgress = newProgress
        }
        updatePlantProgress(for: newProgress)
    }
    // MARK: - Leaf
    //
    // Leaf appears ONLY after 88%.
    // It grows during the remaining 12%:
    //
    // 88%  -> 0%
    // 100% -> 100%
    private func updatePlantProgress(for value: Double? = nil) {
        let current = value ?? displayedProgress
        guard current >= 88 else {
            withAnimation(.easeOut(duration: 0.15)) {
                plantProgress = 0
            }
            return
        }
        let normalized = (current - 88.0) / 12.0
        let leaf = max(0, min(1, normalized))
        withAnimation(.linear(duration: 0.08)) {
            plantProgress = leaf
        }
    }
    // MARK: - Discharging
    private func startDischargingAnimation() {
        guard !isDischargingAnimation else { return }
        isDischargingAnimation = true
        plantProgress = 0
        randomOrder = Array(0..<segmentCount).shuffled()
        disappearedSegments.removeAll()
        // Reset the visible state first.
        displayedProgress = max(0, min(100, progress))
        // Segments disappear one by one in random order.
        for (position, segment) in randomOrder.enumerated() {
            let delay = Double(position) * 0.09
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard isDischargingAnimation else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    disappearedSegments.insert(segment)
                }
                if position == randomOrder.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                        if isDischargingAnimation {
                            displayedProgress = 0
                            isDischargingAnimation = false
                        }
                    }
                }
            }
        }
    }
}
// MARK: - Apple Charge Logo
private struct AppleChargeLogo: View {
    let progress: Double
    let outlineProgress: Double
    let disappearedSegments: Set<Int>
    private let segmentCount = 8
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            ZStack {
                // MARK: Outline
                Circle()
                    .trim(from: 0, to: max(0, min(1, outlineProgress)))
                    .stroke(
                        Color.white.opacity(0.85),
                        style: StrokeStyle(
                            lineWidth: 1.5,
                            lineCap: .round
                        )
                    )
                    .frame(width: size * 0.72, height: size * 0.72)
                    .rotationEffect(.degrees(-90))
                // MARK: Segments
                ForEach(0..<segmentCount, id: \.self) { index in
                    let visible = isSegmentVisible(index)
                    ChargeSegment(
                        index: index,
                        count: segmentCount,
                        radius: size * 0.36,
                        thickness: size * 0.115
                    )
                    .fill(
                        Color(red: 0.25, green: 0.82, blue: 0.38)
                    )
                    .opacity(visible ? 1 : 0)
                    .scaleEffect(visible ? 1 : 0.82)
                    .animation(
                        .easeOut(duration: 0.12),
                        value: visible
                    )
                }
                // MARK: Center lightning / charging mark
                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.27, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(progress > 0 ? 1 : 0)
            }
            .position(center)
        }
    }
    private func isSegmentVisible(_ index: Int) -> Bool {
        if disappearedSegments.contains(index) {
            return false
        }
        let fraction = max(0, min(1, progress / 100.0))
        let visibleCount = Int(ceil(fraction * Double(segmentCount)))
        return index < visibleCount
    }
}
// MARK: - Charge Segment
private struct ChargeSegment: Shape {
    let index: Int
    let count: Int
    let radius: CGFloat
    let thickness: CGFloat
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(
            x: rect.midX,
            y: rect.midY
        )
        let outerRadius = radius
        let innerRadius = radius - thickness
        let gap = CGFloat.pi / 180.0 * 4.0
        let segmentAngle = 2.0 * CGFloat.pi / CGFloat(count)
        let startAngle =
            -CGFloat.pi / 2.0
            + CGFloat(index) * segmentAngle
            + gap / 2.0
        let endAngle =
            -CGFloat.pi / 2.0
            + CGFloat(index + 1) * segmentAngle
            - gap / 2.0
        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: Angle(radians: Double(startAngle)),
            endAngle: Angle(radians: Double(endAngle)),
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: Angle(radians: Double(endAngle)),
            endAngle: Angle(radians: Double(startAngle)),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}
// MARK: - Leaf
private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        // Stem
        path.move(
            to: CGPoint(
                x: w * 0.58,
                y: h * 0.27
            )
        )
        path.addCurve(
            to: CGPoint(
                x: w * 0.69,
                y: h * 0.08
            ),
            control1: CGPoint(
                x: w * 0.59,
                y: h * 0.18
            ),
            control2: CGPoint(
                x: w * 0.65,
                y: h * 0.11
            )
        )
        // Leaf contour
        path.move(
            to: CGPoint(
                x: w * 0.64,
                y: h * 0.16
            )
        )
        path.addCurve(
            to: CGPoint(
                x: w * 0.88,
                y: h * 0.08
            ),
            control1: CGPoint(
                x: w * 0.74,
                y: h * 0.08
            ),
            control2: CGPoint(
                x: w * 0.84,
                y: h * 0.05
            )
        )
        path.addCurve(
            to: CGPoint(
                x: w * 0.69,
                y: h * 0.28
            ),
            control1: CGPoint(
                x: w * 0.87,
                y: h * 0.21
            ),
            control2: CGPoint(
                x: w * 0.76,
                y: h * 0.27
            )
        )
        path.addCurve(
            to: CGPoint(
                x: w * 0.64,
                y: h * 0.16
            ),
            control1: CGPoint(
                x: w * 0.67,
                y: h * 0.24
            ),
            control2: CGPoint(
                x: w * 0.64,
                y: h * 0.19
            )
        )
        return path
    }
}

ContentView.swift

:::writing{variant=“document” id=“74106”}

import SwiftUI
struct ContentView: View {
    @State private var batteryLevel: Double = 80
    @State private var isCharging = true
    @State private var outlineProgress: Double = 1.0
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Spacer()
                ChargingLogoView(
                    progress: batteryLevel,
                    outlineProgress: outlineProgress,
                    isCharging: isCharging
                )
                .frame(width: 160, height: 160)
                Text("\(Int(batteryLevel))%")
                    .font(
                        .system(
                            size: 34,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                Spacer()
                VStack(spacing: 16) {
                    Slider(
                        value: $batteryLevel,
                        in: 0...100,
                        step: 1
                    )
                    .padding(.horizontal, 40)
                    Button {
                        isCharging.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Image(
                                systemName: isCharging
                                    ? "bolt.fill"
                                    : "power"
                            )
                            Text(
                                isCharging
                                    ? "Отключить зарядку"
                                    : "Подключить зарядку"
                            )
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    isCharging
                                        ? Color.red.opacity(0.8)
                                        : Color.green.opacity(0.8)
                                )
                        )
                    }
                    .padding(.horizontal, 30)
                }
                Spacer()
                    .frame(height: 20)
            }
        }
    }
}
#Preview {
    ContentView()
}
