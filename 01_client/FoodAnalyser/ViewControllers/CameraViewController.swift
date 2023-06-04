import UIKit
import AVFoundation
import CoreLocation
import Photos
import MediaPlayer

class CameraViewController: UIViewController {
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var setupResult: SessionSetupResult = .success
    private var spinner: UIActivityIndicatorView!
    private let photoOutput = AVCapturePhotoOutput()
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    @objc dynamic var deviceInput: AVCaptureDeviceInput!
    
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var photoCounter: UILabel!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var detailLevelButton: UIButton!
    @IBOutlet weak var featureSensitivityButton: UIButton!
    
    // function gets called when view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup menu buttons for object capture configuration
        self.setupMenuButtons()
        
        // setup the preview view for photo capture and spinner
        previewView.session = captureSession
		
        // check app permission for camera access
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // the user has granted camera access
            case .authorized:
                break
            
            // the user has not yet granted camera access
            case .notDetermined:
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted {
                        self.setupResult = .notAuthorized
                    }
                    self.sessionQueue.resume()
                })
            
            // the user has denied camera access
            default:
                setupResult = .notAuthorized
        }
        
        // configure the camera session in session queue asynchronously
        sessionQueue.async {
            self.configureSession()
        }
        
        // show spinner for loading animation
        DispatchQueue.main.async {
            self.spinner = UIActivityIndicatorView(style: .large)
            self.spinner.color = UIColor.yellow
            self.previewView.addSubview(self.spinner)
        }
    }
    
    // function configures the capture session
    fileprivate func configureSession() {
        if setupResult != .success { return }
        
        // configure capture session
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // select and prepare input device for capture session
        do {
            var defaultDevice: AVCaptureDevice?
            
            // configure dual camera setup
            guard let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else {
                print(">>> [ERROR] Dual camera device is unavailable")
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
            print(">>> [INFO] Using dual camera device")
            defaultDevice = dualCameraDevice
            
            // commit session configuration
            guard let device = defaultDevice else {
                print(">>> [ERROR] Default device is unavailable")
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
            
            let deviceInput = try AVCaptureDeviceInput(device: device)
            
            // remove existing capture session inputs to enable switching inputs
            let inputs = captureSession.inputs
            if (!inputs.isEmpty) {
                for input in inputs {
                    captureSession.removeInput(input)
                }
            }
            
            // add input to capture session
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
                self.deviceInput = deviceInput
                
            } else {
                print(">>> [ERROR] Could not add device input to capture session")
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
            
        } catch {
            print(">>> [ERROR] Could not create device input: \(error)")
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }
        
        // remove existing photo outputs to enable switching outputs
        let outputs = captureSession.outputs
        if (!outputs.isEmpty) {
            for output in outputs {
                captureSession.removeOutput(output)
            }
        }
        
        // add photo output to capture session
        if captureSession.canAddOutput(photoOutput) {
            
            photoOutput.maxPhotoQualityPrioritization = .quality
            captureSession.addOutput(photoOutput)
            
            // configurations after photoOutput was added to captureSession
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isDepthDataDeliveryEnabled = true
            
        } else {
            print(">>> [ERROR] Could not add photo output to capture session")
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }
        
        // commit changes to capture session
        captureSession.commitConfiguration()
    }
    
    // function setups the menu buttons for setting the object capture configuration
    fileprivate func setupMenuButtons() {
        let tapAction = { (action: UIAction) in }
        
        // setup items for detail level menu button
        self.detailLevelButton.menu = UIMenu(children: [
            UIAction(title: "preview", handler: tapAction),
            UIAction(title: "reduced", handler: tapAction),
            UIAction(title: "medium", state: .on, handler: tapAction),
            UIAction(title: "full", handler: tapAction),
            UIAction(title: "raw", handler: tapAction)
        ])
        self.detailLevelButton.showsMenuAsPrimaryAction = true
        
        // setup items for feature sensitivity menu button
        self.featureSensitivityButton.menu = UIMenu(children: [
            UIAction(title: "normal", state: .on, handler: tapAction),
            UIAction(title: "high", handler: tapAction)
        ])
        self.featureSensitivityButton.showsMenuAsPrimaryAction = true
    }
    
    // function uploads captured image to server
    fileprivate func uploadImage(_ imageData: Data) {
        // get the server api url for uploading an image
        guard let url: URL = URL(string: Constants.SRV_API_UploadImage) else {
            print(">>> [ERROR] Could not get server api url for image upload")
            return
        }
        
        // create unique UUID for image file and media type for upload
        let fileName = UUID().uuidString
        guard let mediaImage = Media(imageData: imageData, fileName: fileName, key: "file") else {
            print(">>> [ERROR] Could not create media image")
            return
        }
        
        // create request object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary: String = "Boundary-\(NSUUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // define request body
        let dataBody = createDataBody(media: [mediaImage], boundary: boundary)
        request.httpBody = dataBody
        
        // call server api for image uploading
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    // if success, serialize response to JSON
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    let result = "\(json)"
                    if result.contains("200") {
                        print(">>> [INFO] Image was successfully uploaded")
                        
                        // increase photo counter for UI
                        DispatchQueue.main.async {
                            let newPhotoCounterValue = String("\((Int(self.photoCounter.text ?? "0") ?? 0) + 1)")
                            self.photoCounter.text = newPhotoCounterValue
                            print(">>> [INFO] Photo counter: \(newPhotoCounterValue)")
                        }
                    }
                } catch {
                    print(">>> [ERROR] Failed to upload image due to: '\(error)'")
                }
            }
        }.resume()
    }
    
    // button event listener: captures a photo
    @IBAction func captureImage(_ photoButton: UIButton) {
        sessionQueue.async {
            var photoSettings = AVCapturePhotoSettings()
            
            // configure internal photo output format
            if self.photoOutput.availablePhotoPixelFormatTypes.contains(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
                photoSettings = AVCapturePhotoSettings(format: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                ])
            }
            
            // important: set output format before enabling depth data delivery!
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            // includes unfiltered depth info in image file
            photoSettings.isDepthDataFiltered = false
            photoSettings.embedsDepthDataInPhoto = true
            
            // photo settings for best quality
            photoSettings.flashMode = .off
            photoSettings.isHighResolutionPhotoEnabled = true
            photoSettings.photoQualityPrioritization = .quality
            
            // create photo capture delegate object
            let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {
                // present photo capture complete operation (screen flashing animation)
                DispatchQueue.main.async {
                    self.previewView.videoPreviewLayer.opacity = 0
                    UIView.animate(withDuration: 0.25) {
                        self.previewView.videoPreviewLayer.opacity = 1
                    }
                }
                
            }, completionHandler: { photoCaptureProcessor in
                
                // if photo capture is complete, upload image to server api and remove reference for memory deallocation
                if let imageData: Data = photoCaptureProcessor.photoData {
                    self.uploadImage(imageData)
                }
                
                // reset inProgressPhotoCaptureDelegates for new photoCaptureProcessor configuration
                self.sessionQueue.async {
                    self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                }
                
            }, photoProcessingHandler: { animate in
                // shows spinner during photo capture process
                DispatchQueue.main.async {
                    if animate {
                        self.spinner.hidesWhenStopped = true
                        self.spinner.center = CGPoint(x: self.previewView.frame.size.width / 2.0, y: self.previewView.frame.size.height / 2.0)
                        self.spinner.startAnimating()
                    } else {
                        self.spinner.stopAnimating()
                    }
                }
            })
            
            // call capture method
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
    
    // button event listener: finishes photo capturing, starts server processing
    @IBAction func finishCapturing(_ sender: UIButton) {
        // get the selected detail level from associated menu
        guard let detailLevel = self.detailLevelButton.menu?.selectedElements.first?.title.lowercased() else {
            return
        }
        print(">>> [INFO] Selected detail level: \(detailLevel)")
        
        // get the selected feature sensitivity from associated menu
        guard let featureSensitivity = self.featureSensitivityButton.menu?.selectedElements.first?.title.lowercased() else {
            return
        }
        print(">>> [INFO] Selected feature sensitivity: \(featureSensitivity)")
        
        // shows an alert if the user has finished capturing photos of the object
        let alertController = UIAlertController(
            title: "Hinweis",
            message: "Sind Sie mit der Aufnahme der Bilder fertig und wollen mit der Verarbeitung bzw. Analyse fortfahren?",
            preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Nein", style: .cancel, handler: nil)
        let acceptAction = UIAlertAction(title: "Ja", style: .default) { (_) -> Void in
            // navigates to the processing view controller
            let vc = UIStoryboard(name: Constants.SYB_Name, bundle: nil).instantiateViewController(
                withIdentifier: Constants.SID_VC_Processing) as! ProcessingViewController
            vc.modalPresentationStyle = .fullScreen
            vc.detailLevel = detailLevel
            vc.featureSensitivity = featureSensitivity
            self.present(vc, animated: false, completion: nil)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(acceptAction)
        
        // present the alert to the user
        self.present(alertController, animated: true, completion: nil)
    }
    
    // function creates the POST request data body for the image upload
    fileprivate func createDataBody(media: [Media]?, boundary: String) -> Data {
        let lineBreak = "\r\n"
        var body = Data()
        
        if let media = media {
            for photo in media {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(photo.key)\"; filename=\"\(photo.filename)\"\(lineBreak)")
                body.append("Content-Type: \(photo.mimeType + lineBreak + lineBreak)")
                body.append(photo.data)
                body.append(lineBreak)
            }
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        return body
    }
    
}
