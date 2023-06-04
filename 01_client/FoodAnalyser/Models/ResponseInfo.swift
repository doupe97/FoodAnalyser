import UIKit

// struct for storing the server api measurement result
// decodable because the type needs to be converted from its JSON representation (api response) to this object type
struct ResponseInfo: Decodable {
    let statusCode: Int
    let detailLevel: String
    let featureSensitivity: String
    let volumeInCm3: Double
    let measurementTimeInSec: Double
    let numberInputImages: Int
}
