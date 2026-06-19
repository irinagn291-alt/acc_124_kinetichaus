import SwiftUI

struct LiftArchiveView: View {
    @EnvironmentObject private var environment: HausContainer
    @State private var sessions: [WorkoutSession] = []

    var body: some View {
        Group {
            if sessions.isEmpty {
                BlankGridView(systemImage: "clock.arrow.circlepath", title: "No history yet", message: "Complete a workout to see it here.")
            } else {
                List {
                    ForEach(sessions) { s in
                        VStack(alignment: .leading, spacing: GridSpacing.xs) {
                            HStack {
                                Text(s.workoutTitle).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary)
                                Spacer()
                                GridLabel(text: s.status.displayName, color: BauhausColors.success)
                            }
                            Text(DateUtils.string(s.startedAt)).font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
                            HStack(spacing: GridSpacing.md) {
                                Label(NumberFormatterUtils.durationMinutes(s.durationSeconds / 60), systemImage: "clock")
                                Label("\(s.completedSetsCount) sets", systemImage: "list.number")
                                Label("vol \(NumberFormatterUtils.int(s.totalVolume))", systemImage: "scalemass")
                            }
                            .font(GridTypography.caption).foregroundStyle(BauhausColors.textSecondary)
                        }
                        .listRowBackground(BauhausColors.surface)
                        .swipeActions {
                            Button(role: .destructive) {
                                try? environment.workoutRepository.deleteSession(s); reload()
                            } label: { Label("Delete", systemImage: GridIcons.delete) }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(BauhausColors.background)
        .navigationTitle("Workout History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear(perform: reload)
    }

    private func reload() {
        sessions = (try? environment.workoutRepository.fetchAllSessions()) ?? []
    }
}
