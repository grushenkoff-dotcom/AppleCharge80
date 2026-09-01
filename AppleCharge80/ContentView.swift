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
                // ---------------------------------------------------------
                // Логотип.
                //
                // Размер уменьшен примерно вдвое относительно старой
                // версии: было 82% ширины, теперь 41%.
                //
                // Положение фиксированное — верхняя треть экрана.
                // ---------------------------------------------------------
                ChargingLogoView(
                    progress: progress,
                    outlineProgress: outlineProgress,
                    isCharging: isCharging
                )
                .frame(
                    width: min(
                        proxy.size.width * 0.41,
                        180
                    ),
                    height: min(
                        proxy.size.width * 0.41,
                        180
                    )
                )
                .position(
                    x: proxy.size.width / 2.0,
                    y: proxy.size.height * 0.29
                )
                // ---------------------------------------------------------
                // Служебное управление демонстрацией.
                // ---------------------------------------------------------
                if showControls {
                    VStack(spacing: 14) {
                        Spacer()
                        Text(
                            "\(Int((progress * 100).rounded()))%"
                        )
                        .font(
                            .system(
                                size: 18,
                                weight: .medium,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(
                            .white.opacity(0.72)
                        )
                        .monospacedDigit()
                        Slider(
                            value: $progress,
                            in: 0...1
                        )
                        .tint(
                            .white.opacity(0.7)
                        )
                        .padding(
                            .horizontal,
                            28
                        )
                        HStack(spacing: 10) {
                            Button(
                                "Подключить"
                            ) {
                                startChargingDemo()
                            }
                            .buttonStyle(
                                .borderedProminent
                            )
                            Button(
                                "Отключить"
                            ) {
                                disconnectCharging()
                            }
                            .buttonStyle(
                                .bordered
                            )
                            Button(
                                "100%"
                            ) {
                                completeCharging()
                            }
                            .buttonStyle(
                                .bordered
                            )
                        }
                        Button(
                            "Скрыть управление"
                        ) {
                            withAnimation(
                                .easeInOut(
                                    duration: 0.25
                                )
                            ) {
                                showControls = false
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(
                            .white.opacity(0.45)
                        )
                    }
                    .padding(.bottom, 24)
                } else {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(
                                    .easeInOut(
                                        duration: 0.25
                                    )
                                ) {
                                    showControls = true
                                }
                            } label: {
                                Image(
                                    systemName:
                                        "slider.horizontal.3"
                                )
                                .foregroundStyle(
                                    .white.opacity(0.45)
                                )
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
    // MARK: - Start
    private func startChargingDemo() {
        sequenceTask?.cancel()
        // Полный сброс предыдущей анимации.
        progress = 0.0
        outlineProgress = 0.0
        isCharging = true
        sequenceTask = Task { @MainActor in
            // Небольшое появление контура.
            withAnimation(
                .easeOut(duration: 0.35)
            ) {
                outlineProgress = 1.0
            }
            try? await Task.sleep(
                for: .milliseconds(450)
            )
            if Task.isCancelled {
                return
            }
            // Контур становится практически незаметным.
            withAnimation(
                .easeOut(duration: 0.30)
            ) {
                outlineProgress = 0.0
            }
            try? await Task.sleep(
                for: .milliseconds(180)
            )
            if Task.isCancelled {
                return
            }
            // -------------------------------------------------------------
            // ОСНОВНАЯ АНИМАЦИЯ.
            //
            // 0.00 → 1.00
            //
            // ChargingLogoView сама распределяет это время:
            //
            // нижний сектор
            // ↓
            // следующие сектора
            // ↓
            // верхний лист
            // ↓
            // готовый логотип
            // -------------------------------------------------------------
            withAnimation(
                .linear(duration: 14.0)
            ) {
                progress = 1.0
            }
        }
    }
    // MARK: - Complete
    private func completeCharging() {
        sequenceTask?.cancel()
        isCharging = true
        withAnimation(
            .easeInOut(duration: 1.0)
        ) {
            progress = 1.0
            outlineProgress = 0.0
        }
    }
    // MARK: - Disconnect
    private func disconnectCharging() {
        sequenceTask?.cancel()
        // ВАЖНО:
        // progress не сбрасываем здесь.
        //
        // ChargingLogoView получает isCharging == false
        // и самостоятельно запускает плавное растворение.
        isCharging = false
    }
}