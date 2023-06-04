import UIKit

class MeasurementsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    // function gets called when view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register table view delegate and datasource
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // register custom table view cell (TVCLFoodInfo)
        self.tableView.register(TVCLMeasurementInfo.nib(), forCellReuseIdentifier: TVCLMeasurementInfo.identifier)
    }
    
    // function gets called every time this view appears
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
   
    // needs to be implemented because of the UITableViewDelegate
    // provides the table view cell for data presentation
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let customCell = tableView.dequeueReusableCell(withIdentifier: TVCLMeasurementInfo.identifier, for: indexPath) as? TVCLMeasurementInfo else {
            return UITableViewCell()
        }
        customCell.configure(measurement: CoreDataManager.shared.measurements[indexPath.row])
        return customCell
    }
    
    // needs to be implemented because of the UITableViewDelegate
    // provides the data to show in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CoreDataManager.shared.measurements.count
    }

    // needs to be implemented because of the UITableViewDelegate
    // provides the table view cell height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    // function gets called if the user taps on the instruction button
    @IBAction func pressedInstructionButton(_ sender: UIButton) {
        // navigate to the instruction screen
        let vc = UIStoryboard(name: Constants.SYB_Name, bundle: nil).instantiateViewController(
            withIdentifier: Constants.SID_VC_Instruction) as! InstructionViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false, completion: nil)
    }
}
