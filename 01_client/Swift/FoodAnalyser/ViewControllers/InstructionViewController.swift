import UIKit

class InstructionViewController: UIViewController {

    @IBOutlet weak var instructionImage: UIImageView!
    @IBOutlet weak var instructionTitle: UILabel!
    @IBOutlet weak var intructionTextView: UITextView!
    @IBOutlet weak var nextInstructionButton: UIButton!
    @IBOutlet weak var prevInstructionButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    private var instructions = [Instruction]()
    private var currentInstructionNumber: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupInstructions()
        self.changeInstruction()
    }
    
    fileprivate func setupInstructions() {
        // function defines the instruction screens
        self.instructions.append(Instruction(
            id: 1,
            title: "Einführung",
            description: "Die folgenden Instruktionsseiten erklären die Durchführung des Scanvorgangs zur Analyse des vorliegenden Lebensmittels.",
            imageName: "InstructionImage1"))
        
        self.instructions.append(Instruction(
            id: 2,
            title: "Fotografie",
            description: "Um das vorligende Lebensmittel hinsichtlich seines Volumens und der enthaltenen Nährstoffe analysieren zu können, muss dieses im ersten Schritt in unterschiedlichen Winkeln fotografiert werden.",
            imageName: "InstructionImage2"))
        
        self.instructions.append(Instruction(
            id: 3,
            title: "Hochladen",
            description: "Parallel zur Aufnahme der Bilder werden die gespeicherten Aufnahmen zur Analyse an die externe Server API geschickt.",
            imageName: "InstructionImage3"))
        
        self.instructions.append(Instruction(
            id: 4,
            title: "Verarbeitung",
            description: "Der Server generiert aus den erhaltenen Bildern ein 3D-Modell und berechnet anschließend neben dem Volumen und Gewicht die enthaltenen Nährstoffe des Lebensmittels.",
            imageName: "InstructionImage4"))
        
        self.instructions.append(Instruction(
            id: 5,
            title: "Ergebnis",
            description: "Abschließend werden die Ergebnisse der Analyse von der Server API abgerufen und in der App aufbereitet dargestellt.",
            imageName: "InstructionImage5"))
    }
    
    fileprivate func changeInstruction() {
        // function updates the instruction ui components with new values
        if (self.currentInstructionNumber >= 1 && self.currentInstructionNumber <= self.instructions.count) {
            let pageNumber: Int = self.currentInstructionNumber - 1
            let instruction = self.instructions[pageNumber]
            
            if let image = UIImage(named: instruction.imageName) {
                self.instructionImage.image = image
            }
            
            self.instructionTitle.text = "\(instruction.id). \(instruction.title)"
            self.intructionTextView.text = instruction.description
        }
    }
    
    fileprivate func showError() {
        print(">>> [ERROR] Sevrer API is unavailable")
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: "Fehler",
                message: "Die Server API ist nicht erreichbar. Bitte stellen Sie sicher, dass die Server API erreichbar ist und versuchen Sie es dann erneut.",
                preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okayAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func pressedPrevButton(_ sender: UIButton) {
        // show the previous instruction in the ui
        if (self.currentInstructionNumber == 1) {
            self.currentInstructionNumber = self.instructions.count
        } else {
            self.currentInstructionNumber -= 1
        }
        self.changeInstruction()
    }
    
    @IBAction func pressedNextButton(_ sender: UIButton) {
        // show the next instruction in the ui
        if (self.currentInstructionNumber == self.instructions.count) {
            self.currentInstructionNumber = 1
        } else {
            self.currentInstructionNumber += 1
        }
        self.changeInstruction()
    }
    
    @IBAction func pressedStartButton(_ sender: Any) {
        print(">>> [INFO] Check if server api is available")
        
        // get server alive api url
        guard let url: URL = URL(string: Constants.SRV_API_Alive) else {
            print(">>> [ERROR] Could not get server api alive url")
            self.showError()
            return
        }
        
        let request = URLRequest(url: url)
        
        // call server alive api
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let _ = error {
                self.showError()
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    print(">>> [INFO] Server API is available")
                    
                    // show camera view controller if the server api is available
                    DispatchQueue.main.async {
                        let vc = UIStoryboard(name: Constants.SYB_Name, bundle: nil).instantiateViewController(
                            withIdentifier: Constants.SID_VC_Camera) as! CameraViewController
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: false, completion: nil)
                    }
                } else {
                    self.showError()
                    return
                }
            } else {
                self.showError()
                return
            }
        }.resume()
    }
}
