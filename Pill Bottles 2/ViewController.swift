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

  
    let session = AVCaptureSession()
    var camera: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraCaptureOutput: AVCaptureMovieFileOutput?
    var cameraCaptureOutput2: AVCaptureVideoDataOutput?
    var videoFile = URL(string: "file")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
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
            session.addOutput(cameraCaptureOutput!)
            session.addOutput(cameraCaptureOutput2!)
            
            
            
        } catch {
            print(error.localizedDescription)
    
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.frame = view.bounds
    }
        func startRecording(){
            if let output = cameraCaptureOutput{
                output.startRecording(to: videoFile!, recordingDelegate: self)
            }
            }
    func stopRecording() {
        if let output = cameraCaptureOutput{
            output.stopRecording()
        }
    }
    
    @IBAction func videoButton(_ sender: Any) {
        if let output = cameraCaptureOutput {
            if output.isRecording == true {
                self.stopRecording()
            }
            else{
                self.startRecording()
            }
        }
    }
}


extension ViewController: AVCaptureFileOutputRecordingDelegate{
 
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
      /* DispatchQueue.main.async {
            
        }*/
        
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { saved, error in
            if let Error = error{
                print(Error.localizedDescription)
            }
            
        }
    }
    
    
}
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
         
    }
}

