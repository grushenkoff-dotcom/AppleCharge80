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
                    width: millimeters(30, in: proxy.size),
                    height: millimeters(30, in: proxy.size)
                )
                .position(
                    x: proxy.size.width / 2,
                    y: proxy.size.height * 0.46
                )

                if showControls {
                    VStack(spacing: 14) {
                        Spacer()

                        Text("\(Int(progress.rounded()))%")
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

    private func millimeters(_ mm: CGFloat, in size: CGSize) -> CGFloat {
        // iPhone screen points are not physical millimetres. For the first prototype
        // we use a conservative visual scale: 30 mm ≈ 113 pt.
        // Replace this with a calibrated scale if exact physical size is required.
        min(size.width * 0.31, 113)
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

            withAnimation(.easeInOut(duration: 14.0)) {
                progress = 1.0
            }
        }
    }
}
