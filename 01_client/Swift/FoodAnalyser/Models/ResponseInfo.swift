import UIKit

struct ResponseInfo: Decodable {
    let statusCode: Int
    let detailLevel: String
    let featureSensitivity: String
    let volumeInCM3: Double
    let measurementTimeInSeconds: Double
}
