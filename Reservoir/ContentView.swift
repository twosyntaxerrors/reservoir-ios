import SwiftUI
import SpriteKit

struct ReservoirHomeView: View {
    @EnvironmentObject private var store: ReservoirStore
    @EnvironmentObject private var motion: MotionEngine
    @EnvironmentObject private var haptics: HapticsEngine
    @State private var relapsePulse: Double = 0
    @State private var showingReset = false
    @State private var ambientPhase: Double = 0
    @State private var checkInBloom: Double = 0
    @State private var selectedTab: ReservoirTab = .today

    private var accent: Color { store.primaryGlow }

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
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                ambientPhase = 1
            }
        }
        .onDisappear { motion.stop() }
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
                            .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reservoir")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            Text(store.selectedVessel.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.62))
                        }

                        Spacer()
                    }

                    Divider()
                        .overlay(.white.opacity(0.08))

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
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.012, green: 0.026, blue: 0.036),
                    Color(red: 0.018, green: 0.046, blue: 0.060),
                    ReservoirStyle.ink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    ReservoirStyle.cyan.opacity(0.16 + ambientPhase * 0.05),
                    .clear,
                    ReservoirStyle.cyanDeep.opacity(0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)

            Rectangle()
                .fill(.black.opacity(0.16))
                .ignoresSafeArea()
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
                    Text("Discipline,")
                        .foregroundStyle(.white)
                    Text("made visible.")
                        .foregroundStyle(ReservoirStyle.cyanSoft)
                }
                .font(.system(size: 36, weight: .black, design: .rounded))
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
                    let bottleWidth = min(cardWidth * 0.44, 220)
                    let bottleHeight = min(proxy.size.height * 0.83, 370)

                    ZStack {
                        ReservoirSpriteView(
                            streak: store.currentStreak,
                            vessel: store.selectedVessel,
                            tilt: motion.tilt,
                            angularVelocity: motion.angularVelocity,
                            relapsePulse: relapsePulse
                        )
                        .frame(width: bottleWidth, height: bottleHeight)
                        .offset(y: 20)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                heroDayBlock
                                    .frame(width: cardWidth * 0.42, alignment: .leading)

                                Spacer()

                                ProgressRing(
                                    progress: store.fillProgress,
                                    accent: ReservoirStyle.cyan,
                                    lineWidth: 10,
                                    label: "FILLED"
                                )
                                .frame(width: min(cardWidth * 0.25, 126), height: min(cardWidth * 0.25, 126))
                                .padding(.top, 8)
                            }

                            HStack {
                                statusPill(
                                    relapsePulse > 0.04 ? "Zeroed out. Start clean." : store.canCheckInToday ? "Ready for today's check-in" : "Today is secured",
                                    systemImage: relapsePulse > 0.04 ? "arrow.counterclockwise" : store.canCheckInToday ? "drop.fill" : "checkmark.seal.fill"
                                )
                                Spacer(minLength: 0)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 26)
                    }
                }
            }
            .frame(height: 360)

            Divider()
                .overlay(.white.opacity(0.08))

            HStack(spacing: 0) {
                HeroInfoTile(title: "VESSEL", value: store.selectedVessel.title, systemImage: "flask.fill", tint: ReservoirStyle.cyan)
                Divider()
                    .overlay(.white.opacity(0.08))
                HeroInfoTile(title: "NEXT UNLOCK", value: store.nextAchievementTitle, systemImage: "flag.fill", tint: ReservoirStyle.gold)
            }
            .frame(height: 86)
            .background(.white.opacity(0.018))
        }
        .reservoirPanel(stroke: .white.opacity(0.14))
    }

    private var heroAtmosphere: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .white.opacity(0.06),
                    ReservoirStyle.panel.opacity(0.35),
                    .black.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            ReservoirStyle.cyan.opacity(0.08 + store.glowProgress * 0.07),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 24)
                .frame(width: 210, height: 300)
                .offset(x: 18, y: 42)
                .scaleEffect(1.0 + checkInBloom * 0.04)

            Ellipse()
                .fill(ReservoirStyle.cyan.opacity(0.18 + checkInBloom * 0.10))
                .blur(radius: 18)
                .frame(width: 190, height: 24)
                .offset(x: 16, y: 150)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, ReservoirStyle.cyan.opacity(0.10), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .offset(y: 132)
        }
    }

    private var heroDayBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DAY")
                .font(.caption.weight(.bold))
                .tracking(5)
                .foregroundStyle(ReservoirStyle.cyan)

            Text(dayDisplay)
                .font(.system(size: 74, weight: .light, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.58)

            Text(store.milestoneText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
    }

    private var dayDisplay: String {
        store.currentStreak < 10 ? "0\(store.currentStreak)" : "\(store.currentStreak)"
    }

    private func statusPill(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.bold))
                .foregroundStyle(ReservoirStyle.cyan)
            Text(text)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(.black.opacity(0.24), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
    }

    // MARK: - Stats

    private var statsGrid: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(store.longestStreak)", label: "Longest streak", systemImage: "drop", tint: ReservoirStyle.gold)
            StatTile(value: "\(store.totalRetentionDays)", label: "Total days", systemImage: "calendar.badge.checkmark", tint: ReservoirStyle.cyan)
            StatTile(value: "\(Int(store.fillProgress * 100))%", label: "Filled", systemImage: "drop.circle", tint: ReservoirStyle.mint)
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
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(ReservoirStyle.cyanSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }

                Spacer()

                Text(store.daysUntilNextAchievement > 0 ? "\(store.daysUntilNextAchievement)d" : "Done")
                    .font(.title3.weight(.black))
                    .foregroundStyle(ReservoirStyle.cyan)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
            }

            MilestoneBar(progress: store.achievementProgress, accent: ReservoirStyle.cyan)

            Text(store.daysUntilNextAchievement > 0
                 ? "\(store.daysUntilNextAchievement) retained days until the next unlock."
                 : "All milestone unlocks are complete.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(20)
        .background {
            ZStack(alignment: .bottomTrailing) {
                ReservoirStyle.panel.opacity(0.62)
                MountainSilhouette()
                    .fill(ReservoirStyle.cyan.opacity(0.11))
                    .frame(width: 220, height: 86)
                    .offset(x: 18, y: 10)
                LinearGradient(
                    colors: [.white.opacity(0.04), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
    }

    // MARK: - Actions

    private var checkInButton: some View {
        Button {
            store.checkInToday()
            haptics.successBloom()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { checkInBloom = 1 }
            withAnimation(.easeOut(duration: 0.9).delay(0.25)) { checkInBloom = 0 }
        } label: {
            Label(store.canCheckInToday ? "Check In Today" : "Today Secured", systemImage: store.canCheckInToday ? "drop.fill" : "checkmark.seal.fill")
                .font(.title3.weight(.black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
        .buttonStyle(PrimaryButtonStyle(disabled: !store.canCheckInToday))
        .disabled(!store.canCheckInToday)
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
                            .font(.system(size: 24, weight: .bold))
                        Text(tab.title)
                            .font(.footnote.weight(.medium))
                    }
                    .foregroundStyle(selectedTab == tab ? ReservoirStyle.cyan : .white.opacity(0.46))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.018, green: 0.042, blue: 0.056).opacity(0.96),
                    Color(red: 0.008, green: 0.018, blue: 0.026).opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
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

private enum ReservoirStyle {
    static let radius: CGFloat = 8
    static let ink = Color(red: 0.004, green: 0.016, blue: 0.024)
    static let panel = Color(red: 0.047, green: 0.086, blue: 0.113)
    static let panelStrong = Color(red: 0.063, green: 0.112, blue: 0.145)
    static let cyan = Color(red: 0.29, green: 0.76, blue: 1.0)
    static let cyanSoft = Color(red: 0.67, green: 0.86, blue: 1.0)
    static let cyanDeep = Color(red: 0.02, green: 0.22, blue: 0.34)
    static let gold = Color(red: 0.96, green: 0.70, blue: 0.25)
    static let mint = Color(red: 0.46, green: 0.91, blue: 0.74)
    static let coral = Color(red: 1.0, green: 0.43, blue: 0.39)
}

private extension View {
    func reservoirPanel(stroke: Color = .white.opacity(0.10)) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [
                        ReservoirStyle.panelStrong.opacity(0.76),
                        ReservoirStyle.panel.opacity(0.46)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
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
                .stroke(.white.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    LinearGradient(colors: [ReservoirStyle.cyanSoft, accent], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-82))
                .shadow(color: accent.opacity(progress > 0 ? 0.50 : 0), radius: 8)

            VStack(spacing: 5) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(label)
                    .font(.caption.weight(.bold))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.48))
            }
            .padding(.horizontal, 8)
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
                    .fill(.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(LinearGradient(colors: [ReservoirStyle.cyan, ReservoirStyle.cyanSoft], startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * max(0, min(1, progress)))
                    .shadow(color: accent.opacity(progress > 0 ? 0.42 : 0), radius: 6)
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
                .foregroundStyle(.white.opacity(0.62))
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
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
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(value)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
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
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
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
                        .foregroundStyle(active ? vessel.glowColor : .white.opacity(0.42))
                }

                Spacer(minLength: 0)

                Text(vessel.title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .lineLimit(3)
                    .foregroundStyle(.white.opacity(0.58))
            }
            .foregroundStyle(.white)
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
        active ? vessel.glowColor.opacity(0.15) : ReservoirStyle.panel.opacity(0.68)
    }

    private var stroke: Color {
        active ? vessel.glowColor.opacity(0.85) : .white.opacity(0.08)
    }
}

// MARK: - Achievement Row

private struct AchievementRow: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
                    .fill(unlocked ? ReservoirStyle.gold.opacity(0.16) : .white.opacity(0.06))
                    .frame(width: 42, height: 42)
                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(unlocked ? ReservoirStyle.gold : .white.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(unlocked ? achievement.unlock : achievement.subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)
            }

            Spacer()

            Text("\(achievement.days)d")
                .font(.caption.weight(.black))
                .foregroundStyle(unlocked ? ReservoirStyle.gold : .white.opacity(0.58))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .padding(12)
        .background(background, in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(stroke, lineWidth: 1))
    }

    private var background: Color {
        unlocked ? ReservoirStyle.gold.opacity(0.09) : ReservoirStyle.panel.opacity(0.62)
    }

    private var stroke: Color {
        unlocked ? ReservoirStyle.gold.opacity(0.26) : .white.opacity(0.07)
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

// MARK: - Button Styles

private struct PrimaryButtonStyle: ButtonStyle {
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(disabled ? Color.white.opacity(0.55) : Color(red: 0.014, green: 0.066, blue: 0.098))
            .background(background, in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
                    .stroke(.white.opacity(disabled ? 0.06 : 0.34), lineWidth: 1)
            )
            .shadow(color: disabled ? .clear : ReservoirStyle.cyan.opacity(0.34), radius: configuration.isPressed ? 5 : 16, y: 7)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder private var background: some View {
        if disabled {
            ReservoirStyle.panelStrong.opacity(0.7)
        } else {
            LinearGradient(
                colors: [ReservoirStyle.cyanSoft, ReservoirStyle.cyan],
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
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(tint.opacity(0.28), lineWidth: 1))
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
            .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
