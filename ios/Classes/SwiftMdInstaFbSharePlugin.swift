import Flutter
import UIKit
import FBSDKCoreKit
import Social

let FBMarketURL = URL(string: "itms-apps://itunes.apple.com/us/app/apple-store/id284882215");
let INSTAMarketURL = URL(string: "itms-apps://itunes.apple.com/us/app/apple-store/id389801252");

public class SwiftMdInstaFbSharePlugin: NSObject, FlutterPlugin, SharingDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "md_insta_fb_share", binaryMessenger: registrar.messenger())
        let instance = SwiftMdInstaFbSharePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Sharing to instagram stories
        if (call.method == "share_insta_story") {
            let args = (call.arguments as! NSDictionary)
            let urlScheme = URL(string: "instagram-stories://share")!
            // checking if the app can be opened
            if (UIApplication.shared.canOpenURL(urlScheme)) {
                // getting image from flutter using this argument
                let backgroundImagePath = args["backgroundImage"] as! String;
                // converting to swift Image format
                var backgroundImage: UIImage? = nil;
                // Get the file manager to read our image
                let fileManager = FileManager.default;
                
                // check if the file is present on device
                let isBackgroundImageExist = fileManager.fileExists(atPath: backgroundImagePath);
                if (isBackgroundImageExist) {
                    backgroundImage = UIImage(contentsOfFile: backgroundImagePath)!;
                } else {
                    // send imageNotFoundError
                    result(2);
                    return;
                }
                // configure instagram story background image as current image
                let pasteboardItems = [
                    "com.instagram.sharedSticker.backgroundImage" : (backgroundImage ?? nil) as Any
                ] as [String : Any];
                // checking if current iOS version is > 10
                if #available(iOS 10.0, *) {
                    // set expiry time as 5 mins after that the background image will not be available
                    let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate : NSDate().addingTimeInterval(60 * 5)]
                    UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
                    // opening instgram story
                    UIApplication.shared.open(urlScheme, options: [:], completionHandler: { (success) in
                        if (success) {
                            // send result as success
                            result(0);
                        } else {
                            // send appCanNotBeOpenedError
                            result(1);
                        }
                    })
                } else {
                    UIPasteboard.general.items = [pasteboardItems]
                    UIApplication.shared.openURL(urlScheme)
                    result(0);
                }
            } else {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(INSTAMarketURL!, options: [:], completionHandler: { (success) in })
                } else {
                    UIApplication.shared.openURL(INSTAMarketURL!)
                }
                // send appCanNotBeOpenedError
                result(1);
            }
        } else if (call.method == "share_insta_feed") {
            let args = (call.arguments as! NSDictionary);
            let urlScheme = URL(string: "instagram-stories://app")!
            if (UIApplication.shared.canOpenURL(urlScheme)) {
                let backgroundImagePath = args["backgroundImage"] as! String;
                
                let fileManager = FileManager.default;
                
                let isBackgroundImageExist = fileManager.fileExists(atPath: backgroundImagePath);
                if (isBackgroundImageExist) {
                    postImageToInstagram(UIImage(contentsOfFile: backgroundImagePath)!, completion: result);
                } else {
                    result(2);
                }
            } else {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(INSTAMarketURL!, options: [:], completionHandler: { (success) in })
                } else {
                    UIApplication.shared.openURL(INSTAMarketURL!)
                }
                result(1);
            }
        } else if (call.method == "share_FB_story") {
            let args = (call.arguments as! NSDictionary)
            let urlScheme = URL(string: "facebook-stories://share")!
            if (UIApplication.shared.canOpenURL(urlScheme)) {
                let backgroundImagePath = args["backgroundImage"] as! String;
                
                var backgroundImage: UIImage? = nil;
                let fileManager = FileManager.default;
                
                
                let isBackgroundImageExist = fileManager.fileExists(atPath: backgroundImagePath);
                if (isBackgroundImageExist) {
                    backgroundImage = UIImage(contentsOfFile: backgroundImagePath)!;
                } else {
                    return result(2);
                }
                
                let facebookAppID = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String;
                
                if (facebookAppID == nil) {
                    print("FacebookAppID not specified in info.plist");
                    result(4);
                    return;
                }
                
                let pasteboardItems = [
                    "com.facebook.sharedSticker.backgroundImage" : (backgroundImage ?? nil) as Any,
                    "com.facebook.sharedSticker.appID": facebookAppID!,
                ] as [String : Any];
                
                if #available(iOS 10.0, *) {
                    let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate : NSDate().addingTimeInterval(60 * 5)]
                    UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
                    UIApplication.shared.open(urlScheme, options: [:], completionHandler: { (success) in
                        if (success) {
                            result(0);
                        } else {
                            result(1);
                        }
                    })
                } else {
                    UIPasteboard.general.items = [pasteboardItems]
                    UIApplication.shared.openURL(urlScheme)
                    result(0);
                }
            } else {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(FBMarketURL!, options: [:], completionHandler: { (success) in })
                } else {
                    UIApplication.shared.openURL(FBMarketURL!)
                }
                result(1);
            }
        } else if (call.method == "share_FB_feed") {
            let args = (call.arguments as! NSDictionary)
            let backgroundImagePath = args["backgroundImage"] as! String;
            
            let urlScheme = URL(string: "facebook-stories://app")!
            if (!UIApplication.shared.canOpenURL(urlScheme)) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(FBMarketURL!, options: [:], completionHandler: { (success) in })
                } else {
                    UIApplication.shared.openURL(FBMarketURL!)
                }
                return result(1);
            }
            
            var backgroundImage: UIImage? = nil;
            let fileManager = FileManager.default;
            
            let isBackgroundImageExist = fileManager.fileExists(atPath: backgroundImagePath);
            if (isBackgroundImageExist) {
                backgroundImage = UIImage(contentsOfFile: backgroundImagePath)!;
            } else {
                return result(1);
            }
            
            let photo = SharePhoto(
                image: backgroundImage!,
                userGenerated: true
            );
            let content = SharePhotoContent();
            content.photos = [photo];
            
            let viewController = UIApplication.shared.delegate?.window??.rootViewController;
            ShareDialog(fromViewController: viewController, content: content, delegate: self).show()
            result(0);
        }
        else if(call.method == "share_twitter_feed"){
            let args = (call.arguments as! NSDictionary)
            let backgroundImagePath = args["backgroundImage"] as! String;
            let captionText = args["captionText"] as! String;
            
            let urlScheme = URL(string: "twitter://")!
            if !UIApplication.shared.canOpenURL(urlScheme) {
                 result(1)
                 return
            }
            var backgroundImage: UIImage? = nil;
            let fileManager = FileManager.default;
            
            let isBackgroundImageExist = fileManager.fileExists(atPath: backgroundImagePath);
            if (isBackgroundImageExist) {
                backgroundImage = UIImage(contentsOfFile: backgroundImagePath)!;
            } else {
                return result(1);
            }
            // SLServiceTypeTwitter is deprecated but still works somehow
            let sheet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            // Add image and caption to sheet
            sheet?.add(backgroundImage)
            sheet?.setInitialText(captionText)
            // get the rootViewController and preset the sheet
            let viewController = UIApplication.shared.keyWindow?.rootViewController
            viewController?.present(sheet!, animated: true)
            result(0)
    
        }
        else if(call.method == "check_twitter"){
            let urlScheme = URL(string: "twitter://")!
            result(UIApplication.shared.canOpenURL(urlScheme));
        }
        else if (call.method == "check_insta") {
            let urlScheme = URL(string: "instagram-stories://app")!
            result(UIApplication.shared.canOpenURL(urlScheme));
        } else if (call.method == "check_FB") {
            let urlScheme = URL(string: "facebook-stories://app")!
            result(UIApplication.shared.canOpenURL(urlScheme));
        } else {
            result("Not implemented");
        }
    }
    
    func postImageToInstagram(_ image: UIImage, completion: @escaping FlutterResult) {
        // check if instagram can be opened
        if UIApplication.shared.canOpenURL(URL(string: "instagram://app")!) {
            // request for photos access
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // save image to photos
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    completion(0);
                } else {
                    // return galleryAccessError
                    completion(3);
                }
            }
        } else {
            // return appCanNotBeOpenedError
            completion(1);
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print(error)
            return
        }
        // fetch the latest photo from photos
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        if let lastAsset = fetchResult.firstObject {
            let localIdentifier = lastAsset.localIdentifier
            // get the local identifier of latest image from photos
            // open istagram feed share deep link
            let u = "instagram://library?LocalIdentifier=" + localIdentifier
            let url = NSURL(string: u)!
            if UIApplication.shared.canOpenURL(url as URL) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: u)!, options: [:], completionHandler: nil);
                } else {
                    UIApplication.shared.openURL(URL(string: u)!);
                }
                // result(0)
            } else {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(INSTAMarketURL!, options: [:], completionHandler: { (success) in })
                } else {
                    UIApplication.shared.openURL(INSTAMarketURL!)
                }
                // result(1)
            }

        }
    }
    
    //Facebook delegate methods
    public func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        print("Share: Success")
        
    }
    
    public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        print("Share: Fail")
        
    }
    
    public func sharerDidCancel(_ sharer: Sharing) {
        print("Share: Cancel")
    }
}
