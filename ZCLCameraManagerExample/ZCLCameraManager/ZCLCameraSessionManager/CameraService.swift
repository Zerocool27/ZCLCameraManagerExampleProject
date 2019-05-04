//
//  CameraService.swift
//  WhatsAround
//
//  Created by Hasan H. Topcu on 01/12/2016.
//  Copyright © 2016 turquaz. All rights reserved.
//

import Foundation
import AVFoundation

class CameraService: NSObject, AVCaptureFileOutputRecordingDelegate {
    /** The delegate to serve captured image */
    weak var delegate: CameraCaptureProtocol? = nil
    var videoFileOutput: AVCaptureMovieFileOutput? = nil
    var audioInput: AVCaptureDeviceInput? = nil
    var isTorchOpened:Bool = false
    let mBusinessManager = BusinessManager()
    
    var frame: CGRect = CGRect()
    
    init(frame: CGRect) {
        self.frame = frame
    }
    
    /** Getter for session output */
    private lazy var sessionOutput: AVCaptureStillImageOutput = {
        let output = AVCaptureStillImageOutput()
        output.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        
        return output
    }()
    
    /** Getter for session */
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        return session
    }()
    
    func getSession() -> AVCaptureSession {
        return captureSession
    }
    
    /** Getter for Preview Player */
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.captureSession)
        //preview.videoGravity = AVLayerVideoGravity.resizeAspectFill
        preview.frame = self.frame
        preview.videoGravity = .resize
        //preview.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        
        return preview
    }()
    
    func setupCameraSession(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let captureDevice = cameraWithPosition(position: position)
        
        if let captureDevice = captureDevice {
            do {
                let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
                
                captureSession.beginConfiguration()
                
                if (captureSession.canAddInput(deviceInput) == true) {
                    captureSession.addInput(deviceInput)
                }
                setupBestPresetAvailable()
                
                guard let audioDevice: AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio) else {
                    return nil
                }
                
                do {
                    self.audioInput = try AVCaptureDeviceInput(device: audioDevice)
                    
                    let exist = self.captureSession.inputs.contains(where: { (device) -> Bool in
                        return (device as! AVCaptureDeviceInput) == audioInput
                    })
                    
                    print(">>>> Input device count: \(captureSession.inputs.count)")
                    if exist == false {
                        print(">>>> Audio device will be added into capture session")
                        self.captureSession.addInput(audioInput!)
                    } else {
                        print(">>>> Audio device is already exist")
                    }
                    
                } catch {
                    print("caught: \(error)")
                    print("Unable to add audio device to the recording.")
                }
                
                if (captureSession.canAddOutput(sessionOutput) == true) {
                    captureSession.addOutput(sessionOutput)
                }
                
                captureSession.commitConfiguration()
            } catch let error as NSError {
                NSLog("\(error), \(error.localizedDescription)")
            }
        }
        
        return captureDevice
    }
    
    func setupBestPresetAvailable(){
        if captureSession.canSetSessionPreset(.hd4K3840x2160){
            captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
        }else if captureSession.canSetSessionPreset(.hd1920x1080){
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        }else {
            captureSession.sessionPreset = AVCaptureSession.Preset.high
        }
    }
    /*
    // Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        
        // Find the camera
        for device in devices {
            let device = device 
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    */
    
    // Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice?
    {
        let deviceDescoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        
        for device in deviceDescoverySession.devices {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    func takePhoto(device: AVCaptureDevice, deviceOrientation: UIDeviceOrientation?) {
        if let videoConnection = sessionOutput.connection(with: AVMediaType.video) {
            sessionOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { buffer, error in
                if error == nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer!)
                    var image = UIImage(data: imageData!)
                    
                    if let savePhotosIsEnabled = self.mBusinessManager.getUserSettingsPreferencesValue(for: .SAVE_PHOTOS) {
                        if savePhotosIsEnabled == "true" {
                            UIImageWriteToSavedPhotosAlbum(image!, self, nil, nil)
                        }
                    }
                    
                    if let dOrientation = deviceOrientation {
                        if device.position == AVCaptureDevice.Position.back {
                            if (dOrientation == .landscapeLeft) {
                                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.up)
                            } else if (dOrientation == .landscapeRight) {
                                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.down)
                            } else if (dOrientation == .portrait) {
                                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.right)
                            } else if (dOrientation == .portraitUpsideDown) {
                                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.left)
                            }
                        } else if device.position == AVCaptureDevice.Position.front {
                            if (dOrientation == .landscapeLeft) {
                                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.downMirrored)
                            } else if (dOrientation == .landscapeRight) {
                                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.upMirrored)
                            } else if (dOrientation == .portrait) {
                                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.leftMirrored)
                            } else if (dOrientation == .portraitUpsideDown) {
                                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.rightMirrored)
                            }
                        }
                    }
                    
                    let filename = "image_\(UUID().uuidString).jpeg";
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let filePath = documentsURL.appendingPathComponent(filename, isDirectory: false)
                    
                    if image != nil {
                        if let data = UIImageJPEGRepresentation(image!, 1.0) {
                            try? data.write(to: filePath)
                        }
                    }
                    
                    self.delegate?.onCapturedImageReady(imageUrl: filePath, image: image)
                } else {
                     print(error.debugDescription)
                }
                
            })
        }
    }
    
    func startRecordingVideo() throws {
        // Indicate that some changes will be made to the session
        //self.captureSession.beginConfiguration()
        
        //Commit all the configuration changes at once
        //captureSession.commitConfiguration()
        self.videoFileOutput = AVCaptureMovieFileOutput()
        if let videoFileOutput = videoFileOutput {
            
            let fileName = "\(UUID().uuidString)_recorded.mov";
            self.changeTorchMode(value: self.isTorchOpened)
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filePath = documentsURL.appendingPathComponent(fileName, isDirectory: false)
            let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
            
            let orientation = returnedOrientation()
            if self.captureSession.canAddOutput(videoFileOutput) {
                self.captureSession.beginConfiguration()
                self.captureSession.addOutput(videoFileOutput)
                self.captureSession.sessionPreset = .high
                if let connection = videoFileOutput.connection(with: AVMediaType.video){
                    connection.videoOrientation = orientation
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                    self.captureSession.commitConfiguration()
                    videoFileOutput.startRecording(to: filePath, recordingDelegate: recordingDelegate!)
                } else {
                    videoFileOutput.stopRecording()
                    throw CameraError.notStartedToRecord
                }
            }
        }
    }
    
    func stopRecordingVideo() {
        if (videoFileOutput != nil) {
            videoFileOutput!.stopRecording()
            self.captureSession.beginConfiguration()
            self.captureSession.removeOutput(videoFileOutput!)
            self.captureSession.commitConfiguration()
        }
    }
    
    func returnedOrientation() -> AVCaptureVideoOrientation {
        var videoOrientation: AVCaptureVideoOrientation!
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .portrait:
            videoOrientation = .portrait
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            videoOrientation = .landscapeRight
        case .landscapeRight:
            videoOrientation = .landscapeLeft
        case .faceDown, .faceUp, .unknown:
            videoOrientation = .portrait
            break
        }
        return videoOrientation
    }
    
    private func getThumbnail(url: URL) -> UIImage? {
        var image: UIImage? = nil
        
        do {
            let asset = AVURLAsset(url: url, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            image = UIImage(cgImage: cgImage)
            
            /**
            let deviceOrientation = UIDevice.current.orientation
            
            if (deviceOrientation == .landscapeLeft) {
                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.left)
            } else if (deviceOrientation == .landscapeRight) {
                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.right)
            } else if (deviceOrientation == .portrait) {
                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.up)
            } else if (deviceOrientation == .portraitUpsideDown) {
                image = UIImage(cgImage: (image?.cgImage)!, scale: (image?.scale)!, orientation: UIImageOrientation.down)
            }
             */

        } catch {
            image = nil
        }
        
        return image
    }
    
    public func fileOutput(_ captureOutput: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if outputFileURL != nil {
            print ("Connection count: \(connections.count)")
            let thumbnail = getThumbnail(url: outputFileURL)
            var filePath: URL? = nil
            
            if thumbnail != nil {
                if let data = UIImageJPEGRepresentation(thumbnail!, CGFloat(0.8)) {
                    let fileName = "image_\(UUID().uuidString).jpeg";
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    filePath = documentsURL.appendingPathComponent(fileName, isDirectory: false)
                    
                    if filePath != nil {
                        try? data.write(to: filePath!)
                    }
                }
            }
            
            
            // Publish uncompressed video
            self.delegate?.onRecordedVideoReady(videoUrl: outputFileURL, thumbnail: thumbnail, thumbnailImageUrl: filePath)
            
            /**
             let fileName = "recorded_compressed.mov";
             let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
             let compressedOutput = documentsURL.appendingPathComponent(fileName, isDirectory: false)
             
             do {
             try FileManager.default.removeItem(at: compressedOutput)
             } catch {
             
             }
             
             self.compressVideo(input: outputFileURL, output: compressedOutput) { (result) in
             if (result != nil) {
             print("Original path: \(outputFileURL.absoluteString)")
             print("Compressed path: \(compressedOutput.absoluteString)")
             print("Compression result: \(result!.status.rawValue)")
             print("Error: \(result!.error.debugDescription)")
             print("Error: \(result!.error?.localizedDescription)")
             
             if (result!.status == AVAssetExportSessionStatus.completed) {
             self.delegate?.onRecordedVideoReady(videoUrl: compressedOutput, thumbnail: thumbnail)
             } else {
             self.delegate?.onRecordedVideoReady(videoUrl: outputFileURL, thumbnail: thumbnail)
             }
             }
             }
             */
            
        }
    }
    
    func compressVideo(input: URL, output: URL, completion: @escaping (AVAssetExportSession?) -> Void) {
        let urlAsset = AVURLAsset(url: input)
        let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset960x540)
        if let exportSession = exportSession {
            exportSession.outputURL = output
            exportSession.outputFileType = AVFileType.mov
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously {
                completion(exportSession)
            }
        } else {
            completion(nil)
        }
    }
    
    func switchCamera() -> AVCaptureDevice {
        var error: NSError? = nil
        
        // Change camera source
        // Indicate that some changes will be made to the session
        captureSession.beginConfiguration()
        
        let currentCameraInput = captureSession.inputs.first
        
        // Remove existing input
        for input in captureSession.inputs {
            captureSession.removeInput(input )
        }
        
        captureSession.sessionPreset = .high //REDUCE SESSION PRESET TO HIGH FOR SMOOTH TRANSITION
        //Get new input
        var newCamera:AVCaptureDevice! = nil
        
        if let input = currentCameraInput as? AVCaptureDeviceInput {
            if input.device.position == .back {
                newCamera = cameraWithPosition(position: .front)
            } else {
                newCamera = cameraWithPosition(position: .back)
            }
        }
        
        //Add input to session
        var newVideoInput: AVCaptureDeviceInput!
        
        do {
            newVideoInput = try AVCaptureDeviceInput(device: newCamera)
        } catch let err as NSError {
            error = err
            newVideoInput = nil
        }
        
        if(newVideoInput == nil || error != nil) {
            print("Error creating capture device input: \(error!.localizedDescription)")
        } else {
            captureSession.addInput(newVideoInput)
        }
        //Commit all the configuration changes at once
        captureSession.commitConfiguration()

        
        
        return newCamera
    }
    
    func changeSelfieCameraState(isOpened: Bool) -> AVCaptureDevice {
        var error: NSError? = nil
        
        // Change camera source
        // Indicate that some changes will be made to the session
        captureSession.beginConfiguration()
      
        // Remove existing input
        for input in captureSession.inputs {
            captureSession.removeInput(input )
        }
        
        captureSession.sessionPreset = .high //REDUCE SESSION PRESET TO HIGH FOR SMOOTH TRANSITION

        //Get new input
        var newCamera:AVCaptureDevice! = nil
        
        if (isOpened) {
            newCamera = cameraWithPosition(position: .front)
        } else {
            newCamera = cameraWithPosition(position: .back)
        }
        
        //Add input to session
        var newVideoInput: AVCaptureDeviceInput!
        
        do {
            newVideoInput = try AVCaptureDeviceInput(device: newCamera)
        } catch let err as NSError {
            error = err
            newVideoInput = nil
        }
        
        if(newVideoInput == nil || error != nil) {
            print("Error creating capture device input: \(error!.localizedDescription)")
        } else {
            captureSession.addInput(newVideoInput)
        }

        //Commit all the configuration changes at once
        captureSession.commitConfiguration()

        return newCamera
    }
    
    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                device.torchMode = device.torchMode == .on ? .off : .on
                if device.torchMode == .on {
                    self.isTorchOpened = true
                } else if device.torchMode == .off {
                    self.isTorchOpened = false
                } else {
                    self.isTorchOpened = false
                }
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    func changeTorchMode(value: Bool) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                device.torchMode = value == true ? .on : .off
                if device.torchMode == .on {
                    self.isTorchOpened = true
                } else if device.torchMode == .off {
                    self.isTorchOpened = false
                } else {
                    self.isTorchOpened = false
                }
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    func startSession() {
        self.captureSession.startRunning()
    }
    
    func getCameraPreview() -> AVCaptureVideoPreviewLayer {
        return previewLayer
    }
        
}
