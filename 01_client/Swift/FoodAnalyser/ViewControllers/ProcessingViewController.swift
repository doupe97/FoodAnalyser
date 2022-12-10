import UIKit

class ProcessingViewController: UIViewController {

    @IBOutlet weak var imageViewLoading: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
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
        self.requestServerApi()
    }
    
    fileprivate func requestServerApi() {
        // calls the server api for analysing the given object
        print(">>> [INFO] Request server api for analysing object")
        
        // gets the server api url for analysing the object
        guard let url: URL = URL(string: Constants.SRV_API_AnalyseObject) else {
            print(">>> [ERROR] Could not get server api url for analysing object")
            self.showError()
            return
        }

        // creates the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // increase default timeout limit because the 3d model generation process takes longer than 60 sec.
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 900 // 15 min.
        
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
                
                if let foodInfoResponse = try? JSONDecoder().decode(FoodInfoResponse.self, from: responseData) {
                    print(">>> [INFO] API status code: \(foodInfoResponse.statusCode)")
                    print(">>> [INFO] FoodInfo object is available")
                    
                    // show result view with collected food information
                    DispatchQueue.main.async {
                        let vc = UIStoryboard(name: Constants.SYB_Name, bundle: nil).instantiateViewController(
                            withIdentifier: Constants.SID_VC_Result) as! ResultViewController
                        vc.modalPresentationStyle = .fullScreen
                        vc.foodInfo = foodInfoResponse.getFoodInfoObject()
                        self.present(vc, animated: false, completion: nil)
                    }
                    
                } else {
                    print(">>> [ERROR] Could not create food info object from response data")
                    self.showError()
                    return
                }
            }
        }
        task.resume()
    }
    
    fileprivate func showError() {
        // if there is an error, alert the user in ui
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
    
    fileprivate func setupProgressDescriptions() {
        // function defines the progress description texts in the ui
        descriptions.append(ProgressDescription(
            title: "Lade Daten ...",
            description: "Die aufgenommenen Bilder werden nun von der Server API entgegengenommen, als Eingabe geladen und zur Analyse des vorliegenden Lebensmittels verarbeitet."))
        
        descriptions.append(ProgressDescription(
            title: "Erkenne Lebensmittel ...",
            description: "Das erste aufgenommene Bild wird nun an die AWS Rekognition API geschickt, welche eine Bildklassifizierung durchführt und das vorliegende Lebensmittel identifiziert."))
        
        descriptions.append(ProgressDescription(
            title: "Hole Dichte ...",
            description: "Anschließend wird die durchschnittliche Dichte des Lebensmittels mithilfe einer weiteren API ermittelt, um im Folgenden das Gewicht bestimmen zu können."))
        
        descriptions.append(ProgressDescription(
            title: "Generiere 3D-Modell ...",
            description: "Die Object Capture API des RealityKit Frameworks berechnet nun aus der erhaltenen Bilderserie unter Anwendung verschiedener photogrammetrischer Verfahren ein 3D-Modell des Lebensmittels."))
        
        descriptions.append(ProgressDescription(
            title: "Berechne Volumen ...",
            description: "Auf Basis des generierten 3D-Modells kann nun das Volumen des Lebensmittels berechnet werden."))
        
        descriptions.append(ProgressDescription(
            title: "Berechne Gewicht ...",
            description: "Durch Multiplikation von Dichte und Volumen kann das Gewicht des vorliegenden Lebensmittels errechnet werden."))
        
        descriptions.append(ProgressDescription(
            title: "Analysiere Nährstoffe ...",
            description: "Die Lebensmittelbezeichnung wird im letzten Schritt zusammen mit dem Gewicht an die FoodData Central API geschickt, welche die enthaltenen Nährstoffe zurückliefert."))
    }
    
    fileprivate func runTimer() {
        // function starts a timer for updating the progress description texts in the ui
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
    
    fileprivate func stopTimer() {
        // function stops the running timer instance
        self.isTimerRunning = false
        self.timer?.invalidate()
        self.timer = nil
    }

    @objc func updateTimer() {
        // function for updating / cycling the progress description texts in the ui
        if self.currentDescriptionNumber < descriptions.count - 1 {
            self.currentDescriptionNumber += 1
        } else {
            self.currentDescriptionNumber = 0
        }
        self.titleLabel.text = self.descriptions[self.currentDescriptionNumber].title
        self.descriptionTextView.text = self.descriptions[self.currentDescriptionNumber].description
    }
}