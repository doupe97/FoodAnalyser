import UIKit
import AVFoundation
import CoreLocation
import Photos
import MediaPlayer

class CameraViewController: UIViewController {
    
    private enum LidarMode {
        case on
        case off
    }
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let captureSession = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var setupResult: SessionSetupResult = .success
    private let locationManager = CLLocationManager()
    private var spinner: UIActivityIndicatorView!
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioLevel: Float = 0.0
    private let photoOutput = AVCapturePhotoOutput()
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    private let preferredWidthResolution = 1920
    private var lidarMode: LidarMode = .off
    private var keyValueObservations = [NSKeyValueObservation]()
    @objc dynamic var deviceInput: AVCaptureDeviceInput!
    
    @IBOutlet private weak var photoButton: UIButton!
    @IBOutlet weak var lidarModeButton: UIButton!
    @IBOutlet weak var photoCounter: UILabel!
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var readyButton: UIButton!
    
    // MARK: View Controller Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoButton.isEnabled = false
        lidarModeButton.isEnabled = false
        readyButton.isEnabled = false
        infoLabel.text = "DualCam"
        
        // setup the preview view for photo capture and spinner
        previewView.session = captureSession
		
        // check for device component access permissions
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // user has denied access permissions
            setupResult = .notAuthorized
        }
        
        // configureSession has to be called in sessionQueue (async)
        sessionQueue.async {
            self.configureSession()
        }
        
        DispatchQueue.main.async {
            self.spinner = UIActivityIndicatorView(style: .large)
            self.spinner.color = UIColor.yellow
            self.previewView.addSubview(self.spinner)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session if setup succeeded.
                self.addObservers()
                self.captureSession.startRunning()
                self.isSessionRunning = self.captureSession.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "FoodAnalyser does not have permission to use the camera."
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "FoodAnalyser", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Open Settings"), style: .`default`,
                        handler: { _ in
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                      options: [:],
                                                      completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            default:
                DispatchQueue.main.async {
                    let alertMsg = "Something went wrong"
                    let message = NSLocalizedString("Something went wrong", comment: alertMsg)
                    let alertController = UIAlertController(title: "FoodAnalyser", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        registerVolumeButtonObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.captureSession.stopRunning()
                self.isSessionRunning = self.captureSession.isRunning
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    
    
    
    // MARK: Session Management
    
    private func configureSession() {
        if setupResult != .success { return }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // select and prepare input device for capture session
        do {
            var defaultDevice: AVCaptureDevice?
            
            if lidarMode == .on {
                guard let lidarDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) else {
                    print(">>> [ERROR] Lidar camera device is unavailable")
                    setupResult = .configurationFailed
                    captureSession.commitConfiguration()
                    return
                }
                    
                // configure lidar device
                // https://developer.apple.com/documentation/avfoundation/additional_data_capture/capturing_photos_with_depth
                
                guard let format = (lidarDevice.formats.last { format in
                    format.formatDescription.dimensions.width == preferredWidthResolution &&
                    format.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange &&
                    !format.isVideoBinned &&
                    !format.supportedDepthDataFormats.isEmpty
                }) else {
                    print(">>> [ERROR] ConfigureSession: ConfigurationError.requiredFormatUnavailable")
                    return
                }
                
                guard let depthFormat = (format.supportedDepthDataFormats.last { depthFormat in
                    depthFormat.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_DepthFloat16
                }) else {
                    print(">>> [ERROR] ConfigureSession: ConfigurationError.requiredFormatUnavailable")
                    return
                }
                
                try lidarDevice.lockForConfiguration()
                
                lidarDevice.activeFormat = format
                lidarDevice.activeDepthDataFormat = depthFormat
                
                lidarDevice.unlockForConfiguration()
                
                print(">>> [INFO] Using lidar camera device")
                defaultDevice = lidarDevice
                
            } else {
                guard let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else {
                    print(">>> [ERROR] Dual camera device is unavailable")
                    setupResult = .configurationFailed
                    captureSession.commitConfiguration()
                    return
                }
                print(">>> [INFO] Using dual camera device")
                defaultDevice = dualCameraDevice
            }
            
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
    
    
    
    // MARK: Capturing Photos
    
    @IBAction private func capturePhoto(_ photoButton: UIButton) {
        sessionQueue.async {
            var photoSettings = AVCapturePhotoSettings()
            
            if self.photoOutput.availablePhotoPixelFormatTypes.contains(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
                photoSettings = AVCapturePhotoSettings(format: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                ])
            } else {
                photoSettings = AVCapturePhotoSettings()
            }
            
            // important: set output format before enabling depth data delivery!
            // set photo output format to .heif (.heif format is more compressed than .jpeg)
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            // important: set depth data settings after setting photo output format!
            // required photo setting: capture photo depth data
            // required photo setting: embed the depth map into the .heic output file
            photoSettings.isDepthDataDeliveryEnabled = true
            photoSettings.isDepthDataFiltered = false // default is true
            
            // optional photo settings for better quality
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
                        /*let newPhotoCounterValue = String("\((Int(self.photoCounter.text ?? "0") ?? 0) + 1)")
                        self.photoCounter.text = newPhotoCounterValue
                        print(">>> [INFO] Photo counter: \(newPhotoCounterValue)")*/
                    }
                }
            }, completionHandler: { photoCaptureProcessor in
                
                // if photo capture is complete, upload image to server api and remove reference for memory deallocation
                if let imageData: Data = photoCaptureProcessor.photoData {
                    self.uploadImage(imageData)
                }
                
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
            }
            )
            
            // call capture method
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
    
    
    
    // MARK: Button Functions

    @IBAction func toggleLidarMode(_ lidarModeButton: UIButton) {
        sessionQueue.async {
            self.lidarMode = (self.lidarMode == .on) ? .off : .on
            let lidarMode = self.lidarMode
            
            DispatchQueue.main.async {
                if lidarMode == .on {
                    self.lidarModeButton.setImage(#imageLiteral(resourceName: "LidarON"), for: [])
                    self.infoLabel.text = "LiDAR"
                    
                } else {
                    self.lidarModeButton.setImage(#imageLiteral(resourceName: "LidarOFF"), for: [])
                    self.infoLabel.text = "DualCam"
                }
            }
            
            self.configureSession()
        }
    }
    
    @IBAction func showInfoView(_ sender: UIButton) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(
            withIdentifier: Constants.SID_VC_Instruction) as! InstructionViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false, completion: nil)
    }
    
    @IBAction func finishCapturing(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Hinweis",
            message: "Sind Sie mit der Aufnahme der Bilder fertig und wollen mit der Verarbeitung bzw. Analyse fortfahren?",
            preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Nein", style: .cancel, handler: nil)
        let acceptAction = UIAlertAction(title: "Ja", style: .default) { (_) -> Void in
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(
                withIdentifier: Constants.SID_VC_Processing) as! ProcessingViewController
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: false, completion: nil)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(acceptAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: Functions for image upload
    
    func uploadImage(_ imageData: Data) {
        
        guard let url: URL = URL(string: Constants.SRV_API_UploadImage) else {
            print(">>> [ERROR] Could not get server api url for image upload")
            return
        }
        
        let fileName = UUID().uuidString
        guard let mediaImage = Media(imageData: imageData, fileName: fileName, key: "file") else {
            print(">>> [ERROR] Could not create media image")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary: String = "Boundary-\(NSUUID().uuidString)"
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let dataBody = createDataBody(media: [mediaImage], boundary: boundary)
        request.httpBody = dataBody
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
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
    
    func createDataBody(media: [Media]?, boundary: String) -> Data {
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
    
    
    
    // MARK: KVO and Notifications
    
    private func addObservers() {
        let keyValueObservation = captureSession.observe(\.isRunning, options: .new) { _, change in
            
            guard let isSessionRunning = change.newValue else { return }
            
            // check if server api is running
            if let url = URL(string: Constants.SRV_API_Alive) {
                var isApiAlive: Bool = false
                
                let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                    isApiAlive = (data != nil)
                    
                    DispatchQueue.main.async {
                        if isApiAlive {
                            print(">>> [INFO] Server API is online")
                            self.photoButton.isEnabled = isSessionRunning
                            self.lidarModeButton.isEnabled = isSessionRunning
                            self.readyButton.isEnabled = isSessionRunning
                        } else {
                            print(">>> [INFO] Server API is offline")
                            
                            self.photoButton.isEnabled = false
                            self.lidarModeButton.isEnabled = false
                            self.readyButton.isEnabled = false
                            
                            let alertController = UIAlertController(
                                title: "Hinweis",
                                message: "Die Server API ist nicht erreichbar. Stellen Sie sicher, dass die API erreichbar ist.",
                                preferredStyle: .alert)

                            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                    
                }
                task.resume()
            }
        }
        keyValueObservations.append(keyValueObservation)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        
        keyValueObservations.removeAll()
    }
    
    
    
    // MARK: Trick Volume Event For Automatic Photo Capture
    
    private func registerVolumeButtonObserver() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true, options: [])
            audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
            audioLevel = audioSession.outputVolume
        } catch {
            print(">>> [ERROR] Failure in listenVolumeButton")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            let audioSession = AVAudioSession.sharedInstance()
            audioLevel = audioSession.outputVolume
            
            // if the volume has not been reset, capture new photo
            if (audioLevel > 0.2) {
                capturePhoto(self.photoButton)
            }
            
            // reset system volume level if volume level reaches max
            if audioSession.outputVolume > 0.9 {
                MPVolumeView.setVolume(0.2)
                audioLevel = 0.2
            }
        }
    }
}
