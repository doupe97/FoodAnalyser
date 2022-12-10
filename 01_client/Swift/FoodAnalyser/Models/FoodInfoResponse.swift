import UIKit

struct FoodInfoResponse: Decodable {
    let statusCode: Int
    let label: String
    let confidence: Double
    let density: Double
    let detailLevel: String
    let featureSensitivity: String
    let pyvista: LibraryInfo
    let trimesh: LibraryInfo
    let nutrients: Nutrients
    
    func getFoodInfoObject() -> FoodInfo {
        
        var title: String = ""
        
        switch self.label {
            case "pear":
                title = "Birne"
            case "apple":
                title = "Apfel"
            case "orange":
                title = "Orange"
            case "banana":
                title = "Banane"
            case "kiwi":
                title = "Kiwi"
            default:
                title = self.label
        }
        
        return FoodInfo(
            general: [
                FoodInfoItem(iconName: "Object", type: "Objekt", value: title),
                FoodInfoItem(iconName: "Density", type: "Dichte", value: "\(String(self.density.round())) g/cm3"),
                FoodInfoItem(iconName: "Volume", type: "Volumen (P)", value: "\(String(self.pyvista.volumeInCM3.round())) cm3"),
                FoodInfoItem(iconName: "Weight", type: "Gewicht (P)", value: "\(String(self.pyvista.weightInGrams.round())) g"),
                FoodInfoItem(iconName: "Volume", type: "Volumen (T)", value: "\(String(self.trimesh.volumeInCM3.round())) cm3"),
                FoodInfoItem(iconName: "Weight", type: "Gewicht (T)", value: "\(String(self.trimesh.weightInGrams.round())) g"),
                FoodInfoItem(iconName: "Kcal", type: "Kcal", value: "\(self.nutrients.kcal?.round() ?? 0.0)"),
                FoodInfoItem(iconName: "KJ", type: "kJ", value: "\(self.nutrients.kJ?.round() ?? 0.0)"),
                FoodInfoItem(iconName: "Settings", type: "Detail Level", value: "\(String(self.detailLevel))"),
                FoodInfoItem(iconName: "Settings", type: "Sensitivity", value: "\(String(self.featureSensitivity))")
            ],
            macronutrients: [
                FoodInfoItem(iconName: "Protein", type: "Protein", value: "\(self.nutrients.protein?.round() ?? 0.0) g"),
                FoodInfoItem(iconName: "Carbs", type: "Kohlenhydrate", value: "\(self.nutrients.carbohydrates?.round() ?? 0.0) g"),
                FoodInfoItem(iconName: "Fat", type: "Fett", value: "\(self.nutrients.fat?.round() ?? 0.0) g"),
                FoodInfoItem(iconName: "Sugar", type: "Zucker", value: "\(self.nutrients.sugars?.round() ?? 0.0) g"),
                FoodInfoItem(iconName: "Water", type: "Wasser", value: "\(self.nutrients.water?.round() ?? 0.0) ml")
            ],
            micronutrients: [
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin A", value: "\(self.nutrients.vitaminA?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin B-12", value: "\(self.nutrients.vitaminB12?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin C", value: "\(self.nutrients.vitaminC?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin D", value: "\(self.nutrients.vitaminD?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin E", value: "\(self.nutrients.vitaminE?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin K", value: "\(self.nutrients.vitaminK?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Alcohol", type: "Alkohol", value: "\(self.nutrients.alcohol?.round() ?? 0.0) g"),
                FoodInfoItem(iconName: "Iron", type: "Eisen", value: "\(self.nutrients.iron?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Sugar", type: "Glucose", value: "\(self.nutrients.glucose?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Calcium", type: "Kalzium", value: "\(self.nutrients.calcium?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Coffein", type: "Koffein", value: "\(self.nutrients.caffeine?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Copper", type: "Kupfer", value: "\(self.nutrients.copper?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Magnesium", type: "Magnesium", value: "\(self.nutrients.magnesium?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Sugar", type: "Saccharose", value: "\(self.nutrients.sucrose?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Sugar", type: "Maltose", value: "\(self.nutrients.maltose?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Selenium", type: "Selen", value: "\(self.nutrients.selenium?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Sodium", type: "Natrium", value: "\(self.nutrients.sodium?.round() ?? 0.0) mg"),
                FoodInfoItem(iconName: "Zinc", type: "Zink", value: "\(self.nutrients.zinc?.round() ?? 0.0) mg")
            ].sorted(by: { $0.type < $1.type })
        )
    }
}
