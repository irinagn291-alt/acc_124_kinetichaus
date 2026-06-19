import SwiftUI

struct CodexSearchView: View {
    @EnvironmentObject private var environment: HausContainer
    @EnvironmentObject private var network: NetworkMonitor
    @StateObject private var vm = CodexSearchViewModel()

    private let suggestions = ["strength training", "running", "endurance", "nutrition", "bodybuilding", "mobility", "sports psychology", "recovery", "exercise anatomy", "powerlifting", "weight loss", "fitness habits"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GridSpacing.md) {
                searchField
                content
            }
            .padding(GridSpacing.md)
        }
        .background(BauhausColors.background)
        .navigationTitle("Search Books")
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.configure(service: environment.openLibraryService, repository: environment.bookRepository, networkMonitor: network) }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: GridIcons.search).foregroundStyle(BauhausColors.textMuted)
            TextField("Search sports books...", text: $vm.query)
                .foregroundStyle(BauhausColors.textPrimary).submitLabel(.search)
                .onChange(of: vm.query) { _, _ in vm.queryChanged() }
                .onSubmit { Task { await vm.search() } }
        }
        .padding().background(BauhausColors.surface).clipShape(RoundedRectangle(cornerRadius: SharpRadius.md))
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle: suggestionsView
        case .loading: LoadingStateView(message: "Searching...")
        case .loaded(let docs): ForEach(docs) { bookRow($0) }
        case .empty: BlankGridView(systemImage: "magnifyingglass", title: "No books found", message: "Try another search term.")
        case .error(let m): ErrorStateView(title: "Search failed", message: m, retryTitle: "Retry") { Task { await vm.search() } }
        case .offline: BlankGridView(systemImage: GridIcons.offline, title: "No Internet Connection", message: "You can still open My Library offline.")
        }
    }

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: GridSpacing.sm) {
            SectionHeader(title: "Suggestions")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: GridSpacing.xs) {
                ForEach(suggestions, id: \.self) { s in
                    Button { vm.query = s; vm.queryChanged() } label: {
                        Text(s).font(GridTypography.caption).frame(maxWidth: .infinity).padding(GridSpacing.sm)
                            .background(BauhausColors.surface).foregroundStyle(BauhausColors.textSecondary).clipShape(RoundedRectangle(cornerRadius: SharpRadius.sm))
                    }
                }
            }
        }
    }

    private func bookRow(_ dto: OpenLibraryBookDTO) -> some View {
        GridBlock {
            HStack(spacing: GridSpacing.sm) {
                GridImageLoader(urlString: dto.coverURL, placeholderSymbol: "book.closed.fill").frame(width: 48, height: 64).clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(dto.title).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary).lineLimit(2)
                    Text(dto.authorsText).font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted).lineLimit(1)
                    if let year = dto.firstPublishYear { Text("\(String(year))").font(.caption2).foregroundStyle(BauhausColors.textMuted) }
                }
                Spacer()
                Button { vm.saveBook(dto) } label: { Image(systemName: "bookmark.circle.fill").font(.title2).foregroundStyle(BauhausColors.primary) }
                    .frame(width: 44, height: 44).accessibilityLabel("Save Book")
            }
        }
    }
}
