import UIKit

struct Constants {
    
    // storyboard
    static let SYB_Name = "Storyboard"
    
    // view controllers
    static let SID_VC_Instruction = "SID_VC_Instruction"
    static let SID_VC_Camera = "SID_VC_Camera"
    static let SID_VC_Processing = "SID_VC_Processing"
    static let SID_VC_Result = "SID_VC_Result"
    static let SID_VC_Measurement = "SID_VC_Measurement"
    
    // server api endpoint urls
    static let SRV_API_Alive = "http://192.168.178.81:8000/alive"
    static let SRV_API_UploadImage = "http://192.168.178.81:8000/upload-image"
    static let SRV_API_AnalyseObject = "http://192.168.178.81:8000/analyse-object"
    static let SRV_API_Get3DModel = "http://192.168.178.81:8000/get-3d-model"
    
    // file names
    static let FILE_OBJ_Model = "baked_mesh.obj"
    
}
