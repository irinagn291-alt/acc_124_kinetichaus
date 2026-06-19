import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID
    var openLibraryKey: String?
    var title: String
    var authors: [String]
    var firstPublishYear: Int?
    var coverId: Int?
    var coverUrl: String?
    var language: String?
    var subjects: [String]

    var readingStatus: ReadingStatus
    var rating: Int?
    var progressPercent: Double
    var notes: String?

    var savedAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        openLibraryKey: String? = nil,
        title: String,
        authors: [String] = [],
        firstPublishYear: Int? = nil,
        coverId: Int? = nil,
        coverUrl: String? = nil,
        language: String? = nil,
        subjects: [String] = [],
        readingStatus: ReadingStatus = .wantToRead,
        rating: Int? = nil,
        progressPercent: Double = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.openLibraryKey = openLibraryKey
        self.title = title
        self.authors = authors
        self.firstPublishYear = firstPublishYear
        self.coverId = coverId
        self.coverUrl = coverUrl
        self.language = language
        self.subjects = subjects
        self.readingStatus = readingStatus
        self.rating = rating
        self.progressPercent = progressPercent
        self.notes = notes
        self.savedAt = .now
        self.updatedAt = .now
    }

    var authorsText: String {
        authors.isEmpty ? "Unknown Author" : authors.joined(separator: ", ")
    }
}

@Model
final class ReadingSession {
    var id: UUID
    var bookId: UUID?
    var bookTitle: String
    var date: Date
    var durationMinutes: Int
    var pagesRead: Int?
    var note: String?

    init(
        id: UUID = UUID(),
        bookId: UUID? = nil,
        bookTitle: String,
        date: Date = .now,
        durationMinutes: Int,
        pagesRead: Int? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.date = date
        self.durationMinutes = durationMinutes
        self.pagesRead = pagesRead
        self.note = note
    }
}
