import SwiftUI

@MainActor
final class IntakeSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var remoteState: ViewState<[OpenFoodFactsProductDTO]> = .idle
    @Published var localResults: [FoodProduct] = []
    @Published var recentSearches: [String] = []

    private var service: OpenFoodFactsServiceProtocol?
    private var repository: FoodProductRepositoryProtocol?
    private var networkMonitor: NetworkMonitor?
    private var searchTask: Task<Void, Never>?

    func configure(service: OpenFoodFactsServiceProtocol, repository: FoodProductRepositoryProtocol, networkMonitor: NetworkMonitor) {
        guard self.service == nil else { return }
        self.service = service
        self.repository = repository
        self.networkMonitor = networkMonitor
    }

    func queryChanged() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { remoteState = .idle; localResults = []; return }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    func search() async {
        guard let service, let repository, let networkMonitor else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { remoteState = .idle; localResults = []; return }

        localResults = (try? repository.searchLocalProducts(query: trimmed)) ?? []
        guard networkMonitor.isConnected else { remoteState = .offline; return }

        remoteState = .loading
        do {
            let results = try await service.searchProducts(query: trimmed)
            remoteState = results.isEmpty ? .empty : .loaded(results)
            if !recentSearches.contains(trimmed) {
                recentSearches.insert(trimmed, at: 0)
                recentSearches = Array(recentSearches.prefix(8))
            }
        } catch {
            remoteState = .error(error.localizedDescription)
        }
    }

    func saveRemoteProduct(_ dto: OpenFoodFactsProductDTO) -> FoodProduct? {
        guard let repository else { return nil }
        let product = dto.toFoodProduct()
        do { try repository.saveProduct(product); HapticsManager.success(); return product }
        catch { remoteState = .error("Failed to save product."); return nil }
    }
}

@MainActor
final class CodexSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var state: ViewState<[OpenLibraryBookDTO]> = .idle

    private var service: OpenLibraryServiceProtocol?
    private var repository: BookRepositoryProtocol?
    private var networkMonitor: NetworkMonitor?
    private var searchTask: Task<Void, Never>?

    func configure(service: OpenLibraryServiceProtocol, repository: BookRepositoryProtocol, networkMonitor: NetworkMonitor) {
        guard self.service == nil else { return }
        self.service = service
        self.repository = repository
        self.networkMonitor = networkMonitor
    }

    func queryChanged() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { state = .idle; return }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    func search() async {
        guard let service, let networkMonitor else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { state = .idle; return }
        guard networkMonitor.isConnected else { state = .offline; return }
        state = .loading
        do {
            let results = try await service.searchBooks(query: trimmed, language: nil)
            state = results.isEmpty ? .empty : .loaded(results)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    @discardableResult
    func saveBook(_ dto: OpenLibraryBookDTO) -> Bool {
        guard let repository else { return false }
        do { try repository.saveBook(dto.toBook()); HapticsManager.success(); return true }
        catch { state = .error("Failed to save book."); return false }
    }
}
