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
    private var keyValueObservations = [NSKeyValueObservation]()
    @objc dynamic var deviceInput: AVCaptureDeviceInput!
    
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var photoCounter: UILabel!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var detailLevelButton: UIButton!
    @IBOutlet weak var featureSensitivityButton: UIButton!
    
    // MARK: View Controller Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupMenuButtons()
        
        photoButton.isEnabled = false
        readyButton.isEnabled = false
        detailLevelButton.isEnabled = false
        featureSensitivityButton.isEnabled = false
        
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
        
        // check app permissions
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session if setup succeeded.
                self.addObservers()
                self.captureSession.startRunning()
                self.isSessionRunning = self.captureSession.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "FoodAnalyser", message: "FoodAnalyser does not have permission to use the camera.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                
            default:
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "FoodAnalyser", message: "Es ist ein Fehler aufgetreten", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        registerVolumeButtonObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // stop capture session and remove observers
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
    
    
    
    // MARK: Capturing Photos
    
    @IBAction private func capturePhoto(_ photoButton: UIButton) {
        sessionQueue.async {
            var photoSettings = AVCapturePhotoSettings()
            
            // configure internal photo output format
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
            photoSettings.embedsDepthDataInPhoto = true // includes depth map in .heic output file
            
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
    
    fileprivate func setupMenuButtons() {
        let tapAction = { (action: UIAction) in }
        
        // setup items for detail level menu button
        self.detailLevelButton.menu = UIMenu(children: [
            UIAction(title: "Preview", handler: tapAction),
            UIAction(title: "Reduced", handler: tapAction),
            UIAction(title: "Medium", state: .on, handler: tapAction),
            UIAction(title: "Full", handler: tapAction)
        ])
        self.detailLevelButton.showsMenuAsPrimaryAction = true
        
        // setup items for feature sensitivity menu button
        self.featureSensitivityButton.menu = UIMenu(children: [
            UIAction(title: "Normal", handler: tapAction),
            UIAction(title: "High", handler: tapAction)
        ])
        self.featureSensitivityButton.showsMenuAsPrimaryAction = true
    }
    
    @IBAction func finishCapturing(_ sender: UIButton) {
        guard let detailLevel = self.detailLevelButton.menu?.selectedElements.first?.title.lowercased() else {
            return
        }
        print(">>> [INFO] Selected detail level: \(detailLevel)")
        
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
        
        // present the alert in the ui
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: Functions for image upload
    
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
    
    fileprivate func createDataBody(media: [Media]?, boundary: String) -> Data {
        // function creates and returns the request data body for image uploading
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
    
    fileprivate func addObservers() {
        // function activates the ui components if the capture session is running
        let keyValueObservation = captureSession.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            DispatchQueue.main.async {
                self.photoButton.isEnabled = isSessionRunning
                self.readyButton.isEnabled = isSessionRunning
                self.detailLevelButton.isEnabled = isSessionRunning
                self.featureSensitivityButton.isEnabled = isSessionRunning
            }
        }
        keyValueObservations.append(keyValueObservation)
    }
    
    fileprivate func removeObservers() {
        // function deactivates the ui components if the capture session has been finished
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        
        keyValueObservations.removeAll()
    }
    
    
    
    // MARK: Trick Volume Event For Automatic Photo Capture
    
    fileprivate func registerVolumeButtonObserver() {
        // function registrates a custom observer for controlling the system volume output
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
            // get the current audio sessions output volume
            let audioSession = AVAudioSession.sharedInstance()
            audioLevel = audioSession.outputVolume
            
            // if the volume has not been reset, capture new photo
            if (audioLevel > 0.2) {
                capturePhoto(self.photoButton)
            }
            
            // reset audio volume if volume reaches max level
            if audioSession.outputVolume > 0.9 {
                MPVolumeView.setVolume(0.2)
                audioLevel = 0.2
            }
        }
    }
}
