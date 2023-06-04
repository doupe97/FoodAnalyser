import UIKit
import AVFoundation

// class needed for preview screen / loading animation while capturing a photo
class PreviewView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError(">>> [ERROR] Expected AVCaptureVideoPreviewLayer for layer. Check implementation.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get { return videoPreviewLayer.session }
        set { self.videoPreviewLayer.session = newValue }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
