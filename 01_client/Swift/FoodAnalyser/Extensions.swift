import UIKit
import MediaPlayer

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        
        var uniqueDevicePositions = [AVCaptureDevice.Position]()
        
        for device in devices where !uniqueDevicePositions.contains(device.position) {
            uniqueDevicePositions.append(device.position)
        }
        
        return uniqueDevicePositions.count
    }
}

// update system volume
extension MPVolumeView {
    static func setVolume(_ value: Float) {
        let volView = MPVolumeView()
        let sld = volView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            sld?.value = value
        }
    }
}

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

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
