import Foundation
import SwiftData

@Model
final class FoodProduct {
    var id: UUID
    var source: FoodSource
    var openFoodFactsId: String?

    var name: String
    var brand: String?
    var imageUrl: String?

    var caloriesPer100g: Double
    var proteinPer100g: Double
    var fatPer100g: Double
    var carbsPer100g: Double
    var sugarPer100g: Double?
    var fiberPer100g: Double?
    var saltPer100g: Double?

    var nutriScore: String?
    var ingredients: String?
    var allergens: String?
    var notes: String?

    var isFavorite: Bool
    var cachedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        source: FoodSource = .manual,
        openFoodFactsId: String? = nil,
        name: String,
        brand: String? = nil,
        imageUrl: String? = nil,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        fatPer100g: Double,
        carbsPer100g: Double,
        sugarPer100g: Double? = nil,
        fiberPer100g: Double? = nil,
        saltPer100g: Double? = nil,
        nutriScore: String? = nil,
        ingredients: String? = nil,
        allergens: String? = nil,
        notes: String? = nil,
        isFavorite: Bool = false,
        cachedAt: Date? = nil
    ) {
        self.id = id
        self.source = source
        self.openFoodFactsId = openFoodFactsId
        self.name = name
        self.brand = brand
        self.imageUrl = imageUrl
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.fatPer100g = fatPer100g
        self.carbsPer100g = carbsPer100g
        self.sugarPer100g = sugarPer100g
        self.fiberPer100g = fiberPer100g
        self.saltPer100g = saltPer100g
        self.nutriScore = nutriScore
        self.ingredients = ingredients
        self.allergens = allergens
        self.notes = notes
        self.isFavorite = isFavorite
        self.cachedAt = cachedAt
        self.createdAt = .now
        self.updatedAt = .now
    }
}

@Model
final class Meal {
    var id: UUID
    var date: Date
    var type: MealType
    var title: String
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var items: [MealItem]

    init(
        id: UUID = UUID(),
        date: Date,
        type: MealType,
        title: String,
        notes: String? = nil,
        items: [MealItem] = []
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.title = title
        self.notes = notes
        self.items = items
        self.createdAt = .now
        self.updatedAt = .now
    }

    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    var totalFat: Double { items.reduce(0) { $0 + $1.fat } }
    var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
}

@Model
final class MealItem {
    var id: UUID
    var foodProductId: UUID?
    var productName: String
    var amountGrams: Double

    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double
    var sugar: Double?
    var fiber: Double?
    var salt: Double?

    init(
        id: UUID = UUID(),
        foodProductId: UUID? = nil,
        productName: String,
        amountGrams: Double,
        calories: Double,
        protein: Double,
        fat: Double,
        carbs: Double,
        sugar: Double? = nil,
        fiber: Double? = nil,
        salt: Double? = nil
    ) {
        self.id = id
        self.foodProductId = foodProductId
        self.productName = productName
        self.amountGrams = amountGrams
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.sugar = sugar
        self.fiber = fiber
        self.salt = salt
    }
}

@Model
final class HydrationLog {
    var id: UUID
    var date: Date
    var amountMl: Int
    var note: String?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        amountMl: Int,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.amountMl = amountMl
        self.note = note
    }
}
