import SwiftUI

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let days: Int
    let subtitle: String
    let unlock: String

    static let all: [Achievement] = [
        Achievement(id: "first-drop", title: "First Drop", days: 1, subtitle: "The reservoir awakens.", unlock: "Aether shimmer"),
        Achievement(id: "one-week", title: "One Week", days: 7, subtitle: "A visible pool of discipline.", unlock: "Soft particle field"),
        Achievement(id: "one-moon", title: "One Moon", days: 30, subtitle: "A full lunar cycle retained.", unlock: "Alchemist Vessel + golden glow"),
        Achievement(id: "iron-discipline", title: "Iron Discipline", days: 90, subtitle: "Energy begins to move on its own.", unlock: "Dragon Blood Vial + internal currents"),
        Achievement(id: "ascension", title: "Ascension", days: 365, subtitle: "A legendary reservoir.", unlock: "Cosmic Reservoir + celestial effects")
    ]
}

enum VesselSkin: String, CaseIterable, Identifiable {
    case apprentice
    case alchemist
    case dragon
    case cosmic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apprentice: return "Apprentice Flask"
        case .alchemist: return "Alchemist Vessel"
        case .dragon: return "Dragon Blood Vial"
        case .cosmic: return "Cosmic Reservoir"
        }
    }

    var unlockDays: Int {
        switch self {
        case .apprentice: return 0
        case .alchemist: return 30
        case .dragon: return 90
        case .cosmic: return 365
        }
    }

    var description: String {
        switch self {
        case .apprentice: return "Clear hand-blown glass. A quiet beginning."
        case .alchemist: return "Etched crystal geometry that amplifies glow."
        case .dragon: return "Heavy obsidian glass with molten resonance."
        case .cosmic: return "A void-glass relic bending starlight inward."
        }
    }

    var liquidColors: [UIColor] {
        switch self {
        case .apprentice: return [UIColor(red: 0.45, green: 0.92, blue: 1.0, alpha: 1), UIColor(red: 0.12, green: 0.33, blue: 1.0, alpha: 1)]
        case .alchemist: return [UIColor(red: 1.0, green: 0.83, blue: 0.35, alpha: 1), UIColor(red: 0.2, green: 0.45, blue: 1.0, alpha: 1)]
        case .dragon: return [UIColor(red: 1.0, green: 0.38, blue: 0.25, alpha: 1), UIColor(red: 0.45, green: 0.04, blue: 0.08, alpha: 1)]
        case .cosmic: return [UIColor(red: 0.66, green: 0.52, blue: 1.0, alpha: 1), UIColor(red: 0.05, green: 0.12, blue: 0.38, alpha: 1)]
        }
    }

    var glowColor: Color {
        switch self {
        case .apprentice: return .cyan
        case .alchemist: return .yellow
        case .dragon: return .orange
        case .cosmic: return .purple
        }
    }
}

func fillFraction(for days: Int) -> Double {
    if days <= 0 { return 0 }
    if days < 7 { return 0.04 + Double(days) * 0.018 }
    if days < 30 { return 0.16 + (Double(days - 7) / 23.0) * 0.16 }
    if days < 90 { return 0.32 + (Double(days - 30) / 60.0) * 0.24 }
    if days < 180 { return 0.56 + (Double(days - 90) / 90.0) * 0.15 }
    if days < 365 { return 0.71 + (Double(days - 180) / 185.0) * 0.19 }
    return min(0.97, 0.9 + log10(Double(days - 340)) * 0.035)
}

func glowStrength(for days: Int) -> Double {
    min(1.0, 0.12 + Double(days) / 180.0)
}
