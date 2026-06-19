import SwiftUI

struct LiftDetailView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss

    let workout: Workout

    @State private var showEditor = false
    @State private var showExecution = false
    @State private var showAddToCalendar = false
    @State private var confirmDelete = false
    @State private var recentSessions: [WorkoutSession] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GridSpacing.md) {
                header
                if let desc = workout.workoutDescription, !desc.isEmpty {
                    GridBlock { Text(desc).font(GridTypography.body).foregroundStyle(BauhausColors.textSecondary) }
                }
                infoCard
                exercisesCard
                recentCard
                actions
            }
            .padding(GridSpacing.md)
        }
        .background(BauhausColors.background)
        .navigationTitle(workout.title)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showExecution, onDismiss: reload) {
            LiftLiveView(workout: workout)
        }
        .sheet(isPresented: $showEditor) { LiftEditorView(workout: workout) }
        .sheet(isPresented: $showAddToCalendar) { PlanEventEditor(event: nil, defaultDate: .now) }
        .confirmationDialog("Delete Workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) {
                try? environment.workoutRepository.deleteWorkout(workout); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: reload)
    }

    private var header: some View {
        HStack {
            Image(systemName: workout.type.icon).font(.largeTitle).foregroundStyle(BauhausColors.primary)
            VStack(alignment: .leading) {
                Text(workout.type.displayName).font(GridTypography.title3).foregroundStyle(BauhausColors.textPrimary)
                GridLabel(text: workout.difficulty.displayName, color: BauhausColors.secondary)
            }
            Spacer()
        }
    }

    private var infoCard: some View {
        GridBlock {
            HStack {
                infoItem("\(workout.estimatedDurationMinutes)", "Minutes")
                infoItem("\(workout.exercises.count)", "Exercises")
                infoItem(workout.goal ?? "—", "Goal")
            }
        }
    }

    private var exercisesCard: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                SectionHeader(title: "Exercises")
                if workout.exercises.isEmpty {
                    Text("No exercises").foregroundStyle(BauhausColors.textMuted)
                }
                ForEach(workout.sortedExercises) { ex in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary)
                        Text(detail(ex)).font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func detail(_ ex: WorkoutExercise) -> String {
        var parts = ["\(ex.muscleGroup.displayName)", "\(ex.sets) sets"]
        if let reps = ex.reps { parts.append("\(reps) reps") }
        if let w = ex.weightKg { parts.append("\(NumberFormatterUtils.decimal(w)) kg") }
        return parts.joined(separator: " • ")
    }

    private var recentCard: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                SectionHeader(title: "Recent Sessions")
                if recentSessions.isEmpty {
                    Text("No sessions yet").foregroundStyle(BauhausColors.textMuted)
                }
                ForEach(recentSessions.prefix(5)) { s in
                    HStack {
                        Text(DateUtils.string(s.startedAt, DateUtils.shortDay)).foregroundStyle(BauhausColors.textPrimary)
                        Spacer()
                        Text(NumberFormatterUtils.durationMinutes(s.durationSeconds / 60)).foregroundStyle(BauhausColors.textMuted)
                        Text("vol \(NumberFormatterUtils.int(s.totalVolume))").font(.caption).foregroundStyle(BauhausColors.textMuted)
                    }
                    .font(GridTypography.body)
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: GridSpacing.sm) {
            RedActionButton(title: "Start Workout", systemImage: "play.fill") { showExecution = true }
            HStack(spacing: GridSpacing.sm) {
                OutlineActionButton(title: "Edit", systemImage: GridIcons.edit) { showEditor = true }
                OutlineActionButton(title: "Add to Calendar", systemImage: GridIcons.calendar) { showAddToCalendar = true }
            }
            Button(role: .destructive) { confirmDelete = true } label: {
                Label("Delete Workout", systemImage: GridIcons.delete).frame(maxWidth: .infinity).frame(minHeight: 44)
            }
            .foregroundStyle(BauhausColors.danger)
        }
    }

    private func infoItem(_ value: String, _ label: String) -> some View {
        VStack {
            Text(value).font(GridTypography.title3).foregroundStyle(BauhausColors.textPrimary).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func reload() {
        let all = (try? environment.workoutRepository.fetchAllSessions()) ?? []
        recentSessions = all.filter { $0.workoutId == workout.id }
    }
}
