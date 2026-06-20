import Combine
import CoreHaptics
import UIKit

@MainActor
final class HapticsEngine: ObservableObject {
    private var engine: CHHapticEngine?

    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    func softTick() {
        play(intensity: 0.18, sharpness: 0.2, duration: 0.04)
    }

    func successBloom() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }
        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.28),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.18)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.12),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.08)
            ], relativeTime: 0.05, duration: 0.22)
        ]
        play(events: events)
    }

    func releaseCrack() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.38),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.72)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.12)
            ], relativeTime: 0.08, duration: 0.36)
        ]
        play(events: events)
    }

    private func play(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: CGFloat(intensity))
            return
        }
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        ], relativeTime: 0, duration: duration)
        play(events: [event])
    }

    private func play(events: [CHHapticEvent]) {
        do {
            if engine == nil { prepare() }
            try engine?.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}
