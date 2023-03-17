import UIKit

struct ResponseInfo: Decodable {
    let statusCode: Int
    let detailLevel: String
    let featureSensitivity: String
    let volumeInCm3: Double
    let measurementTimeInSec: Double
    let numberInputImages: Int
}
