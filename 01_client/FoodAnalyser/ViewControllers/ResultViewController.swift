import UIKit
import SceneKit.ModelIO

class ResultViewController: UIViewController, URLSessionDownloadDelegate {
    
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var labelDetailLevel: UILabel!
    @IBOutlet weak var labelFeatureSensitivity: UILabel!
    @IBOutlet weak var labelVolume: UILabel!
    @IBOutlet weak var labelMeasurementTime: UILabel!
    @IBOutlet weak var labelNumberInputImages: UILabel!
    
    // contains the server api response data
    public var responseInfo: ResponseInfo? = nil
    
    // function gets called when view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // download the generated 3d model file from the server api
        self.downloadModelFile()
        
        // draw response info on screen
        if let responseInfo = self.responseInfo {
            labelDetailLevel.text = "\(responseInfo.detailLevel)"
            labelFeatureSensitivity.text = "\(responseInfo.featureSensitivity)"
            labelNumberInputImages.text = "\(responseInfo.numberInputImages) Bilder"
            labelVolume.text = "\(responseInfo.volumeInCm3) cm3"
            labelMeasurementTime.text = "\(responseInfo.measurementTimeInSec) sec."
        }
    }
    
    // function gets called when user taps on Speichern button
    @IBAction func pressedSaveResult(_ sender: UIButton) {
        let dialog = UIAlertController(title: "Speicherung", message: "Bitte geben Sie eine Bezeichnung für diese Messung an.", preferredStyle: .alert)
        dialog.addTextField()
        
        let submitAction = UIAlertAction(title: "Speichern", style: .default) { [unowned dialog] _ in
            if let responseInfo = self.responseInfo {
                
                // save result locally in CoreData
                CoreDataManager.shared.createMeasurement(
                    title: "\(dialog.textFields![0].text ?? "")",
                    dateTime: Date.now,
                    detailLevel: responseInfo.detailLevel,
                    featureSensitivity: responseInfo.featureSensitivity,
                    measurementTime: responseInfo.measurementTimeInSec,
                    volume: responseInfo.volumeInCm3,
                    numberInputImages: Int32(responseInfo.numberInputImages))
                
                // navigate to measurements screen
                let vc = UIStoryboard(name: Constants.SYB_Name, bundle: nil).instantiateViewController(
                    withIdentifier: Constants.SID_VC_Measurement) as! MeasurementsViewController
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: false, completion: nil)
            }
        }
        
        dialog.addAction(submitAction)
        dialog.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
        self.present(dialog, animated: true)
    }
    
    // function gets called when the file download has been finished
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            // get file location url and store downloaded 3d model file in local application storage
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = paths[0].appendingPathComponent(Constants.FILE_OBJ_Model)
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: location)
            print(">>> [INFO] Successfully downloaded and saved generated 3D model locally")
            
        } catch {
            print(">>> [ERROR] Failed storing 3D model file to local disk due to: '\(error)'")
        }
        
        self.setupSceneModel()
    }
    
    // function downloads the generated 3d model file from the server api endpoint
    fileprivate func downloadModelFile() {
        guard let apiUrl = URL(string: Constants.SRV_API_Get3DModel) else { return }
        let session = URLSession(configuration: URLSession.shared.configuration, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: apiUrl)
        task.resume()
    }
    
    // function loads the downloaded 3d model file in the scene view in the ui
    fileprivate func setupSceneModel() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if paths.count > 0 {
            self.sceneView.autoenablesDefaultLighting = true
            self.sceneView.allowsCameraControl = true
            self.sceneView.backgroundColor = UIColor.black
            let asset = MDLAsset(url: paths[0].appendingPathComponent(Constants.FILE_OBJ_Model))
            let scene = SCNScene(mdlAsset: asset)
            self.sceneView.scene = scene
        }
    }
    
}
