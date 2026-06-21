import SwiftUI

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let days: Int
    let subtitle: String
    let unlock: String

    static let all: [Achievement] = [
        Achievement(id: "first-drop", title: "First Light", days: 1, subtitle: "The vessel catches its first glow.", unlock: "First light recorded"),
        Achievement(id: "one-week", title: "One Week", days: 7, subtitle: "Seven days held without a break.", unlock: "Weekly mark held"),
        Achievement(id: "one-moon", title: "One Month", days: 30, subtitle: "A full month of discipline.", unlock: "Beaker unlocked"),
        Achievement(id: "iron-discipline", title: "Ninety Days", days: 90, subtitle: "A season kept.", unlock: "Carafe unlocked"),
        Achievement(id: "ascension", title: "One Year", days: 365, subtitle: "The reservoir, filled.", unlock: "Reservoir unlocked")
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
        case .apprentice: return "Phial"
        case .alchemist: return "Beaker"
        case .dragon: return "Carafe"
        case .cosmic: return "Reservoir"
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
        case .apprentice: return "Clear glass for the first measure."
        case .alchemist: return "A wider vessel with finer marks."
        case .dragon: return "Tall glass for a longer season."
        case .cosmic: return "The full reservoir, held steady."
        }
    }

    var liquidColors: [UIColor] {
        switch self {
        case .apprentice: return [UIColor(red: 0.13, green: 0.75, blue: 0.82, alpha: 1), UIColor(red: 0.04, green: 0.51, blue: 0.58, alpha: 1)]
        case .alchemist: return [UIColor(red: 0.18, green: 0.82, blue: 0.88, alpha: 1), UIColor(red: 0.05, green: 0.55, blue: 0.62, alpha: 1)]
        case .dragon: return [UIColor(red: 0.27, green: 0.84, blue: 0.90, alpha: 1), UIColor(red: 0.07, green: 0.48, blue: 0.55, alpha: 1)]
        case .cosmic: return [UIColor(red: 0.49, green: 0.92, blue: 0.96, alpha: 1), UIColor(red: 0.11, green: 0.49, blue: 0.55, alpha: 1)]
        }
    }

    var glowColor: Color {
        switch self {
        case .apprentice: return Color(red: 0.13, green: 0.75, blue: 0.82)
        case .alchemist: return Color(red: 0.18, green: 0.82, blue: 0.88)
        case .dragon: return Color(red: 0.27, green: 0.84, blue: 0.90)
        case .cosmic: return Color(red: 0.49, green: 0.92, blue: 0.96)
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
