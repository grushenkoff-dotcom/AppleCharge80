import SwiftUI
import UIKit

struct ContentView: View {

    @State private var batteryLevel: Double = 0.0
    @State private var isCharging = false

    var body: some View {
        ChargingLogoView(
            progress: batteryLevel,
            outlineProgress: 0,
            isCharging: isCharging
        )
        .preferredColorScheme(.dark)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            updateBatteryState()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIDevice.batteryLevelDidChangeNotification
            )
        ) { _ in
            updateBatteryState()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIDevice.batteryStateDidChangeNotification
            )
        ) { _ in
            updateBatteryState()
        }
        .onDisappear {
            UIDevice.current.isBatteryMonitoringEnabled = false
        }
    }

    private func updateBatteryState() {
        let level = UIDevice.current.batteryLevel

        if level >= 0 {
            batteryLevel = Double(level)
        } else {
            batteryLevel = 0
        }

        switch UIDevice.current.batteryState {
        case .charging, .full:
            isCharging = true

        case .unplugged, .unknown:
            isCharging = false

        @unknown default:
            isCharging = false
        }
    }
}
