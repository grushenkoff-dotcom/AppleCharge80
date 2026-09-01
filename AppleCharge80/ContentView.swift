import SwiftUI

struct ContentView: View {
    @State private var progress: Double = 0.0
    @State private var isCharging = false
    @State private var outlineProgress: Double = 0.0
    @State private var showControls = true
    @State private var sequenceTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                ChargingLogoView(
                    progress: progress,
                    outlineProgress: outlineProgress,
                    isCharging: isCharging
                )
                .frame(
                    width: min(proxy.size.width * 0.82, 360),
                    height: min(proxy.size.width * 0.82, 360)
                )
                // Верхняя треть экрана.
                .position(
                    x: proxy.size.width / 2,
                    y: proxy.size.height * 0.29
                )

                if showControls {
                    VStack(spacing: 14) {
                        Spacer()

                        Text("\(Int((progress * 100).rounded()))%")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .monospacedDigit()

                        Slider(value: $progress, in: 0...1)
                            .tint(.white.opacity(0.7))
                            .padding(.horizontal, 28)

                        HStack(spacing: 12) {
                            Button("Подключить зарядку") {
                                startChargingDemo()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("100%") {
                                sequenceTask?.cancel()
                                isCharging = true

                                withAnimation(.easeInOut(duration: 0.8)) {
                                    outlineProgress = 1
                                    progress = 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }

                        Button("Скрыть управление") {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showControls = false
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.bottom, 24)
                } else {
                    VStack {
                        HStack {
                            Spacer()

                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showControls = true
                                }
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundStyle(.white.opacity(0.45))
                                    .padding(12)
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            sequenceTask?.cancel()
        }
    }

    private func startChargingDemo() {
        sequenceTask?.cancel()

        progress = 0
        outlineProgress = 0
        isCharging = true

        sequenceTask = Task { @MainActor in
            withAnimation(.easeInOut(duration: 1.0)) {
                outlineProgress = 1.0
            }

            try? await Task.sleep(for: .milliseconds(1000))
            if Task.isCancelled { return }

            withAnimation(.easeInOut(duration: 0.45)) {
                outlineProgress = 0.0
            }

            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled { return }

            // Последовательное заполнение.
            // Листик внутри ChargingLogoView разрешается только при progress == 1.
            withAnimation(.easeInOut(duration: 14.0)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Charging Logo

private struct ChargingLogoView: View {
    let progress: Double
    let outlineProgress: Double
    let isCharging: Bool

    @State private var plantStartDate: Date?
    @State private var finishedGrowth = false

    private let sectorCount = 12

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                // Мягкие волны появляются только во время зарядки.
                if isCharging {
                    ChargingWaves(
                        time: now,
                        strength: progress >= 0.999 ? 0.34 : 0.20
                    )
                }

                // Очень мелкая "пыль".
                DustParticles(
                    time: now,
                    amount: 72,
                    active: isCharging
                )

                // Основная форма зарядки.
                ChargingSectors(
                    progress: progress,
                    time: now,
                    sectorCount: sectorCount,
                    frozen: finishedGrowth
                )

                // Растение НИКОГДА не появляется до полного заполнения.
                if progress >= 0.999 {
                    GrowingPlant(
                        time: now,
                        startDate: plantStartDate,
                        completed: finishedGrowth
                    )
                    .onAppear {
                        if plantStartDate == nil {
                            plantStartDate = Date()
                        }
                    }
                }

                if outlineProgress > 0 {
                    RoundedRectangle(cornerRadius: 30)
                        .trim(from: 0, to: outlineProgress)
                        .stroke(
                            .white.opacity(0.42),
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round
                            )
                        )
                        .padding(16)
                }
            }
            .onChange(of: progress) { _, newValue in
                if newValue < 0.999 {
                    plantStartDate = nil
                    finishedGrowth = false
                } else if plantStartDate == nil {
                    plantStartDate = Date()
                }
            }
            .onChange(of: plantStartDate) { _, newDate in
                guard let newDate else { return }

                // Рост длится примерно 5.5 секунды.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.6) {
                    guard plantStartDate == newDate else { return }
                    withAnimation(.easeInOut(duration: 1.2)) {
                        finishedGrowth = true
                    }
                }
            }
        }
    }
}

// MARK: - Sectors

private struct ChargingSectors: View {
    let progress: Double
    let time: TimeInterval
    let sectorCount: Int
    let frozen: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size * 0.245

            ZStack {
                ForEach(0..<sectorCount, id: \.self) { index in
                    let sectorFraction = 1.0 / Double(sectorCount)
                    let localProgress = min(
                        1,
                        max(0, (progress - Double(index) * sectorFraction) / sectorFraction)
                    )

                    // Сектор остаётся на своём месте.
                    // Никакого перемешивания, вращения или смены порядка.
                    let layerDepth = sectorCount - index
                    let amplitude = frozen ? 0 : 1.0 / Double(max(layerDepth, 1))
                    let speed = 0.55 + Double(index) * 0.025

                    let wobbleX = sin(time * speed + Double(index) * 1.71) * size * 0.012 * amplitude
                    let wobbleY = cos(time * speed * 0.83 + Double(index) * 2.13) * size * 0.009 * amplitude

                    ChargingSectorShape(
                        startAngle: -90 + Double(index) * (360.0 / Double(sectorCount)),
                        endAngle: -90 + Double(index + 1) * (360.0 / Double(sectorCount)),
                        progress: localProgress
                    )
                    .fill(
                        SectorColor(
                            index: index,
                            progress: progress,
                            time: time,
                            frozen: frozen
                        )
                    )
                    .frame(width: radius * 2.0, height: radius * 2.0)
                    .position(
                        x: center.x + wobbleX,
                        y: center.y + wobbleY
                    )
                    .opacity(localProgress > 0 ? 1 : 0)
                }
            }
        }
    }
}

private struct ChargingSectorShape: Shape {
    let startAngle: Double
    let endAngle: Double
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let fullAngle = endAngle - startAngle
        let visibleAngle = fullAngle * progress

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(startAngle + visibleAngle),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

private struct SectorColor: ShapeStyle {
    let index: Int
    let progress: Double
    let time: TimeInterval
    let frozen: Bool

    func _apply(to shape: inout _ShapeStyle_Shape) {
        let shimmer = frozen
            ? 0.5 + 0.5 * sin(time * 0.22 + Double(index) * 0.73)
            : 0.5

        let base = 0.48 + Double(index) * 0.018
        let value = min(0.82, base + shimmer * 0.12)

        shape.foregroundStyle(
            Color(
                hue: 0.24 + Double(index) * 0.003,
                saturation: 0.56,
                brightness: value
            )
        )
    }
}

// MARK: - Growing Plant

private struct GrowingPlant: View {
    let time: TimeInterval
    let startDate: Date?
    let completed: Bool

    private var growth: Double {
        guard let startDate else { return 0 }

        let elapsed = time + Date().timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate
        let raw = min(1, max(0, elapsed / 5.6))

        // Неровный natural-growth easing:
        // быстрое вытягивание, короткие паузы, затем раскрытие листьев.
        return 1 - pow(1 - raw, 2.7)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let g = completed ? 1.0 : growth

            ZStack {
                // Главный стебель.
                PlantStem(progress: g)
                    .stroke(
                        Color(
                            red: 0.30,
                            green: 0.20,
                            blue: 0.08
                        ),
                        style: StrokeStyle(
                            lineWidth: max(2, size * 0.014),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                // Коричневые маленькие веточки с зелёными листьями.
                Branch(
                    progress: max(0, min(1, (g - 0.28) / 0.72)),
                    side: -1,
                    y: 0.44
                )

                Branch(
                    progress: max(0, min(1, (g - 0.43) / 0.57)),
                    side: 1,
                    y: 0.35
                )

                Branch(
                    progress: max(0, min(1, (g - 0.57) / 0.43)),
                    side: -1,
                    y: 0.25
                )

                Branch(
                    progress: max(0, min(1, (g - 0.70) / 0.30)),
                    side: 1,
                    y: 0.17
                )

                // Маленькие цветочки появляются ближе к завершению роста.
                Flower(
                    progress: max(0, min(1, (g - 0.78) / 0.22)),
                    x: 0.61,
                    y: 0.17
                )

                Flower(
                    progress: max(0, min(1, (g - 0.87) / 0.13)),
                    x: 0.37,
                    y: 0.25
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

private struct PlantStem: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let x = rect.midX
        let bottom = rect.maxY * 0.68
        let top = rect.minY + rect.height * 0.17 * (1 - progress)

        var path = Path()
        path.move(to: CGPoint(x: x, y: bottom))

        path.addCurve(
            to: CGPoint(x: x - rect.width * 0.035 * progress, y: top),
            control1: CGPoint(
                x: x - rect.width * 0.06 * progress,
                y: bottom - rect.height * 0.22 * progress
            ),
            control2: CGPoint(
                x: x + rect.width * 0.08 * progress,
                y: bottom - rect.height * 0.48 * progress
            )
        )

        return path
    }
}

private struct Branch: View {
    let progress: Double
    let side: CGFloat
    let y: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let baseX = w / 2
            let baseY = h * y
            let length = w * 0.16 * progress
            let endX = baseX + side * length
            let endY = baseY - h * 0.055 * progress

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: baseX, y: baseY))
                    path.addCurve(
                        to: CGPoint(x: endX, y: endY),
                        control1: CGPoint(
                            x: baseX + side * length * 0.35,
                            y: baseY - h * 0.015
                        ),
                        control2: CGPoint(
                            x: baseX + side * length * 0.72,
                            y: endY + h * 0.025
                        )
                    )
                }
                .stroke(
                    Color(
                        red: 0.31,
                        green: 0.19,
                        blue: 0.08
                    ),
                    style: StrokeStyle(
                        lineWidth: max(1.4, w * 0.009),
                        lineCap: .round
                    )
                )

                GrowingLeaf(
                    progress: progress,
                    x: endX,
                    y: endY,
                    angle: side * 25
                )

                GrowingLeaf(
                    progress: max(0, progress - 0.18),
                    x: baseX + side * length * 0.55,
                    y: baseY - h * 0.025 * progress,
                    angle: -side * 42
                )
            }
        }
    }
}

private struct GrowingLeaf: View {
    let progress: Double
    let x: CGFloat
    let y: CGFloat
    let angle: CGFloat

    var body: some View {
        let p = min(1, max(0, progress))
        let size = 10 + 16 * p

        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.33,
                            green: 0.63,
                            blue: 0.20
                        ),
                        Color(
                            red: 0.16,
                            green: 0.38,
                            blue: 0.10
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size, height: size * 0.55)
            .rotationEffect(.degrees(Double(angle)))
            .scaleEffect(x: 0.15 + 0.85 * p, y: 0.15 + 0.85 * p)
            .position(x: x, y: y)
            .opacity(p)
    }
}

private struct Flower: View {
    let progress: Double
    let x: CGFloat
    let y: CGFloat

    var body: some View {
        let p = min(1, max(0, progress))
        let size = 7 + 8 * p

        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(
                        Color(
                            red: 0.82,
                            green: 0.90,
                            blue: 0.50
                        )
                        .opacity(0.82)
                    )
                    .frame(width: size * 0.52, height: size * 0.52)
                    .offset(
                        x: cos(Double(index) * .pi * 2 / 5) * size * 0.24,
                        y: sin(Double(index) * .pi * 2 / 5) * size * 0.24
                    )
            }

            Circle()
                .fill(
                    Color(
                        red: 0.95,
                        green: 0.72,
                        blue: 0.22
                    )
                )
                .frame(width: size * 0.30, height: size * 0.30)
        }
        .scaleEffect(p)
        .opacity(p)
        .position(x: x * 1.0, y: y * 1.0)
    }
}

// MARK: - Waves

private struct ChargingWaves: View {
    let time: TimeInterval
    let strength: Double

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    let phase = time * 0.42 + Double(index) * 1.55
                    let scale = 0.52 + 0.15 * CGFloat((sin(phase) + 1) / 2)

                    Circle()
                        .stroke(
                            .white.opacity(
                                strength * (0.45 - Double(index) * 0.09)
                            ),
                            lineWidth: 1.1
                        )
                        .frame(
                            width: size * scale,
                            height: size * scale
                        )
                        .scaleEffect(
                            0.86 + 0.14 * CGFloat((sin(phase) + 1) / 2)
                        )
                }
            }
        }
    }
}

// MARK: - Dust

private struct DustParticles: View {
    let time: TimeInterval
    let amount: Int
    let active: Bool

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            Canvas { context, _ in
                guard active else { return }

                for index in 0..<amount {
                    let seed = Double(index)
                    let xBase = pseudoRandom(seed * 13.17)
                    let yBase = pseudoRandom(seed * 7.91 + 4.2)

                    let driftX = sin(time * (0.10 + xBase * 0.13) + seed) * width * 0.035
                    let driftY = cos(time * (0.08 + yBase * 0.12) + seed * 1.7) * height * 0.035

                    let x = width * xBase + driftX
                    let y = height * yBase + driftY

                    let radius = 0.7 + pseudoRandom(seed * 3.77) * 1.5
                    let opacity = 0.08 + pseudoRandom(seed * 9.31) * 0.38

                    context.opacity = opacity

                    context.fill(
                        Path(
                            ellipseIn: CGRect(
                                x: x - radius,
                                y: y - radius,
                                width: radius * 2,
                                height: radius * 2
                            )
                        ),
                        with: .color(.white)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func pseudoRandom(_ value: Double) -> Double {
        let x = sin(value * 12.9898) * 43758.5453
        return x - floor(x)
    }
}
