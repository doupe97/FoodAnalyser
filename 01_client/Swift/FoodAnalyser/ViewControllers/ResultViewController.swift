import UIKit
import SceneKit.ModelIO

class ResultViewController: UIViewController, URLSessionDownloadDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segControl: UISegmentedControl!
    
    public var foodInfo: FoodInfo? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register table view delegate and datasource
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // register custom table view cell (TVCLFoodInfo)
        self.tableView.register(TVCLFoodInfo.nib(), forCellReuseIdentifier: TVCLFoodInfo.identifier)
        
        // call function for downloading the generated 3d model file from the server
        self.downloadModelFile()
    }
    
    
    // MARK: Table View Controller Delegate and Datasource Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // function defines the number of items in the table view based on selected segment control value
        switch self.segControl.selectedSegmentIndex {
        case 0:
            return (self.foodInfo != nil) ? self.foodInfo!.general.count : 0
        case 1:
            return (self.foodInfo != nil) ? self.foodInfo!.macronutrients.count : 0
        case 2:
            return (self.foodInfo != nil) ? self.foodInfo!.micronutrients.count : 0
        default:
            return (self.foodInfo != nil) ? self.foodInfo!.general.count : 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let customCell = tableView.dequeueReusableCell(withIdentifier: TVCLFoodInfo.identifier, for: indexPath) as? TVCLFoodInfo else {
            return UITableViewCell()
        }
        
        guard let foodInfoObj = self.foodInfo else {
            return UITableViewCell()
        }
        
        // show food information based on selected segment control value
        switch self.segControl.selectedSegmentIndex {
        case 0:
            customCell.configure(foodInfoItem: foodInfoObj.general[indexPath.row])
        case 1:
            customCell.configure(foodInfoItem: foodInfoObj.macronutrients[indexPath.row])
        case 2:
            customCell.configure(foodInfoItem: foodInfoObj.micronutrients[indexPath.row])
        default:
            customCell.configure(foodInfoItem: foodInfoObj.general[indexPath.row])
        }
        
        return customCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
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
    
    // function for toggling the segment control
    @IBAction func toggleSegmentControl(_ sender: UISegmentedControl) {
        // reload the table view with new content based on the selected segment control
        self.tableView.reloadData()
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
