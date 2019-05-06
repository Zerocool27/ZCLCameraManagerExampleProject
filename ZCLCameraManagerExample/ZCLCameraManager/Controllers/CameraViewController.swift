//
//  CameraViewController.swift
//  ZCLCameraManagerExample
//
//  Created by fatih on 3/29/19.
//  Copyright © 2019 fatih. All rights reserved.
//

import UIKit
import AVFoundation

enum CaptureMode : Int{
    case photo = 0
    case video = 1
}

enum FlashIcons: String {
    case auto = "flashAuto"
    case off = "flashOff"
    case on = "flashOn"
}

class CameraViewController: UIViewController {
    
    /** Camera Variables **/
    var isVideoRecording:Bool = false
    var pivotPinchScale:CGFloat = 0
    var cameraViewSingleTapGesture : UITapGestureRecognizer!
    var previewCameraLayer : AVCaptureVideoPreviewLayer!
    var focusSquare: CameraFocusSquare? = nil
    var cameraMode : CaptureMode = .photo
    
    /** Helper Variables **/
    var currentFlashIcon : FlashIcons = .auto
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    var orientationObserver: NSObjectProtocol?
    
    /** Camera View Outlets **/
    @IBOutlet weak var cameraView: UIView!
    
    /** Helper Outlets **/
    @IBOutlet weak var tapGestureView: UIView!
    
    /** Top Container Outlets **/
    @IBOutlet weak var captureModeControl: UISegmentedControl!
    @IBAction func toggleCaptureMode(_ captureModeControl: UISegmentedControl) {
        self.toggleCameraButtons(isEnabled: false)
        if captureModeControl.selectedSegmentIndex == CaptureMode.photo.rawValue {
            ZCLCameraSessionManager.shared.configureSessionForPhoto {
                DispatchQueue.main.async {
                    self.toggleCameraButtons(isEnabled: true)
                    self.cameraMode = .photo
                }
            }
        } else if captureModeControl.selectedSegmentIndex == CaptureMode.video.rawValue {
            ZCLCameraSessionManager.shared.configureSessionForVideo { (success) in
                if success{
                    DispatchQueue.main.async {
                        self.toggleCameraButtons(isEnabled: true)
                        self.cameraMode = .video
                    }
                }else{
                    DispatchQueue.main.async {
                        captureModeControl.selectedSegmentIndex = 0
                        self.toggleCameraButtons(isEnabled: true)
                        self.cameraMode = .photo
                    }
                }
            }
        }
    }
    
    /** Bottom Container Outlets **/
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var cameraActionButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    
    @IBAction func flashButtonOnClick(_ sender: Any) {
        ZCLCameraSessionManager.shared.toggleFlashMode()
        checkFlashMode()
    }
    
    @IBAction func cameraActionButtonOnClick(_ sender: Any) {
        if self.cameraMode == .photo{
            takePhoto()
        }else{
            if isVideoRecording {
                stopVideoRecording()
            }else{
                startVideoRecording()
            }
        }
    }
    @IBAction func switchButtonOnClick(_ sender: Any) {
        ZCLCameraSessionManager.shared.changeCamera()
    }
}

//MARK: Gesture Functions
extension CameraViewController{
    
    @objc func cameraViewPinchGestured(recognizer: UIPinchGestureRecognizer) {
        let device = ZCLCameraSessionManager.shared.getCameraDevice()
        do {
            try device.lockForConfiguration()
            switch recognizer.state {
            case .began:
                self.pivotPinchScale = device.videoZoomFactor
            case .changed:
                var factor = self.pivotPinchScale * recognizer.scale
                factor = max(1, min(factor, device.activeFormat.videoMaxZoomFactor))
                if factor > CAMERA_MAX_ZOOM_SCALE {
                    return
                }
                device.videoZoomFactor = factor
            default:
                break
            }
            device.unlockForConfiguration()
        } catch {
            // handle exception
        }
        
    }
    
    @objc func cameraViewTapGestured(recognizer: UITapGestureRecognizer){
        let screenSize = cameraView.bounds.size
        let point = recognizer.location(in: cameraView)
        let x = point.y / screenSize.height
        let y = point.x / screenSize.width
        let focusPoint = CGPoint(x: x , y: 1.0 - y)
        
        //TODO: updateFocusSquare
        self.updateFocusSquare(point: point)
        ZCLCameraSessionManager.shared.focusToPoint(point: focusPoint)
    }
    
    @objc func dismissViewWithPanGesture(recognizer: UIPanGestureRecognizer){
        
        let touchPoint = recognizer.location(in: self.view?.window)
        
        if recognizer.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if recognizer.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y   > 0 {
                self.view.frame = CGRect(x: 0 , y: 0 + (touchPoint.y - initialTouchPoint.y), width: self.view.frame.size.width, height: self.view.frame.size.height)
                self.view.alpha = 1.0 - (touchPoint.y - initialTouchPoint.y) / initialTouchPoint.y + 0.1
            }
        } else if recognizer.state == UIGestureRecognizer.State.ended || recognizer.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                self.dismissView()
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                    self.view.alpha = 1.0
                })
            }
        }
    }
    
}

//MARK: Override Methods
extension CameraViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        ZCLCameraSessionManager.shared.startSession()
        setupObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ZCLCameraSessionManager.shared.stopSession()
        removeObservers()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.repaintCameraPreview()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: Setup/Remove Methods
extension CameraViewController{
    func setupView(){
        setupCameraSession()
        setupUIComponents()
        setupAudioSessionForRecording()
        setupGestures()
    }
    func setupUIComponents(){
        cameraActionButton.contentVerticalAlignment = .fill
        cameraActionButton.contentHorizontalAlignment = .fill
        checkFlashMode()
    }
    func setupObservers(){
        
        orientationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main, using: { notification in
            var rotation_angle: CGFloat = 0
            
            switch UIDevice.current.orientation
            {
            case .landscapeLeft:
                rotation_angle = (CGFloat(Double.pi) / 2)
            case .landscapeRight:
                rotation_angle = (CGFloat(-Double.pi) / 2)
            case .unknown, .portrait, .faceUp, .faceDown:
                rotation_angle = 0
            default:
                rotation_angle = 0
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                self.rotateViewsBasedOnOrientation(with: rotation_angle)
            }, completion: nil)
        })
    }
    func removeObservers(){
        if orientationObserver != nil {
            NotificationCenter.default.removeObserver(orientationObserver!)
        }
    }
    func setupCameraSession(){
        
        let rect = self.getCameraViewBounds()
        ZCLCameraSessionManager.shared.initializeCameraPreview(with: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
        let cameraPreview = ZCLCameraSessionManager.shared.getPreview()
        setupCameraView(previewLayer: cameraPreview)
        ZCLCameraSessionManager.shared.delegate = self
    }
    
    func setupCameraView(previewLayer: AVCaptureVideoPreviewLayer) {
        previewCameraLayer = previewLayer
        previewCameraLayer.setNeedsLayout()
        previewCameraLayer.frame = self.cameraView.frame
        self.cameraView.layer.addSublayer(previewCameraLayer)
        DispatchQueue.main.async {
            self.previewCameraLayer.frame = self.cameraView.bounds
            self.view.layoutIfNeeded()
        }
    }
    
    func setupAudioSessionForRecording(){
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.videoRecording, options: [.allowBluetooth,.allowAirPlay,.allowBluetoothA2DP,.defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true,options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
    }
    func setupGestures(){
        
        cameraViewSingleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.cameraViewTapGestured))
        cameraViewSingleTapGesture.numberOfTapsRequired = 1
        cameraViewSingleTapGesture.numberOfTouchesRequired = 1
        self.tapGestureView.addGestureRecognizer(cameraViewSingleTapGesture)
        toggleSingleTapInCameraView(isEnabled: true)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.dismissViewWithPanGesture))
        self.tapGestureView.addGestureRecognizer(panGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.cameraViewPinchGestured))
        self.view.addGestureRecognizer(pinchGesture)
        cameraViewSingleTapGesture.require(toFail: pinchGesture)
    }
}

//MARK: Video/Image Management Methods
extension CameraViewController{
    func stopVideoRecording(){
        toggleCameraSwitchButton(isEnabled: true)
        disableVideoRecordingButton()
        isVideoRecording = false
        ZCLCameraSessionManager.shared.stopRecordingVideo()
    }
    
    func startVideoRecording(){
        toggleCameraSwitchButton(isEnabled: false)
        enableVideoRecordingButton()
        isVideoRecording = true
        ZCLCameraSessionManager.shared.startRecordingVideo()
    }
    
    func takePhoto(){
        toggleCameraSwitchButton(isEnabled: false)
        toggleCameraActionButton(isEnabled: false)
        ZCLCameraSessionManager.shared.takePhoto(for: UIDevice.current.orientation)
    }
}

//MARK: Controller Initializer
extension CameraViewController{
    static func initViewController() -> CameraViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
    }
}
