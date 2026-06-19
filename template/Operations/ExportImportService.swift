import Foundation
import SwiftData

// MARK: - Codable Backup DTOs

struct BackupFile: Codable {
    var schemaVersion: Int
    var exportedAt: Date
    var appName: String
    var data: BackupData
}

struct BackupData: Codable {
    var profile: ProfileDTO?
    var workouts: [WorkoutDTO]
    var workoutSessions: [WorkoutSessionDTO]
    var trainingPrograms: [ProgramDTO]
    var foods: [FoodDTO]
    var meals: [MealDTO]
    var hydrationLogs: [HydrationDTO]
    var books: [BookDTO]
    var readingSessions: [ReadingSessionDTO]
    var calendarEvents: [CalendarEventDTO]
    var bodyMeasurements: [BodyMeasurementDTO]
    var goals: [GoalDTO]
}

struct ProfileDTO: Codable {
    var id: UUID, name: String, age: Int?, heightCm: Double?, currentWeightKg: Double?, targetWeightKg: Double?
    var activityLevel: String, trainingLevel: String, mainGoals: [String]
    var dailyCaloriesGoal: Double, proteinGoalGrams: Double, fatGoalGrams: Double, carbsGoalGrams: Double, waterGoalMl: Int
}

struct ExerciseDTO: Codable {
    var id: UUID, name: String, muscleGroup: String, equipment: String?, sets: Int, reps: Int?, weightKg: Double?
    var durationSeconds: Int?, distanceMeters: Double?, restSeconds: Int, tempo: String?, rpe: Int?, notes: String?, orderIndex: Int
}

struct WorkoutDTO: Codable {
    var id: UUID, title: String, workoutDescription: String?, type: String, difficulty: String, goal: String?
    var estimatedDurationMinutes: Int, tags: [String], exercises: [ExerciseDTO]
}

struct PerformedSetDTO: Codable {
    var id: UUID, exerciseName: String, muscleGroup: String, setIndex: Int, reps: Int?, weightKg: Double?
    var durationSeconds: Int?, distanceMeters: Double?, rpe: Int?, isCompleted: Bool, completedAt: Date?
}

struct WorkoutSessionDTO: Codable {
    var id: UUID, workoutId: UUID?, workoutTitle: String, startedAt: Date, endedAt: Date?, durationSeconds: Int
    var status: String, perceivedDifficulty: Int?, notes: String?, totalVolume: Double
    var completedExercisesCount: Int, completedSetsCount: Int, performedSets: [PerformedSetDTO]
}

struct ProgramDayDTO: Codable {
    var id: UUID, dayIndex: Int, weekday: Int?, title: String, notes: String?, plannedWorkoutId: UUID?, isCompleted: Bool
}
struct ProgramWeekDTO: Codable {
    var id: UUID, weekIndex: Int, title: String, notes: String?, days: [ProgramDayDTO]
}
struct ProgramDTO: Codable {
    var id: UUID, title: String, programDescription: String?, goal: String, difficulty: String
    var startDate: Date?, endDate: Date?, weeksCount: Int, daysPerWeek: Int, status: String, weeks: [ProgramWeekDTO]
}

struct FoodDTO: Codable {
    var id: UUID, source: String, openFoodFactsId: String?, name: String, brand: String?, imageUrl: String?
    var caloriesPer100g: Double, proteinPer100g: Double, fatPer100g: Double, carbsPer100g: Double
    var sugarPer100g: Double?, fiberPer100g: Double?, saltPer100g: Double?
    var nutriScore: String?, ingredients: String?, allergens: String?, notes: String?, isFavorite: Bool
}

struct MealItemDTO: Codable {
    var id: UUID, foodProductId: UUID?, productName: String, amountGrams: Double
    var calories: Double, protein: Double, fat: Double, carbs: Double, sugar: Double?, fiber: Double?, salt: Double?
}
struct MealDTO: Codable {
    var id: UUID, date: Date, type: String, title: String, notes: String?, items: [MealItemDTO]
}

struct HydrationDTO: Codable { var id: UUID, date: Date, amountMl: Int, note: String? }

struct BookDTO: Codable {
    var id: UUID, openLibraryKey: String?, title: String, authors: [String], firstPublishYear: Int?
    var coverId: Int?, coverUrl: String?, language: String?, subjects: [String]
    var readingStatus: String, rating: Int?, progressPercent: Double, notes: String?
}

struct ReadingSessionDTO: Codable {
    var id: UUID, bookId: UUID?, bookTitle: String, date: Date, durationMinutes: Int, pagesRead: Int?, note: String?
}

struct CalendarEventDTO: Codable {
    var id: UUID, title: String, eventType: String, startDate: Date, endDate: Date?
    var status: String, notes: String?, colorHex: String?, relatedEntityId: UUID?
}

struct BodyMeasurementDTO: Codable {
    var id: UUID, date: Date, weightKg: Double?, bodyFatPercent: Double?, muscleMassKg: Double?
    var waistCm: Double?, chestCm: Double?, hipsCm: Double?, armCm: Double?, thighCm: Double?, neckCm: Double?, note: String?
}

struct GoalDTO: Codable {
    var id: UUID, title: String, type: String, targetValue: Double, currentValue: Double, unit: String
    var deadline: Date?, isCompleted: Bool, notes: String?
}

enum ImportMode { case merge, replaceAll }

struct ImportPreview {
    let workouts, workoutSessions, foods, meals, books, goals, bodyMeasurements, calendarEvents: Int
}

enum ExportImportError: LocalizedError {
    case unsupportedVersion
    case decodingFailed
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: "This backup was created by a newer version of the app."
        case .decodingFailed: "Failed to read the backup file."
        }
    }
}

@MainActor
final class ExportImportService {
    static let schemaVersion = 1
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    // MARK: Export

    func buildBackup() throws -> BackupFile {
        let workouts = try context.fetch(FetchDescriptor<Workout>())
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let programs = try context.fetch(FetchDescriptor<TrainingProgram>())
        let foods = try context.fetch(FetchDescriptor<FoodProduct>())
        let meals = try context.fetch(FetchDescriptor<Meal>())
        let hydration = try context.fetch(FetchDescriptor<HydrationLog>())
        let books = try context.fetch(FetchDescriptor<Book>())
        let readingSessions = try context.fetch(FetchDescriptor<ReadingSession>())
        let events = try context.fetch(FetchDescriptor<CalendarEvent>())
        let measurements = try context.fetch(FetchDescriptor<BodyMeasurement>())
        let goals = try context.fetch(FetchDescriptor<UserGoal>())
        let profile = try context.fetch(FetchDescriptor<UserProfile>()).first

        let data = BackupData(
            profile: profile.map(Self.dto),
            workouts: workouts.map(Self.dto),
            workoutSessions: sessions.map(Self.dto),
            trainingPrograms: programs.map(Self.dto),
            foods: foods.map(Self.dto),
            meals: meals.map(Self.dto),
            hydrationLogs: hydration.map { HydrationDTO(id: $0.id, date: $0.date, amountMl: $0.amountMl, note: $0.note) },
            books: books.map(Self.dto),
            readingSessions: readingSessions.map { ReadingSessionDTO(id: $0.id, bookId: $0.bookId, bookTitle: $0.bookTitle, date: $0.date, durationMinutes: $0.durationMinutes, pagesRead: $0.pagesRead, note: $0.note) },
            calendarEvents: events.map(Self.dto),
            bodyMeasurements: measurements.map(Self.dto),
            goals: goals.map(Self.dto)
        )
        return BackupFile(schemaVersion: Self.schemaVersion, exportedAt: .now, appName: "KineticHaus", data: data)
    }

    func exportJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(try buildBackup())
    }

    func writeExport() throws -> URL {
        let data = try exportJSONData()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("KineticHaus-Backup.json")
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: Import

    func decode(_ data: Data) throws -> BackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let backup = try? decoder.decode(BackupFile.self, from: data) else {
            throw ExportImportError.decodingFailed
        }
        guard backup.schemaVersion <= Self.schemaVersion else {
            throw ExportImportError.unsupportedVersion
        }
        return backup
    }

    func preview(_ backup: BackupFile) -> ImportPreview {
        let d = backup.data
        return ImportPreview(
            workouts: d.workouts.count, workoutSessions: d.workoutSessions.count, foods: d.foods.count,
            meals: d.meals.count, books: d.books.count, goals: d.goals.count,
            bodyMeasurements: d.bodyMeasurements.count, calendarEvents: d.calendarEvents.count
        )
    }

    func performImport(_ backup: BackupFile, mode: ImportMode) throws {
        if mode == .replaceAll { try deleteAll() }
        let d = backup.data

        let profileEmpty = try context.fetch(FetchDescriptor<UserProfile>()).isEmpty
        if let p = d.profile, mode == .replaceAll || profileEmpty {
            context.insert(Self.model(p))
        }
        d.workouts.forEach { context.insert(Self.model($0)) }
        d.workoutSessions.forEach { context.insert(Self.model($0)) }
        d.trainingPrograms.forEach { context.insert(Self.model($0)) }
        d.foods.forEach { context.insert(Self.model($0)) }
        d.meals.forEach { context.insert(Self.model($0)) }
        d.hydrationLogs.forEach { context.insert(HydrationLog(id: $0.id, date: $0.date, amountMl: $0.amountMl, note: $0.note)) }
        d.books.forEach { context.insert(Self.model($0)) }
        d.readingSessions.forEach { context.insert(ReadingSession(id: $0.id, bookId: $0.bookId, bookTitle: $0.bookTitle, date: $0.date, durationMinutes: $0.durationMinutes, pagesRead: $0.pagesRead, note: $0.note)) }
        d.calendarEvents.forEach { context.insert(Self.model($0)) }
        d.bodyMeasurements.forEach { context.insert(Self.model($0)) }
        d.goals.forEach { context.insert(Self.model($0)) }
        try context.save()
    }

    func deleteAll() throws {
        try context.delete(model: Workout.self)
        try context.delete(model: WorkoutSession.self)
        try context.delete(model: TrainingProgram.self)
        try context.delete(model: FoodProduct.self)
        try context.delete(model: Meal.self)
        try context.delete(model: HydrationLog.self)
        try context.delete(model: Book.self)
        try context.delete(model: ReadingSession.self)
        try context.delete(model: CalendarEvent.self)
        try context.delete(model: BodyMeasurement.self)
        try context.delete(model: UserGoal.self)
        try context.save()
    }

    func resetAll() throws {
        try deleteAll()
        try context.delete(model: UserProfile.self)
        try context.save()
    }
}

// MARK: - Mapping helpers

extension ExportImportService {
    static func dto(_ p: UserProfile) -> ProfileDTO {
        ProfileDTO(id: p.id, name: p.name, age: p.age, heightCm: p.heightCm, currentWeightKg: p.currentWeightKg, targetWeightKg: p.targetWeightKg, activityLevel: p.activityLevel, trainingLevel: p.trainingLevel.rawValue, mainGoals: p.mainGoals, dailyCaloriesGoal: p.dailyCaloriesGoal, proteinGoalGrams: p.proteinGoalGrams, fatGoalGrams: p.fatGoalGrams, carbsGoalGrams: p.carbsGoalGrams, waterGoalMl: p.waterGoalMl)
    }
    static func model(_ d: ProfileDTO) -> UserProfile {
        UserProfile(id: d.id, name: d.name, age: d.age, heightCm: d.heightCm, currentWeightKg: d.currentWeightKg, targetWeightKg: d.targetWeightKg, activityLevel: d.activityLevel, trainingLevel: DifficultyLevel(rawValue: d.trainingLevel) ?? .beginner, mainGoals: d.mainGoals, dailyCaloriesGoal: d.dailyCaloriesGoal, proteinGoalGrams: d.proteinGoalGrams, fatGoalGrams: d.fatGoalGrams, carbsGoalGrams: d.carbsGoalGrams, waterGoalMl: d.waterGoalMl)
    }

    static func dto(_ w: Workout) -> WorkoutDTO {
        WorkoutDTO(id: w.id, title: w.title, workoutDescription: w.workoutDescription, type: w.type.rawValue, difficulty: w.difficulty.rawValue, goal: w.goal, estimatedDurationMinutes: w.estimatedDurationMinutes, tags: w.tags, exercises: w.sortedExercises.map { e in
            ExerciseDTO(id: e.id, name: e.name, muscleGroup: e.muscleGroup.rawValue, equipment: e.equipment, sets: e.sets, reps: e.reps, weightKg: e.weightKg, durationSeconds: e.durationSeconds, distanceMeters: e.distanceMeters, restSeconds: e.restSeconds, tempo: e.tempo, rpe: e.rpe, notes: e.notes, orderIndex: e.orderIndex)
        })
    }
    static func model(_ d: WorkoutDTO) -> Workout {
        Workout(id: d.id, title: d.title, workoutDescription: d.workoutDescription, type: WorkoutType(rawValue: d.type) ?? .strength, difficulty: DifficultyLevel(rawValue: d.difficulty) ?? .beginner, goal: d.goal, estimatedDurationMinutes: d.estimatedDurationMinutes, tags: d.tags, exercises: d.exercises.map { e in
            WorkoutExercise(id: e.id, name: e.name, muscleGroup: MuscleGroup(rawValue: e.muscleGroup) ?? .other, equipment: e.equipment, sets: e.sets, reps: e.reps, weightKg: e.weightKg, durationSeconds: e.durationSeconds, distanceMeters: e.distanceMeters, restSeconds: e.restSeconds, tempo: e.tempo, rpe: e.rpe, notes: e.notes, orderIndex: e.orderIndex)
        })
    }

    static func dto(_ s: WorkoutSession) -> WorkoutSessionDTO {
        WorkoutSessionDTO(id: s.id, workoutId: s.workoutId, workoutTitle: s.workoutTitle, startedAt: s.startedAt, endedAt: s.endedAt, durationSeconds: s.durationSeconds, status: s.status.rawValue, perceivedDifficulty: s.perceivedDifficulty, notes: s.notes, totalVolume: s.totalVolume, completedExercisesCount: s.completedExercisesCount, completedSetsCount: s.completedSetsCount, performedSets: s.performedSets.map { p in
            PerformedSetDTO(id: p.id, exerciseName: p.exerciseName, muscleGroup: p.muscleGroup.rawValue, setIndex: p.setIndex, reps: p.reps, weightKg: p.weightKg, durationSeconds: p.durationSeconds, distanceMeters: p.distanceMeters, rpe: p.rpe, isCompleted: p.isCompleted, completedAt: p.completedAt)
        })
    }
    static func model(_ d: WorkoutSessionDTO) -> WorkoutSession {
        let s = WorkoutSession(id: d.id, workoutId: d.workoutId, workoutTitle: d.workoutTitle, startedAt: d.startedAt)
        s.endedAt = d.endedAt
        s.durationSeconds = d.durationSeconds
        s.status = SessionStatus(rawValue: d.status) ?? .completed
        s.perceivedDifficulty = d.perceivedDifficulty
        s.notes = d.notes
        s.totalVolume = d.totalVolume
        s.completedExercisesCount = d.completedExercisesCount
        s.completedSetsCount = d.completedSetsCount
        s.performedSets = d.performedSets.map { p in
            PerformedSet(id: p.id, exerciseName: p.exerciseName, muscleGroup: MuscleGroup(rawValue: p.muscleGroup) ?? .other, setIndex: p.setIndex, reps: p.reps, weightKg: p.weightKg, durationSeconds: p.durationSeconds, distanceMeters: p.distanceMeters, rpe: p.rpe, isCompleted: p.isCompleted, completedAt: p.completedAt)
        }
        return s
    }

    static func dto(_ p: TrainingProgram) -> ProgramDTO {
        ProgramDTO(id: p.id, title: p.title, programDescription: p.programDescription, goal: p.goal, difficulty: p.difficulty.rawValue, startDate: p.startDate, endDate: p.endDate, weeksCount: p.weeksCount, daysPerWeek: p.daysPerWeek, status: p.status.rawValue, weeks: p.sortedWeeks.map { w in
            ProgramWeekDTO(id: w.id, weekIndex: w.weekIndex, title: w.title, notes: w.notes, days: w.sortedDays.map { day in
                ProgramDayDTO(id: day.id, dayIndex: day.dayIndex, weekday: day.weekday, title: day.title, notes: day.notes, plannedWorkoutId: day.plannedWorkoutId, isCompleted: day.isCompleted)
            })
        })
    }
    static func model(_ d: ProgramDTO) -> TrainingProgram {
        TrainingProgram(id: d.id, title: d.title, programDescription: d.programDescription, goal: d.goal, difficulty: DifficultyLevel(rawValue: d.difficulty) ?? .beginner, startDate: d.startDate, endDate: d.endDate, weeksCount: d.weeksCount, daysPerWeek: d.daysPerWeek, status: ProgramStatus(rawValue: d.status) ?? .draft, weeks: d.weeks.map { w in
            ProgramWeek(id: w.id, weekIndex: w.weekIndex, title: w.title, notes: w.notes, days: w.days.map { day in
                ProgramDay(id: day.id, dayIndex: day.dayIndex, weekday: day.weekday, title: day.title, notes: day.notes, plannedWorkoutId: day.plannedWorkoutId, isCompleted: day.isCompleted)
            })
        })
    }

    static func dto(_ f: FoodProduct) -> FoodDTO {
        FoodDTO(id: f.id, source: f.source.rawValue, openFoodFactsId: f.openFoodFactsId, name: f.name, brand: f.brand, imageUrl: f.imageUrl, caloriesPer100g: f.caloriesPer100g, proteinPer100g: f.proteinPer100g, fatPer100g: f.fatPer100g, carbsPer100g: f.carbsPer100g, sugarPer100g: f.sugarPer100g, fiberPer100g: f.fiberPer100g, saltPer100g: f.saltPer100g, nutriScore: f.nutriScore, ingredients: f.ingredients, allergens: f.allergens, notes: f.notes, isFavorite: f.isFavorite)
    }
    static func model(_ d: FoodDTO) -> FoodProduct {
        FoodProduct(id: d.id, source: FoodSource(rawValue: d.source) ?? .imported, openFoodFactsId: d.openFoodFactsId, name: d.name, brand: d.brand, imageUrl: d.imageUrl, caloriesPer100g: d.caloriesPer100g, proteinPer100g: d.proteinPer100g, fatPer100g: d.fatPer100g, carbsPer100g: d.carbsPer100g, sugarPer100g: d.sugarPer100g, fiberPer100g: d.fiberPer100g, saltPer100g: d.saltPer100g, nutriScore: d.nutriScore, ingredients: d.ingredients, allergens: d.allergens, notes: d.notes, isFavorite: d.isFavorite)
    }

    static func dto(_ m: Meal) -> MealDTO {
        MealDTO(id: m.id, date: m.date, type: m.type.rawValue, title: m.title, notes: m.notes, items: m.items.map { i in
            MealItemDTO(id: i.id, foodProductId: i.foodProductId, productName: i.productName, amountGrams: i.amountGrams, calories: i.calories, protein: i.protein, fat: i.fat, carbs: i.carbs, sugar: i.sugar, fiber: i.fiber, salt: i.salt)
        })
    }
    static func model(_ d: MealDTO) -> Meal {
        Meal(id: d.id, date: d.date, type: MealType(rawValue: d.type) ?? .custom, title: d.title, notes: d.notes, items: d.items.map { i in
            MealItem(id: i.id, foodProductId: i.foodProductId, productName: i.productName, amountGrams: i.amountGrams, calories: i.calories, protein: i.protein, fat: i.fat, carbs: i.carbs, sugar: i.sugar, fiber: i.fiber, salt: i.salt)
        })
    }

    static func dto(_ b: Book) -> BookDTO {
        BookDTO(id: b.id, openLibraryKey: b.openLibraryKey, title: b.title, authors: b.authors, firstPublishYear: b.firstPublishYear, coverId: b.coverId, coverUrl: b.coverUrl, language: b.language, subjects: b.subjects, readingStatus: b.readingStatus.rawValue, rating: b.rating, progressPercent: b.progressPercent, notes: b.notes)
    }
    static func model(_ d: BookDTO) -> Book {
        Book(id: d.id, openLibraryKey: d.openLibraryKey, title: d.title, authors: d.authors, firstPublishYear: d.firstPublishYear, coverId: d.coverId, coverUrl: d.coverUrl, language: d.language, subjects: d.subjects, readingStatus: ReadingStatus(rawValue: d.readingStatus) ?? .wantToRead, rating: d.rating, progressPercent: d.progressPercent, notes: d.notes)
    }

    static func dto(_ e: CalendarEvent) -> CalendarEventDTO {
        CalendarEventDTO(id: e.id, title: e.title, eventType: e.eventType.rawValue, startDate: e.startDate, endDate: e.endDate, status: e.status.rawValue, notes: e.notes, colorHex: e.colorHex, relatedEntityId: e.relatedEntityId)
    }
    static func model(_ d: CalendarEventDTO) -> CalendarEvent {
        CalendarEvent(id: d.id, title: d.title, eventType: CalendarEventType(rawValue: d.eventType) ?? .note, startDate: d.startDate, endDate: d.endDate, status: CalendarEventStatus(rawValue: d.status) ?? .planned, notes: d.notes, colorHex: d.colorHex, relatedEntityId: d.relatedEntityId)
    }

    static func dto(_ m: BodyMeasurement) -> BodyMeasurementDTO {
        BodyMeasurementDTO(id: m.id, date: m.date, weightKg: m.weightKg, bodyFatPercent: m.bodyFatPercent, muscleMassKg: m.muscleMassKg, waistCm: m.waistCm, chestCm: m.chestCm, hipsCm: m.hipsCm, armCm: m.armCm, thighCm: m.thighCm, neckCm: m.neckCm, note: m.note)
    }
    static func model(_ d: BodyMeasurementDTO) -> BodyMeasurement {
        BodyMeasurement(id: d.id, date: d.date, weightKg: d.weightKg, bodyFatPercent: d.bodyFatPercent, muscleMassKg: d.muscleMassKg, waistCm: d.waistCm, chestCm: d.chestCm, hipsCm: d.hipsCm, armCm: d.armCm, thighCm: d.thighCm, neckCm: d.neckCm, note: d.note)
    }

    static func dto(_ g: UserGoal) -> GoalDTO {
        GoalDTO(id: g.id, title: g.title, type: g.type.rawValue, targetValue: g.targetValue, currentValue: g.currentValue, unit: g.unit, deadline: g.deadline, isCompleted: g.isCompleted, notes: g.notes)
    }
    static func model(_ d: GoalDTO) -> UserGoal {
        UserGoal(id: d.id, title: d.title, type: GoalType(rawValue: d.type) ?? .custom, targetValue: d.targetValue, currentValue: d.currentValue, unit: d.unit, deadline: d.deadline, isCompleted: d.isCompleted, notes: d.notes)
    }
}
