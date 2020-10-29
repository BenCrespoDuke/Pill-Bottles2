//
//  ViewController.swift
//  Pill Bottles 2
//
//  Created by Benjamin Crespo on 10/6/20.
//

import UIKit
import AVKit
import Metal
import AVFoundation
import Photos
import CoreImage
import FirebaseDatabase
import FirebaseStorage
class ViewController: UIViewController {

    var ref: DatabaseReference!
    let storage = Storage.storage()
    var storageRef: StorageReference!
    var totalFrame = 30
    var durationOfVideo = 30
    var framesTakenPerSecond = 1
    var frameNumber = 0
    var fileNumer = 1
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
    var masterPictureArray: [[CVImageBuffer]] = []
    var currentArray: [CIImage] = []
    var pngArray: [Data] = []
    let sessionQueue = DispatchQueue(label:"sessionQueue",qos: .utility ,attributes: .concurrent)
    let ProcessingQueue = DispatchQueue(label: "processingQueue", qos: .background, attributes: .concurrent)
    var metalDevice = MTLCreateSystemDefaultDevice()
    var textureChache: CVMetalTextureCache?
    let renderer = CIContext.init()
    //let pixelFormat: MetalCameraPixelFormat?
    
    
    
    
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var CameraView: UIView!
    @IBOutlet weak var ProgressBar: UIProgressView!
    @IBOutlet weak var ProgressLabel: UILabel!
    
    
   
    
    
    // MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ProgressBar!.isHidden = true
        ProgressLabel!.isHidden = true
        ProgressBar.progress = 0.0
        ref = Database.database().reference()
        storageRef = storage.reference()
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
        //videoButton
    }
      
    // MARK: CaptureSession
    func BeginCaptureSession() {
        
        camera = AVCaptureDevice.default(for: .video)
       /* guard let metaldevice = metalDevice, CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metaldevice, nil,&textureChache ) == kCVReturnSuccess
        else {
            
        }*/
       
        do {
            let cameraCaptueInput = try AVCaptureDeviceInput(device: camera!)
          
            cameraCaptureOutput2 = AVCaptureVideoDataOutput()
            session.addInput(cameraCaptueInput)
            session.addOutput(cameraCaptureOutput2!)
            connection = AVCaptureConnection(inputPorts: session.inputs[0].ports, output: session.outputs[0])
           
            cameraCaptureOutput2!.setSampleBufferDelegate(self, queue: sessionQueue)
            
           //cameraCaptureOutput2!.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String):NSNumber(value: kCVPixelFormatType_48RGB)]
            cameraCaptureOutput2!.alwaysDiscardsLateVideoFrames = false
            
            
        } catch {
            print(error.localizedDescription)
    
        }
      
        session.beginConfiguration()
        session.commitConfiguration()
        session.startRunning()
       previewLayer = AVCaptureVideoPreviewLayer(session: session)
        //previewLayer?.frame = view.frame
       previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.frame = CameraView.bounds
        CameraView.layer.addSublayer(previewLayer!)
        if previewLayer != nil{
            print("it exists")
        }
        //print(session.inputs[0].ports)
        //print("all done")
    }
        
    func startRecording() {
    
    }
    
    
// MARK: Processing Method
    func stopRecording() {
        
        var i = currentArray.count-1
        var percentAmount = 1.0/((Float)(currentArray.count))
        DispatchQueue.main.async { [self] in
            ProgressLabel.text = "Converting Photos ...."
        }
        
        while i >= 0 {
            autoreleasepool{
                if let data = self.CIImageToPNG(image: currentArray[i]){
                    pngArray.append(data)
                    print("added to array")
                }
            }
            print("data removed")
            currentArray.remove(at: i)
            i = i-1
            DispatchQueue.main.async { [self] in
                ProgressBar.setProgress(ProgressBar.progress + percentAmount, animated: true)
            }
        }
        DispatchQueue.main.async { [self] in
            ProgressLabel.text = "Sending Images to WizeView ...."
            ProgressBar.setProgress(0.0, animated: false)
        }
        percentAmount = 1.0/((Float)(pngArray.count))
        if let reff = storageRef{
            
            for item in pngArray{
                
                let currentReff = reff.child("File \(fileNumer)")
                let uploadTask = currentReff.putData(item, metadata: nil) {(metadata,error) in
                    guard let metaData = metadata else{
                        print(error?.localizedDescription)
                        return
                    }
                                        
                    
                }
              fileNumer = fileNumer+1
                DispatchQueue.main.async { [self] in
                    ProgressBar.setProgress(ProgressBar.progress+percentAmount, animated: true)
                }
            }
            
        }
        
        var num = pngArray.count-1
        
        while num >= 0 {
            pngArray.remove(at: num)
            num = num-1
        }
        DispatchQueue.main.async { [self] in
            ProgressBar.isHidden = true
            ProgressBar.setProgress(0, animated: false)
            ProgressLabel.text = "Done!"
            sleep(2000)
            ProgressLabel.isHidden = true
            videoButton.setTitle("start Video", for: .normal)
            videoButton.isEnabled = true
            CameraView.isHidden = false
            
        }
    }
    
    
    
    
    func CIImageToPNGData(image: CIImage) -> Data? {
        if let cSpace = CGColorSpace(name: CGColorSpace.sRGB){
        let data = renderer.pngRepresentation(of: image, format: CIFormat(rawValue: CIFormat.RawValue(kCVPixelFormatType_30RGB)), colorSpace:cSpace , options: [:])
            return data
        }
        return nil
    }
    
    func CIImageToPNG(image:CIImage) -> Data? {
        var uImage:UIImage?
        uImage = UIImage(ciImage: image)
        let data = uImage!.pngData()
    
        uImage = nil
        return data
    }
        
        
        func getFileDirectoryPath() -> URL? {
            let path = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)
            return path.first
        }
        
        func savePNGtoFiles(Data: Data){
            let path = getFileDirectoryPath()?.appendingPathComponent("test.png")
            if let Path = path{
            try? Data.write(to: Path)
            }
        }
       
    
    @IBAction func videoButton(_ sender: Any) {
        if isRecording == true{
            isRecording = false
            DispatchQueue.main.async { [self] in
                videoButton.setTitle("Processing ...", for: .normal)
                CameraView.isHidden = true
                videoButton.backgroundColor = UIColor.systemGreen
                ProgressLabel.isHidden = false
                ProgressBar.isHidden = false
            }
            print("stop")
            self.stopRecording()
        }
        else{
            DispatchQueue.main.async { [self] in
                videoButton.setTitle("Recording ...", for: .normal)
                videoButton.backgroundColor = UIColor.red
                videoButton.isEnabled = false
            }
            isRecording = true
            
            
        }
    }
 
    func CMSampleBufferToCIImage(buffer: CMSampleBuffer){
       if let pixleBuffer = CMSampleBufferGetImageBuffer(buffer){
            let ciImage = CIImage(cvPixelBuffer: pixleBuffer)
        currentArray.insert(ciImage, at: 0)
        }
        
        
    }
    
    override func didReceiveMemoryWarning(){
        print("memoryWarning")
        print(pngArray.count)
    }
    
}
// MARK: sampleBufferDelegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
       // print("called")
        
        if isRecording {
          
           print(frameNumber)
           frameNumber=frameNumber+1
            if frameNumber%(30/framesTakenPerSecond) == 0{
            ProcessingQueue.async {
                self.CMSampleBufferToCIImage(buffer: sampleBuffer)
                
                if self.frameNumber == self.totalFrame*(self.durationOfVideo*self.framesTakenPerSecond){
//                    self.isRecording = false
                    self.videoButton(self)
                }
            }
            }
            
            
                
            
        }
        
       
    }
       
        
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print(kCMSampleBufferAttachmentKey_DroppedFrameReason)
        session.stopRunning()
       session.startRunning()
}

}
