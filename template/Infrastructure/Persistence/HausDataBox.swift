import SwiftData

enum HausDataBox {
    static let shared: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSession.self,
            PerformedSet.self,
            TrainingProgram.self,
            ProgramWeek.self,
            ProgramDay.self,
            FoodProduct.self,
            Meal.self,
            MealItem.self,
            HydrationLog.self,
            Book.self,
            ReadingSession.self,
            CalendarEvent.self,
            BodyMeasurement.self,
            UserGoal.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }()
}
