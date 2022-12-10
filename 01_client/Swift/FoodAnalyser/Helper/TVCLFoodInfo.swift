import UIKit

class TVCLFoodInfo: UITableViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var labelType: UILabel!
    @IBOutlet weak var labelValue: UILabel!
    
    static let identifier = "TVCLFoodInfo"
    
    // function for getting the associated nib / xib file
    // the xib file defines the ui for the custom table view cell
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    // function is called when the custom table view cell is initialized
    override func awakeFromNib() {
        super.awakeFromNib()
        self.cellView.backgroundColor = UIColor.black
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // function configures the custom table view cell
    public func configure(foodInfoItem: FoodInfoItem) {
        self.iconImage.image = UIImage(named: foodInfoItem.iconName)
        self.labelType.text = foodInfoItem.type
        self.labelValue.text = foodInfoItem.value
    }
    
}
