import SwiftUI

struct CodexView: View {
    @EnvironmentObject private var environment: HausContainer

    enum Tab: String, CaseIterable, Identifiable {
        case myLibrary = "My Library", search = "Search", categories = "Categories", notes = "Notes"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .myLibrary
    @State private var books: [Book] = []
    @State private var statusFilter: ReadingStatus?

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Group {
                switch tab {
                case .myLibrary: myLibrary
                case .search: CodexSearchView()
                case .categories: categories
                case .notes: notes
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BauhausColors.background)
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear(perform: reload)
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GridSpacing.xs) {
                ForEach(Tab.allCases) { item in
                    Button { tab = item } label: {
                        Text(item.rawValue)
                            .font(GridTypography.captionMedium)
                            .padding(.horizontal, GridSpacing.sm)
                            .padding(.vertical, GridSpacing.xs)
                            .background(tab == item ? BauhausColors.primary : BauhausColors.surface)
                            .foregroundStyle(tab == item ? .black : BauhausColors.textSecondary)
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel(item.rawValue)
                }
            }
            .padding(.horizontal, GridSpacing.md)
            .padding(.vertical, GridSpacing.sm)
        }
    }

    private var myLibrary: some View {
        Group {
            if books.isEmpty {
                BlankGridView(systemImage: GridIcons.library, title: "No books saved", message: "Search OpenLibrary and save useful sports books.", actionTitle: "Search Books") { tab = .search }
            } else {
                ScrollView {
                    VStack(spacing: GridSpacing.sm) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                chip("All", isOn: statusFilter == nil) { statusFilter = nil }
                                ForEach(ReadingStatus.allCases) { st in chip(st.displayName, isOn: statusFilter == st) { statusFilter = st } }
                            }
                        }
                        ForEach(books.filter { statusFilter == nil || $0.readingStatus == statusFilter }) { book in
                            NavigationLink { CodexDetailView(book: book) } label: { bookRow(book) }
                        }
                    }
                    .padding(GridSpacing.md)
                }
            }
        }
    }

    private var categories: some View {
        let subjects = Dictionary(grouping: books.flatMap { $0.subjects }, by: { $0 }).map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
        return ScrollView {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                if subjects.isEmpty { Text("No categories yet").foregroundStyle(BauhausColors.textMuted).padding() }
                ForEach(subjects.prefix(40), id: \.0) { subject, count in
                    GridBlock { HStack { Text(subject).foregroundStyle(BauhausColors.textPrimary); Spacer(); Text("\(count)").foregroundStyle(BauhausColors.textMuted) } }
                }
            }
            .padding(GridSpacing.md)
        }
    }

    private var notes: some View {
        let withNotes = books.filter { ($0.notes ?? "").isEmpty == false }
        return ScrollView {
            VStack(spacing: GridSpacing.sm) {
                if withNotes.isEmpty { BlankGridView(systemImage: "note.text", title: "No notes", message: "Add notes to your saved books.") }
                ForEach(withNotes) { book in
                    NavigationLink { CodexDetailView(book: book) } label: {
                        GridBlock {
                            VStack(alignment: .leading) {
                                Text(book.title).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary)
                                Text(book.notes ?? "").font(GridTypography.caption).foregroundStyle(BauhausColors.textSecondary).lineLimit(3)
                            }
                        }
                    }
                }
            }
            .padding(GridSpacing.md)
        }
    }

    private func bookRow(_ book: Book) -> some View {
        GridBlock {
            HStack(spacing: GridSpacing.sm) {
                GridImageLoader(urlString: book.coverUrl, placeholderSymbol: "book.closed.fill").frame(width: 48, height: 64).clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary).lineLimit(2)
                    Text(book.authorsText).font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted).lineLimit(1)
                    GridLabel(text: book.readingStatus.displayName, color: BauhausColors.secondary)
                }
                Spacer()
            }
        }
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(GridTypography.captionMedium).padding(.horizontal, GridSpacing.sm).padding(.vertical, GridSpacing.xs)
                .background(isOn ? BauhausColors.primary : BauhausColors.surface).foregroundStyle(isOn ? .black : BauhausColors.textSecondary).clipShape(Capsule())
        }
    }

    private func reload() { books = (try? environment.bookRepository.fetchBooks()) ?? [] }
}
