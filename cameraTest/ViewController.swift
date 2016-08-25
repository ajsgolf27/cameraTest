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
    
    //MARK: variables
    
    var dataString = NSString()
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    //MARK: outlets
    
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var emotionData: UITextView!
    
    //MARK: actions
    
    @IBAction func didPressTakePhoto(sender: UIButton) {
       
         if ((self.captureSession?.sessionPreset) != nil) {

        let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo)
                stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                
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

    
    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set up capture session once view loads
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        captureSession?.sessionPreset = AVCaptureSessionPreset1280x720
        
        //find the front facing camera
        
        guard let frontCam = AVCaptureDevice.devices().filter({ $0.position == .Front })
            .first as? AVCaptureDevice else {
                fatalError("No front facing camera found")
        }
        let input = try! AVCaptureDeviceInput(device: frontCam)
        
        if  captureSession!.canAddInput(input) {
            print("input added")
            captureSession!.addInput(input)

        }
        
        //run session
        captureSession?.startRunning()
        
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        captureSession!.addOutput(stillImageOutput)

        print("leaving viewdidload")

            }

    // uploading the taken picture to the api
    func upload_request(imageData: NSData)
    {
        //start nsurl request, the values are from the website
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
                //when no data is returned app crashes ie. cannot find a face
                self.dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                // print data to debugger
                print(self.dataString)
                
                
                // parse json using built in functionaity
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
                    
                    
                    // since the upload is in a seperate thread access the main thread to set the returned data
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

