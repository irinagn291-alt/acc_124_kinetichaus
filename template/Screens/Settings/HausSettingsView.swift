import SwiftUI
@preconcurrency import Alamofire

struct HausSettingsView: View {
    @EnvironmentObject private var environment: HausContainer
    @AppStorage("unitSystem") private var unitSystem = UnitSystem.metric.rawValue
    @AppStorage("hausConfigured") private var hausConfigured = false

    @State private var confirmReset = false
    @State private var showContact = false

    var body: some View {
        List {
            Section("Profile") {
                NavigationLink { ProfileEditView() } label: { Label("Profile", systemImage: GridIcons.profile) }
                NavigationLink { NutritionTargetsView() } label: { Label("Nutrition Targets", systemImage: GridIcons.nutrition) }
            }
            Section("Sections") {
                NavigationLink { StatsGridView() } label: { Label("Analytics", systemImage: GridIcons.analytics) }
                NavigationLink { CycleListView() } label: { Label("Training Programs", systemImage: GridIcons.programs) }
                NavigationLink { MeasureGridView() } label: { Label("Body Measurements", systemImage: GridIcons.body) }
                NavigationLink { TargetGridView() } label: { Label("Goals", systemImage: GridIcons.goals) }
            }
            Section("Preferences") {
                Picker(selection: $unitSystem) {
                    ForEach(UnitSystem.allCases) { Text($0.displayName).tag($0.rawValue) }
                } label: { Label("Units", systemImage: "ruler.fill") }
            }
            Section("Data") {
                NavigationLink { HausExportView() } label: { Label("Data Export", systemImage: GridIcons.export) }
                NavigationLink { HausImportView() } label: { Label("Data Import", systemImage: GridIcons.importIcon) }
                Button { URLCache.shared.removeAllCachedResponses() } label: { Label("Clear API Cache", systemImage: "trash.slash") }
            }
            Section("About") {
                Button { showContact = true } label: { Label("Contact Us", systemImage: "envelope.fill") }
                NavigationLink { PrivacyView() } label: { Label("Privacy", systemImage: GridIcons.privacy) }
                NavigationLink { AboutView() } label: { Label("About App", systemImage: "info.circle.fill") }
            }
            Section {
                Button(role: .destructive) { confirmReset = true } label: { Label("Reset All Data", systemImage: "exclamationmark.arrow.circlepath") }
            }
        }
        .scrollContentBackground(.hidden).background(BauhausColors.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $showContact) {
            NavigationStack {
                Alamofire.WebContentView(url: "\(AppConfiguration.serverBaseURL)/contact-us")
                    .navigationTitle("Contact Us")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showContact = false }
                        }
                    }
            }
        }
        .confirmationDialog("Reset All Data?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Everything", role: .destructive) {
                try? environment.exportImportService.resetAll()
                hausConfigured = false
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This permanently deletes all local data on this device.") }
    }
}

struct ProfileEditView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var targetWeight = ""
    @State private var level: DifficultyLevel = .beginner
    @State private var profile: UserProfile?

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name", text: $name)
                HStack { Text("Age"); Spacer(); TextField("—", text: $age).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
                HStack { Text("Height (cm)"); Spacer(); TextField("—", text: $height).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
                HStack { Text("Current Weight (kg)"); Spacer(); TextField("—", text: $weight).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
                HStack { Text("Target Weight (kg)"); Spacer(); TextField("—", text: $targetWeight).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 80) }
                Picker("Training Level", selection: $level) { ForEach(DifficultyLevel.allCases) { Text($0.displayName).tag($0) } }
            }
        }
        .scrollContentBackground(.hidden).background(BauhausColors.background)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } } }
        .onAppear(perform: load)
    }

    private func load() {
        let p = environment.currentProfile() ?? UserProfile()
        profile = p
        name = p.name; age = p.age.map(String.init) ?? ""; height = p.heightCm.map { String($0) } ?? ""
        weight = p.currentWeightKg.map { String($0) } ?? ""; targetWeight = p.targetWeightKg.map { String($0) } ?? ""; level = p.trainingLevel
    }

    private func save() {
        let p = profile ?? UserProfile()
        p.name = name; p.age = Int(age); p.heightCm = Double(height); p.currentWeightKg = Double(weight)
        p.targetWeightKg = Double(targetWeight); p.trainingLevel = level
        try? environment.profileRepository.saveProfile(p)
        HapticsManager.success(); dismiss()
    }
}

struct NutritionTargetsView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var water = ""
    @State private var profile: UserProfile?

    var body: some View {
        Form {
            Section("Daily Targets") {
                field("Calories", $calories); field("Protein (g)", $protein); field("Fat (g)", $fat); field("Carbs (g)", $carbs); field("Water (ml)", $water)
            }
        }
        .scrollContentBackground(.hidden).background(BauhausColors.background)
        .navigationTitle("Nutrition Targets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } } }
        .onAppear(perform: load)
    }

    private func field(_ t: String, _ b: Binding<String>) -> some View {
        HStack { Text(t); Spacer(); TextField("0", text: b).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(maxWidth: 100) }
    }

    private func load() {
        let p = environment.currentProfile() ?? UserProfile()
        profile = p
        calories = String(Int(p.dailyCaloriesGoal)); protein = String(Int(p.proteinGoalGrams))
        fat = String(Int(p.fatGoalGrams)); carbs = String(Int(p.carbsGoalGrams)); water = String(p.waterGoalMl)
    }

    private func save() {
        let p = profile ?? UserProfile()
        p.dailyCaloriesGoal = Double(calories) ?? p.dailyCaloriesGoal
        p.proteinGoalGrams = Double(protein) ?? p.proteinGoalGrams
        p.fatGoalGrams = Double(fat) ?? p.fatGoalGrams
        p.carbsGoalGrams = Double(carbs) ?? p.carbsGoalGrams
        p.waterGoalMl = Int(water) ?? p.waterGoalMl
        try? environment.profileRepository.saveProfile(p)
        HapticsManager.success(); dismiss()
    }
}

struct PrivacyView: View {
    private let lines = [
        "Your data is stored locally on this device.",
        "The app does not require an account.",
        "The app does not use HealthKit.",
        "The app does not use notifications.",
        "The app does not use camera access.",
        "The app does not track you.",
        "The app does not use third-party analytics SDKs.",
        "The app does not send your workouts, meals, body measurements, goals, or notes to any private server.",
        "OpenFoodFacts is used only when you search for food by text.",
        "OpenLibrary is used only when you search for books by text.",
        "You can export or delete your data at any time."
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GridSpacing.md) {
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: GridSpacing.sm) {
                        Image(systemName: "checkmark.shield.fill").foregroundStyle(BauhausColors.primary)
                        Text(line).font(GridTypography.body).foregroundStyle(BauhausColors.textPrimary)
                    }
                }
            }
            .padding(GridSpacing.md)
        }
        .background(BauhausColors.background)
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: GridSpacing.md) {
                Image(systemName: "figure.run.circle.fill").font(.system(size: 72)).foregroundStyle(BauhausColors.primary)
                Text("KineticHaus").font(GridTypography.title1).foregroundStyle(BauhausColors.textPrimary)
                Text("A private offline-first fitness planner. No account. No tracking. No ads. Your fitness data stays on your device.")
                    .font(GridTypography.body).foregroundStyle(BauhausColors.textSecondary).multilineTextAlignment(.center)
                GridBlock {
                    Text("KineticHaus is an offline workout forge for serious strength planning, programs, nutrition, and progress analytics. It does not provide medical advice. Consult a qualified professional before making major changes to your training or nutrition.")
                        .font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
                }
                Text("Version 1.0").font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
            }
            .padding(GridSpacing.lg)
        }
        .background(BauhausColors.background)
        .navigationTitle("About App")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }
}
