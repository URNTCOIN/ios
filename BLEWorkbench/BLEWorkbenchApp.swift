import SwiftUI

@main
struct BLEWorkbenchApp: App {
    @StateObject private var bluetooth = BluetoothLab()

    var body: some Scene {
        WindowGroup {
            WorkbenchTabs()
                .environmentObject(bluetooth)
                .preferredColorScheme(.light)
                .tint(LabTheme.sage)
        }
    }
}

enum LabTheme {
    static let ink = Color(red: 0.13, green: 0.16, blue: 0.14)
    static let secondary = Color(red: 0.43, green: 0.48, blue: 0.43)
    static let sage = Color(red: 0.47, green: 0.59, blue: 0.47)
    static let paleSage = Color(red: 0.91, green: 0.94, blue: 0.90)
    static let canvas = Color(red: 0.95, green: 0.96, blue: 0.93)
}
