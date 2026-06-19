import Foundation

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, stretching, functional, mobility, recovery, mixed
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .strength: "Strength"
        case .cardio: "Cardio"
        case .stretching: "Stretching"
        case .functional: "Functional"
        case .mobility: "Mobility"
        case .recovery: "Recovery"
        case .mixed: "Mixed"
        }
    }
    var icon: String {
        switch self {
        case .strength: "figure.strengthtraining.traditional"
        case .cardio: "figure.run"
        case .stretching: "figure.flexibility"
        case .functional: "figure.cross.training"
        case .mobility: "figure.mind.and.body"
        case .recovery: "bed.double.fill"
        case .mixed: "square.grid.2x2.fill"
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced, professional
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        case .professional: "Professional"
        }
    }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, legs, shoulders, arms, core, glutes, fullBody, cardio, mobility, other
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .legs: "Legs"
        case .shoulders: "Shoulders"
        case .arms: "Arms"
        case .core: "Core"
        case .glutes: "Glutes"
        case .fullBody: "Full Body"
        case .cardio: "Cardio"
        case .mobility: "Mobility"
        case .other: "Other"
        }
    }
}

enum SessionStatus: String, Codable, CaseIterable, Identifiable {
    case planned, inProgress, completed, skipped, cancelled
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .planned: "Planned"
        case .inProgress: "In Progress"
        case .completed: "Completed"
        case .skipped: "Skipped"
        case .cancelled: "Cancelled"
        }
    }
}

enum ProgramStatus: String, Codable, CaseIterable, Identifiable {
    case draft, active, paused, completed
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .draft: "Draft"
        case .active: "Active"
        case .paused: "Paused"
        case .completed: "Completed"
        }
    }
}

enum FoodSource: String, Codable, CaseIterable, Identifiable {
    case manual, openFoodFacts, imported
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .manual: "Manual"
        case .openFoodFacts: "OpenFoodFacts"
        case .imported: "Imported"
        }
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, snack, lunch, dinner, postWorkout, custom
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .breakfast: "Breakfast"
        case .snack: "Snack"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .postWorkout: "Post Workout"
        case .custom: "Custom"
        }
    }
    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .snack: "carrot.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .postWorkout: "bolt.fill"
        case .custom: "fork.knife"
        }
    }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case wantToRead, reading, completed, paused, abandoned
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .wantToRead: "Want to Read"
        case .reading: "Reading"
        case .completed: "Completed"
        case .paused: "Paused"
        case .abandoned: "Abandoned"
        }
    }
}

enum CalendarEventType: String, Codable, CaseIterable, Identifiable {
    case workout, mealPlan, rest, measurement, reading, competition, note
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .workout: "Workout"
        case .mealPlan: "Meal Plan"
        case .rest: "Rest Day"
        case .measurement: "Body Measurement"
        case .reading: "Reading"
        case .competition: "Competition"
        case .note: "Note"
        }
    }
    var icon: String {
        switch self {
        case .workout: "figure.strengthtraining.traditional"
        case .mealPlan: "fork.knife"
        case .rest: "bed.double.fill"
        case .measurement: "scalemass.fill"
        case .reading: "books.vertical.fill"
        case .competition: "trophy.fill"
        case .note: "note.text"
        }
    }
}

enum CalendarEventStatus: String, Codable, CaseIterable, Identifiable {
    case planned, completed, skipped, moved, cancelled
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .planned: "Planned"
        case .completed: "Completed"
        case .skipped: "Skipped"
        case .moved: "Moved"
        case .cancelled: "Cancelled"
        }
    }
}

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case bodyWeight, calories, protein, workoutsCount, workoutDuration, water, reading, programCompletion, custom
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .bodyWeight: "Body Weight"
        case .calories: "Calories"
        case .protein: "Protein"
        case .workoutsCount: "Workouts Count"
        case .workoutDuration: "Workout Duration"
        case .water: "Water"
        case .reading: "Reading"
        case .programCompletion: "Program Completion"
        case .custom: "Custom"
        }
    }
    var defaultUnit: String {
        switch self {
        case .bodyWeight: "kg"
        case .calories: "kcal"
        case .protein: "g"
        case .workoutsCount: "sessions"
        case .workoutDuration: "min"
        case .water: "ml"
        case .reading: "books"
        case .programCompletion: "%"
        case .custom: ""
        }
    }
}
