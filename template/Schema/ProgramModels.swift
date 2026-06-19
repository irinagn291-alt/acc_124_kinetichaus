import Foundation
import SwiftData

@Model
final class TrainingProgram {
    var id: UUID
    var title: String
    var programDescription: String?
    var goal: String
    var difficulty: DifficultyLevel
    var startDate: Date?
    var endDate: Date?
    var weeksCount: Int
    var daysPerWeek: Int
    var status: ProgramStatus
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var weeks: [ProgramWeek]

    init(
        id: UUID = UUID(),
        title: String,
        programDescription: String? = nil,
        goal: String,
        difficulty: DifficultyLevel = .beginner,
        startDate: Date? = nil,
        endDate: Date? = nil,
        weeksCount: Int,
        daysPerWeek: Int,
        status: ProgramStatus = .draft,
        weeks: [ProgramWeek] = []
    ) {
        self.id = id
        self.title = title
        self.programDescription = programDescription
        self.goal = goal
        self.difficulty = difficulty
        self.startDate = startDate
        self.endDate = endDate
        self.weeksCount = weeksCount
        self.daysPerWeek = daysPerWeek
        self.status = status
        self.weeks = weeks
        self.createdAt = .now
        self.updatedAt = .now
    }

    var sortedWeeks: [ProgramWeek] { weeks.sorted { $0.weekIndex < $1.weekIndex } }

    var allDays: [ProgramDay] { weeks.flatMap { $0.days } }
}

@Model
final class ProgramWeek {
    var id: UUID
    var weekIndex: Int
    var title: String
    var notes: String?

    @Relationship(deleteRule: .cascade)
    var days: [ProgramDay]

    init(
        id: UUID = UUID(),
        weekIndex: Int,
        title: String,
        notes: String? = nil,
        days: [ProgramDay] = []
    ) {
        self.id = id
        self.weekIndex = weekIndex
        self.title = title
        self.notes = notes
        self.days = days
    }

    var sortedDays: [ProgramDay] { days.sorted { $0.dayIndex < $1.dayIndex } }
}

@Model
final class ProgramDay {
    var id: UUID
    var dayIndex: Int
    var weekday: Int?
    var title: String
    var notes: String?
    var plannedWorkoutId: UUID?
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        dayIndex: Int,
        weekday: Int? = nil,
        title: String,
        notes: String? = nil,
        plannedWorkoutId: UUID? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.dayIndex = dayIndex
        self.weekday = weekday
        self.title = title
        self.notes = notes
        self.plannedWorkoutId = plannedWorkoutId
        self.isCompleted = isCompleted
    }
}
