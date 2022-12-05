import AVFoundation
import Photos
import UIKit

class PhotoCaptureProcessor: NSObject {
    
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    private let willCapturePhotoAnimation: () -> Void
    private let completionHandler: (PhotoCaptureProcessor) -> Void
    private let photoProcessingHandler: (Bool) -> Void
    public var photoData: Data?
    private var maxPhotoProcessingTime: CMTime?

    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         willCapturePhotoAnimation: @escaping () -> Void,
         completionHandler: @escaping (PhotoCaptureProcessor) -> Void,
         photoProcessingHandler: @escaping (Bool) -> Void) {
        
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.completionHandler = completionHandler
        self.photoProcessingHandler = photoProcessingHandler
    }
    
    private func didFinish() {
        completionHandler(self)
    }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
        // screen flashing animation
        willCapturePhotoAnimation()
        
        guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
            return
        }
        
        // shows spinner if processing time exceeds one second
        let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
        if maxPhotoProcessingTime > oneSecond {
            photoProcessingHandler(true)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        photoProcessingHandler(false)

        if let error = error {
            print(">>> [ERROR] Failed capturing photo: \(error)")
            return
        } else {
            // fileDataRepresentation = https://developer.apple.com/documentation/avfoundation/avcapturephoto/2873919-filedatarepresentation
            // photo and depth map included
            photoData = photo.fileDataRepresentation()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print(">>> [ERROR] Failed capturing photo: \(error)")
            self.completionHandler(self)
            return
        }

        guard let photoData = photoData else {
            print(">>> [ERROR] No photo data found")
            self.completionHandler(self)
            return
        }

        // https://developer.apple.com/documentation/avfoundation/photo_capture/capturing_still_and_live_photos/saving_captured_photos
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: photoData, options: nil)
                    
                }, completionHandler: { _, error in
                    if let error = error {
                        print(">>> [ERROR] Failed saving photo to system photo library: \(error)")
                    }
                    self.completionHandler(self)
                }
                )
            } else {
                self.completionHandler(self)
            }
        }
    }
}
