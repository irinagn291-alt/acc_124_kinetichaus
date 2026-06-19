import SwiftUI

struct CycleListView: View {
    @EnvironmentObject private var environment: HausContainer
    @State private var programs: [TrainingProgram] = []
    @State private var showEditor = false

    var body: some View {
        Group {
            if programs.isEmpty {
                BlankGridView(systemImage: GridIcons.programs, title: "No programs yet", message: "Create a multi-week training program to structure your training.", actionTitle: "Create Program") { showEditor = true }
            } else {
                List {
                    ForEach(programs) { program in
                        NavigationLink { CycleDetailView(program: program) } label: { row(program) }
                            .listRowBackground(BauhausColors.surface)
                            .swipeActions {
                                Button(role: .destructive) { try? environment.programRepository.deleteProgram(program); reload() } label: { Label("Delete", systemImage: GridIcons.delete) }
                            }
                    }
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
        }
        .background(BauhausColors.background)
        .navigationTitle("Training Programs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showEditor = true } label: { Image(systemName: GridIcons.add) }.accessibilityLabel("Create Program") } }
        .sheet(isPresented: $showEditor, onDismiss: reload) { CycleEditorView(program: nil) }
        .onAppear(perform: reload)
    }

    private func row(_ p: TrainingProgram) -> some View {
        let progress = ProgramProgressCalculator.progress(p)
        return VStack(alignment: .leading, spacing: GridSpacing.xs) {
            HStack {
                Text(p.title).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary)
                Spacer()
                GridLabel(text: p.status.displayName, color: statusColor(p.status))
            }
            Text("\(p.goal) • \(p.weeksCount) weeks • \(p.daysPerWeek)/week").font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
            ProgressView(value: progress.fraction).tint(BauhausColors.primary)
        }
    }

    private func statusColor(_ s: ProgramStatus) -> Color {
        switch s {
        case .draft: BauhausColors.textMuted
        case .active: BauhausColors.success
        case .paused: BauhausColors.warning
        case .completed: BauhausColors.secondary
        }
    }

    private func reload() { programs = (try? environment.programRepository.fetchPrograms()) ?? [] }
}

struct CycleEditorView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss
    let program: TrainingProgram?

    @State private var title = ""
    @State private var description = ""
    @State private var goal = ""
    @State private var difficulty: DifficultyLevel = .beginner
    @State private var startDate = Date.now
    @State private var weeks = 4
    @State private var daysPerWeek = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Program") {
                    TextField("Program Name", text: $title)
                    TextField("Description", text: $description, axis: .vertical).lineLimit(2...4)
                    TextField("Goal", text: $goal)
                    Picker("Difficulty", selection: $difficulty) { ForEach(DifficultyLevel.allCases) { Text($0.displayName).tag($0) } }
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Stepper("Weeks: \(weeks)", value: $weeks, in: 1...104)
                    Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 1...7)
                }
            }
            .navigationTitle(program == nil ? "Create Program" : "Edit Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || goal.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let program else { return }
        title = program.title; description = program.programDescription ?? ""; goal = program.goal
        difficulty = program.difficulty; startDate = program.startDate ?? .now; weeks = program.weeksCount; daysPerWeek = program.daysPerWeek
    }

    private func save() {
        let target = program ?? TrainingProgram(title: title, goal: goal, weeksCount: weeks, daysPerWeek: daysPerWeek)
        target.title = title; target.programDescription = description.isEmpty ? nil : description
        target.goal = goal; target.difficulty = difficulty; target.startDate = startDate
        let end = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: startDate)
        target.endDate = end; target.weeksCount = weeks; target.daysPerWeek = daysPerWeek
        if target.weeks.isEmpty {
            target.weeks = (1...weeks).map { w in
                ProgramWeek(weekIndex: w, title: "Week \(w)", days: (1...daysPerWeek).map { d in
                    ProgramDay(dayIndex: d, title: "Day \(d)")
                })
            }
        }
        try? environment.programRepository.saveProgram(target)
        HapticsManager.success()
        dismiss()
    }
}
