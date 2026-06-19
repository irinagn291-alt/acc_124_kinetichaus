import Foundation
import SwiftUI

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case week, month, threeMonths, year, allTime
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .threeMonths: "3 Months"
        case .year: "Year"
        case .allTime: "All Time"
        }
    }
    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .threeMonths: 90
        case .year: 365
        case .allTime: 3650
        }
    }
    func range(now: Date = .now) -> (start: Date, end: Date) {
        DateUtils.range(byAddingDays: days, to: now)
    }
}

struct TodayDashboardSummary {
    let date: Date
    let plannedWorkoutTitle: String?
    let completedWorkoutsCount: Int
    let caloriesConsumed: Double
    let caloriesGoal: Double
    let proteinConsumed: Double
    let proteinGoal: Double
    let waterConsumedMl: Int
    let waterGoalMl: Int
    let activeGoalsCount: Int
    let completedGoalsCount: Int
    let currentReadingBookTitle: String?
}

struct WorkoutAnalyticsSummary {
    let periodStart: Date
    let periodEnd: Date
    let sessionsCount: Int
    let totalDurationMinutes: Int
    let totalVolume: Double
    let averageDurationMinutes: Double
    let averageRPE: Double?
    let completionRate: Double
    let mostTrainedMuscleGroups: [MuscleGroup]
}

struct NutritionAnalyticsSummary {
    let averageCalories: Double
    let averageProtein: Double
    let averageFat: Double
    let averageCarbs: Double
    let averageWaterMl: Double
    let targetHitRate: Double
    let highestCaloriesDate: Date?
    let lowestCaloriesDate: Date?
}

struct BodyAnalyticsSummary {
    let currentWeightKg: Double?
    let weightChangeKg: Double?
    let bodyFatChangePercent: Double?
    let muscleMassChangeKg: Double?
    let latestMeasurementDate: Date?
}

struct GoalAnalyticsSummary {
    let activeGoalsCount: Int
    let completedGoalsCount: Int
    let overdueGoalsCount: Int
    let averageProgress: Double
}

struct ReadingAnalyticsSummary {
    let savedBooksCount: Int
    let completedBooksCount: Int
    let currentlyReadingCount: Int
    let totalReadingMinutes: Int
    let averageSessionMinutes: Double
}

struct WeightChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weightKg: Double
}

struct CaloriesChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let goal: Double
}

struct MacroChartSegment: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let color: Color
}

struct WorkoutVolumePoint: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
}

struct DayCountPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Double
}
