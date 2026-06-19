import SwiftUI

struct CodexDetailView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss
    let book: Book

    @State private var status: ReadingStatus = .wantToRead
    @State private var progress: Double = 0
    @State private var rating = 0
    @State private var notes = ""
    @State private var sessions: [ReadingSession] = []
    @State private var showAddSession = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GridSpacing.md) {
                header
                statusCard
                progressCard
                ratingCard
                notesCard
                sessionsCard
                Button(role: .destructive) { try? environment.bookRepository.deleteBook(book); dismiss() } label: {
                    Label("Delete Book", systemImage: GridIcons.delete).frame(maxWidth: .infinity).frame(minHeight: 44)
                }.foregroundStyle(BauhausColors.danger)
            }
            .padding(GridSpacing.md)
        }
        .background(BauhausColors.background)
        .navigationTitle("Book")
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSession, onDismiss: reloadSessions) { ReadingSessionEditorView(book: book) }
        .onAppear(perform: load)
    }

    private var header: some View {
        HStack(spacing: GridSpacing.md) {
            GridImageLoader(urlString: book.coverUrl, placeholderSymbol: "book.closed.fill").frame(width: 90, height: 120).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: GridSpacing.xs) {
                Text(book.title).font(GridTypography.title3).foregroundStyle(BauhausColors.textPrimary)
                Text(book.authorsText).font(GridTypography.body).foregroundStyle(BauhausColors.textSecondary)
                if let year = book.firstPublishYear { Text(String(year)).font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted) }
                if let lang = book.language { Text("Language: \(lang)").font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted) }
            }
            Spacer()
        }
    }

    private var statusCard: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                SectionHeader(title: "Reading Status")
                Picker("Status", selection: $status) { ForEach(ReadingStatus.allCases) { Text($0.displayName).tag($0) } }
                    .pickerStyle(.menu)
                    .onChange(of: status) { _, v in book.readingStatus = v; save() }
            }
        }
    }

    private var progressCard: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                SectionHeader(title: "Progress")
                HStack { Text("\(Int(progress))%").foregroundStyle(BauhausColors.textPrimary); Spacer() }
                Slider(value: $progress, in: 0...100, step: 1) { editing in if !editing { book.progressPercent = progress; save() } }
                    .tint(BauhausColors.primary)
            }
        }
    }

    private var ratingCard: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                SectionHeader(title: "Rating")
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Button { rating = star; book.rating = star; save() } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star").foregroundStyle(BauhausColors.warning).font(.title3)
                        }.frame(width: 44, height: 44)
                    }
                }
            }
        }
    }

    private var notesCard: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                SectionHeader(title: "Notes")
                TextField("Add notes...", text: $notes, axis: .vertical).lineLimit(3...6)
                    .onChange(of: notes) { _, v in book.notes = v.isEmpty ? nil : v }
                OutlineActionButton(title: "Save Notes") { save() }
            }
        }
    }

    private var sessionsCard: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                HStack { SectionHeader(title: "Reading Sessions"); Button { showAddSession = true } label: { Image(systemName: GridIcons.add) } }
                if sessions.isEmpty { Text("No sessions logged").foregroundStyle(BauhausColors.textMuted) }
                ForEach(sessions) { s in
                    HStack {
                        Text(DateUtils.string(s.date, DateUtils.shortDay)).foregroundStyle(BauhausColors.textPrimary)
                        Spacer()
                        Text("\(s.durationMinutes) min").foregroundStyle(BauhausColors.textMuted)
                        if let pages = s.pagesRead { Text("\(pages) p").font(.caption).foregroundStyle(BauhausColors.textMuted) }
                    }.font(GridTypography.body)
                }
            }
        }
    }

    private func load() {
        status = book.readingStatus; progress = book.progressPercent; rating = book.rating ?? 0; notes = book.notes ?? ""
        reloadSessions()
    }

    private func reloadSessions() {
        sessions = ((try? environment.bookRepository.fetchAllReadingSessions()) ?? []).filter { $0.bookId == book.id }
    }

    private func save() { try? environment.bookRepository.saveBook(book) }
}

struct ReadingSessionEditorView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss
    let book: Book
    @State private var date = Date.now
    @State private var minutes = 30
    @State private var pages = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Stepper("Duration: \(minutes) min", value: $minutes, in: 1...600, step: 5)
                HStack { Text("Pages read"); Spacer(); TextField("—", text: $pages).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
            }
            .navigationTitle("Add Reading Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let session = ReadingSession(bookId: book.id, bookTitle: book.title, date: date, durationMinutes: minutes, pagesRead: Int(pages))
                        try? environment.bookRepository.saveReadingSession(session)
                        HapticsManager.success(); dismiss()
                    }
                }
            }
        }
    }
}
