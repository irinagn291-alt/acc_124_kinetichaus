import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var age: Int?
    var heightCm: Double?
    var currentWeightKg: Double?
    var targetWeightKg: Double?
    var activityLevel: String
    var trainingLevel: DifficultyLevel
    var mainGoals: [String]

    var dailyCaloriesGoal: Double
    var proteinGoalGrams: Double
    var fatGoalGrams: Double
    var carbsGoalGrams: Double
    var waterGoalMl: Int

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "Athlete",
        age: Int? = nil,
        heightCm: Double? = nil,
        currentWeightKg: Double? = nil,
        targetWeightKg: Double? = nil,
        activityLevel: String = "moderate",
        trainingLevel: DifficultyLevel = .beginner,
        mainGoals: [String] = [],
        dailyCaloriesGoal: Double = 2200,
        proteinGoalGrams: Double = 140,
        fatGoalGrams: Double = 70,
        carbsGoalGrams: Double = 250,
        waterGoalMl: Int = 2500
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.heightCm = heightCm
        self.currentWeightKg = currentWeightKg
        self.targetWeightKg = targetWeightKg
        self.activityLevel = activityLevel
        self.trainingLevel = trainingLevel
        self.mainGoals = mainGoals
        self.dailyCaloriesGoal = dailyCaloriesGoal
        self.proteinGoalGrams = proteinGoalGrams
        self.fatGoalGrams = fatGoalGrams
        self.carbsGoalGrams = carbsGoalGrams
        self.waterGoalMl = waterGoalMl
        self.createdAt = .now
        self.updatedAt = .now
    }
}
