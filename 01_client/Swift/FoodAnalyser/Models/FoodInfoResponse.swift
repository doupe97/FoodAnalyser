import UIKit

struct FoodInfoResponse: Decodable {
    let statusCode: Int
    let label: String
    let confidence: Double
    let density: Double
    let detailLevel: String
    let featureSensitivity: String
    let measurementTimeInSeconds: Double
    let pyvista: LibraryInfo
    let trimesh: LibraryInfo
    let nutrients: Nutrients
    
    func transformRawValue(_ value: Double?) -> String {
        var result = "---"
        if let val = value {
            result = "\(val.round())"
        }
        return result
    }
    
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
                FoodInfoItem(iconName: "Kcal", type: "Kcal", value: self.transformRawValue(self.nutrients.kcal)),
                FoodInfoItem(iconName: "KJ", type: "kJ", value: self.transformRawValue(self.nutrients.kJ)),
                FoodInfoItem(iconName: "Settings", type: "Detail Level", value: "\(String(self.detailLevel))"),
                FoodInfoItem(iconName: "Settings", type: "Sensitivity", value: "\(String(self.featureSensitivity))"),
                FoodInfoItem(iconName: "Settings", type: "Messzeit", value: "\(String(self.measurementTimeInSeconds.round())) sec.")
            ],
            macronutrients: [
                FoodInfoItem(iconName: "Protein", type: "Protein", value: "\(self.transformRawValue(self.nutrients.protein)) g"),
                FoodInfoItem(iconName: "Carbs", type: "Kohlenhydrate", value: "\(self.transformRawValue(self.nutrients.carbohydrates)) g"),
                FoodInfoItem(iconName: "Fat", type: "Fett", value: "\(self.transformRawValue(self.nutrients.fat)) g"),
                FoodInfoItem(iconName: "Sugar", type: "Zucker", value: "\(self.transformRawValue(self.nutrients.sugars)) g"),
                FoodInfoItem(iconName: "Water", type: "Wasser", value: "\(self.transformRawValue(self.nutrients.water)) g")
            ],
            micronutrients: [
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin A", value: "\(self.transformRawValue(self.nutrients.vitaminA)) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin B-12", value: "\(self.transformRawValue(self.nutrients.vitaminB12)) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin C", value: "\(self.transformRawValue(self.nutrients.vitaminC)) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin D", value: "\(self.transformRawValue(self.nutrients.vitaminD)) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin E", value: "\(self.transformRawValue(self.nutrients.vitaminE)) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin K", value: "\(self.transformRawValue(self.nutrients.vitaminK)) mg"),
                FoodInfoItem(iconName: "Alcohol", type: "Alkohol", value: "\(self.transformRawValue(self.nutrients.alcohol)) g"),
                FoodInfoItem(iconName: "Iron", type: "Eisen", value: "\(self.transformRawValue(self.nutrients.iron)) mg"),
                FoodInfoItem(iconName: "Sugar", type: "Glucose", value: "\(self.transformRawValue(self.nutrients.glucose)) mg"),
                FoodInfoItem(iconName: "Calcium", type: "Kalzium", value: "\(self.transformRawValue(self.nutrients.calcium)) mg"),
                FoodInfoItem(iconName: "Caffeine", type: "Koffein", value: "\(self.transformRawValue(self.nutrients.caffeine)) mg"),
                FoodInfoItem(iconName: "Copper", type: "Kupfer", value: "\(self.transformRawValue(self.nutrients.copper)) mg"),
                FoodInfoItem(iconName: "Magnesium", type: "Magnesium", value: "\(self.transformRawValue(self.nutrients.magnesium)) mg"),
                FoodInfoItem(iconName: "Sugar", type: "Saccharose", value: "\(self.transformRawValue(self.nutrients.sucrose)) mg"),
                FoodInfoItem(iconName: "Sugar", type: "Maltose", value: "\(self.transformRawValue(self.nutrients.maltose)) mg"),
                FoodInfoItem(iconName: "Selenium", type: "Selen", value: "\(self.transformRawValue(self.nutrients.selenium)) mg"),
                FoodInfoItem(iconName: "Sodium", type: "Natrium", value: "\(self.transformRawValue(self.nutrients.sodium)) mg"),
                FoodInfoItem(iconName: "Zinc", type: "Zink", value: "\(self.transformRawValue(self.nutrients.zinc)) mg")
            ].sorted(by: { $0.type < $1.type })
        )
    }
}
