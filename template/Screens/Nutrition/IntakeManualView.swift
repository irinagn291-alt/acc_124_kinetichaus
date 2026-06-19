import SwiftUI

struct IntakeManualView: View {
    @EnvironmentObject private var environment: HausContainer
    @Environment(\.dismiss) private var dismiss

    let product: FoodProduct?
    var onSaved: ((FoodProduct) -> Void)? = nil

    @State private var name = ""
    @State private var brand = ""
    @State private var serving = "100"
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var sugar = ""
    @State private var fiber = ""
    @State private var salt = ""
    @State private var notes = ""

    private var isValid: Bool {
        let n = name.trimmingCharacters(in: .whitespaces)
        return !n.isEmpty && n.count <= 120 && (Double(calories) ?? -1) >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Food Name", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Serving Size (g)", text: $serving).keyboardType(.decimalPad)
                }
                Section("Per 100 g") {
                    numberField("Calories", $calories)
                    numberField("Protein", $protein)
                    numberField("Fat", $fat)
                    numberField("Carbs", $carbs)
                    numberField("Sugar", $sugar)
                    numberField("Fiber", $fiber)
                    numberField("Salt", $salt)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle(product == nil ? "Create Food" : "Edit Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid) }
            }
            .onAppear(perform: load)
        }
    }

    private func numberField(_ title: String, _ binding: Binding<String>) -> some View {
        HStack { Text(title); Spacer(); TextField("0", text: binding).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 100) }
    }

    private func load() {
        guard let product else { return }
        name = product.name; brand = product.brand ?? ""
        calories = "\(product.caloriesPer100g)"; protein = "\(product.proteinPer100g)"
        fat = "\(product.fatPer100g)"; carbs = "\(product.carbsPer100g)"
        sugar = product.sugarPer100g.map { "\($0)" } ?? ""; fiber = product.fiberPer100g.map { "\($0)" } ?? ""
        salt = product.saltPer100g.map { "\($0)" } ?? ""; notes = product.notes ?? ""
    }

    private func save() {
        let target = product ?? FoodProduct(name: name, caloriesPer100g: 0, proteinPer100g: 0, fatPer100g: 0, carbsPer100g: 0)
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.brand = brand.isEmpty ? nil : brand
        target.caloriesPer100g = Double(calories) ?? 0
        target.proteinPer100g = Double(protein) ?? 0
        target.fatPer100g = Double(fat) ?? 0
        target.carbsPer100g = Double(carbs) ?? 0
        target.sugarPer100g = Double(sugar)
        target.fiberPer100g = Double(fiber)
        target.saltPer100g = Double(salt)
        target.notes = notes.isEmpty ? nil : notes
        if product == nil { target.source = .manual }
        try? environment.foodProductRepository.saveProduct(target)
        HapticsManager.success()
        dismiss()
        onSaved?(target)
    }
}
