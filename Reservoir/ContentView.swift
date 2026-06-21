import SwiftUI
import SpriteKit

struct ReservoirHomeView: View {
    @EnvironmentObject private var store: ReservoirStore
    @EnvironmentObject private var motion: MotionEngine
    @EnvironmentObject private var haptics: HapticsEngine
    @State private var relapsePulse: Double = 0
    @State private var showingReset = false
    @State private var checkInBloom: Double = 0
    @State private var selectedTab: ReservoirTab = .today
    @State private var showingBackdate = false
    @State private var backdateSelection = Date()
    @AppStorage("reservoir.theme") private var themeRawValue = ReservoirTheme.light.rawValue

    private var accent: Color { store.primaryGlow }
    private var theme: ReservoirTheme {
        ReservoirTheme(rawValue: themeRawValue) ?? .light
    }

    var body: some View {
        ZStack {
            background

            Group {
                switch selectedTab {
                case .today:
                    todayDashboard
                case .milestones:
                    milestonesDashboard
                case .profile:
                    profileDashboard
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomNavigation
        }
        .onAppear {
            motion.start()
            haptics.prepare()
        }
        .onDisappear { motion.stop() }
        .preferredColorScheme(theme.colorScheme)
        .alert("Reset everything to 0?", isPresented: $showingReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset to 0", role: .destructive) { performReset() }
        } message: {
            Text("This clears current streak, longest streak, total retained days, last check-in, unlocked vessel choice, and relapse count.")
        }
    }

    // MARK: - Dashboards

    private var todayDashboard: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                heroHeader
                reservoirHeroCard
                statsGrid
                milestoneCallout
                checkInButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private var milestonesDashboard: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                screenTitle("Milestones", subtitle: "Unlocks and vessels")
                milestoneCallout
                vesselCollection
                achievements
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private var profileDashboard: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                screenTitle("Profile", subtitle: "Current reservoir")

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(accent)
                            .frame(width: 56, height: 56)
                            .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: ReservoirStyle.iconRadius, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reservoir")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(ReservoirStyle.textPrimary)
                            Text(store.selectedVessel.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(ReservoirStyle.textSecondary)
                        }

                        Spacer()
                    }

                    Divider()
                        .overlay(ReservoirStyle.hairline)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("APPEARANCE")
                            .font(.caption.weight(.bold))
                            .tracking(3)
                            .foregroundStyle(ReservoirStyle.textMuted)

                        HStack(spacing: 8) {
                            ForEach(ReservoirTheme.allCases) { option in
                                Button {
                                    themeRawValue = option.rawValue
                                    haptics.softTick()
                                } label: {
                                    Label(option.title, systemImage: option.systemImage)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.82)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(ThemeChipStyle(active: theme == option))
                            }
                        }
                    }

                    Divider()
                        .overlay(ReservoirStyle.hairline)

                    Button { showingReset = true } label: {
                        Label("Reset everything to 0", systemImage: "arrow.counterclockwise")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(GhostButtonStyle(tint: ReservoirStyle.coral))
                }
                .padding(16)
                .reservoirPanel()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private func screenTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RESERVOIR")
                .font(.caption.weight(.bold))
                .tracking(7)
                .foregroundStyle(ReservoirStyle.cyan)
            Text(title)
                .font(.system(size: 38, weight: .semibold, design: .default))
                .foregroundStyle(ReservoirStyle.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(ReservoirStyle.textSecondary)
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ReservoirStyle.canvas,
                    ReservoirStyle.canvas,
                    ReservoirStyle.canvasDeep
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    ReservoirStyle.cyan.opacity(0.06),
                    .clear,
                    ReservoirStyle.cyan.opacity(0.045)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var heroHeader: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                Text("RESERVOIR")
                    .font(.caption.weight(.bold))
                    .tracking(7)
                    .foregroundStyle(ReservoirStyle.cyan)

                VStack(alignment: .leading, spacing: -1) {
                    Text("Reservoir")
                        .foregroundStyle(ReservoirStyle.textPrimary)
                    Text("measured daily.")
                        .foregroundStyle(ReservoirStyle.cyanSoft)
                }
                .font(.system(size: 34, weight: .semibold, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button { showingReset = true } label: {
                Label("Reset to 0", systemImage: "arrow.counterclockwise")
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
            }
            .buttonStyle(UtilityButtonStyle(tint: ReservoirStyle.coral))
            .accessibilityLabel("Reset everything to zero")
        }
    }

    // MARK: - Hero

    private var reservoirHeroCard: some View {
        VStack(spacing: 0) {
            ZStack {
                heroAtmosphere

                GeometryReader { proxy in
                    let cardWidth = proxy.size.width

                    ZStack {
                        // The bottle is the centered hero. Metadata flanks it in the
                        // gutters (top-left + top-right) and is never drawn on top of it.
                        ReservoirSpriteView(
                            streak: store.currentStreak,
                            vessel: store.selectedVessel,
                            tilt: motion.tilt,
                            angularVelocity: motion.angularVelocity,
                            relapsePulse: relapsePulse
                        )
                        .frame(width: min(cardWidth * 0.40, 178), height: 300)
                        .offset(x: cardWidth * 0.09, y: 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        VStack(alignment: .leading, spacing: 14) {
                            heroDayBlock

                            statusPill(
                                relapsePulse > 0.04 ? "Start clean" : store.canCheckInToday ? "Ready to check in" : "Today secured",
                                systemImage: relapsePulse > 0.04 ? "arrow.counterclockwise" : store.canCheckInToday ? "drop.fill" : "checkmark.seal.fill"
                            )
                        }
                        .frame(width: cardWidth * 0.39, alignment: .leading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 20)
                        .padding(.top, 26)

                        ProgressRing(
                            progress: store.fillProgress,
                            accent: ReservoirStyle.cyan,
                            lineWidth: 9,
                            label: "FILLED"
                        )
                        .frame(width: min(cardWidth * 0.21, 104), height: min(cardWidth * 0.21, 104))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, 20)
                        .padding(.top, 28)
                    }
                }
            }
            .frame(height: 360)

            Divider()
                .overlay(ReservoirStyle.hairline)

            HStack(spacing: 0) {
                HeroInfoTile(title: "VESSEL", value: store.selectedVessel.title, systemImage: "flask.fill", tint: ReservoirStyle.cyan)
                Divider()
                    .overlay(ReservoirStyle.hairline)
                HeroInfoTile(title: "NEXT UNLOCK", value: store.nextAchievementTitle, systemImage: "flag.fill", tint: ReservoirStyle.cyan)
            }
            .frame(height: 86)
            .background(ReservoirStyle.panelSubtle)
        }
        .reservoirPanel(stroke: ReservoirStyle.hairline)
    }

    private var heroAtmosphere: some View {
        LinearGradient(
            colors: [
                ReservoirStyle.panelElevated,
                ReservoirStyle.panel,
                ReservoirStyle.canvasDeep.opacity(0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroDayBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DAY")
                .font(.caption.weight(.bold))
                .tracking(5)
                .foregroundStyle(ReservoirStyle.cyan)

            Text(dayDisplay)
                .font(.system(size: 78, weight: .light, design: .default))
                .foregroundStyle(ReservoirStyle.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.58)

            Text(store.milestoneText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ReservoirStyle.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
    }

    private var dayDisplay: String {
        store.currentStreak < 10 ? "0\(store.currentStreak)" : "\(store.currentStreak)"
    }

    private func statusPill(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(ReservoirStyle.cyan)
            Text(text)
                .font(.caption2.weight(.bold))
                .foregroundStyle(ReservoirStyle.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(ReservoirStyle.panelSubtle, in: Capsule())
        .overlay(Capsule().stroke(ReservoirStyle.hairline, lineWidth: 1))
    }

    // MARK: - Stats

    private var statsGrid: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(store.longestStreak)", label: "Longest streak", systemImage: "drop", tint: ReservoirStyle.cyan)
            StatTile(value: "\(store.totalRetentionDays)", label: "Total days", systemImage: "calendar.badge.checkmark", tint: ReservoirStyle.cyan)
        }
    }

    // MARK: - Milestone

    private var milestoneCallout: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MILESTONE")
                        .font(.caption.weight(.bold))
                        .tracking(4)
                        .foregroundStyle(ReservoirStyle.cyan)
                    Text(store.nextAchievementTitle)
                        .font(.system(size: 26, weight: .semibold, design: .default))
                        .foregroundStyle(ReservoirStyle.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }

                Spacer()

                Text(store.daysUntilNextAchievement > 0 ? "\(store.daysUntilNextAchievement)d" : "Done")
                    .font(.title3.weight(.black))
                    .foregroundStyle(ReservoirStyle.cyan)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 12)
                    .background(ReservoirStyle.panelSubtle, in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(ReservoirStyle.hairline, lineWidth: 1))
            }

            MilestoneBar(progress: store.achievementProgress, accent: ReservoirStyle.cyan)

            Text(store.daysUntilNextAchievement > 0
                 ? "\(store.daysUntilNextAchievement) retained days until the next unlock."
                 : "All milestone unlocks are complete.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ReservoirStyle.textSecondary)
        }
        .padding(20)
        .background {
            ZStack(alignment: .bottomTrailing) {
                ReservoirStyle.panel
                LinearGradient(
                    colors: [ReservoirStyle.cyan.opacity(0.04), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(ReservoirStyle.hairline, lineWidth: 1))
    }

    // MARK: - Actions

    private var checkInButton: some View {
        VStack(spacing: 12) {
            Button {
                registerCheckIn(on: Date())
            } label: {
                Label(store.canCheckInToday ? "Check In Today" : "Today Secured", systemImage: store.canCheckInToday ? "drop.fill" : "checkmark.seal.fill")
                    .font(.title3.weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
            .buttonStyle(PrimaryButtonStyle(disabled: !store.canCheckInToday))
            .disabled(!store.canCheckInToday)

            Button {
                backdateSelection = store.canCheckInToday ? Date() : (Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
                showingBackdate = true
            } label: {
                Label("Log a past day", systemImage: "calendar.badge.plus")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(GhostButtonStyle(tint: ReservoirStyle.cyanSoft))
        }
        .sheet(isPresented: $showingBackdate) {
            BackdateSheet(
                selection: $backdateSelection,
                earliest: store.earliestCheckInDate,
                unloggedThroughToday: { store.unloggedDaysThroughToday(from: $0) },
                onCatchUp: {
                    bloomCheckIn { store.checkInThroughToday(from: backdateSelection) }
                    showingBackdate = false
                },
                onCancel: { showingBackdate = false }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func registerCheckIn(on date: Date) {
        guard store.canCheckIn(on: date) else { return }
        bloomCheckIn { store.checkIn(on: date) }
    }

    private func bloomCheckIn(_ action: () -> Void) {
        action()
        haptics.successBloom()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { checkInBloom = 1 }
        withAnimation(.easeOut(duration: 0.9).delay(0.25)) { checkInBloom = 0 }
    }

    // MARK: - Collection

    private var vesselCollection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Vessels", systemImage: "flask.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(VesselSkin.allCases) { vessel in
                        VesselCard(
                            vessel: vessel,
                            unlocked: store.isUnlocked(vessel),
                            active: store.selectedVessel == vessel,
                            onSelect: {
                                store.selectVessel(vessel)
                                haptics.softTick()
                            }
                        )
                    }
                }
                .padding(.trailing, 18)
            }
        }
    }

    // MARK: - Achievements

    private var achievements: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Achievements", systemImage: "rosette")
            VStack(spacing: 8) {
                ForEach(Achievement.all) { achievement in
                    AchievementRow(
                        achievement: achievement,
                        unlocked: store.longestStreak >= achievement.days
                    )
                }
            }
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack(spacing: 0) {
            ForEach(ReservoirTab.allCases) { tab in
                Button {
                    selectedTab = tab
                    haptics.softTick()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 22, weight: .semibold))
                        Text(tab.title)
                            .font(.footnote.weight(.medium))
                    }
                    .foregroundStyle(selectedTab == tab ? ReservoirStyle.cyan : ReservoirStyle.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .background(ReservoirStyle.navigationBar)
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
                .stroke(ReservoirStyle.hairline, lineWidth: 1)
                .frame(height: 1)
        }
    }

    private func performReset() {
        withAnimation(.easeOut(duration: 0.15)) { relapsePulse = 1 }
        haptics.releaseCrack()
        store.reset()
        withAnimation(.easeOut(duration: 1.15).delay(0.1)) { relapsePulse = 0 }
    }
}

// MARK: - Tabs

private enum ReservoirTab: String, CaseIterable, Identifiable {
    case today
    case milestones
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .milestones: return "Milestones"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "drop.fill"
        case .milestones: return "flag.fill"
        case .profile: return "person.crop.circle"
        }
    }
}

// MARK: - Styling

private enum ReservoirTheme: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

private enum ReservoirStyle {
    static let radius: CGFloat = 14
    static let iconRadius: CGFloat = 7
    static let canvas = dynamic(light: UIColor(hex: 0xF4F2EC), dark: UIColor(hex: 0x08090C))
    static let canvasDeep = dynamic(light: UIColor(hex: 0xE7E5DF), dark: UIColor(hex: 0x111418))
    static let panel = dynamic(light: .white, dark: UIColor(hex: 0x15181C))
    static let panelElevated = dynamic(light: UIColor(hex: 0xFFFEFA), dark: UIColor(hex: 0x1B1F24))
    static let panelSubtle = dynamic(light: UIColor(hex: 0xF8F7F2), dark: UIColor(hex: 0x20252A))
    static let navigationBar = dynamic(light: UIColor(hex: 0xFFFEFA).withAlphaComponent(0.94), dark: UIColor(hex: 0x0D1013).withAlphaComponent(0.96))
    static let textPrimary = dynamic(light: UIColor(hex: 0x191B1D), dark: UIColor(hex: 0xEAF0F2))
    static let textSecondary = dynamic(light: UIColor(hex: 0x3C4145), dark: UIColor(hex: 0xAEB8BE))
    static let textMuted = dynamic(light: UIColor(hex: 0x6A7177), dark: UIColor(hex: 0x7C878E))
    static let hairline = dynamic(light: UIColor(hex: 0x141618).withAlphaComponent(0.08), dark: UIColor(hex: 0xEAF0F2).withAlphaComponent(0.10))
    static let ink = canvas
    static let panelStrong = dynamic(light: UIColor(hex: 0xECE9E0), dark: UIColor(hex: 0x252A30))
    static let cyan = dynamic(light: UIColor(hex: 0x0FA6B8), dark: UIColor(hex: 0x46D7E6))
    static let cyanSoft = dynamic(light: UIColor(hex: 0x22BFD1), dark: UIColor(hex: 0x7CEBF4))
    static let cyanDeep = dynamic(light: UIColor(hex: 0x0B8294), dark: UIColor(hex: 0x1C7E8C))
    static let gold = Color(red: 0.96, green: 0.70, blue: 0.25)
    static let mint = Color(red: 0.46, green: 0.91, blue: 0.74)
    static let coral = dynamic(light: UIColor(hex: 0xD8463C), dark: UIColor(hex: 0xFF4438))

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light })
    }
}

private extension View {
    func reservoirPanel(stroke: Color = ReservoirStyle.hairline) -> some View {
        let shape = RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
        return self
            .background(ReservoirStyle.panel, in: shape)
            .overlay(shape.stroke(stroke, lineWidth: 1))
    }
}

private extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Progress Ring

private struct ProgressRing: View {
    let progress: Double
    let accent: Color
    var lineWidth: CGFloat = 9
    var label = "FILLED"

    var body: some View {
        ZStack {
            Circle()
                .stroke(ReservoirStyle.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    LinearGradient(colors: [ReservoirStyle.cyanSoft, accent], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-82))

            VStack(spacing: 3) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(ReservoirStyle.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(label)
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(ReservoirStyle.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 6)
        }
        .animation(.easeInOut(duration: 0.6), value: progress)
    }
}

// MARK: - Milestone Bar

private struct MilestoneBar: View {
    let progress: Double
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(ReservoirStyle.panelSubtle)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(LinearGradient(colors: [ReservoirStyle.cyan, ReservoirStyle.cyanSoft], startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * max(0, min(1, progress)))
            }
        }
        .frame(height: 8)
        .animation(.easeInOut(duration: 0.6), value: progress)
    }
}

// MARK: - Section Title

private struct SectionTitle: View {
    let title: String
    let systemImage: String

    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ReservoirStyle.textMuted)
            Text(title)
                .font(.system(.headline, design: .default).weight(.semibold))
                .foregroundStyle(ReservoirStyle.textPrimary)
        }
    }
}

// MARK: - Hero Info Tile

private struct HeroInfoTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: ReservoirStyle.iconRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(ReservoirStyle.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ReservoirStyle.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Stat Tile

private struct StatTile: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(tint)
                .frame(height: 28)

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 34, weight: .semibold, design: .default))
                .foregroundStyle(ReservoirStyle.textPrimary)
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ReservoirStyle.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 142)
        .padding(18)
        .reservoirPanel()
    }
}

// MARK: - Vessel Card

private struct VesselCard: View {
    let vessel: VesselSkin
    let unlocked: Bool
    let active: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(vessel.glowColor)
                        .frame(width: 18, height: 18)
                        .shadow(color: vessel.glowColor.opacity(active ? 0.75 : 0.25), radius: active ? 8 : 2)
                    Spacer()
                    Image(systemName: unlocked ? (active ? "checkmark.circle.fill" : "circle") : "lock.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(active ? ReservoirStyle.cyan : ReservoirStyle.textMuted)
                }

                Spacer(minLength: 0)

                Text(vessel.title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .lineLimit(3)
                    .foregroundStyle(ReservoirStyle.textSecondary)
            }
            .foregroundStyle(ReservoirStyle.textPrimary)
            .frame(width: 166, height: 132, alignment: .topLeading)
            .padding(14)
            .background(background, in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(stroke, lineWidth: active ? 1.5 : 1))
            .opacity(unlocked ? 1 : 0.48)
        }
        .disabled(!unlocked)
        .accessibilityLabel("\(vessel.title), \(subtitle)")
    }

    private var subtitle: String {
        unlocked ? vessel.description : "Unlocks at \(vessel.unlockDays) days"
    }

    private var background: Color {
        active ? ReservoirStyle.cyan.opacity(0.10) : ReservoirStyle.panel
    }

    private var stroke: Color {
        active ? ReservoirStyle.cyan.opacity(0.70) : ReservoirStyle.hairline
    }
}

// MARK: - Achievement Row

private struct AchievementRow: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: ReservoirStyle.iconRadius, style: .continuous)
                    .fill(unlocked ? ReservoirStyle.cyan.opacity(0.14) : ReservoirStyle.panelSubtle)
                    .frame(width: 42, height: 42)
                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(unlocked ? ReservoirStyle.cyan : ReservoirStyle.textMuted)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ReservoirStyle.textPrimary)
                Text(unlocked ? achievement.unlock : achievement.subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(ReservoirStyle.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Text("\(achievement.days)d")
                .font(.caption.weight(.black))
                .foregroundStyle(unlocked ? ReservoirStyle.cyan : ReservoirStyle.textMuted)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(ReservoirStyle.panelSubtle, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .padding(12)
        .background(background, in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(stroke, lineWidth: 1))
    }

    private var background: Color {
        unlocked ? ReservoirStyle.cyan.opacity(0.07) : ReservoirStyle.panel
    }

    private var stroke: Color {
        unlocked ? ReservoirStyle.cyan.opacity(0.26) : ReservoirStyle.hairline
    }
}

// MARK: - Decorative Shape

private struct MountainSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY - rect.height * 0.10))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.24))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.maxY - rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.74, y: rect.maxY - rect.height * 0.42))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Backdate Sheet

private struct BackdateSheet: View {
    @Binding var selection: Date
    let unloggedThroughToday: (Date) -> Int
    let onCatchUp: () -> Void
    let onCancel: () -> Void

    /// Captured once so the range identity is stable across re-renders
    /// (a range whose bounds recompute every render breaks date selection).
    @State private var range: ClosedRange<Date>

    init(selection: Binding<Date>, earliest: Date, unloggedThroughToday: @escaping (Date) -> Int, onCatchUp: @escaping () -> Void, onCancel: @escaping () -> Void) {
        _selection = selection
        self.unloggedThroughToday = unloggedThroughToday
        self.onCatchUp = onCatchUp
        self.onCancel = onCancel
        _range = State(initialValue: earliest...Date())
    }

    private var fillCount: Int { unloggedThroughToday(selection) }
    private var isToday: Bool { Calendar.current.isDateInToday(selection) }

    var body: some View {
        ZStack {
            ReservoirStyle.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LOG DAYS")
                        .font(.caption.weight(.bold))
                        .tracking(5)
                        .foregroundStyle(ReservoirStyle.cyan)
                    Text("Catch up your streak")
                        .font(.system(size: 26, weight: .semibold, design: .default))
                        .foregroundStyle(ReservoirStyle.textPrimary)
                    Text("Pick the day you started. Catching up logs every day from then through today so your streak counts them.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ReservoirStyle.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                DatePicker(
                    "Day",
                    selection: $selection,
                    in: range,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .tint(ReservoirStyle.cyan)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .reservoirPanel()

                Spacer(minLength: 0)

                Button(action: onCatchUp) {
                    Label(catchUpTitle, systemImage: "drop.fill")
                        .font(.title3.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(PrimaryButtonStyle(disabled: fillCount == 0))
                .disabled(fillCount == 0)

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(GhostButtonStyle(tint: ReservoirStyle.textSecondary))
            }
            .padding(20)
        }
    }

    private var catchUpTitle: String {
        if fillCount == 0 { return "All caught up" }
        if isToday { return "Check In Today" }
        return "Catch Up to Today (\(fillCount) day\(fillCount == 1 ? "" : "s"))"
    }
}

// MARK: - Button Styles

private struct PrimaryButtonStyle: ButtonStyle {
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(disabled ? ReservoirStyle.textMuted : Color.white)
            .background(background, in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
                    .stroke(disabled ? ReservoirStyle.hairline : ReservoirStyle.cyan.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: ReservoirStyle.cyan.opacity(disabled ? 0 : 0.18), radius: configuration.isPressed ? 2 : 7, y: 3)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder private var background: some View {
        if disabled {
            ReservoirStyle.panelStrong
        } else {
            LinearGradient(
                colors: [ReservoirStyle.cyanSoft, ReservoirStyle.cyanDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct GhostButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tint)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(tint.opacity(0.22), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct UtilityButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tint)
            .background(ReservoirStyle.panelSubtle, in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(ReservoirStyle.hairline, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct ThemeChipStyle: ButtonStyle {
    let active: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(active ? ReservoirStyle.textPrimary : ReservoirStyle.textMuted)
            .background(active ? ReservoirStyle.panelElevated : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(active ? ReservoirStyle.hairline : Color.clear, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
