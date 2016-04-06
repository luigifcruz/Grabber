//
//  ModalViewController.swift
//  Grabber
//
//  Created by Luigi Freitas on 10/24/15.
//  Copyright © 2015 Luigi Freitas. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Alamofire
import AVFoundation
import MediaPlayer
import Photos
import AssetsLibrary


class ModalViewController: UIViewController {

    @IBOutlet weak var Label: UILabel!
    @IBOutlet weak var ModalView: UIVisualEffectView!
    @IBOutlet weak var dots: UIImageView!
    @IBOutlet weak var check: UIImageView!
    @IBOutlet weak var Percentage: UILabel!
    
    @IBOutlet weak var Progress: ProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ModalView.layer.cornerRadius = 20
        ModalView.clipsToBounds = true
        
        let item : NSExtensionItem = self.extensionContext!.inputItems[0] as! NSExtensionItem
        let itemProvider : NSItemProvider = item.attachments![0] as! NSItemProvider
        
        if (itemProvider.hasItemConformingToTypeIdentifier("public.url")) {
            itemProvider.loadItemForTypeIdentifier("public.url", options: nil, completionHandler: { (urlItem, error) in
                self.GrabVideo(String(urlItem!))
            })
        }
        
        if !(PHPhotoLibrary.authorizationStatus() == .Authorized) {
            PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
                switch status{
                case .Authorized:
                    dispatch_async(dispatch_get_main_queue(), {
                        print("Authorized")
                    })
                    break
                case .Denied:
                    dispatch_async(dispatch_get_main_queue(), {
                        print("Denied")
                    })
                    break
                default:
                    dispatch_async(dispatch_get_main_queue(), {
                        print("Default")
                    })
                    break
                }
            })
        }
        
        check.alpha = 0
        Percentage.alpha = 0
    }
    
    func rewind(SayToUser: String) {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.Label.text = SayToUser
            UIView.animateWithDuration(0.3, delay: 2.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.ModalView.alpha = 0
                }, completion: { (value: Bool) in
                    self.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
            })
        })
    }
    
    func GrabVideo(URL: String) {
        Alamofire.request(.POST, "https://app.luigifreitas.me/grabber/GrabVideo", parameters: ["URL": URL])
            .responseJSON { response in
                if let JSON = response.result.value {
                    let confirmation:Bool = JSON["confirmation"] as! Bool
                    
                    if(confirmation) {
                        print(JSON)
                        let VideoURL:String = JSON["url"] as! String
                        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                            self.dots.alpha = 0
                            self.Percentage.alpha = 1
                            }, completion: { (value: Bool) in
                                self.Label.text = "Downloading..."
                        })
                        print("Downloading")
                        
                        var url = ""
                        
                        let destination: (NSURL, NSHTTPURLResponse) -> (NSURL) = {
                            (temporaryURL, response) in
                            if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
                                let path = directoryURL.URLByAppendingPathComponent(response.suggestedFilename!)
                                url = String(path)
                                return path
                            }
                            return temporaryURL
                        }
                        
                        Alamofire.download(.GET, VideoURL, destination: destination)
                            .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    let progress = Float(totalBytesRead)/Float(totalBytesExpectedToRead)
                                    self.Percentage.text = String(floor(progress*100)) + "%"
                                    self.Progress.animateProgressViewToProgress(progress)
                                    self.Progress.updateProgressViewWith(Float(totalBytesRead), totalFileSize: Float(totalBytesExpectedToRead))
                                }
                            }
                            .response { _, response, data, error in
                                if let error = error {
                                    print("Failed with error: \(error)")
                                } else {
                                    
                                    
                                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                                        _ = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(NSURL(string: url)!)
                                        }, completionHandler: { success, error in
                                            if error == nil {
                                                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                                    do {
                                                        try NSFileManager.defaultManager().removeItemAtURL(NSURL(string: url)!)
                                                        print("Old video have been removed!")
                                                    } catch {
                                                        print("Nope, nothing was removed.")
                                                    }
                                                    
                                                    UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                                                        self.check.alpha = 1
                                                        self.Percentage.alpha = 0
                                                        self.Label.text = "Wonderfully Done!"
                                                        }, completion: nil)
                                                    
                                                    UIView.animateWithDuration(0.3, delay: 2.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                                                        self.ModalView.alpha = 0
                                                        }, completion: { (value: Bool) in
                                                            self.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                                                    })
                                                })
                                                
                                            } else {
                                                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                                    self.Label.text = "Cannot save 😪"
                                                    do {
                                                        try NSFileManager.defaultManager().removeItemAtURL(NSURL(string: url)!)
                                                        print("Old video have been removed!")
                                                    } catch {
                                                        print("Nope, nothing was removed.")
                                                    }
                                                    UIView.animateWithDuration(0.3, delay: 2.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                                                        self.ModalView.alpha = 0
                                                        }, completion: { (value: Bool) in
                                                            self.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                                                    })
                                                })
                                            }
                                    })
                                }
                        }
                        
                       
                    } else {
                        let error:String = JSON["error"] as! String
                        
                        switch(error) {
                            case "invalid_url":
                                self.rewind("Invalid URL!")
                                break;
                            
                            case "invalid_tweet":
                                self.rewind("Invalid Tweet!")
                                break;
                            
                            case "server_error":
                                self.rewind("Server is Dead 🔥")
                                break;
                            
                            default:
                                self.rewind("Some unknow error 👽")
                                break;
                        }
                        
                    }
                }
        }
    }
    
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

