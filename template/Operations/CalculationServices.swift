import Foundation

struct NutritionSummary {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let sugar: Double
    let fiber: Double
    let salt: Double

    static let zero = NutritionSummary(calories: 0, protein: 0, fat: 0, carbs: 0, sugar: 0, fiber: 0, salt: 0)
}

struct NutritionCalculationService {
    func calculate(product: FoodProduct, amountGrams: Double) -> NutritionSummary {
        NutritionSummary(
            calories: product.caloriesPer100g * amountGrams / 100,
            protein: product.proteinPer100g * amountGrams / 100,
            fat: product.fatPer100g * amountGrams / 100,
            carbs: product.carbsPer100g * amountGrams / 100,
            sugar: (product.sugarPer100g ?? 0) * amountGrams / 100,
            fiber: (product.fiberPer100g ?? 0) * amountGrams / 100,
            salt: (product.saltPer100g ?? 0) * amountGrams / 100
        )
    }

    func summary(for meals: [Meal]) -> NutritionSummary {
        var calories = 0.0, protein = 0.0, fat = 0.0, carbs = 0.0, sugar = 0.0, fiber = 0.0, salt = 0.0
        for item in meals.flatMap({ $0.items }) {
            calories += item.calories
            protein += item.protein
            fat += item.fat
            carbs += item.carbs
            sugar += item.sugar ?? 0
            fiber += item.fiber ?? 0
            salt += item.salt ?? 0
        }
        return NutritionSummary(calories: calories, protein: protein, fat: fat, carbs: carbs, sugar: sugar, fiber: fiber, salt: salt)
    }
}

enum WorkoutVolumeCalculator {
    static func volume(reps: Int?, weightKg: Double?, durationSeconds: Int?, distanceMeters: Double?) -> Double {
        if let weightKg, weightKg > 0, let reps { return weightKg * Double(reps) }
        if let reps, reps > 0 { return Double(reps) }
        if let durationSeconds, durationSeconds > 0 { return Double(durationSeconds) }
        if let distanceMeters, distanceMeters > 0 { return distanceMeters }
        return 0
    }

    static func volume(for set: PerformedSet) -> Double {
        volume(reps: set.reps, weightKg: set.weightKg, durationSeconds: set.durationSeconds, distanceMeters: set.distanceMeters)
    }
}

@MainActor
final class WorkoutSessionService {
    func recompute(_ session: WorkoutSession) {
        let completed = session.performedSets.filter { $0.isCompleted }
        session.completedSetsCount = completed.count
        session.completedExercisesCount = Set(completed.map { $0.exerciseName }).count
        session.totalVolume = completed.reduce(0) { $0 + WorkoutVolumeCalculator.volume(for: $1) }
        if let end = session.endedAt {
            session.durationSeconds = Int(end.timeIntervalSince(session.startedAt))
        } else {
            session.durationSeconds = Int(Date.now.timeIntervalSince(session.startedAt))
        }
    }

    func averageRPE(_ session: WorkoutSession) -> Double? {
        let rpes = session.performedSets.compactMap { $0.isCompleted ? $0.rpe : nil }
        guard !rpes.isEmpty else { return nil }
        return Double(rpes.reduce(0, +)) / Double(rpes.count)
    }
}

struct ProgramProgress {
    let completedDays: Int
    let totalDays: Int
    var fraction: Double { totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0 }
}

enum ProgramProgressCalculator {
    static func progress(_ program: TrainingProgram) -> ProgramProgress {
        let all = program.allDays
        let done = all.filter { $0.isCompleted }.count
        return ProgramProgress(completedDays: done, totalDays: all.count)
    }
}

enum GoalProgressCalculator {
    static func progress(for goal: UserGoal, startValue: Double? = nil) -> Double {
        guard goal.targetValue != 0 else { return 0 }
        if goal.type == .bodyWeight, let start = startValue {
            let totalDelta = goal.targetValue - start
            guard totalDelta != 0 else { return goal.currentValue == goal.targetValue ? 1 : 0 }
            let currentDelta = goal.currentValue - start
            return min(max(currentDelta / totalDelta, 0), 1)
        }
        return min(max(goal.currentValue / goal.targetValue, 0), 1)
    }
}
