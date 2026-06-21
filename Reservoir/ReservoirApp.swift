import SwiftUI

@main
struct ReservoirApp: App {
    @StateObject private var store = ReservoirStore()
    @StateObject private var motion = MotionEngine()
    @StateObject private var haptics = HapticsEngine()

    var body: some Scene {
        WindowGroup {
            ReservoirHomeView()
                .environmentObject(store)
                .environmentObject(motion)
                .environmentObject(haptics)
        }
    }
}
