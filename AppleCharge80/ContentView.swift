import SwiftUI

struct ContentView: View {
    @State private var progress: Double = 0
    @State private var isCharging = false
    @State private var outlineProgress: Double = 0   // совместимость с ChargingLogoView
    @State private var showControls = true
    @State private var sequenceTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // ВАЖНО: ChargingLogoView теперь полноэкранный.
            // Поэтому поток частиц физически начинается от нижнего края экрана,
            // а сам логотип внутри него фиксирован в верхней трети.
            ChargingLogoView(
                progress: progress,
                outlineProgress: outlineProgress,
                isCharging: isCharging
            )

            controls
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            sequenceTask?.cancel()
        }
    }

    @ViewBuilder
    private var controls: some View {
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

                    Button("Отключить") {
                        disconnectCharging()
                    }
                    .buttonStyle(.bordered)

                    Button("100%") {
                        sequenceTask?.cancel()
                        isCharging = true
                        withAnimation(.easeOut(duration: 0.8)) {
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
            .padding(.horizontal, 8)
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

    private func startChargingDemo() {
        sequenceTask?.cancel()

        progress = 0
        outlineProgress = 0
        isCharging = true

        sequenceTask = Task { @MainActor in
            // Небольшая фаза: частицы уже летят от низа,
            // нижний сектор ещё не начал линейно расти.
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }

            withAnimation(.linear(duration: 14.0)) {
                progress = 1
            }
        }
    }

    private func disconnectCharging() {
        sequenceTask?.cancel()
        isCharging = false
    }
}
