import UIKit
import Flutter
import Mobile

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    MobileInitApplication(documentsPath)
    
    let controller = self.window.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel.init(name: "nhentai", binaryMessenger: controller as! FlutterBinaryMessenger)
    
    channel.setMethodCallHandler { (call, result) in
        Thread {
            if call.method == "flatInvoke" {
                if let args = call.arguments as? Dictionary<String, Any>,
                   let method = args["method"] as? String,
                   let params = args["params"] as? String{
                    var error: NSError?
                    let data = MobileFlatInvoke(method, params, &error)
                    if error != nil {
                        result(FlutterError(code: "", message: error?.localizedDescription, details: ""))
                    }else{
                        result(data)
                    }
                }else{
                    result(FlutterError(code: "", message: "params error", details: ""))
                }
            }
            else if call.method == "saveFileToImage"{
                if let args = call.arguments as? Dictionary<String, Any>,
                   let path = args["path"] as? String{
                    
                    do {
                        let fileURL: URL = URL(fileURLWithPath: path)
                            let imageData = try Data(contentsOf: fileURL)
                        
                        if let uiImage = UIImage(data: imageData) {
                            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                            result("OK")
                        }else{
                            result(FlutterError(code: "", message: "Error loading image ", details: ""))
                        }
                        
                    } catch {
                            result(FlutterError(code: "", message: "Error loading image : \(error)", details: ""))
                    }
                    
                }else{
                    result(FlutterError(code: "", message: "params error", details: ""))
                }
            }
            else{
                result(FlutterMethodNotImplemented)
            }
        }.start()
    }
    
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
