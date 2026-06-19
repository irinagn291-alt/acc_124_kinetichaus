import Foundation
import SwiftData

protocol WorkoutRepositoryProtocol {
    func fetchWorkouts() throws -> [Workout]
    func fetchWorkout(id: UUID) throws -> Workout?
    func saveWorkout(_ workout: Workout) throws
    func deleteWorkout(_ workout: Workout) throws
    func fetchSessions(from startDate: Date, to endDate: Date) throws -> [WorkoutSession]
    func fetchAllSessions() throws -> [WorkoutSession]
    func saveSession(_ session: WorkoutSession) throws
    func deleteSession(_ session: WorkoutSession) throws
}

protocol ProgramRepositoryProtocol {
    func fetchPrograms() throws -> [TrainingProgram]
    func fetchProgram(id: UUID) throws -> TrainingProgram?
    func saveProgram(_ program: TrainingProgram) throws
    func deleteProgram(_ program: TrainingProgram) throws
    func fetchActiveProgram() throws -> TrainingProgram?
}

protocol NutritionRepositoryProtocol {
    func fetchMeals(for date: Date) throws -> [Meal]
    func fetchMeals(from startDate: Date, to endDate: Date) throws -> [Meal]
    func saveMeal(_ meal: Meal) throws
    func deleteMeal(_ meal: Meal) throws
    func fetchHydrationLogs(for date: Date) throws -> [HydrationLog]
    func addHydration(amountMl: Int, date: Date) throws
    func deleteHydrationLog(_ log: HydrationLog) throws
    func fetchNutritionSummary(for date: Date) throws -> NutritionSummary
}

protocol FoodProductRepositoryProtocol {
    func fetchProducts() throws -> [FoodProduct]
    func fetchFavoriteProducts() throws -> [FoodProduct]
    func searchLocalProducts(query: String) throws -> [FoodProduct]
    func saveProduct(_ product: FoodProduct) throws
    func deleteProduct(_ product: FoodProduct) throws
}

protocol BookRepositoryProtocol {
    func fetchBooks() throws -> [Book]
    func fetchBook(id: UUID) throws -> Book?
    func fetchBooks(status: ReadingStatus) throws -> [Book]
    func searchLocalBooks(query: String) throws -> [Book]
    func saveBook(_ book: Book) throws
    func deleteBook(_ book: Book) throws
    func fetchReadingSessions(from startDate: Date, to endDate: Date) throws -> [ReadingSession]
    func fetchAllReadingSessions() throws -> [ReadingSession]
    func saveReadingSession(_ session: ReadingSession) throws
}

protocol CalendarRepositoryProtocol {
    func fetchEvents(from startDate: Date, to endDate: Date) throws -> [CalendarEvent]
    func fetchEvents(for date: Date) throws -> [CalendarEvent]
    func saveEvent(_ event: CalendarEvent) throws
    func deleteEvent(_ event: CalendarEvent) throws
}

protocol BodyMeasurementRepositoryProtocol {
    func fetchMeasurements() throws -> [BodyMeasurement]
    func fetchMeasurements(from startDate: Date, to endDate: Date) throws -> [BodyMeasurement]
    func saveMeasurement(_ measurement: BodyMeasurement) throws
    func deleteMeasurement(_ measurement: BodyMeasurement) throws
}

protocol GoalRepositoryProtocol {
    func fetchGoals() throws -> [UserGoal]
    func fetchActiveGoals() throws -> [UserGoal]
    func fetchCompletedGoals() throws -> [UserGoal]
    func saveGoal(_ goal: UserGoal) throws
    func deleteGoal(_ goal: UserGoal) throws
}

protocol UserProfileRepositoryProtocol {
    func fetchProfile() throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) throws
}

// MARK: - Implementations

@MainActor
final class SwiftDataRepository {
    let context: ModelContext
    init(context: ModelContext) { self.context = context }
}

@MainActor
final class WorkoutRepository: WorkoutRepositoryProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetchWorkouts() throws -> [Workout] {
        try context.fetch(FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
    }
    func fetchWorkout(id: UUID) throws -> Workout? {
        try context.fetch(FetchDescriptor<Workout>(predicate: #Predicate { $0.id == id })).first
    }
    func saveWorkout(_ workout: Workout) throws {
        workout.updatedAt = .now
        context.insert(workout)
        try context.save()
    }
    func deleteWorkout(_ workout: Workout) throws {
        context.delete(workout)
        try context.save()
    }
    func fetchSessions(from startDate: Date, to endDate: Date) throws -> [WorkoutSession] {
        try context.fetch(FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.startedAt >= startDate && $0.startedAt < endDate },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        ))
    }
    func fetchAllSessions() throws -> [WorkoutSession] {
        try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)]))
    }
    func saveSession(_ session: WorkoutSession) throws {
        context.insert(session)
        try context.save()
    }
    func deleteSession(_ session: WorkoutSession) throws {
        context.delete(session)
        try context.save()
    }
}

@MainActor
final class ProgramRepository: ProgramRepositoryProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetchPrograms() throws -> [TrainingProgram] {
        try context.fetch(FetchDescriptor<TrainingProgram>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
    }
    func fetchProgram(id: UUID) throws -> TrainingProgram? {
        try context.fetch(FetchDescriptor<TrainingProgram>(predicate: #Predicate { $0.id == id })).first
    }
    func saveProgram(_ program: TrainingProgram) throws {
        program.updatedAt = .now
        context.insert(program)
        try context.save()
    }
    func deleteProgram(_ program: TrainingProgram) throws {
        context.delete(program)
        try context.save()
    }
    func fetchActiveProgram() throws -> TrainingProgram? {
        try fetchPrograms().first { $0.status == .active }
    }
}

@MainActor
final class NutritionRepository: NutritionRepositoryProtocol {
    private let context: ModelContext
    private let calc = NutritionCalculationService()
    init(context: ModelContext) { self.context = context }

    func fetchMeals(for date: Date) throws -> [Meal] {
        let (start, end) = DateUtils.dayRange(for: date)
        return try fetchMeals(from: start, to: end)
    }
    func fetchMeals(from startDate: Date, to endDate: Date) throws -> [Meal] {
        try context.fetch(FetchDescriptor<Meal>(
            predicate: #Predicate { $0.date >= startDate && $0.date < endDate },
            sortBy: [SortDescriptor(\.date)]
        ))
    }
    func saveMeal(_ meal: Meal) throws {
        meal.updatedAt = .now
        context.insert(meal)
        try context.save()
    }
    func deleteMeal(_ meal: Meal) throws {
        context.delete(meal)
        try context.save()
    }
    func fetchHydrationLogs(for date: Date) throws -> [HydrationLog] {
        let (start, end) = DateUtils.dayRange(for: date)
        return try context.fetch(FetchDescriptor<HydrationLog>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))
    }
    func addHydration(amountMl: Int, date: Date) throws {
        context.insert(HydrationLog(date: date, amountMl: amountMl))
        try context.save()
    }
    func deleteHydrationLog(_ log: HydrationLog) throws {
        context.delete(log)
        try context.save()
    }
    func fetchNutritionSummary(for date: Date) throws -> NutritionSummary {
        calc.summary(for: try fetchMeals(for: date))
    }
}

@MainActor
final class FoodProductRepository: FoodProductRepositoryProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetchProducts() throws -> [FoodProduct] {
        try context.fetch(FetchDescriptor<FoodProduct>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
    }
    func fetchFavoriteProducts() throws -> [FoodProduct] {
        try context.fetch(FetchDescriptor<FoodProduct>(predicate: #Predicate { $0.isFavorite }, sortBy: [SortDescriptor(\.name)]))
    }
    func searchLocalProducts(query: String) throws -> [FoodProduct] {
        guard !query.isEmpty else { return try fetchProducts() }
        return try fetchProducts().filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    func saveProduct(_ product: FoodProduct) throws {
        product.updatedAt = .now
        context.insert(product)
        try context.save()
    }
    func deleteProduct(_ product: FoodProduct) throws {
        context.delete(product)
        try context.save()
    }
}

@MainActor
final class BookRepository: BookRepositoryProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetchBooks() throws -> [Book] {
        try context.fetch(FetchDescriptor<Book>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)]))
    }
    func fetchBook(id: UUID) throws -> Book? {
        try context.fetch(FetchDescriptor<Book>(predicate: #Predicate { $0.id == id })).first
    }
    func fetchBooks(status: ReadingStatus) throws -> [Book] {
        try fetchBooks().filter { $0.readingStatus == status }
    }
    func searchLocalBooks(query: String) throws -> [Book] {
        guard !query.isEmpty else { return try fetchBooks() }
        return try fetchBooks().filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
    func saveBook(_ book: Book) throws {
        book.updatedAt = .now
        context.insert(book)
        try context.save()
    }
    func deleteBook(_ book: Book) throws {
        context.delete(book)
        try context.save()
    }
    func fetchReadingSessions(from startDate: Date, to endDate: Date) throws -> [ReadingSession] {
        try context.fetch(FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.date >= startDate && $0.date < endDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))
    }
    func fetchAllReadingSessions() throws -> [ReadingSession] {
        try context.fetch(FetchDescriptor<ReadingSession>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
    }
    func saveReadingSession(_ session: ReadingSession) throws {
        context.insert(session)
        try context.save()
    }
}

@MainActor
final class CalendarRepository: CalendarRepositoryProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetchEvents(from startDate: Date, to endDate: Date) throws -> [CalendarEvent] {
        try context.fetch(FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { $0.startDate >= startDate && $0.startDate < endDate },
            sortBy: [SortDescriptor(\.startDate)]
        ))
    }
    func fetchEvents(for date: Date) throws -> [CalendarEvent] {
        let (start, end) = DateUtils.dayRange(for: date)
        return try fetchEvents(from: start, to: end)
    }
    func saveEvent(_ event: CalendarEvent) throws {
        event.updatedAt = .now
        context.insert(event)
        try context.save()
    }
    func deleteEvent(_ event: CalendarEvent) throws {
        context.delete(event)
        try context.save()
    }
}

@MainActor
final class BodyMeasurementRepository: BodyMeasurementRepositoryProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetchMeasurements() throws -> [BodyMeasurement] {
        try context.fetch(FetchDescriptor<BodyMeasurement>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
    }
    func fetchMeasurements(from startDate: Date, to endDate: Date) throws -> [BodyMeasurement] {
        try context.fetch(FetchDescriptor<BodyMeasurement>(
            predicate: #Predicate { $0.date >= startDate && $0.date < endDate },
            sortBy: [SortDescriptor(\.date)]
        ))
    }
    func saveMeasurement(_ measurement: BodyMeasurement) throws {
        measurement.updatedAt = .now
        context.insert(measurement)
        try context.save()
    }
    func deleteMeasurement(_ measurement: BodyMeasurement) throws {
        context.delete(measurement)
        try context.save()
    }
}

@MainActor
final class GoalRepository: GoalRepositoryProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetchGoals() throws -> [UserGoal] {
        try context.fetch(FetchDescriptor<UserGoal>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
    }
    func fetchActiveGoals() throws -> [UserGoal] {
        try context.fetch(FetchDescriptor<UserGoal>(predicate: #Predicate { !$0.isCompleted }, sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    }
    func fetchCompletedGoals() throws -> [UserGoal] {
        try context.fetch(FetchDescriptor<UserGoal>(predicate: #Predicate { $0.isCompleted }))
    }
    func saveGoal(_ goal: UserGoal) throws {
        goal.updatedAt = .now
        context.insert(goal)
        try context.save()
    }
    func deleteGoal(_ goal: UserGoal) throws {
        context.delete(goal)
        try context.save()
    }
}

@MainActor
final class UserProfileRepository: UserProfileRepositoryProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetchProfile() throws -> UserProfile? {
        try context.fetch(FetchDescriptor<UserProfile>()).first
    }
    func saveProfile(_ profile: UserProfile) throws {
        profile.updatedAt = .now
        context.insert(profile)
        try context.save()
    }
}
