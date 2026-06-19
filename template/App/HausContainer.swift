import SwiftUI
import SwiftData

@MainActor
final class HausContainer: ObservableObject {
    let context: ModelContext

    let apiClient: APIClientProtocol
    let networkMonitor: NetworkMonitor

    let workoutRepository: WorkoutRepositoryProtocol
    let programRepository: ProgramRepositoryProtocol
    let nutritionRepository: NutritionRepositoryProtocol
    let foodProductRepository: FoodProductRepositoryProtocol
    let bookRepository: BookRepositoryProtocol
    let calendarRepository: CalendarRepositoryProtocol
    let bodyRepository: BodyMeasurementRepositoryProtocol
    let goalRepository: GoalRepositoryProtocol
    let profileRepository: UserProfileRepositoryProtocol

    let openFoodFactsService: OpenFoodFactsServiceProtocol
    let openLibraryService: OpenLibraryServiceProtocol
    let nutritionCalculation: NutritionCalculationService
    let workoutSessionService: WorkoutSessionService
    let analyticsService: AnalyticsService
    let exportImportService: ExportImportService

    init(container: ModelContainer = HausDataBox.shared) {
        let ctx = container.mainContext
        self.context = ctx

        let client = APIClient()
        self.apiClient = client
        self.networkMonitor = NetworkMonitor()

        let workout = WorkoutRepository(context: ctx)
        let program = ProgramRepository(context: ctx)
        let nutrition = NutritionRepository(context: ctx)
        let food = FoodProductRepository(context: ctx)
        let book = BookRepository(context: ctx)
        let calendar = CalendarRepository(context: ctx)
        let body = BodyMeasurementRepository(context: ctx)
        let goal = GoalRepository(context: ctx)
        let profile = UserProfileRepository(context: ctx)

        self.workoutRepository = workout
        self.programRepository = program
        self.nutritionRepository = nutrition
        self.foodProductRepository = food
        self.bookRepository = book
        self.calendarRepository = calendar
        self.bodyRepository = body
        self.goalRepository = goal
        self.profileRepository = profile

        self.openFoodFactsService = OpenFoodFactsService(apiClient: client)
        self.openLibraryService = OpenLibraryService(apiClient: client)
        self.nutritionCalculation = NutritionCalculationService()
        self.workoutSessionService = WorkoutSessionService()
        self.analyticsService = AnalyticsService(
            workoutRepo: workout, nutritionRepo: nutrition, bodyRepo: body, goalRepo: goal, bookRepo: book
        )
        self.exportImportService = ExportImportService(context: ctx)

        MockDataSeeder.seedIfNeeded(ctx)
    }

    func currentProfile() -> UserProfile? {
        try? profileRepository.fetchProfile()
    }
}
