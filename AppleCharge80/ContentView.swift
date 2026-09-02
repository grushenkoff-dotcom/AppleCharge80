import SwiftUI

struct ContentView: View {
    @State private var batteryLevel: Double = 80
    @State private var isCharging = true
    @State private var outlineProgress: Double = 1

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ChargingLogoView(
                    progress: batteryLevel,
                    outlineProgress: outlineProgress,
                    isCharging: isCharging
                )
                .frame(width: 160, height: 160)

                Text("\(Int(batteryLevel))%")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                VStack(spacing: 16) {
                    Slider(
                        value: $batteryLevel,
                        in: 0...100,
                        step: 1
                    )
                    .padding(.horizontal, 36)

                    Button {
                        isCharging.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isCharging ? "bolt.fill" : "power")

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
