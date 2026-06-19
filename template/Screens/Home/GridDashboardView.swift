import SwiftUI

struct GridDashboardView: View {
    @EnvironmentObject private var environment: HausContainer
    @EnvironmentObject private var network: NetworkMonitor
    @State private var summary: TodayDashboardSummary?

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
                if !network.isConnected { GridOfflineBar() }
                if let summary {
                    Text("WEEKLY METRICS").font(GridTypography.caption).foregroundStyle(BauhausColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, GridSpacing.sm)
                    HStack(spacing: 0) {
                metricBox("VOL", NumberFormatterUtils.int((try? environment.workoutRepository.fetchSessions(from: AnalyticsPeriod.week.range().start, to: AnalyticsPeriod.week.range().end))?.filter { $0.status == .completed }.reduce(0.0) { $0 + $1.totalVolume } ?? 0))
                metricBox("SES", "\((try? environment.workoutRepository.fetchSessions(from: AnalyticsPeriod.week.range().start, to: AnalyticsPeriod.week.range().end))?.filter { $0.status == .completed }.count ?? 0)")
                metricBox("KCAL", "\(NumberFormatterUtils.int(summary.caloriesConsumed))")
            }
            NavigationLink { LiftCatalogView() } label: {
                bauhausBlock("Start Lift", summary.plannedWorkoutTitle ?? "Ready", true)
            }
            NavigationLink { CycleListView() } label: {
                bauhausBlock("Active Cycle", "Open programs", false)
            }
            NavigationLink { IntakeDayView() } label: {
                bauhausBlock("Intake Log", "\(NumberFormatterUtils.int(summary.caloriesConsumed)) / \(NumberFormatterUtils.int(summary.caloriesGoal)) kcal", true)
            }
            NavigationLink { MeasureGridView() } label: {
                bauhausBlock("Measurements", "Track measurements", false)
            }
            NavigationLink { CodexView() } label: {
                bauhausBlock("Codex", summary.currentReadingBookTitle ?? "Shelf", true)
            }
            NavigationLink { TargetGridView() } label: {
                bauhausBlock("Targets", "\(summary.activeGoalsCount) active", false)
            }
                } else {
                    LoadingStateView()
                }
            }
            .padding(GridSpacing.md)
        }
        .scrollContentBackground(.hidden)
        .background(BauhausColors.background)
        .navigationTitle("KineticHaus")
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { secondaryMenu }
        }
        .onAppear(perform: reload)
    }

    private var secondaryMenu: some View {
        Menu {
            NavigationLink { PlanGridView() } label: { Label("Calendar", systemImage: GridIcons.calendar) }
            NavigationLink { StatsGridView() } label: { Label("Analytics", systemImage: GridIcons.analytics) }
            NavigationLink { MeasureGridView() } label: { Label("Body", systemImage: GridIcons.body) }
            NavigationLink { TargetGridView() } label: { Label("Goals", systemImage: GridIcons.goals) }
            NavigationLink { HausSettingsView() } label: { Label("Settings", systemImage: GridIcons.settings) }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private func reload() {
        summary = try? environment.analyticsService.todaySummary(profile: environment.currentProfile())
    }

    private func metricBox(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(GridTypography.caption).foregroundStyle(BauhausColors.textSecondary)
            Text(value).font(GridTypography.title2).foregroundStyle(BauhausColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GridSpacing.md)
        .background(BauhausColors.surface)
    }

    private func bauhausBlock(_ title: String, _ subtitle: String, _ accent: Bool) -> some View {
        HStack {
            Rectangle().fill(accent ? BauhausColors.primary : BauhausColors.secondary).frame(width: 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(GridTypography.title3).foregroundStyle(BauhausColors.textPrimary)
                Text(subtitle).font(GridTypography.caption).foregroundStyle(BauhausColors.textSecondary)
            }
            Spacer()
        }
        .padding(GridSpacing.md)
        .background(BauhausColors.elevatedSurface)
    }
}
