import SwiftUI

struct LiftEditorView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss

    let workout: Workout?

    @State private var title = ""
    @State private var description = ""
    @State private var type: WorkoutType = .strength
    @State private var goal = ""
    @State private var duration = 60
    @State private var difficulty: DifficultyLevel = .beginner
    @State private var tags = ""
    @State private var exercises: [ExerciseDraft] = []
    @State private var editingDraft: ExerciseDraft?
    @State private var showExerciseEditor = false

    private var isEditing: Bool { workout != nil }
    private var isValid: Bool {
        let t = title.trimmingCharacters(in: .whitespaces)
        return !t.isEmpty && t.count <= 80
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("Workout Name", text: $title)
                    TextField("Description", text: $description, axis: .vertical).lineLimit(2...5)
                    Picker("Type", selection: $type) { ForEach(WorkoutType.allCases) { Text($0.displayName).tag($0) } }
                    TextField("Goal", text: $goal)
                    Stepper("Duration: \(duration) min", value: $duration, in: 5...300, step: 5)
                    Picker("Difficulty", selection: $difficulty) { ForEach(DifficultyLevel.allCases) { Text($0.displayName).tag($0) } }
                    TextField("Tags (comma separated)", text: $tags)
                }
                Section("Exercises") {
                    if exercises.isEmpty {
                        Text("No exercises added").foregroundStyle(BauhausColors.textMuted)
                    }
                    ForEach(exercises) { ex in
                        Button { editingDraft = ex; showExerciseEditor = true } label: {
                            VStack(alignment: .leading) {
                                Text(ex.name).foregroundStyle(BauhausColors.textPrimary)
                                Text("\(ex.muscleGroup.displayName) • \(ex.sets) sets").font(.caption).foregroundStyle(BauhausColors.textMuted)
                            }
                        }
                    }
                    .onDelete { exercises.remove(atOffsets: $0) }
                    Button { editingDraft = nil; showExerciseEditor = true } label: {
                        Label("Add Exercise", systemImage: GridIcons.add)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Workout" : "Create Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid) }
            }
            .sheet(isPresented: $showExerciseEditor) {
                ExerciseEditorView(draft: editingDraft) { result in
                    if let idx = exercises.firstIndex(where: { $0.id == result.id }) {
                        exercises[idx] = result
                    } else {
                        exercises.append(result)
                    }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let workout else { return }
        title = workout.title
        description = workout.workoutDescription ?? ""
        type = workout.type
        goal = workout.goal ?? ""
        duration = workout.estimatedDurationMinutes
        difficulty = workout.difficulty
        tags = workout.tags.joined(separator: ", ")
        exercises = workout.sortedExercises.map { ExerciseDraft(from: $0) }
    }

    private func save() {
        let target = workout ?? Workout(title: title)
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.workoutDescription = description.isEmpty ? nil : description
        target.type = type
        target.goal = goal.isEmpty ? nil : goal
        target.estimatedDurationMinutes = duration
        target.difficulty = difficulty
        target.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        target.exercises = exercises.enumerated().map { idx, d in d.toModel(order: idx) }
        try? environment.workoutRepository.saveWorkout(target)
        HapticsManager.success()
        dismiss()
    }
}

struct ExerciseDraft: Identifiable {
    var id = UUID()
    var name = ""
    var muscleGroup: MuscleGroup = .other
    var equipment = ""
    var sets = 3
    var reps: Int? = 10
    var weightKg: Double?
    var durationSeconds: Int?
    var distanceMeters: Double?
    var restSeconds = 90
    var tempo = ""
    var rpe: Int?
    var notes = ""

    init() {}

    init(from e: WorkoutExercise) {
        id = e.id; name = e.name; muscleGroup = e.muscleGroup; equipment = e.equipment ?? ""
        sets = e.sets; reps = e.reps; weightKg = e.weightKg; durationSeconds = e.durationSeconds
        distanceMeters = e.distanceMeters; restSeconds = e.restSeconds; tempo = e.tempo ?? ""; rpe = e.rpe; notes = e.notes ?? ""
    }

    func toModel(order: Int) -> WorkoutExercise {
        WorkoutExercise(id: id, name: name, muscleGroup: muscleGroup, equipment: equipment.isEmpty ? nil : equipment, sets: sets, reps: reps, weightKg: weightKg, durationSeconds: durationSeconds, distanceMeters: distanceMeters, restSeconds: restSeconds, tempo: tempo.isEmpty ? nil : tempo, rpe: rpe, notes: notes.isEmpty ? nil : notes, orderIndex: order)
    }
}

struct ExerciseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let draft: ExerciseDraft?
    let onSave: (ExerciseDraft) -> Void

    @State private var d = ExerciseDraft()

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise Name", text: $d.name)
                    Picker("Muscle Group", selection: $d.muscleGroup) { ForEach(MuscleGroup.allCases) { Text($0.displayName).tag($0) } }
                    TextField("Equipment", text: $d.equipment)
                }
                Section("Volume") {
                    Stepper("Sets: \(d.sets)", value: $d.sets, in: 1...100)
                    optionalIntField("Reps", value: $d.reps, range: 0...1000)
                    optionalDoubleField("Weight (kg)", value: $d.weightKg)
                    optionalIntField("Duration (sec)", value: $d.durationSeconds, range: 0...86400)
                    optionalDoubleField("Distance (m)", value: $d.distanceMeters)
                    Stepper("Rest: \(d.restSeconds) sec", value: $d.restSeconds, in: 0...3600, step: 15)
                }
                Section("Advanced") {
                    TextField("Tempo", text: $d.tempo)
                    optionalIntField("RPE (1-10)", value: $d.rpe, range: 1...10)
                    TextField("Notes", text: $d.notes, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle(draft == nil ? "Add Exercise" : "Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Exercise") { onSave(d); dismiss() }
                        .disabled(d.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { if let draft { d = draft } }
        }
    }

    private func optionalIntField(_ title: String, value: Binding<Int?>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("—", value: value, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(maxWidth: 100)
        }
    }

    private func optionalDoubleField(_ title: String, value: Binding<Double?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("—", value: value, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 100)
        }
    }
}
