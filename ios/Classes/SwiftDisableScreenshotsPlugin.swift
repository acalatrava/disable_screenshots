import Flutter
import UIKit

public class SwiftDisableScreenshotsPlugin: NSObject {
  var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SwiftDisableScreenshotsPlugin()
    let methodChannel = FlutterMethodChannel(
        name: "com.devlxx.DisableScreenshots/disableScreenshots", 
        binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    
    let channel = FlutterEventChannel(
        name: "com.devlxx.DisableScreenshots/observer", 
        binaryMessenger: registrar.messenger()
    )
    channel.setStreamHandler(instance)
  }
    
  @objc func callScreenshots() {
    eventSink!("")
  }

  @objc func callCaptureChanged() {
    if UIScreen.main.isCaptured {
        eventSink!("")
    }
  }
}

extension UIWindow {
    struct Holder {
        static var _mySecureTextField:UITextField = UITextField()
    }
    var _mySecureTextField:UITextField {
        get {
            return Holder._mySecureTextField
        }
        set(newValue) {
            Holder._mySecureTextField = newValue
        }
    }

  func makeSecure() {
      let field = _mySecureTextField
      if (field.tag == 31337) {
          field.isSecureTextEntry = true
          return;
      }
      field.isSecureTextEntry = true
      field.tag = 31337;
      self.addSubview(field)
      field.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
      field.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
      self.layer.superlayer?.addSublayer(field.layer)
      field.layer.sublayers?.first?.addSublayer(self.layer)
    }
    
    func makeInsecure() {
        NSLog("makeInsecure %@", self.viewWithTag(31337) ?? "null");
        let field = _mySecureTextField
        field.isSecureTextEntry = false
      }
}

extension SwiftDisableScreenshotsPlugin: FlutterPlugin {
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "disableScreenshots":
                if let arg = call.arguments as? Dictionary<String, Any>, let disable = arg["disable"] as? Bool {
                    if disable {
                        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.makeSecure();
                    } else {
                        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.makeInsecure();
                    }
                } else {
                    print("【SwiftDisableScreenshotsPlugin】disableScreenshots 收到错误参数")
                }

            case "checkIfRecording":
                if UIScreen.main.isCaptured {
                    eventSink!("")
                }

                
            default:
                result(FlutterMethodNotImplemented)
            
        }
    }
}

extension SwiftDisableScreenshotsPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(callScreenshots),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(callCaptureChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil)
        
        return nil
    }
       
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
}
