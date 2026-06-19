import Foundation

struct OpenFoodFactsSearchResponse: Decodable {
    let products: [OpenFoodFactsProductDTO]
}

struct OpenFoodFactsProductDTO: Decodable, Identifiable {
    var id: String { code ?? UUID().uuidString }

    let code: String?
    let productName: String?
    let brands: String?
    let imageUrl: String?
    let nutriscoreGrade: String?
    let ingredientsText: String?
    let allergens: String?
    let nutriments: OpenFoodFactsNutrimentsDTO?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case imageUrl = "image_url"
        case nutriscoreGrade = "nutriscore_grade"
        case ingredientsText = "ingredients_text"
        case allergens
        case nutriments
    }
}

struct OpenFoodFactsNutrimentsDTO: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let fat100g: Double?
    let carbohydrates100g: Double?
    let sugars100g: Double?
    let fiber100g: Double?
    let salt100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case fat100g = "fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case sugars100g = "sugars_100g"
        case fiber100g = "fiber_100g"
        case salt100g = "salt_100g"
    }
}

extension OpenFoodFactsProductDTO {
    var displayName: String {
        if let productName, !productName.isEmpty { return productName }
        return "Unnamed Product"
    }

    var hasCompleteNutrition: Bool {
        guard let n = nutriments else { return false }
        return n.energyKcal100g != nil && n.proteins100g != nil && n.fat100g != nil && n.carbohydrates100g != nil
    }

    func toFoodProduct() -> FoodProduct {
        FoodProduct(
            source: .openFoodFacts,
            openFoodFactsId: code,
            name: displayName,
            brand: brands,
            imageUrl: imageUrl,
            caloriesPer100g: nutriments?.energyKcal100g ?? 0,
            proteinPer100g: nutriments?.proteins100g ?? 0,
            fatPer100g: nutriments?.fat100g ?? 0,
            carbsPer100g: nutriments?.carbohydrates100g ?? 0,
            sugarPer100g: nutriments?.sugars100g,
            fiberPer100g: nutriments?.fiber100g,
            saltPer100g: nutriments?.salt100g,
            nutriScore: nutriscoreGrade,
            ingredients: ingredientsText,
            allergens: allergens,
            cachedAt: .now
        )
    }
}

protocol OpenFoodFactsServiceProtocol {
    func searchProducts(query: String) async throws -> [OpenFoodFactsProductDTO]
}

final class OpenFoodFactsService: OpenFoodFactsServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func searchProducts(query: String) async throws -> [OpenFoodFactsProductDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        let endpoint = Endpoint.openFoodFactsSearch(query: trimmed)
        let response: OpenFoodFactsSearchResponse = try await apiClient.request(endpoint)
        return response.products
    }
}
