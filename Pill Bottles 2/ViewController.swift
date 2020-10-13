//
//  ViewController.swift
//  Pill Bottles 2
//
//  Created by Benjamin Crespo on 10/6/20.
//

import UIKit
import AVFoundation
import Photos
class ViewController: UIViewController {

    var frameNumber = 0
    let session = AVCaptureSession()
    var camera: AVCaptureDevice?
    var connection: AVCaptureConnection?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraCaptureOutput: AVCaptureMovieFileOutput?
    var cameraCaptureOutput2: AVCaptureVideoDataOutput?
    var recordingQueue: DispatchQueue?
    var isRecording = false
    let ourURL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
    var videoFile:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //print(ourURL.absoluteURL)
        videoFile = URL(fileURLWithPath: "file", relativeTo: ourURL)
        switch PHPhotoLibrary.authorizationStatus(){
        case .authorized:
            break
        case .notDetermined:
        PHPhotoLibrary.requestAuthorization({ answer in
                                             
                                             })
            break
        default:
            break
        }
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            BeginCaptureSession()
            break
        case .denied:
            break
        default:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {answer in
                if answer == true{
                    self.BeginCaptureSession()
                                          
                                          }
                else{
                    return
                }})
        
        }
    }
        
    
    func BeginCaptureSession() {
        
        camera = AVCaptureDevice.default(for: .video)
        
        do {
            let cameraCaptueInput = try AVCaptureDeviceInput(device: camera!)
            cameraCaptureOutput = AVCaptureMovieFileOutput()
            cameraCaptureOutput2 = AVCaptureVideoDataOutput()
            session.addInput(cameraCaptueInput)
            //session.addOutput(cameraCaptureOutput!)
            session.addOutput(cameraCaptureOutput2!)
            connection = AVCaptureConnection(inputPorts: session.inputs[0].ports, output: session.outputs[0])
            let sessionQueue = DispatchQueue(label:"sessionQueue")
            cameraCaptureOutput2!.setSampleBufferDelegate(self, queue: sessionQueue)
            
            
        } catch {
            print(error.localizedDescription)
    
        }
      
        session.beginConfiguration()
        session.commitConfiguration()
        session.startRunning()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.frame = view.bounds
        if previewLayer != nil{
            print("it exists")
        }
        //print(session.inputs[0].ports)
        //print("all done")
    }
        
    
    @IBAction func videoButton(_ sender: Any) {
        if isRecording == true{
            isRecording = false
        }
        else{
            isRecording = true
        }
    }
}

/*extension ViewController: AVCaptureFileOutputRecordingDelegate{
 
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("recording begain")
      /*DispatchQueue.main.async {
            
        }*/
        
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("saving")
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { saved, error in
            if let Error = error{
                print(Error.localizedDescription)
            }
            
        }
    }
    
    
}*/
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isRecording {
            print("capture")
           print(frameNumber)
            frameNumber=frameNumber+1
        }
             }
}

