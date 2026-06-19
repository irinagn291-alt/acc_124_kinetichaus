import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var title: String
    var workoutDescription: String?
    var type: WorkoutType
    var difficulty: DifficultyLevel
    var goal: String?
    var estimatedDurationMinutes: Int
    var tags: [String]
    var lastPerformedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var exercises: [WorkoutExercise]

    init(
        id: UUID = UUID(),
        title: String,
        workoutDescription: String? = nil,
        type: WorkoutType = .strength,
        difficulty: DifficultyLevel = .beginner,
        goal: String? = nil,
        estimatedDurationMinutes: Int = 60,
        tags: [String] = [],
        exercises: [WorkoutExercise] = []
    ) {
        self.id = id
        self.title = title
        self.workoutDescription = workoutDescription
        self.type = type
        self.difficulty = difficulty
        self.goal = goal
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.tags = tags
        self.exercises = exercises
        self.createdAt = .now
        self.updatedAt = .now
    }

    var sortedExercises: [WorkoutExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

@Model
final class WorkoutExercise {
    var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var equipment: String?
    var sets: Int
    var reps: Int?
    var weightKg: Double?
    var durationSeconds: Int?
    var distanceMeters: Double?
    var restSeconds: Int
    var tempo: String?
    var rpe: Int?
    var notes: String?
    var orderIndex: Int

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup = .other,
        equipment: String? = nil,
        sets: Int = 3,
        reps: Int? = nil,
        weightKg: Double? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Double? = nil,
        restSeconds: Int = 90,
        tempo: String? = nil,
        rpe: Int? = nil,
        notes: String? = nil,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.restSeconds = restSeconds
        self.tempo = tempo
        self.rpe = rpe
        self.notes = notes
        self.orderIndex = orderIndex
    }
}

@Model
final class WorkoutSession {
    var id: UUID
    var workoutId: UUID?
    var workoutTitle: String
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int
    var status: SessionStatus
    var perceivedDifficulty: Int?
    var mood: String?
    var notes: String?
    var totalVolume: Double
    var completedExercisesCount: Int
    var completedSetsCount: Int

    @Relationship(deleteRule: .cascade)
    var performedSets: [PerformedSet]

    init(
        id: UUID = UUID(),
        workoutId: UUID? = nil,
        workoutTitle: String,
        startedAt: Date = .now
    ) {
        self.id = id
        self.workoutId = workoutId
        self.workoutTitle = workoutTitle
        self.startedAt = startedAt
        self.durationSeconds = 0
        self.status = .inProgress
        self.totalVolume = 0
        self.completedExercisesCount = 0
        self.completedSetsCount = 0
        self.performedSets = []
    }
}

@Model
final class PerformedSet {
    var id: UUID
    var exerciseName: String
    var muscleGroup: MuscleGroup
    var setIndex: Int
    var reps: Int?
    var weightKg: Double?
    var durationSeconds: Int?
    var distanceMeters: Double?
    var rpe: Int?
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        muscleGroup: MuscleGroup = .other,
        setIndex: Int,
        reps: Int? = nil,
        weightKg: Double? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Double? = nil,
        rpe: Int? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.setIndex = setIndex
        self.reps = reps
        self.weightKg = weightKg
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.rpe = rpe
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
