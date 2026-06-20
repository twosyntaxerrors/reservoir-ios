import Combine
import CoreMotion
import SwiftUI

struct MotionState: Equatable {
    var x: Double = 0
    var y: Double = 0
}

@MainActor
final class MotionEngine: ObservableObject {
    @Published private(set) var tilt = MotionState()
    @Published private(set) var angularVelocity: Double = 0

    private let manager = CMMotionManager()
    private let queue = OperationQueue()

    init() {
        queue.name = "Reservoir.MotionEngine"
        queue.qualityOfService = .userInteractive
    }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let gravity = motion.gravity
            let rotation = motion.rotationRate
            let angular = min(1.0, sqrt(rotation.x * rotation.x + rotation.y * rotation.y + rotation.z * rotation.z) / 5.0)
            Task { @MainActor in
                self.tilt = MotionState(x: max(-1, min(1, gravity.x)), y: max(-1, min(1, gravity.y)))
                self.angularVelocity = angular
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
