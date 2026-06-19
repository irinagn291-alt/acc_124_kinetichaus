import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var id: UUID
    var title: String
    var eventType: CalendarEventType
    var startDate: Date
    var endDate: Date?
    var status: CalendarEventStatus
    var notes: String?
    var colorHex: String?
    var relatedEntityId: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        eventType: CalendarEventType,
        startDate: Date,
        endDate: Date? = nil,
        status: CalendarEventStatus = .planned,
        notes: String? = nil,
        colorHex: String? = nil,
        relatedEntityId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.eventType = eventType
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.notes = notes
        self.colorHex = colorHex
        self.relatedEntityId = relatedEntityId
        self.createdAt = .now
        self.updatedAt = .now
    }
}

@Model
final class BodyMeasurement {
    var id: UUID
    var date: Date

    var weightKg: Double?
    var bodyFatPercent: Double?
    var muscleMassKg: Double?

    var waistCm: Double?
    var chestCm: Double?
    var hipsCm: Double?
    var armCm: Double?
    var thighCm: Double?
    var neckCm: Double?

    var note: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weightKg: Double? = nil,
        bodyFatPercent: Double? = nil,
        muscleMassKg: Double? = nil,
        waistCm: Double? = nil,
        chestCm: Double? = nil,
        hipsCm: Double? = nil,
        armCm: Double? = nil,
        thighCm: Double? = nil,
        neckCm: Double? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.bodyFatPercent = bodyFatPercent
        self.muscleMassKg = muscleMassKg
        self.waistCm = waistCm
        self.chestCm = chestCm
        self.hipsCm = hipsCm
        self.armCm = armCm
        self.thighCm = thighCm
        self.neckCm = neckCm
        self.note = note
        self.createdAt = .now
        self.updatedAt = .now
    }
}

@Model
final class UserGoal {
    var id: UUID
    var title: String
    var type: GoalType
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var deadline: Date?
    var isCompleted: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        type: GoalType,
        targetValue: Double,
        currentValue: Double = 0,
        unit: String,
        deadline: Date? = nil,
        isCompleted: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.notes = notes
        self.createdAt = .now
        self.updatedAt = .now
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(max(currentValue / targetValue, 0), 1)
    }
}
