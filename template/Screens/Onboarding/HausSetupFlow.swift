import SwiftUI

struct HausSetupFlow: View {
    @EnvironmentObject private var environment: HausContainer
    @AppStorage("hausConfigured") private var onboardingDone = false
    @State private var step = 0
    @State private var selectedGoals: Set<String> = []
    @State private var trainingLevel: DifficultyLevel = .beginner
    @State private var age = ""
    @State private var height = ""
    @State private var currentWeight = ""
    @State private var targetWeight = ""
    @State private var activityLevel = "Moderate"
    @State private var calories = "2200"
    @State private var protein = "140"
    @State private var fat = "70"
    @State private var carbs = "250"
    @State private var water = "2500"
    private let goalOptions = ["Hypertrophy", "Fat reduction", "Maintenance", "Strength gain", "Endurance", "Mobility", "Macro control", "Knowledge"]

    var body: some View {
        ZStack {
            BauhausColors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ProgressView(value: Double(step + 1), total: Double(3))
                    .tint(BauhausColors.primary)
                    .padding()
                TabView(selection: $step) {
                                        welcome.tag(0)
                    goals.tag(1)
                    level.tag(2)
                    finish.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)
            }
        }
    }

    private func container<Content: View>(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GridSpacing.lg) {
                VStack(alignment: .leading, spacing: GridSpacing.xs) {
                    Text(title).font(GridTypography.title1).foregroundStyle(BauhausColors.textPrimary)
                    if let subtitle { Text(subtitle).font(GridTypography.body).foregroundStyle(BauhausColors.textSecondary) }
                }
                content()
            }
            .padding(GridSpacing.lg)
        }
    }

    private var welcome: some View {
        VStack {
            Spacer()
            VStack(spacing: GridSpacing.md) {
                Image(systemName: "GridIcons.today")
                    .font(.system(size: 80))
                    .foregroundStyle(BauhausColors.primary)
                Text("Structure your training")
                    .font(GridTypography.title1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BauhausColors.textPrimary)
                Text("KineticHaus: precise planning for lifts, intake, and measurable progress.")
                    .font(GridTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BauhausColors.textSecondary)
            }
            .padding(GridSpacing.lg)
            Spacer()
            RedActionButton(title: "Configure") { next() }.padding(GridSpacing.lg)
        }
    }

    private var goals: some View {
        VStack {
            container(title: "Objectives", subtitle: "Select applicable targets.") {
                VStack(spacing: GridSpacing.sm) {
                    ForEach(goalOptions, id: \.self) { goal in
                        selectableRow(goal, isOn: selectedGoals.contains(goal)) {
                            if selectedGoals.contains(goal) { selectedGoals.remove(goal) } else { selectedGoals.insert(goal) }
                        }
                    }
                }
            }
            RedActionButton(title: "Continue") { next() }.padding(GridSpacing.lg)
        }
    }

    private var level: some View {
        VStack {
            container(title: "Training tier") {
                VStack(spacing: GridSpacing.sm) {
                    ForEach(DifficultyLevel.allCases) { lvl in
                        selectableRow(lvl.displayName, isOn: trainingLevel == lvl) { trainingLevel = lvl }
                    }
                }
            }
            RedActionButton(title: "Continue") { next() }.padding(GridSpacing.lg)
        }
    }

    private var finish: some View {
        VStack {
            Spacer()
            VStack(spacing: GridSpacing.md) {
                Image(systemName: GridIcons.success)
                    .font(.system(size: 80))
                    .foregroundStyle(BauhausColors.primary)
                Text("System ready").font(GridTypography.title1).foregroundStyle(BauhausColors.textPrimary)
                Text("Offline. Account-free. Exact.")
                    .font(GridTypography.body).multilineTextAlignment(.center).foregroundStyle(BauhausColors.textSecondary)
            }
            .padding(GridSpacing.lg)
            Spacer()
            RedActionButton(title: "Open KineticHaus") { complete() }.padding(GridSpacing.lg)
        }
    }

    private func selectableRow(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(BauhausColors.textPrimary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? BauhausColors.primary : BauhausColors.textMuted)
            }
            .padding()
            .frame(minHeight: GridSize.minTouchTarget)
            .background(isOn ? BauhausColors.primary.opacity(0.12) : BauhausColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: SharpRadius.md))
        }
    }

    private func field(_ title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack {
            Text(title).foregroundStyle(BauhausColors.textSecondary)
            Spacer()
            TextField("", text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(BauhausColors.textPrimary)
        }
        .padding()
        .background(BauhausColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: SharpRadius.md))
    }

    private func next() { withAnimation { step = min(step + 1, 1) } }

    private func complete() {
        let profile = UserProfile(
            age: Int(age), heightCm: Double(height), currentWeightKg: Double(currentWeight),
            targetWeightKg: Double(targetWeight), activityLevel: activityLevel.lowercased(),
            trainingLevel: trainingLevel, mainGoals: Array(selectedGoals),
            dailyCaloriesGoal: Double(calories) ?? 2200, proteinGoalGrams: Double(protein) ?? 140,
            fatGoalGrams: Double(fat) ?? 70, carbsGoalGrams: Double(carbs) ?? 250, waterGoalMl: Int(water) ?? 2500
        )
        try? environment.profileRepository.saveProfile(profile)
        HapticsManager.success()
        onboardingDone = true
    }
}
