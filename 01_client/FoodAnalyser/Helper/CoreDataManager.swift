import UIKit
import CoreData

class CoreDataManager {
    
    // represents the app context
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // static instance of CoreDataManager class
    static let shared = CoreDataManager()
    
    // contains the stored measurements
    public var measurements = [Measurement]()
    
    // constructor
    private init() {
        self.loadAllMeasurements()
    }
    
    // function loads all locally saved measurements from Core Data
    public func loadAllMeasurements() {
        let request = NSFetchRequest<Measurement>(entityName: "Measurement")
        request.returnsObjectsAsFaults = false
        do {
            self.measurements = try context.fetch(request)
        } catch {
            print(">>> [ERROR] Could not load measurements from Core Data")
        }
    }

    // function creates a new measurement entry in Core Data
    public func createMeasurement(title: String, dateTime: Date, detailLevel: String, featureSensitivity: String, measurementTime: Double, volume: Double, numberInputImages: Int32) {
        
        let measurement = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context) as! Measurement
        
        measurement.title = title
        measurement.dateTime = Date()
        measurement.detailLevel = detailLevel
        measurement.featureSensitivity = featureSensitivity
        measurement.measurementTime = measurementTime
        measurement.volume = volume
        measurement.numberInputImages = numberInputImages
        
        // save new measurement
        do {
            try context.save()
        } catch {
            print(">>> [ERROR] Could not save new measurement to Core Data")
        }
        
        // updates local class variable
        self.loadAllMeasurements()
    }
}
