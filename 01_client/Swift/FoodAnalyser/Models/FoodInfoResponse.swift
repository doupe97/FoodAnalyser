import UIKit

struct FoodInfoResponse: Decodable {
    let statusCode: Int
    let label: String
    let confidence: Double
    let density: Double
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
                FoodInfoItem(iconName: "Volume", type: "Volumen", value: "\(String(self.pyvista.volumeInCM3.round())) cm3"),
                FoodInfoItem(iconName: "Weight", type: "Gewicht", value: "\(String(self.pyvista.weightInGrams.round())) g"),
                FoodInfoItem(iconName: "Kcal", type: "Kcal", value: "\(String(self.nutrients.kcal.round()))"),
                FoodInfoItem(iconName: "KJ", type: "kJ", value: "\(String(self.nutrients.kJ.round()))")
            ],
            macronutrients: [
                FoodInfoItem(iconName: "Protein", type: "Protein", value: "\(String(self.nutrients.protein.round())) g"),
                FoodInfoItem(iconName: "Carbs", type: "Kohlenhydrate", value: "\(String(self.nutrients.carbohydrates.round())) g"),
                FoodInfoItem(iconName: "Fat", type: "Fett", value: "\(String(self.nutrients.fat.round())) g"),
                FoodInfoItem(iconName: "Sugar", type: "Zucker", value: "\(String(self.nutrients.sugars.round())) g"),
                FoodInfoItem(iconName: "Water", type: "Wasser", value: "\(String(self.nutrients.water.round())) ml")
            ],
            micronutrients: [
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin A", value: "\(String(self.nutrients.vitaminA.round())) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin B-12", value: "\(String(self.nutrients.vitaminB12.round())) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin C", value: "\(String(self.nutrients.vitaminC.round())) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin D", value: "\(String(self.nutrients.vitaminD.round())) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin E", value: "\(String(self.nutrients.vitaminE.round())) mg"),
                FoodInfoItem(iconName: "Vitamin", type: "Vitamin K", value: "\(String(self.nutrients.vitaminK.round())) mg"),
                FoodInfoItem(iconName: "Alcohol", type: "Alkohol", value: "\(String(self.nutrients.alcohol.round())) g"),
                FoodInfoItem(iconName: "Iron", type: "Eisen", value: "\(String(self.nutrients.iron.round())) mg"),
                FoodInfoItem(iconName: "Sugar", type: "Glucose", value: "\(String(self.nutrients.glucose.round())) mg"),
                FoodInfoItem(iconName: "Calcium", type: "Kalzium", value: "\(String(self.nutrients.calcium.round())) mg"),
                FoodInfoItem(iconName: "Coffein", type: "Koffein", value: "\(String(self.nutrients.caffeine.round())) mg"),
                FoodInfoItem(iconName: "Copper", type: "Kupfer", value: "\(String(self.nutrients.copper.round())) mg"),
                FoodInfoItem(iconName: "Magnesium", type: "Magnesium", value: "\(String(self.nutrients.magnesium.round())) mg"),
                FoodInfoItem(iconName: "Sugar", type: "Saccharose", value: "\(String(self.nutrients.sucrose.round())) mg"),
                FoodInfoItem(iconName: "Sugar", type: "Maltose", value: "\(String(self.nutrients.maltose.round())) mg"),
                FoodInfoItem(iconName: "Selenium", type: "Selen", value: "\(String(self.nutrients.selenium.round())) mg"),
                FoodInfoItem(iconName: "Sodium", type: "Natrium", value: "\(String(self.nutrients.sodium.round())) mg"),
                FoodInfoItem(iconName: "Zinc", type: "Zink", value: "\(String(self.nutrients.zinc.round())) mg")
            ].sorted(by: { $0.type < $1.type })
        )
    }
}
