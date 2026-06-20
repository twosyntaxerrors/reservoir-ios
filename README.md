# Reservoir Native iOS

Reservoir is a premium offline-first native iOS MVP that visualizes semen retention as a living glass vessel slowly filling with luminous energy over time.

## Stack

- SwiftUI app shell and interface
- SpriteKit interactive bottle/liquid scene
- CoreMotion accelerometer/gyroscope tilt input
- Core Haptics subtle feedback
- UserDefaults local streak persistence
- 60fps SpriteKit render target
- No backend

## Implemented

- Large glass vessel home-screen centerpiece
- Tilt-reactive 2D liquid surface with slosh, waves, bubbles, glow, and particles
- Streak progression visual states from first drop through cosmic reservoir
- Current streak, longest streak, and total retention days
- Daily check-in flow
- Relapse/reset flow with crack + draining/release animation state
- Achievements and unlockable vessels
- Preview +1 day control for quick visual QA

## Key files

- `ReservoirApp.swift` — SwiftUI entry point and environment objects
- `ContentView.swift` — home UI, actions, achievements, collection
- `ReservoirSpriteView.swift` — `UIViewRepresentable` SpriteKit bridge and 60fps vessel/liquid scene
- `MotionEngine.swift` — CoreMotion device motion at 60Hz
- `HapticsEngine.swift` — Core Haptics patterns with UIKit fallback
- `ReservoirStore.swift` — offline UserDefaults streak storage
- `ReservoirModels.swift` — progression curves, achievements, vessel definitions

## Build

Open `Reservoir.xcodeproj` in Xcode and run the `Reservoir` scheme on an iPhone simulator or device.

The project was bootstrapped with the Chorus/Vibecode SwiftUI template, which uses Xcode filesystem-synchronized groups, so added Swift files are auto-discovered by the project.
