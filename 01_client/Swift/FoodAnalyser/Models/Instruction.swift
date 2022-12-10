import UIKit

public class Instruction {
    var Id = Int()
    var Title = String()
    var Description = String()
    var ImageName = String()
    var Image: UIImage? = nil
    
    init(
        id: Int,
        title: String,
        description: String,
        imageName: String
    ) {
        self.Id = id
        self.Title = title
        self.Description = description
        self.ImageName = imageName
        
        if (!imageName.isEmpty) {
            if let targetImage = UIImage(named: imageName) {
                self.Image = targetImage
            }
        }
    }
}
