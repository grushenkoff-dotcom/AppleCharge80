import SwiftUI
import UIKit

struct ContentView: View {

    @State private var batteryLevel: Float = 0.0
    @State private var isCharging: Bool = false

    var body: some View {
        ChargingLogoView(
            progress: Double(batteryLevel),
            outlineProgress: 0,
            isCharging: isCharging
        )
        .preferredColorScheme(.dark)
        .onAppear {
            startBatteryMonitoring()
            updateBatteryState()
        }
        .onDisappear {
            UIDevice.current.isBatteryMonitoringEnabled = false
        }
    }

    // MARK: - Battery

    private func startBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        updateBatteryState()
    }

    private func updateBatteryState() {
        let level = UIDevice.current.batteryLevel

        if level >= 0 {
            batteryLevel = level
        } else {
            batteryLevel = 0
        }

        switch UIDevice.current.batteryState {
        case .charging,
             .full:
            isCharging = true

        default:
            isCharging = false
        }
    }
}
