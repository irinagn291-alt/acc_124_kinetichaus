import SwiftUI

struct IntakeDayView: View {

    @EnvironmentObject private var environment: HausContainer
    @EnvironmentObject private var network: NetworkMonitor
    @State private var date = Date.now
    @State private var meals: [Meal] = []
    @State private var summary = NutritionSummary.zero
    @State private var waterMl = 0
    @State private var showAddFood = false
    @State private var showWater = false
    private var profile: UserProfile? { environment.currentProfile() }

    private func shift(_ v: Int) { date = Calendar.current.date(byAdding: .day, value: v, to: date) ?? date }
    private func reload() {
        meals = (try? environment.nutritionRepository.fetchMeals(for: date)) ?? []
        summary = environment.nutritionCalculation.summary(for: meals)
        waterMl = ((try? environment.nutritionRepository.fetchHydrationLogs(for: date)) ?? []).reduce(0) { $0 + $1.amountMl }
    }
    private func addWater(_ ml: Int) {
        try? environment.nutritionRepository.addHydration(amountMl: ml, date: date)
        HapticsManager.light(); reload()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
                if !network.isConnected { GridOfflineBar().padding(GridSpacing.md) }
                dateSelector.padding(GridSpacing.md)
                bauhausCell("KCAL", "\(NumberFormatterUtils.int(summary.calories))/\(NumberFormatterUtils.int(profile?.dailyCaloriesGoal ?? 2200))", BauhausColors.primary)
                HStack(spacing: 2) {
                    bauhausCell("P", "\(NumberFormatterUtils.int(summary.protein))g", BauhausColors.protein)
                    bauhausCell("F", "\(NumberFormatterUtils.int(summary.fat))g", BauhausColors.fat)
                    bauhausCell("C", "\(NumberFormatterUtils.int(summary.carbs))g", BauhausColors.carbs)
                }
                bauhausCell("H2O", "\(waterMl)/\(profile?.waterGoalMl ?? 2500) ml", BauhausColors.secondary)
                waterControls.padding(.horizontal, GridSpacing.md)
                mealsSection.padding(GridSpacing.md)
            }
        }
        .background(BauhausColors.background)
        .navigationTitle("Intake")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showAddFood = true } label: { Image(systemName: GridIcons.add) } } }
        .sheet(isPresented: $showAddFood, onDismiss: reload) { IntakeAddFlow(date: date) }
        .sheet(isPresented: $showWater, onDismiss: reload) { AddWaterSheet(date: date) }
        .onAppear(perform: reload).onChange(of: date) { _, _ in reload() }
    }


    private var dateSelector: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(DateUtils.string(date, DateUtils.dayMonth)).font(GridTypography.bodyMedium).foregroundStyle(BauhausColors.textPrimary)
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal, GridSpacing.sm).padding(.vertical, GridSpacing.xs)
        .background(BauhausColors.surface).clipShape(RoundedRectangle(cornerRadius: SharpRadius.md))
    }


    private var waterControls: some View {
        HStack(spacing: 2) {
            ForEach([250, 500], id: \.self) { ml in
                Button { addWater(ml) } label: {
                    Text("+\(ml)").frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(BauhausColors.primary).foregroundStyle(BauhausColors.onPrimary)
                }
            }
            Button { showWater = true } label: {
                Text("…").frame(width: 44).padding(.vertical, 10).background(BauhausColors.elevatedSurface)
            }
        }
    }


    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: GridSpacing.sm) {
            Text("Meals").font(GridTypography.captionMedium).foregroundStyle(BauhausColors.textSecondary)
            if meals.isEmpty {
                BlankGridView(systemImage: GridIcons.nutrition, title: "No meals", message: "Add food to start tracking.", actionTitle: "Add") { showAddFood = true }
            } else {
                ForEach(meals) { meal in
                    NavigationLink { IntakeMealView(meal: meal) } label: { mealRowBauhaus(meal) }
                }
            }
        }
    }

    private func bauhausCell(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Rectangle().fill(color).frame(width: 8)
            VStack(alignment: .leading) {
                Text(label).font(GridTypography.caption).foregroundStyle(BauhausColors.textSecondary)
                Text(value).font(GridTypography.title3).foregroundStyle(BauhausColors.textPrimary)
            }
            Spacer()
        }
        .padding(GridSpacing.md).background(BauhausColors.surface)
    }

    private func mealRowBauhaus(_ meal: Meal) -> some View {
        HStack {
            Text(meal.type.displayName.uppercased()).font(GridTypography.captionMedium)
            Spacer()
            Text("\(NumberFormatterUtils.int(meal.totalCalories))").font(GridTypography.title3)
        }
        .padding(GridSpacing.sm).background(BauhausColors.elevatedSurface)
    }
}


struct AddWaterSheet: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss
    var date: Date = .now
    @State private var amount = "250"
    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") { TextField("ml", text: $amount).keyboardType(.numberPad) }
            }
            .navigationTitle("Add Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BauhausColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let ml = Int(amount), ml > 0, ml <= 5000 {
                            try? environment.nutritionRepository.addHydration(amountMl: ml, date: date)
                            HapticsManager.success()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
