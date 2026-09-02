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
    TimelineView(
        .animation(
            minimumInterval: 1.0 / 60.0,
            paused: false
        )
    ) { context in
        let now = context.date
        let disconnectElapsed =
            disconnectStart.map {
                now.timeIntervalSince($0)
            }
        let chargeElapsed =
            chargeStartDate.map {
                max(0, now.timeIntervalSince($0))
            } ?? 0
        let logoHeight: CGFloat = 181
        let logoWidth =
            logoHeight * 814.0 / 1000.0
        GeometryReader { geo in
            ZStack(alignment: .top) {
                PlantParticleField(
                    progress: progress,
                    isCharging: isCharging,
                    time: chargeElapsed,
                    logoHeight: logoHeight
                )
                .frame(
                    width: geo.size.width,
                    height: geo.size.height
                )
                AppleLogoFill(
                    progress: progress,
                    time: chargeElapsed,
                    disconnectElapsed: disconnectElapsed,
                    disconnectOrder: disconnectOrder
                )
                .frame(
                    width: logoWidth,
                    height: logoHeight
                )
                .padding(
                    .top,
                    max(
                        42,
                        geo.size.height * 0.075
                    )
                )
            }
            .frame(
                width: geo.size.width,
                height: geo.size.height,
                alignment: .top
            )
        }
        .onAppear {
            updateState(
                charging: isCharging,
                now: now
            )
        }
        .onChange(of: isCharging) { _, charging in
            updateState(
                charging: charging,
                now: now
            )
        }
    }
    .background(Color.black)
    .ignoresSafeArea()
}
private func updateState(
    charging: Bool,
    now: Date
) {
    if charging {
        disconnectStart = nil
        disconnectOrder.removeAll()
        chargeStartDate = now
    } else {
        if disconnectStart == nil {
            disconnectStart = now
        }
        if disconnectOrder.isEmpty {
            disconnectOrder =
                Array(0..<sectorCount).shuffled()
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
        let bodyTop =
            geo.size.height * 0.2443
        let bodyBottom =
            geo.size.height * 0.9999
        let bodyHeight =
            bodyBottom - bodyTop
        let bandHeight =
            bodyHeight / CGFloat(sectorCount)
        let normalizedProgress =
            max(
                0,
                min(1, progress)
            )
        let scaled =
            normalizedProgress *
            Double(sectorCount)
        let completed =
            min(
                sectorCount,
                Int(scaled)
            )
        let currentFraction =
            completed >= sectorCount
            ? 0
            : scaled - Double(completed)
        let leafGrowth =
            leafProgress
        let alive =
            normalizedProgress >= 1 &&
            disconnectElapsed == nil
        ZStack {
            // =================================================
            // COLOR LAYER
            // =================================================
            ZStack(alignment: .top) {
                ForEach(
                    0..<sectorCount,
                    id: \.self
                ) { index in
                    let visibility =
                        sectorVisibility(
                            index: index,
                            completed: completed,
                            currentFraction: currentFraction,
                            disconnectElapsed: disconnectElapsed
                        )
                    if visibility > 0.001 {
                        let pulse =
                            heartbeat(
                                time,
                                phase:
                                    Double(index) * 0.035
                            )
                        let intensity =
                            0.94 +
                            0.10 * pulse
                        Rectangle()
                            .fill(
                                sectorGradient(
                                    base: colors[index],
                                    index: index,
                                    time: time,
                                    intensity: intensity
                                )
                            )
                            .frame(
                                width: geo.size.width,
                                height: bandHeight + 1
                            )
                            .offset(
                                y:
                                    bodyTop +
                                    CGFloat(index) *
                                    bandHeight
                            )
                            .opacity(visibility)
                    }
                }
            }
            .clipShape(
                AppleBodyShape()
            )
            // =================================================
            // CONTACT GLOW
            // =================================================
            //
            // Только маленькое свечение в точке входа.
            // Оно не создает зеленой линии внутри Apple.
            //
            if normalizedProgress > 0.72 &&
                disconnectElapsed == nil {
                let contact =
                    smoothStep(
                        (normalizedProgress - 0.72) / 0.28
                    )
                let pulse =
                    heartbeat(
                        time,
                        phase: 0
                    )
                RadialGradient(
                    colors: [
                        Color(
                            red: 0.52,
                            green: 1.0,
                            blue: 0.38
                        )
                        .opacity(
                            0.20 *
                            contact *
                            (0.55 + 0.45 * pulse)
                        ),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.055
                )
                .frame(
                    width: geo.size.width * 0.16,
                    height: geo.size.height * 0.075
                )
                .position(
                    x: geo.size.width * 0.5,
                    y: bodyBottom - 1
                )
                .blur(radius: 2.2)
                .clipShape(
                    AppleBodyShape()
                )
            }
            // =================================================
            // EXTERNAL SOFT EDGE ONLY
            // =================================================
            AppleBodyShape()
                .stroke(
                    Color.white.opacity(
                        alive ? 0.27 : 0.20
                    ),
                    lineWidth: 1.05
                )
                .blur(radius: 4.5)
                .opacity(
                    alive ? 0.85 : 0.65
                )
            // =================================================
            // SHARP EDGE
            // =================================================
            AppleBodyShape()
                .stroke(
                    Color.white.opacity(
                        0.075 +
                        0.055 *
                        heartbeat(
                            time,
                            phase: 0
                        )
                    ),
                    lineWidth: 0.55
                )
            // =================================================
            // FILLED LEAF
            // =================================================
            if leafGrowth > 0 {
                AppleLeafShape()
                    .fill(
                        Color(
                            red: 0.42,
                            green: 0.78,
                            blue: 0.12
                        )
                    )
                    .opacity(
                        min(
                            1,
                            leafGrowth * 1.15
                        )
                    )
                AppleLeafShape()
                    .trim(
                        from: 0,
                        to: leafGrowth
                    )
                    .stroke(
                        Color(
                            red: 0.50,
                            green: 0.88,
                            blue: 0.18
                        ),
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .opacity(
                        min(
                            1,
                            leafGrowth * 1.15
                        )
                    )
            }
        }
    }
}
// MARK: - Sector Visibility
private func sectorVisibility(
    index: Int,
    completed: Int,
    currentFraction: Double,
    disconnectElapsed: TimeInterval?
) -> Double {
    guard let elapsed = disconnectElapsed else {
        if index < completed {
            return 1
        }
        if index == completed &&
            completed < sectorCount {
            return smoothStep(
                currentFraction
            )
        }
        return 0
    }
    guard
        let position =
            disconnectOrder.firstIndex(
                of: index
            )
    else {
        return 1
    }
    let start =
        Double(position) *
        sectorStartStep
    let local =
        elapsed - start
    if local <= 0 {
        return 1
    }
    if local >= sectorDuration {
        return 0
    }
    let t =
        local / sectorDuration
    return 1 -
        smoothStep(t)
}
// MARK: - Leaf Progress
private var leafProgress: Double {
    guard disconnectElapsed == nil else {
        return 0
    }
    guard progress >= 0.88 else {
        return 0
    }
    let t =
        (progress - 0.88) / 0.12
    return smoothStep(
        max(
            0,
            min(1, t)
        )
    )
}
// MARK: - Smooth Step
private func smoothStep(
    _ value: Double
) -> Double {
    let t =
        max(
            0,
            min(1, value)
        )
    return
        t * t *
        (3 - 2 * t)
}
// MARK: - Heartbeat
private func heartbeat(
    _ time: TimeInterval,
    phase: Double
) -> Double {
    let cycle =
        (time * 1.08 + phase)
            .truncatingRemainder(
                dividingBy: 1
            )
    let first =
        exp(
            -pow(
                (cycle - 0.095) / 0.052,
                2
            )
        )
    let second =
        exp(
            -pow(
                (cycle - 0.225) / 0.075,
                2
            )
        )
    return min(
        1,
        first * 0.95 +
        second * 0.52
    )
}
// MARK: - Sector Gradient
private func sectorGradient(
    base: SectorColor,
    index: Int,
    time: TimeInterval,
    intensity: Double
) -> LinearGradient {
    let pulse =
        heartbeat(
            time,
            phase:
                Double(index) * 0.035
        )
    let drift =
        0.5 +
        0.5 *
        sin(
            time * 0.72 +
            Double(index) * 0.85
        )
    let dark =
        base.color(
            multipliedBy:
                0.82 +
                0.08 * pulse +
                0.035 * drift
        )
    let mid =
        base.color(
            multipliedBy:
                intensity +
                0.045 * drift
        )
    let bright =
        base.color(
            multipliedBy:
                0.91 +
                0.14 * pulse +
                0.035 * drift
        )
    return LinearGradient(
        stops: [
            .init(
                color: dark,
                location: 0
            ),
            .init(
                color: mid,
                location: 0.32
            ),
            .init(
                color: bright,
                location: 0.55
            ),
            .init(
                color: mid,
                location: 0.76
            ),
            .init(
                color: dark,
                location: 1
            )
        ],
        startPoint: UnitPoint(
            x: 0.03 + 0.10 * pulse,
            y: 0
        ),
        endPoint: UnitPoint(
            x: 0.87 - 0.08 * pulse,
            y: 1
        )
    )
}

}

// MARK: - Sector Color

private struct SectorColor {

let r: Double
let g: Double
let b: Double
func color(
    multipliedBy factor: Double
) -> Color {
    Color(
        red: min(1, r * factor),
        green: min(1, g * factor),
        blue: min(1, b * factor)
    )
}

}

// MARK: - Plant Particle Field

private struct PlantParticleField: View {

let progress: Double
let isCharging: Bool
let time: TimeInterval
let logoHeight: CGFloat
var body: some View {
    Canvas { context, canvasSize in
        drawFlow(
            context: &context,
            canvasSize: canvasSize
        )
        drawPollen(
            context: &context,
            canvasSize: canvasSize
        )
    }
    .allowsHitTesting(false)
}
// MARK: - Growing Flow
private func drawFlow(
    context: inout GraphicsContext,
    canvasSize: CGSize
) {
    guard isCharging else {
        return
    }
    guard progress > 0 else {
        return
    }
    let logoTopY =
        max(
            42,
            canvasSize.height * 0.075
        )
    let logoBottomY =
        logoTopY +
        logoHeight
    // Поток растет снизу вверх.
    // Кончик входит непосредственно в нижнюю
    // границу формирующегося Apple.
    let startY =
        canvasSize.height + 24
    let targetY =
        logoBottomY + 1
    let travel =
        max(
            0,
            min(
                1,
                progress * 1.20
            )
        )
    let eased =
        easeOut(travel)
    let headY =
        startY -
        (startY - targetY) *
        CGFloat(eased)
    // ---------------------------------------------------------
    // Движение головы.
    // Не фиксированная центральная точка.
    // ---------------------------------------------------------
    let centerX =
        canvasSize.width * 0.5
    let phase =
        time * 1.15
    let bendA =
        sin(phase) *
        canvasSize.width *
        0.018
    let bendB =
        sin(
            phase * 0.63 + 1.4
        ) *
        canvasSize.width *
        0.012
    let headX =
        centerX +
        bendA +
        bendB
    // ---------------------------------------------------------
    // Короткий растущий стебель.
    // ---------------------------------------------------------
    let stemLength =
        min(
            canvasSize.height * 0.34,
            max(
                20,
                (startY - headY) * 0.30
            )
        )
    let tailY =
        headY +
        stemLength
    let tailWave =
        sin(
            phase * 0.8 + 0.7
        ) *
        canvasSize.width *
        0.025
    let tailX =
        centerX +
        tailWave
    // Поток остается очень узким,
    // но не превращается в математическую линию.
    let width =
        max(
            1.35,
            canvasSize.width * 0.0019
        )
    var path = Path()
    path.move(
        to: CGPoint(
            x: tailX,
            y: tailY
        )
    )
    path.addCurve(
        to: CGPoint(
            x: headX,
            y: headY
        ),
        control1: CGPoint(
            x:
                centerX -
                canvasSize.width * 0.055,
            y:
                tailY -
                stemLength * 0.28
        ),
        control2: CGPoint(
            x:
                centerX +
                canvasSize.width * 0.050,
            y:
                headY +
                stemLength * 0.30
        )
    )
    let opacity =
        0.22 *
        eased
    context.stroke(
        path,
        with: .color(
            Color(
                red: 0.42,
                green: 0.92,
                blue: 0.32
            )
            .opacity(opacity)
        ),
        style: StrokeStyle(
            lineWidth: width,
            lineCap: .round,
            lineJoin: .round
        )
    )
    // ---------------------------------------------------------
    // Светящийся кончик.
    // ---------------------------------------------------------
    let radius =
        max(
            1.0,
            canvasSize.width * 0.0023
        )
    let tipRect =
        CGRect(
            x: headX - radius,
            y: headY - radius,
            width: radius * 2,
            height: radius * 2
        )
    context.fill(
        Path(
            ellipseIn: tipRect
        ),
        with: .color(
            Color(
                red: 0.55,
                green: 1.0,
                blue: 0.40
            )
            .opacity(
                0.30 * eased
            )
        )
    )
}
// MARK: - Pollen
private func drawPollen(
    context: inout GraphicsContext,
    canvasSize: CGSize
) {
    guard isCharging else {
        return
    }
    guard progress > 0.05 else {
        return
    }
    let count = 28
    for index in 0..<count {
        let seed =
            Double(index) * 17.31
        let phase =
            seed.truncatingRemainder(
                dividingBy: 6.28318
            )
        let speed =
            0.18 +
            (
                seed.truncatingRemainder(
                    dividingBy: 100
                ) / 100
            ) * 0.22
        let t =
            (
                time * speed +
                phase
            )
            .truncatingRemainder(
                dividingBy: 1
            )
        let xBase =
            (
                seed * 7.17
            )
            .truncatingRemainder(
                dividingBy: 1
            )
        let x =
            canvasSize.width *
            (
                0.22 +
                0.56 * xBase
            )
        let y =
            canvasSize.height *
            (
                0.92 -
                0.68 * t
            )
        let radius =
            0.65 +
            (
                seed.truncatingRemainder(
                    dividingBy: 100
                ) / 100
            ) * 1.2
        let pulse =
            heartbeat(
                time,
                phase: phase
            )
        let opacity =
            0.08 +
            0.13 * pulse
        let rect =
            CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2,
                height: radius * 2
            )
        context.fill(
            Path(
                ellipseIn: rect
            ),
            with: .color(
                Color(
                    red: 0.46,
                    green: 0.88,
                    blue: 0.32
                )
                .opacity(opacity)
            )
        )
    }
}
// MARK: - Ease Out
private func easeOut(
    _ value: Double
) -> Double {
    let t =
        max(
            0,
            min(1, value)
        )
    return 1 -
        pow(
            1 - t,
            3
        )
}
// MARK: - Heartbeat
private func heartbeat(
    _ time: TimeInterval,
    phase: Double
) -> Double {
    let cycle =
        (time * 1.08 + phase)
            .truncatingRemainder(
                dividingBy: 1
            )
    let first =
        exp(
            -pow(
                (cycle - 0.095) / 0.052,
                2
            )
        )
    let second =
        exp(
            -pow(
                (cycle - 0.225) / 0.075,
                2
            )
        )
    return min(
        1,
        first * 0.95 +
        second * 0.52
    )
}

}
