import SwiftUI
import Charts

struct StatsGridView: View {
    @EnvironmentObject private var environment: HausContainer
    enum Tab: String, CaseIterable, Identifiable {
        case overview = "TOTAL", workouts = "LIFT", nutrition = "INTAKE", body = "MEASURE", goals = "TARGET", reading = "CODEX"
        var id: String { rawValue }
    }
    @State private var tab: Tab = .overview
    @State private var period: AnalyticsPeriod = .month

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(AnalyticsPeriod.allCases) { p in
                        Button { period = p } label: {
                            Text(p.displayName).font(GridTypography.caption)
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(period == p ? BauhausColors.primary : BauhausColors.surface)
                                .foregroundStyle(period == p ? BauhausColors.onPrimary : BauhausColors.textPrimary)
                        }
                    }
                }
                VStack(spacing: 2) {
                    ForEach(Tab.allCases) { item in
                        Button { tab = item } label: {
                            HStack {
                                Rectangle().fill(tab == item ? BauhausColors.primary : BauhausColors.textMuted).frame(width: 4)
                                Text(item.rawValue).font(GridTypography.captionMedium)
                                    .foregroundStyle(tab == item ? BauhausColors.textPrimary : BauhausColors.textSecondary)
                                Spacer()
                            }
                            .padding(GridSpacing.md)
                            .background(BauhausColors.elevatedSurface)
                        }
                    }
                }
                .padding(.vertical, GridSpacing.sm)
                tabBody.padding(GridSpacing.md)
            }
        }
        .background(BauhausColors.background)
        .navigationTitle("Grid Stats")
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func metricWrap<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 2, content: content)
    }

    private func chartBlock<C: View>(_ title: String, @ViewBuilder _ chart: () -> C) -> some View {
        VStack(alignment: .leading, spacing: GridSpacing.xs) {
            Text(title).font(GridTypography.caption).foregroundStyle(BauhausColors.textSecondary)
            chart().frame(height: 160).padding(GridSpacing.sm).background(BauhausColors.surface)
        }
    }

    private var overview: some View {
        let w = (try? environment.analyticsService.workoutSummary(period: period))
        let g = (try? environment.analyticsService.goalSummary())
        let r = (try? environment.analyticsService.readingSummary(period: period))
        let b = (try? environment.analyticsService.bodySummary(period: period))
        return metricWrap {
            GridMetric(title: "Workouts", value: "\(w?.sessionsCount ?? 0)", color: BauhausColors.primary, icon: GridIcons.workouts)
            GridMetric(title: "Training Time", value: NumberFormatterUtils.durationMinutes(w?.totalDurationMinutes ?? 0), color: BauhausColors.secondary, icon: "clock.fill")
            GridMetric(title: "Volume", value: NumberFormatterUtils.int(w?.totalVolume ?? 0), color: BauhausColors.info, icon: "scalemass")
            GridMetric(title: "Goals Done", value: "\(g?.completedGoalsCount ?? 0)", color: BauhausColors.success, icon: GridIcons.goals)
            GridMetric(title: "Books Done", value: "\(r?.completedBooksCount ?? 0)", color: BauhausColors.accent, icon: GridIcons.library)
            GridMetric(title: "Weight", value: b?.currentWeightKg.map { "\(NumberFormatterUtils.decimal($0)) kg" } ?? "—", color: BauhausColors.warning, icon: GridIcons.body)
        }
    }

    private var workouts: some View {
        let summary = try? environment.analyticsService.workoutSummary(period: period)
        let perDay = (try? environment.analyticsService.workoutsPerDay(period: period)) ?? []
        let volume = (try? environment.analyticsService.volumePoints(period: period)) ?? []
        return VStack(spacing: GridSpacing.md) {
            if let summary, summary.sessionsCount == 0 {
                BlankGridView(systemImage: GridIcons.workouts, title: "No data yet", message: "Complete workouts to unlock stats.")
            } else {
                metricWrap {
                    GridMetric(title: "Sessions", value: "\(summary?.sessionsCount ?? 0)", color: BauhausColors.primary, icon: GridIcons.workouts)
                    GridMetric(title: "Avg Duration", value: "\(Int(summary?.averageDurationMinutes ?? 0)) min", color: BauhausColors.secondary, icon: "clock")
                    GridMetric(title: "Completion", value: "\(Int((summary?.completionRate ?? 0) * 100))%", color: BauhausColors.success, icon: "checkmark")
                    GridMetric(title: "Avg RPE", value: summary?.averageRPE.map { NumberFormatterUtils.decimal($0) } ?? "—", color: BauhausColors.accent, icon: "gauge")
                }
                chartBlock("Workouts per Week") {
                    Chart(perDay) { BarMark(x: .value("Date", $0.date, unit: .day), y: .value("Count", $0.count)).foregroundStyle(BauhausColors.primary) }
                }
                chartBlock("Training Volume") {
                    Chart(volume) { LineMark(x: .value("Date", $0.date), y: .value("Volume", $0.volume)).foregroundStyle(BauhausColors.info) }
                }
            }
        }
    }

    private var nutrition: some View {
        let goal = environment.currentProfile()?.dailyCaloriesGoal ?? 2200
        let summary = try? environment.analyticsService.nutritionSummary(period: period, caloriesGoal: goal)
        let points = (try? environment.analyticsService.caloriesPoints(period: period, goal: goal)) ?? []
        return VStack(spacing: GridSpacing.md) {
            if points.isEmpty {
                BlankGridView(systemImage: GridIcons.nutrition, title: "No data yet", message: "Log meals to see nutrition trends.")
            } else {
                metricWrap {
                    GridMetric(title: "Avg Calories", value: NumberFormatterUtils.int(summary?.averageCalories ?? 0), color: BauhausColors.accent, icon: GridIcons.calories)
                    GridMetric(title: "Avg Protein", value: "\(NumberFormatterUtils.int(summary?.averageProtein ?? 0)) g", color: BauhausColors.protein, icon: GridIcons.protein)
                    GridMetric(title: "Avg Fat", value: "\(NumberFormatterUtils.int(summary?.averageFat ?? 0)) g", color: BauhausColors.fat, icon: GridIcons.fat)
                    GridMetric(title: "Target Hit", value: "\(Int((summary?.targetHitRate ?? 0) * 100))%", color: BauhausColors.success, icon: "target")
                }
                chartBlock("Calories vs Goal") {
                    Chart(points) {
                        BarMark(x: .value("Date", $0.date, unit: .day), y: .value("Calories", $0.calories)).foregroundStyle(BauhausColors.accent)
                        RuleMark(y: .value("Goal", goal)).foregroundStyle(BauhausColors.textMuted).lineStyle(StrokeStyle(dash: [5]))
                    }
                }
            }
        }
    }

    private var bodyTab: some View {
        let summary = try? environment.analyticsService.bodySummary(period: period)
        let points = (try? environment.analyticsService.weightPoints(period: period)) ?? []
        return VStack(spacing: GridSpacing.md) {
            metricWrap {
                GridMetric(title: "Current Weight", value: summary?.currentWeightKg.map { "\(NumberFormatterUtils.decimal($0)) kg" } ?? "—", color: BauhausColors.primary, icon: GridIcons.body)
                GridMetric(title: "Weight Change", value: summary?.weightChangeKg.map { "\(NumberFormatterUtils.decimal($0)) kg" } ?? "—", color: BauhausColors.secondary, icon: "arrow.up.arrow.down")
            }
            if points.count >= 2 {
                chartBlock("Weight Trend") {
                    Chart(points) { LineMark(x: .value("Date", $0.date), y: .value("Weight", $0.weightKg)).foregroundStyle(BauhausColors.primary) }
                }
            } else {
                BlankGridView(systemImage: GridIcons.body, title: "No data yet", message: "Add body measurements to see trends.")
            }
        }
    }

    private var goals: some View {
        let summary = try? environment.analyticsService.goalSummary()
        return metricWrap {
            GridMetric(title: "Active", value: "\(summary?.activeGoalsCount ?? 0)", color: BauhausColors.primary, icon: GridIcons.goals)
            GridMetric(title: "Completed", value: "\(summary?.completedGoalsCount ?? 0)", color: BauhausColors.success, icon: "checkmark.circle")
            GridMetric(title: "Overdue", value: "\(summary?.overdueGoalsCount ?? 0)", color: BauhausColors.danger, icon: "exclamationmark")
            GridMetric(title: "Avg Progress", value: "\(Int((summary?.averageProgress ?? 0) * 100))%", color: BauhausColors.secondary, icon: "chart.bar")
        }
    }

    private var reading: some View {
        let summary = try? environment.analyticsService.readingSummary(period: period)
        return metricWrap {
            GridMetric(title: "Saved Books", value: "\(summary?.savedBooksCount ?? 0)", color: BauhausColors.primary, icon: GridIcons.library)
            GridMetric(title: "Reading", value: "\(summary?.currentlyReadingCount ?? 0)", color: BauhausColors.secondary, icon: "book")
            GridMetric(title: "Completed", value: "\(summary?.completedBooksCount ?? 0)", color: BauhausColors.success, icon: "checkmark.circle")
            GridMetric(title: "Reading Time", value: NumberFormatterUtils.durationMinutes(summary?.totalReadingMinutes ?? 0), color: BauhausColors.accent, icon: "clock")
        }
    }

    @ViewBuilder private var tabBody: some View {
        switch tab {
        case .overview: overview
        case .workouts: workouts
        case .nutrition: nutrition
        case .body: bodyTab
        case .goals: goals
        case .reading: reading
        }
    }

}
