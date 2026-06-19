import Foundation

struct OpenLibrarySearchResponse: Decodable {
    let docs: [OpenLibraryBookDTO]
}

struct OpenLibraryBookDTO: Decodable, Identifiable {
    var id: String { key }

    let key: String
    let title: String
    let authorName: [String]?
    let firstPublishYear: Int?
    let coverI: Int?
    let language: [String]?
    let subject: [String]?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authorName = "author_name"
        case firstPublishYear = "first_publish_year"
        case coverI = "cover_i"
        case language
        case subject
    }
}

extension OpenLibraryBookDTO {
    var coverURL: String? {
        guard let coverI else { return nil }
        return "https://covers.openlibrary.org/b/id/\(coverI)-M.jpg"
    }

    var authorsText: String {
        guard let authorName, !authorName.isEmpty else { return "Unknown Author" }
        return authorName.joined(separator: ", ")
    }

    func toBook() -> Book {
        Book(
            openLibraryKey: key,
            title: title,
            authors: authorName ?? [],
            firstPublishYear: firstPublishYear,
            coverId: coverI,
            coverUrl: coverURL,
            language: language?.first,
            subjects: Array((subject ?? []).prefix(20)),
            readingStatus: .wantToRead,
            progressPercent: 0
        )
    }
}

protocol OpenLibraryServiceProtocol {
    func searchBooks(query: String, language: String?) async throws -> [OpenLibraryBookDTO]
}

final class OpenLibraryService: OpenLibraryServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func searchBooks(query: String, language: String? = nil) async throws -> [OpenLibraryBookDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        let endpoint = Endpoint.openLibrarySearch(query: trimmed, language: language)
        let response: OpenLibrarySearchResponse = try await apiClient.request(endpoint)
        return response.docs
    }
}
