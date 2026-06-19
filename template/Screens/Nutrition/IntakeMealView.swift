import SwiftUI

struct IntakeMealView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss
    let meal: Meal
    @State private var showAddFood = false
    @State private var refresh = UUID()

    var body: some View {
        ScrollView {
            VStack(spacing: GridSpacing.md) {
                GridBlock {
                    HStack {
                        summaryItem("\(NumberFormatterUtils.int(meal.totalCalories))", "kcal")
                        summaryItem("\(NumberFormatterUtils.int(meal.totalProtein))", "P")
                        summaryItem("\(NumberFormatterUtils.int(meal.totalFat))", "F")
                        summaryItem("\(NumberFormatterUtils.int(meal.totalCarbs))", "C")
                    }
                }
                GridBlock {
                    VStack(alignment: .leading, spacing: GridSpacing.sm) {
                        SectionHeader(title: "Food Items")
                        if meal.items.isEmpty { Text("No items").foregroundStyle(BauhausColors.textMuted) }
                        ForEach(meal.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.productName).foregroundStyle(BauhausColors.textPrimary)
                                    Text("\(NumberFormatterUtils.int(item.amountGrams)) g • \(NumberFormatterUtils.int(item.calories)) kcal").font(.caption).foregroundStyle(BauhausColors.textMuted)
                                }
                                Spacer()
                                Button { remove(item) } label: { Image(systemName: GridIcons.delete).foregroundStyle(BauhausColors.danger) }.frame(width: 44, height: 44)
                            }
                        }
                    }
                }
                .id(refresh)
                RedActionButton(title: "Add Food", systemImage: GridIcons.add) { showAddFood = true }
                Button(role: .destructive) { try? environment.nutritionRepository.deleteMeal(meal); dismiss() } label: {
                    Label("Delete Meal", systemImage: GridIcons.delete).frame(maxWidth: .infinity).frame(minHeight: 44)
                }.foregroundStyle(BauhausColors.danger)
            }
            .padding(GridSpacing.md)
        }
        .background(BauhausColors.background)
        .navigationTitle(meal.type.displayName)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddFood, onDismiss: { refresh = UUID() }) { IntakeAddFlow(date: meal.date) }
    }

    private func summaryItem(_ v: String, _ l: String) -> some View {
        VStack { Text(v).font(GridTypography.title3).foregroundStyle(BauhausColors.textPrimary); Text(l).font(.caption).foregroundStyle(BauhausColors.textMuted) }.frame(maxWidth: .infinity)
    }

    private func remove(_ item: MealItem) {
        meal.items.removeAll { $0.id == item.id }
        try? environment.nutritionRepository.saveMeal(meal)
        refresh = UUID()
    }
}
