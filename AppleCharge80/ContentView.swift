import SwiftUI

struct ContentView: View {
    @State private var testProgress: Double = 0.0
    @State private var testIsCharging = false
    @State private var chargingTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            ChargingLogoView(
                progress: testProgress,
                outlineProgress: 0,
                isCharging: testIsCharging
            )

            VStack {
                Spacer()

                VStack(spacing: 10) {
                    Button {
                        startTestCharging()
                    } label: {
                        Text("▶ ЗАРЯДКА 0 → 100%")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }

                    Button {
                        disconnectTest()
                    } label: {
                        Text("⏏ ОТКЛЮЧИТЬ")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }

                    HStack(spacing: 10) {
                        Button {
                            setTestProgress(0.50)
                        } label: {
                            Text("⚡ 50%")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                        }

                        Button {
                            resetTest()
                        } label: {
                            Text("↺ СБРОС")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onDisappear {
            chargingTask?.cancel()
        }
    }

    // MARK: - Test controls

    private func startTestCharging() {
        chargingTask?.cancel()

        testProgress = 0
        testIsCharging = true

        chargingTask = Task {
            let duration: Double = 8.0
            let frameTime: UInt64 = 16_666_667

            for frame in 0...480 {
                if Task.isCancelled {
                    return
                }

                let progress = Double(frame) / 480.0

                await MainActor.run {
                    testProgress = progress
                    testIsCharging = true
                }

                try? await Task.sleep(nanoseconds: frameTime)
            }

            await MainActor.run {
                testProgress = 1.0
                testIsCharging = true
            }
        }
    }

    private func disconnectTest() {
        chargingTask?.cancel()

        // Оставляем текущий уровень и сообщаем ChargingLogoView,
        // что питание отключено. Он запускает свою 3-секундную
        // последовательность случайного исчезновения.
        testIsCharging = false
    }

    private func setTestProgress(_ value: Double) {
        chargingTask?.cancel()

        testProgress = value
        testIsCharging = true
    }

    private func resetTest() {
        chargingTask?.cancel()

        testProgress = 0.0
        testIsCharging = false
    }
}
