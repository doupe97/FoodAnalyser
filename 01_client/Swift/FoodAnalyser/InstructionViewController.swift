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
    
    private func setupInstructions() {
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
            description: "Parallel zur Aufnahme der Fotos werden die gespeicherten Aufnahmen zur Analyse auf den externen Server hochgeladen.",
            imageName: "InstructionImage3"))
        
        self.instructions.append(Instruction(
            id: 4,
            title: "Verarbeitung",
            description: "Der Server generiert aus den erhaltenen Aufnahmen ein 3D-Modell und berechnet anschließend das Volumen sowie die enthaltenen Nährstoffe des Lebensmittels.",
            imageName: "InstructionImage4"))
        
        self.instructions.append(Instruction(
            id: 5,
            title: "Ergebnis",
            description: "Abschließend werden die Ergebnisse des Scanvorgangs vom Server abgerufen und in dieser App dargestellt.",
            imageName: "InstructionImage5"))
    }
    
    private func changeInstruction() {
        if (self.currentInstructionNumber >= 1 && self.currentInstructionNumber <= self.instructions.count) {
            let pageNumber: Int = self.currentInstructionNumber - 1
            let instruction = self.instructions[pageNumber]
            if let image = instruction.Image {
                self.instructionImage.image = image
            }
            self.instructionTitle.text = "\(instruction.Id). \(instruction.Title)"
            self.intructionTextView.text = instruction.Description
        }
    }
    
    @IBAction func pressedPrevButton(_ sender: UIButton) {
        if (self.currentInstructionNumber == 1) {
            self.currentInstructionNumber = self.instructions.count
        } else {
            self.currentInstructionNumber -= 1
        }
        self.changeInstruction()
    }
    
    @IBAction func pressedNextButton(_ sender: UIButton) {
        if (self.currentInstructionNumber == self.instructions.count) {
            self.currentInstructionNumber = 1
        } else {
            self.currentInstructionNumber += 1
        }
        self.changeInstruction()
    }
    
    @IBAction func pressedStartButton(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(
            withIdentifier: Constants.SID_VC_Camera) as! CameraViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false, completion: nil)
    }
}
