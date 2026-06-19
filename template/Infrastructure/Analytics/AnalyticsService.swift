import Foundation

@MainActor
final class AnalyticsService {
    private let workoutRepo: WorkoutRepositoryProtocol
    private let nutritionRepo: NutritionRepositoryProtocol
    private let bodyRepo: BodyMeasurementRepositoryProtocol
    private let goalRepo: GoalRepositoryProtocol
    private let bookRepo: BookRepositoryProtocol

    init(
        workoutRepo: WorkoutRepositoryProtocol,
        nutritionRepo: NutritionRepositoryProtocol,
        bodyRepo: BodyMeasurementRepositoryProtocol,
        goalRepo: GoalRepositoryProtocol,
        bookRepo: BookRepositoryProtocol
    ) {
        self.workoutRepo = workoutRepo
        self.nutritionRepo = nutritionRepo
        self.bodyRepo = bodyRepo
        self.goalRepo = goalRepo
        self.bookRepo = bookRepo
    }

    func workoutSummary(period: AnalyticsPeriod) throws -> WorkoutAnalyticsSummary {
        let (start, end) = period.range()
        let sessions = try workoutRepo.fetchSessions(from: start, to: end).filter { $0.status == .completed }
        let totalDuration = sessions.reduce(0) { $0 + $1.durationSeconds } / 60
        let totalVolume = sessions.reduce(0) { $0 + $1.totalVolume }
        let avgDuration = sessions.isEmpty ? 0 : Double(totalDuration) / Double(sessions.count)
        let rpes = sessions.compactMap { $0.perceivedDifficulty }
        let avgRPE = rpes.isEmpty ? nil : Double(rpes.reduce(0, +)) / Double(rpes.count)

        var groupCounts: [MuscleGroup: Int] = [:]
        for s in sessions {
            for set in s.performedSets where set.isCompleted {
                groupCounts[set.muscleGroup, default: 0] += 1
            }
        }
        let top = groupCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }

        let allInRange = try workoutRepo.fetchSessions(from: start, to: end)
        let completionRate = allInRange.isEmpty ? 0 : Double(sessions.count) / Double(allInRange.count)

        return WorkoutAnalyticsSummary(
            periodStart: start, periodEnd: end,
            sessionsCount: sessions.count,
            totalDurationMinutes: totalDuration,
            totalVolume: totalVolume,
            averageDurationMinutes: avgDuration,
            averageRPE: avgRPE,
            completionRate: completionRate,
            mostTrainedMuscleGroups: Array(top)
        )
    }

    func workoutsPerDay(period: AnalyticsPeriod) throws -> [DayCountPoint] {
        let (start, end) = period.range()
        let sessions = try workoutRepo.fetchSessions(from: start, to: end).filter { $0.status == .completed }
        let grouped = Dictionary(grouping: sessions) { DateUtils.startOfDay($0.startedAt) }
        return grouped.map { DayCountPoint(date: $0.key, count: Double($0.value.count)) }.sorted { $0.date < $1.date }
    }

    func volumePoints(period: AnalyticsPeriod) throws -> [WorkoutVolumePoint] {
        let (start, end) = period.range()
        let sessions = try workoutRepo.fetchSessions(from: start, to: end).filter { $0.status == .completed }
        let grouped = Dictionary(grouping: sessions) { DateUtils.startOfDay($0.startedAt) }
        return grouped.map { WorkoutVolumePoint(date: $0.key, volume: $0.value.reduce(0) { $0 + $1.totalVolume }) }
            .sorted { $0.date < $1.date }
    }

    func nutritionSummary(period: AnalyticsPeriod, caloriesGoal: Double) throws -> NutritionAnalyticsSummary {
        let points = try caloriesPoints(period: period, goal: caloriesGoal)
        guard !points.isEmpty else {
            return NutritionAnalyticsSummary(averageCalories: 0, averageProtein: 0, averageFat: 0, averageCarbs: 0, averageWaterMl: 0, targetHitRate: 0, highestCaloriesDate: nil, lowestCaloriesDate: nil)
        }
        let (start, end) = period.range()
        let meals = try nutritionRepo.fetchMeals(from: start, to: end)
        let days = max(points.count, 1)
        let avgCal = points.reduce(0) { $0 + $1.calories } / Double(days)
        let avgProtein = meals.reduce(0) { $0 + $1.totalProtein } / Double(days)
        let avgFat = meals.reduce(0) { $0 + $1.totalFat } / Double(days)
        let avgCarbs = meals.reduce(0) { $0 + $1.totalCarbs } / Double(days)
        let hit = points.filter { $0.calories >= $0.goal * 0.9 && $0.calories <= $0.goal * 1.1 }.count
        let hitRate = Double(hit) / Double(days)
        let highest = points.max { $0.calories < $1.calories }?.date
        let lowest = points.min { $0.calories < $1.calories }?.date
        return NutritionAnalyticsSummary(
            averageCalories: avgCal, averageProtein: avgProtein, averageFat: avgFat, averageCarbs: avgCarbs,
            averageWaterMl: 0, targetHitRate: hitRate, highestCaloriesDate: highest, lowestCaloriesDate: lowest
        )
    }

    func caloriesPoints(period: AnalyticsPeriod, goal: Double) throws -> [CaloriesChartPoint] {
        let (start, end) = period.range()
        let meals = try nutritionRepo.fetchMeals(from: start, to: end)
        let grouped = Dictionary(grouping: meals) { DateUtils.startOfDay($0.date) }
        return grouped.map { CaloriesChartPoint(date: $0.key, calories: $0.value.reduce(0) { $0 + $1.totalCalories }, goal: goal) }
            .sorted { $0.date < $1.date }
    }

    func bodySummary(period: AnalyticsPeriod) throws -> BodyAnalyticsSummary {
        let (start, end) = period.range()
        let measurements = try bodyRepo.fetchMeasurements(from: start, to: end).sorted { $0.date < $1.date }
        let latest = measurements.last
        let first = measurements.first
        let weightChange: Double? = {
            guard let l = latest?.weightKg, let f = first?.weightKg else { return nil }
            return l - f
        }()
        let bfChange: Double? = {
            guard let l = latest?.bodyFatPercent, let f = first?.bodyFatPercent else { return nil }
            return l - f
        }()
        let mmChange: Double? = {
            guard let l = latest?.muscleMassKg, let f = first?.muscleMassKg else { return nil }
            return l - f
        }()
        return BodyAnalyticsSummary(
            currentWeightKg: latest?.weightKg,
            weightChangeKg: weightChange,
            bodyFatChangePercent: bfChange,
            muscleMassChangeKg: mmChange,
            latestMeasurementDate: latest?.date
        )
    }

    func weightPoints(period: AnalyticsPeriod) throws -> [WeightChartPoint] {
        let (start, end) = period.range()
        return try bodyRepo.fetchMeasurements(from: start, to: end)
            .compactMap { m in m.weightKg.map { WeightChartPoint(date: m.date, weightKg: $0) } }
            .sorted { $0.date < $1.date }
    }

    func goalSummary() throws -> GoalAnalyticsSummary {
        let active = try goalRepo.fetchActiveGoals()
        let completed = try goalRepo.fetchCompletedGoals()
        let overdue = active.filter { ($0.deadline.map { $0 < .now }) ?? false }.count
        let avg = active.isEmpty ? 0 : active.reduce(0.0) { $0 + $1.progress } / Double(active.count)
        return GoalAnalyticsSummary(
            activeGoalsCount: active.count,
            completedGoalsCount: completed.count,
            overdueGoalsCount: overdue,
            averageProgress: avg
        )
    }

    func readingSummary(period: AnalyticsPeriod) throws -> ReadingAnalyticsSummary {
        let (start, end) = period.range()
        let books = try bookRepo.fetchBooks()
        let sessions = try bookRepo.fetchReadingSessions(from: start, to: end)
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }
        let avgSession = sessions.isEmpty ? 0 : Double(totalMinutes) / Double(sessions.count)
        return ReadingAnalyticsSummary(
            savedBooksCount: books.count,
            completedBooksCount: books.filter { $0.readingStatus == .completed }.count,
            currentlyReadingCount: books.filter { $0.readingStatus == .reading }.count,
            totalReadingMinutes: totalMinutes,
            averageSessionMinutes: avgSession
        )
    }

    func macroSegments(for date: Date) throws -> [MacroChartSegment] {
        let summary = try nutritionRepo.fetchNutritionSummary(for: date)
        return [
            MacroChartSegment(title: "Protein", value: summary.protein, color: BauhausColors.protein),
            MacroChartSegment(title: "Fat", value: summary.fat, color: BauhausColors.fat),
            MacroChartSegment(title: "Carbs", value: summary.carbs, color: BauhausColors.carbs)
        ]
    }

    func todaySummary(profile: UserProfile?) throws -> TodayDashboardSummary {
        let today = Date.now
        let summary = try nutritionRepo.fetchNutritionSummary(for: today)
        let water = try nutritionRepo.fetchHydrationLogs(for: today).reduce(0) { $0 + $1.amountMl }
        let (start, end) = DateUtils.dayRange(for: today)
        let sessions = try workoutRepo.fetchSessions(from: start, to: end)
        let completed = sessions.filter { $0.status == .completed }.count
        let active = try goalRepo.fetchActiveGoals().count
        let done = try goalRepo.fetchCompletedGoals().count
        let reading = try bookRepo.fetchBooks(status: .reading).first?.title
        return TodayDashboardSummary(
            date: today,
            plannedWorkoutTitle: sessions.first(where: { $0.status != .completed })?.workoutTitle,
            completedWorkoutsCount: completed,
            caloriesConsumed: summary.calories,
            caloriesGoal: profile?.dailyCaloriesGoal ?? 2200,
            proteinConsumed: summary.protein,
            proteinGoal: profile?.proteinGoalGrams ?? 140,
            waterConsumedMl: water,
            waterGoalMl: profile?.waterGoalMl ?? 2500,
            activeGoalsCount: active,
            completedGoalsCount: done,
            currentReadingBookTitle: reading
        )
    }

    func localInsights() throws -> [String] {
        var insights: [String] = []
        let weekRange = AnalyticsPeriod.week.range()
        let sessions = try workoutRepo.fetchSessions(from: weekRange.start, to: weekRange.end).filter { $0.status == .completed }
        insights.append("You completed \(sessions.count) workout\(sessions.count == 1 ? "" : "s") this week.")

        let readingSessions = try bookRepo.fetchReadingSessions(from: weekRange.start, to: weekRange.end)
        if !readingSessions.isEmpty {
            insights.append("You completed \(readingSessions.count) reading session\(readingSessions.count == 1 ? "" : "s") this week.")
        }

        let measurements = try bodyRepo.fetchMeasurements().prefix(2)
        if measurements.count == 2, let a = measurements.first?.weightKg, let b = measurements.last?.weightKg, abs(a - b) < 0.3 {
            insights.append("Your body weight has been stable recently.")
        }
        return insights
    }
}
