import SwiftUI

struct LiftCatalogView: View {
    @EnvironmentObject private var environment: HausContainer

    enum SortOption: String, CaseIterable, Identifiable {
        case recent = "Recent", duration = "Duration", difficulty = "Difficulty"
        var id: String { rawValue }
    }

    @State private var workouts: [Workout] = []
    @State private var query = ""
    @State private var typeFilter: WorkoutType?
    @State private var sort: SortOption = .recent
    @State private var showEditor = false

    private var filtered: [Workout] {
        var list = workouts
        if !query.isEmpty { list = list.filter { $0.title.localizedCaseInsensitiveContains(query) } }
        if let typeFilter { list = list.filter { $0.type == typeFilter } }
        switch sort {
        case .recent: list.sort { $0.updatedAt > $1.updatedAt }
        case .duration: list.sort { $0.estimatedDurationMinutes > $1.estimatedDurationMinutes }
        case .difficulty: list.sort { $0.difficulty.rawValue < $1.difficulty.rawValue }
        }
        return list
    }

    var body: some View {
        Group {
            if workouts.isEmpty {
                BlankGridView(systemImage: GridIcons.workouts, title: "No workouts yet", message: "Create your first workout and add it to your calendar.", actionTitle: "Create Workout") { showEditor = true }
            } else {
                List {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                filterChip("All", isOn: typeFilter == nil) { typeFilter = nil }
                                ForEach(WorkoutType.allCases) { t in
                                    filterChip(t.displayName, isOn: typeFilter == t) { typeFilter = t }
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                    ForEach(filtered) { workout in
                        NavigationLink { LiftDetailView(workout: workout) } label: { row(workout) }
                            .listRowBackground(BauhausColors.surface)
                            .swipeActions {
                                Button(role: .destructive) { delete(workout) } label: { Label("Delete", systemImage: GridIcons.delete) }
                                Button { duplicate(workout) } label: { Label("Duplicate", systemImage: "doc.on.doc") }.tint(BauhausColors.secondary)
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BauhausColors.background)
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .modifier(WorkoutSearchModifier(query: $query, isEnabled: !workouts.isEmpty))
        .toolbar {
            if !workouts.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) { ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) } }
                    } label: { Image(systemName: "arrow.up.arrow.down") }
                        .accessibilityLabel("Sort Workouts")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: GridSpacing.md) {
                    if !workouts.isEmpty {
                        NavigationLink { LiftArchiveView() } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        .accessibilityLabel("Workout History")
                    }
                    Button { showEditor = true } label: { Image(systemName: GridIcons.add) }
                        .accessibilityLabel("Create Workout")
                }
            }
        }
        .sheet(isPresented: $showEditor, onDismiss: reload) { LiftEditorView(workout: nil) }
        .onAppear(perform: reload)
    }

    private func row(_ w: Workout) -> some View {
        VStack(alignment: .leading, spacing: GridSpacing.xs) {
            Text(w.title).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary)
            HStack(spacing: GridSpacing.sm) {
                Label(w.type.displayName, systemImage: w.type.icon)
                Text("\(w.estimatedDurationMinutes) min")
                Text("\(w.exercises.count) ex")
            }
            .font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
            if let last = w.lastPerformedAt {
                Text("Last: \(DateUtils.string(last, DateUtils.shortDay))").font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
            }
        }
    }

    private func filterChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(GridTypography.captionMedium)
                .padding(.horizontal, GridSpacing.sm).padding(.vertical, GridSpacing.xs)
                .background(isOn ? BauhausColors.primary : BauhausColors.elevatedSurface)
                .foregroundStyle(isOn ? .black : BauhausColors.textSecondary)
                .clipShape(Capsule())
        }
    }

    private func reload() {
        workouts = (try? environment.workoutRepository.fetchWorkouts()) ?? []
    }

    private func delete(_ w: Workout) {
        try? environment.workoutRepository.deleteWorkout(w); reload()
    }

    private func duplicate(_ w: Workout) {
        let copy = Workout(title: w.title + " Copy", workoutDescription: w.workoutDescription, type: w.type, difficulty: w.difficulty, goal: w.goal, estimatedDurationMinutes: w.estimatedDurationMinutes, tags: w.tags, exercises: w.sortedExercises.map {
            WorkoutExercise(name: $0.name, muscleGroup: $0.muscleGroup, equipment: $0.equipment, sets: $0.sets, reps: $0.reps, weightKg: $0.weightKg, durationSeconds: $0.durationSeconds, distanceMeters: $0.distanceMeters, restSeconds: $0.restSeconds, tempo: $0.tempo, rpe: $0.rpe, notes: $0.notes, orderIndex: $0.orderIndex)
        })
        try? environment.workoutRepository.saveWorkout(copy); reload()
    }
}

private struct WorkoutSearchModifier: ViewModifier {
    @Binding var query: String
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $query, prompt: "Search Workouts")
        } else {
            content
        }
    }
}
