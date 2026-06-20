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

    private var accent: Color { store.primaryGlow }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    heroPanel
                    statsPanel
                    actionPanel
                    milestonePanel
                    vesselCollection
                    achievements
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            motion.start()
            haptics.prepare()
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
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

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ReservoirStyle.ink,
                    Color(red: 0.028, green: 0.044, blue: 0.052),
                    Color(red: 0.007, green: 0.009, blue: 0.014)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    accent.opacity(0.18 + ambientPhase * 0.08),
                    .clear,
                    ReservoirStyle.gold.opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.screen)

            VStack(spacing: 0) {
                ForEach(0..<18, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.018))
                        .frame(height: 1)
                    Spacer(minLength: 22)
                }
            }
            .opacity(0.45)
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("RESERVOIR")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .tracking(3)
                    .foregroundStyle(accent)
                Text("Discipline, made visible")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button { showingReset = true } label: {
                Label("Reset to 0", systemImage: "arrow.counterclockwise")
                    .labelStyle(.titleAndIcon)
                    .font(.footnote.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .buttonStyle(UtilityButtonStyle(tint: ReservoirStyle.danger))
            .accessibilityLabel("Reset everything to zero")
        }
    }

    // MARK: - Hero

    private var heroPanel: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Day \(store.currentStreak)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                    Text(store.milestoneText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.64))
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                ProgressRing(
                    progress: store.fillProgress,
                    accent: accent,
                    lineWidth: 7
                )
                .frame(width: 76, height: 76)
                .accessibilityLabel("Reservoir fill \(Int(store.fillProgress * 100)) percent")
            }

            vesselStage

            HStack(spacing: 10) {
                HeroMetric(title: "Vessel", value: store.selectedVessel.title, systemImage: "flask.fill", tint: accent)
                HeroMetric(title: "Next", value: store.nextAchievementTitle, systemImage: "flag.checkered", tint: ReservoirStyle.gold)
            }
        }
        .padding(16)
        .reservoirPanel(stroke: accent.opacity(0.24))
    }

    private var vesselStage: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width, 430)
            let stageHeight = min(proxy.size.height, 430)

            ZStack {
                RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.10 + store.glowProgress * 0.14),
                                ReservoirStyle.panel.opacity(0.42),
                                .black.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(accent.opacity(0.18 + checkInBloom * 0.22))
                            .frame(height: 1)
                            .blur(radius: 2)
                    }

                Circle()
                    .fill(accent.opacity(0.12 + store.glowProgress * 0.22))
                    .blur(radius: 42)
                    .frame(width: width * 0.68, height: width * 0.68)
                    .offset(y: 20)
                    .scaleEffect(1.0 + checkInBloom * 0.08)

                ReservoirSpriteView(
                    streak: store.currentStreak,
                    vessel: store.selectedVessel,
                    tilt: motion.tilt,
                    angularVelocity: motion.angularVelocity,
                    relapsePulse: relapsePulse
                )
                .frame(width: width, height: stageHeight)
                .padding(.top, 4)

                VStack {
                    Spacer()
                    statusPill(
                        relapsePulse > 0.04 ? "Zeroed out. Start clean." : store.canCheckInToday ? "Ready for today's check-in" : "Today is secured",
                        systemImage: relapsePulse > 0.04 ? "arrow.counterclockwise" : store.canCheckInToday ? "drop.fill" : "checkmark.seal.fill"
                    )
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(height: min(UIScreen.main.bounds.height * 0.42, 420))
    }

    private func statusPill(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
            Text(text)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(.black.opacity(0.38), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Stats

    private var statsPanel: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(store.longestStreak)", label: "Longest", systemImage: "trophy.fill", tint: ReservoirStyle.gold)
            StatTile(value: "\(store.totalRetentionDays)", label: "Total days", systemImage: "calendar", tint: accent)
            StatTile(value: "\(Int(store.fillProgress * 100))%", label: "Filled", systemImage: "gauge.with.dots.needle.33percent", tint: ReservoirStyle.danger)
        }
    }

    // MARK: - Actions

    private var actionPanel: some View {
        VStack(spacing: 10) {
            Button {
                store.checkInToday()
                haptics.successBloom()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { checkInBloom = 1 }
                withAnimation(.easeOut(duration: 0.9).delay(0.25)) { checkInBloom = 0 }
            } label: {
                Label(store.canCheckInToday ? "Check In Today" : "Today Secured", systemImage: store.canCheckInToday ? "drop.fill" : "checkmark.seal.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(PrimaryButtonStyle(accent: accent, disabled: !store.canCheckInToday))
            .disabled(!store.canCheckInToday)

            HStack(spacing: 10) {
                Button {
                    store.previewAdvanceOneDay()
                    haptics.softTick()
                } label: {
                    Label("Preview +1", systemImage: "plus.forward")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(GhostButtonStyle(tint: accent))

                Button { showingReset = true } label: {
                    Label("Reset to 0", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(GhostButtonStyle(tint: ReservoirStyle.danger))
            }
        }
    }

    // MARK: - Milestone progress

    private var milestonePanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionTitle("Milestone", systemImage: "flag.fill")

            HStack(alignment: .firstTextBaseline) {
                Text(store.nextAchievementTitle)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer()

                Text(store.daysUntilNextAchievement > 0 ? "\(store.daysUntilNextAchievement)d" : "Done")
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .foregroundStyle(accent)
            }

            MilestoneBar(progress: store.achievementProgress, accent: accent)

            Text(store.daysUntilNextAchievement > 0
                 ? "\(store.daysUntilNextAchievement) retained days until the next unlock."
                 : "All milestone unlocks are complete.")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.58))
        }
        .padding(16)
        .reservoirPanel()
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

    private func performReset() {
        withAnimation(.easeOut(duration: 0.15)) { relapsePulse = 1 }
        haptics.releaseCrack()
        store.reset()
        withAnimation(.easeOut(duration: 1.15).delay(0.1)) { relapsePulse = 0 }
    }
}

// MARK: - Styling

private enum ReservoirStyle {
    static let radius: CGFloat = 8
    static let ink = Color(red: 0.012, green: 0.017, blue: 0.022)
    static let panel = Color(red: 0.055, green: 0.073, blue: 0.078)
    static let panelStrong = Color(red: 0.079, green: 0.102, blue: 0.105)
    static let gold = Color(red: 0.94, green: 0.76, blue: 0.34)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.32)
}

private extension View {
    func reservoirPanel(stroke: Color = .white.opacity(0.08)) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [
                        ReservoirStyle.panelStrong.opacity(0.78),
                        ReservoirStyle.panel.opacity(0.48)
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
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.10), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    AngularGradient(colors: [accent.opacity(0.55), accent, .white], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.opacity(progress > 0 ? 0.55 : 0), radius: 6)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
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
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(LinearGradient(colors: [accent.opacity(0.72), accent], startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * max(0, min(1, progress)))
                    .shadow(color: accent.opacity(progress > 0 ? 0.45 : 0), radius: 5)
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

// MARK: - Hero Metric

private struct HeroMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
    }
}

// MARK: - Stat Tile

private struct StatTile: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.52))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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

// MARK: - Button Styles

private struct PrimaryButtonStyle: ButtonStyle {
    let accent: Color
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(disabled ? Color.white.opacity(0.55) : Color(red: 0.016, green: 0.024, blue: 0.026))
            .background(background, in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous)
                    .stroke(.white.opacity(disabled ? 0.08 : 0.36), lineWidth: 1)
            )
            .shadow(color: disabled ? .clear : accent.opacity(0.32), radius: configuration.isPressed ? 4 : 12, y: 5)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder private var background: some View {
        if disabled {
            ReservoirStyle.panelStrong.opacity(0.7)
        } else {
            LinearGradient(
                colors: [.white, accent.opacity(0.86)],
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
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: ReservoirStyle.radius, style: .continuous).stroke(tint.opacity(0.26), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
