import UIKit

class TVCLMeasurementInfo: UITableViewCell {

    @IBOutlet weak var labelTitel: UILabel!
    @IBOutlet weak var labelDateTime: UILabel!
    @IBOutlet weak var labelDetailLevelFeatureSensitivity: UILabel!
    @IBOutlet weak var labelVolumeMeasurementTime: UILabel!
    
    static let identifier = "TVCLMeasurementInfo"
    
    // function for getting the associated nib / xib file
    // the xib file defines the ui for the custom table view cell
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    // function is called when the custom table view cell is initialized
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // function configures the custom table view cell
    public func configure(measurement: Measurement) {
        self.labelTitel.text = measurement.title
        self.labelDateTime.text = "\(measurement.dateTime ?? Date.now)"
        self.labelDetailLevelFeatureSensitivity.text = "\(measurement.detailLevel ?? "") - \(measurement.featureSensitivity ?? "")"
        self.labelVolumeMeasurementTime.text = "\(measurement.volume) cm3 - \(measurement.measurementTime) sec."
    }
    
}
