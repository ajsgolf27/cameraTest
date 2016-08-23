//
//  ViewController.swift
//  cameraTest
//
//  Created by Andrew Stallone on 7/21/16.
//  Copyright © 2016 Andrew Stallone. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {
    
    var dataString = NSString()
    
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var emotionData: UITextView!
    
    @IBAction func didPressTakePhoto(sender: UIButton) {
       
         if ((self.captureSession?.sessionPreset) != nil) {

            print("button pressed")
        let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo)
                stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                print("inside completionhandler")
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let intent = CGColorRenderingIntent.RenderingIntentDefault
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, intent)
                    
                    let image = UIImage(CGImage: cgImageRef!, scale: 0.9, orientation: UIImageOrientation.Right)
                    
                    self.capturedImage.image = image
                    print("picture taken ")
                    self.upload_request(imageData)
                    
                    
                    sender.hidden = true
                    
            })
    }else{
        print("session not running")
        }

    }

    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        captureSession?.sessionPreset = AVCaptureSessionPreset1280x720
        
        
        print("inside view did load")
        //var backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        guard let frontCam = AVCaptureDevice.devices().filter({ $0.position == .Front })
            .first as? AVCaptureDevice else {
                fatalError("No front facing camera found")
        }

        
        
        let input = try! AVCaptureDeviceInput(device: frontCam)
        
        if  captureSession!.canAddInput(input) {
            print("input added")
            captureSession!.addInput(input)
            

        }
        
        
        captureSession?.startRunning()
        
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        captureSession!.addOutput(stillImageOutput)

        print("leaving viewdidload")
       
        
            }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func upload_request(imageData: NSData)
    {
        print("inside upload request")
        let url:NSURL = NSURL(string: "https://api.projectoxford.ai/emotion/v1.0/recognize")!
        let session = NSURLSession.sharedSession()
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("69072359eb954fc798bc543833875810", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        
        
        print("uploaded started processing")
        
        
        var emotions: [Float] = []
        
        
        let task = session.uploadTaskWithRequest(request, fromData: imageData, completionHandler:
            {(data,response,error) in
                
                guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                    print("error")
                    return
                }
                print("data returned")
                //uncomment to get all data returned even error codes
                self.dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                print(self.dataString)
                
                
                
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers)
                    
                    
                    let info : NSArray =  (json.valueForKey("scores") as? NSArray)!
                    
                    let anger: Float? = info[0].valueForKey("anger") as? Float
                    let contempt: Float? = info[0].valueForKey("contempt") as? Float
                    let disgust: Float? = info[0].valueForKey("disgust") as? Float
                    let fear: Float? = info[0].valueForKey("fear") as? Float
                    let happiness: Float? = info[0].valueForKey("happiness") as? Float
                    let neutral: Float? = info[0].valueForKey("neutral") as? Float
                    let sadness: Float? = info[0].valueForKey("sadness") as? Float
                    let surprise: Float? = info[0].valueForKey("surprise") as? Float
                    
                    emotions.append(anger!)
                    emotions.append(contempt!)
                    emotions.append(disgust!)
                    emotions.append(fear!)
                    emotions.append(happiness!)
                    emotions.append(neutral!)
                    emotions.append(sadness!)
                    emotions.append(surprise!)
                    
                    
                    
                    //print(emotions)
                    
                    let dictionary = [
                        "anger" : [emotions[0]],
                        "contempt" : [emotions[1]],
                        "disgust" : [emotions[2]],
                        "fear" : [emotions[3]],
                        "happiness" : [emotions[4]],
                        "neutral" : [emotions[5]],
                        "sadness" : [emotions[6]],
                        "surprise" : [emotions[7]]
                    ]
                    
                    
                    //for (key,value) in dictionary {
                    
                    //}
                    //print(dictionary)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.emotionData.text = self.dataString as String
                    }
                    
                    
                    
                } catch let error as NSError {
                    print("Failed to load: \(error.localizedDescription)")
                }
            }
        );
        
        
        
        
        task.resume()
        
        
    }

        
        
        
    

}

