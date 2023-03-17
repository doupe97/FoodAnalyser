import UIKit

class ProcessingViewController: UIViewController {

    @IBOutlet weak var imageViewLoading: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    public var detailLevel: String = "medium" // default
    public var featureSensitivity: String = "normal" // default
    
    var timer: Timer?
    var isTimerRunning = false
    var currentDescriptionNumber: Int = 0
    var descriptions = [ProgressDescription]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupProgressDescriptions()
        
        // show loading animation gif
        if let bundleUrl = Bundle.main.url(forResource: "loading", withExtension: "gif") {
            if let imageData = try? Data(contentsOf: bundleUrl) {
                if let gifImage = UIImage.gifImageWithData(imageData) {
                    self.imageViewLoading.image = gifImage
                }
            }
        }
        
        // show first description text
        if let firstDescription = descriptions.first {
            self.titleLabel.text = firstDescription.title
            self.descriptionTextView.text = firstDescription.description
        }
        
        // start timer for looping description texts
        self.runTimer()
        
        // request server api
        self.requestServerApi(detailLevel: self.detailLevel, featureSensitivity: self.featureSensitivity)
    }
    
    // function calls the server api for analysing the object
    fileprivate func requestServerApi(detailLevel: String, featureSensitivity: String) {
        print(">>> [INFO] Request server api for analysing object")
        
        // get the server api url for analysing the object
        guard let url: URL = URL(string: Constants.SRV_API_AnalyseObject) else {
            print(">>> [ERROR] Could not get server api url for analysing object")
            self.showError()
            return
        }

        // create the request object
        guard var urlComponents = URLComponents(string: url.absoluteString) else {
            print(">>> [ERROR] Could not create url components")
            return
        }
        
        // append request url get parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "dl", value: detailLevel),
            URLQueryItem(name: "fs", value: featureSensitivity)
        ]
        
        guard let url = urlComponents.url else {
            print(">>> [ERROR] Could not create url from url components")
            return
        }
        
        print(">>> [INFO] Request url: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // increase default timeout limit because the 3d model generation process may take more time
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 2700 // set timeout limit to 45 min.
        
        // create session with custom configuration
        let session = URLSession(configuration: configuration)
        
        // calls the server api
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print(">>> [ERROR] API error during analysing object due to: '\(error)'")
                self.showError()
                return
            }
            
            // if success, get raw response data and create food info object from it
            if let responseData = data {
                self.stopTimer()
                
                if let responseInfo = try? JSONDecoder().decode(ResponseInfo.self, from: responseData) {
                    
                    if responseInfo.statusCode == 200 {
                        print(">>> [INFO] ResponseInfo object is available")
                        
                        // navigate to result view controller for presentation
                        DispatchQueue.main.async {
                            let vc = UIStoryboard(name: Constants.SYB_Name, bundle: nil).instantiateViewController(
                                withIdentifier: Constants.SID_VC_Result) as! ResultViewController
                            vc.modalPresentationStyle = .fullScreen
                            vc.responseInfo = responseInfo
                            self.present(vc, animated: false, completion: nil)
                        }
                    } else {
                        print(">>> [ERROR] Response was unsuccessful")
                        self.showError()
                        return
                    }
                    
                } else {
                    print(">>> [ERROR] Could not create ResponseInfo object from response data")
                    self.showError()
                    return
                }
            } else {
                print(">>> [ERROR] Could not get raw response data")
                self.showError()
                return
            }
        }
        task.resume()
    }
    
    // function shows error message to user
    fileprivate func showError() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: "Fehler",
                message: "Es ist ein Fehler bei der Verarbeitung der Daten aufgetreten. Bitte versuchen Sie es erneut.",
                preferredStyle: .alert)
            
            let okayAction = UIAlertAction(title: "OK", style: .default) { (_) -> Void in
                let vc = UIStoryboard(name: Constants.SYB_Name, bundle: nil).instantiateViewController(
                    withIdentifier: Constants.SID_VC_Camera) as! CameraViewController
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: false, completion: nil)
            }
            
            alertController.addAction(okayAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // function defines the progress description texts in the ui
    fileprivate func setupProgressDescriptions() {
        descriptions.append(ProgressDescription(
            title: "Lade Bilder ...",
            description: "Die aufgenommenen Bilder werden nun von dem Server API entgegengenommen, als Eingabe geladen und zur Analyse des vorliegenden Lebensmittels vorbereitet."))
        
        descriptions.append(ProgressDescription(
            title: "Generiere 3D Modell ...",
            description: "Das Object Capture API des RealityKit Frameworks berechnet nun auf Basis der hochgeladenen Bilder unter Anwendung photogrammetrischer Verfahren ein 3D Modell des Lebensmittels."))
        
        descriptions.append(ProgressDescription(
            title: "Erfasse Messzeit ...",
            description: "Parallel zur Objektrekonstruktion wird die Messzeit bzw. die Dauer der Rekonstruktion gemessen und dokumentiert."))
        
        descriptions.append(ProgressDescription(
            title: "Berechne Volumen ...",
            description: "Auf Basis des generierten 3D Modells kann nun das Volumen des Lebensmittels berechnet werden."))
        
        descriptions.append(ProgressDescription(
            title: "Bereite Rückgabe vor ...",
            description: "Das Messergebnis wird für die Rückgabe an den anfragenden Client zusammengestellt."))
    }
    
    // function starts a timer for updating the progress description texts in the ui
    fileprivate func runTimer() {
        self.isTimerRunning = true
        guard self.timer == nil else { return }
        self.timer = Timer.scheduledTimer(
            timeInterval: 10, // cycles progress description text every 10 sec.
            target: self,
            selector: (#selector(updateTimer)),
            userInfo: nil,
            repeats: true
        )
    }
    
    // function stops the running timer instance
    fileprivate func stopTimer() {
        self.isTimerRunning = false
        self.timer?.invalidate()
        self.timer = nil
    }

    // function for updating / cycling the progress description texts in the ui
    @objc func updateTimer() {
        if self.currentDescriptionNumber < descriptions.count - 1 {
            self.currentDescriptionNumber += 1
        } else {
            self.currentDescriptionNumber = 0
        }
        self.titleLabel.text = self.descriptions[self.currentDescriptionNumber].title
        self.descriptionTextView.text = self.descriptions[self.currentDescriptionNumber].description
    }
}
