import UIKit

class MeasurementsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register table view delegate and datasource
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // register custom table view cell (TVCLFoodInfo)
        self.tableView.register(TVCLMeasurementInfo.nib(), forCellReuseIdentifier: TVCLMeasurementInfo.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let customCell = tableView.dequeueReusableCell(withIdentifier: TVCLMeasurementInfo.identifier, for: indexPath) as? TVCLMeasurementInfo else {
            return UITableViewCell()
        }
        customCell.configure(measurement: CoreDataManager.shared.measurements[indexPath.row])
        return customCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CoreDataManager.shared.measurements.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    @IBAction func pressedInstructionButton(_ sender: UIButton) {
        let vc = UIStoryboard(name: Constants.SYB_Name, bundle: nil).instantiateViewController(
            withIdentifier: Constants.SID_VC_Instruction) as! InstructionViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false, completion: nil)
    }
}
