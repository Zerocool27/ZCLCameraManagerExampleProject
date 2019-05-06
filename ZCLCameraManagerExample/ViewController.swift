//
//  ViewController.swift
//  ZCLCameraManagerExample
//
//  Created by fatih on 3/29/19.
//  Copyright © 2019 fatih. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBAction func launcCameraButtonOnClick(_ sender: Any) {
        handleCameraPermissions()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
}

// MARK: Helper Methods
extension ViewController{
    private func handleCameraPermissions(){
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            DispatchQueue.main.async {
                ZCLCameraSessionManager.shared.setupResult = .success
                let cameraVC = CameraViewController.initViewController()
                cameraVC.modalPresentationStyle = .overCurrentContext
                cameraVC.modalTransitionStyle = .crossDissolve
                self.present(cameraVC, animated: true, completion: nil)
            }
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    ZCLCameraSessionManager.shared.setupResult = .notAuthorized
                }else{
                    DispatchQueue.main.async {
                        ZCLCameraSessionManager.shared.setupResult = .success
                        let cameraVC = CameraViewController.initViewController()
                        cameraVC.modalPresentationStyle = .overCurrentContext
                        cameraVC.modalTransitionStyle = .crossDissolve
                        self.present(cameraVC, animated: true, completion: nil)
                    }
                }
            })
        default:
            // The user has previously denied access.
            ZCLCameraSessionManager.shared.setupResult = .notAuthorized
        }
    }
}

