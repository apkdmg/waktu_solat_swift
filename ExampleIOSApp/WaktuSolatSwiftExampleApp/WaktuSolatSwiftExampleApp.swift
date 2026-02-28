import SwiftUI
import WaktuSolatSwift

@main
struct WaktuSolatSwiftExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: PrayerTimesViewModel())
        }
    }
}
