import UIKit

struct Media {
    let key: String
    let filename: String
    let data: Data
    let mimeType: String
    
    init?(imageData: Data, fileName: String, key: String) {
        self.key = key
        self.mimeType = "image/heic"
        self.filename = "\(fileName).heic"
        self.data = imageData
    }
}
