import SwiftUI

struct CycleDetailView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss
    let program: TrainingProgram

    @State private var workouts: [Workout] = []
    @State private var refreshToken = UUID()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GridSpacing.md) {
                header
                progressCard
                weeksSection
                actions
            }
            .padding(GridSpacing.md)
            .id(refreshToken)
        }
        .background(BauhausColors.background)
        .navigationTitle(program.title)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { workouts = (try? environment.workoutRepository.fetchWorkouts()) ?? [] }
    }

    private var header: some View {
        GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.xs) {
                Text(program.goal).font(GridTypography.title3).foregroundStyle(BauhausColors.textPrimary)
                if let d = program.programDescription, !d.isEmpty {
                    Text(d).font(GridTypography.body).foregroundStyle(BauhausColors.textSecondary)
                }
                HStack { GridLabel(text: program.status.displayName, color: BauhausColors.success); GridLabel(text: program.difficulty.displayName, color: BauhausColors.secondary) }
            }
        }
    }

    private var progressCard: some View {
        let p = ProgramProgressCalculator.progress(program)
        return GridBlock {
            VStack(alignment: .leading, spacing: GridSpacing.sm) {
                SectionHeader(title: "Progress")
                ProgressView(value: p.fraction).tint(BauhausColors.primary)
                Text("\(p.completedDays) / \(p.totalDays) days completed").font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
            }
        }
    }

    private var weeksSection: some View {
        VStack(spacing: GridSpacing.sm) {
            ForEach(program.sortedWeeks) { week in
                GridBlock {
                    VStack(alignment: .leading, spacing: GridSpacing.xs) {
                        Text(week.title).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary)
                        ForEach(week.sortedDays) { day in dayRow(day) }
                    }
                }
            }
        }
    }

    private func dayRow(_ day: ProgramDay) -> some View {
        let assigned = workouts.first { $0.id == day.plannedWorkoutId }
        return HStack {
            Button {
                day.isCompleted.toggle()
                try? environment.programRepository.saveProgram(program)
                refreshToken = UUID()
            } label: {
                Image(systemName: day.isCompleted ? "checkmark.circle.fill" : "circle").foregroundStyle(day.isCompleted ? BauhausColors.success : BauhausColors.textMuted)
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading) {
                Text(day.title).foregroundStyle(BauhausColors.textPrimary)
                Text(assigned?.title ?? "No workout assigned").font(.caption).foregroundStyle(BauhausColors.textMuted)
            }
            Spacer()
            Menu {
                Button("None") { day.plannedWorkoutId = nil; try? environment.programRepository.saveProgram(program); refreshToken = UUID() }
                ForEach(workouts) { w in
                    Button(w.title) { day.plannedWorkoutId = w.id; try? environment.programRepository.saveProgram(program); refreshToken = UUID() }
                }
            } label: { Image(systemName: "dumbbell.fill").foregroundStyle(BauhausColors.primary) }
        }
    }

    private var actions: some View {
        VStack(spacing: GridSpacing.sm) {
            HStack(spacing: GridSpacing.sm) {
                OutlineActionButton(title: "Mark Active") { setStatus(.active) }
                OutlineActionButton(title: "Pause") { setStatus(.paused) }
            }
            HStack(spacing: GridSpacing.sm) {
                OutlineActionButton(title: "Complete") { setStatus(.completed) }
                OutlineActionButton(title: "Add to Calendar", systemImage: GridIcons.calendar) { addToCalendar() }
            }
            Button(role: .destructive) {
                try? environment.programRepository.deleteProgram(program); dismiss()
            } label: { Label("Delete Program", systemImage: GridIcons.delete).frame(maxWidth: .infinity).frame(minHeight: 44) }
                .foregroundStyle(BauhausColors.danger)
        }
    }

    private func setStatus(_ s: ProgramStatus) {
        program.status = s
        try? environment.programRepository.saveProgram(program)
        refreshToken = UUID()
        HapticsManager.success()
    }

    private func addToCalendar() {
        guard let start = program.startDate else { return }
        for week in program.sortedWeeks {
            for day in week.sortedDays where day.plannedWorkoutId != nil {
                let offset = (week.weekIndex - 1) * 7 + (day.dayIndex - 1)
                let date = Calendar.current.date(byAdding: .day, value: offset, to: start) ?? start
                let event = CalendarEvent(title: day.title, eventType: .workout, startDate: date, relatedEntityId: day.plannedWorkoutId)
                try? environment.calendarRepository.saveEvent(event)
            }
        }
        HapticsManager.success()
    }
}
