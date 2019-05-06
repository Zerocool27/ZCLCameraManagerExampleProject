//
//  CameraViewController+Helpers.swift
//  ZCLCameraManagerExample
//
//  Created by fatih on 3/29/19.
//  Copyright © 2019 fatih. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

//MARK: Helper Methods
extension CameraViewController{
    
    func toggleCameraButtons(isEnabled: Bool){
        self.captureModeControl.isEnabled = isEnabled
        self.cameraActionButton.isEnabled = isEnabled
        self.flashButton.isEnabled = isEnabled
        self.switchCameraButton.isEnabled = isEnabled
    }
    
    func repaintCameraPreview(){
        self.previewCameraLayer.frame = self.cameraView.bounds
    }
    
    func rotateViewsBasedOnOrientation(with angle: CGFloat){
        self.switchCameraButton.transform = CGAffineTransform(rotationAngle: angle)
        self.flashButton.transform = CGAffineTransform(rotationAngle: angle)
    }
    func checkFlashMode(){
        if ZCLCameraSessionManager.shared.getFlashMode() == .auto{
            flashButton.setImage(UIImage(named: FlashIcons.auto.rawValue), for: .normal)
        }else if ZCLCameraSessionManager.shared.getFlashMode() == .off{
            flashButton.setImage(UIImage(named: FlashIcons.off.rawValue), for: .normal)
        }else if ZCLCameraSessionManager.shared.getFlashMode() == .on{
            flashButton.setImage(UIImage(named: FlashIcons.on.rawValue), for: .normal)
        }
    }
    
    func updateFocusSquare(point: CGPoint) {
        if let fsquare = self.focusSquare {
            fsquare.updatePoint(point)
        } else {
            self.focusSquare = CameraFocusSquare(touchPoint: point)
            self.cameraView.addSubview(self.focusSquare!)
            self.focusSquare?.setNeedsDisplay()
        }
        self.focusSquare?.animateFocusingAction()
    }
    
    func toggleSingleTapInCameraView(isEnabled:Bool){
        cameraViewSingleTapGesture?.isEnabled = isEnabled
    }
    
    func dismissView() {
        self.dismiss(animated: false, completion: nil)
    }
    
    func getCameraViewBounds() -> CGRect {
        return self.cameraView.bounds
    }
    
    func enableVideoRecordingButton() {
        cameraActionButton.setImage(UIImage(named: "cameraRecording"), for: .normal)
    }
    
    func disableVideoRecordingButton() {
        cameraActionButton.setImage(UIImage(named: "cameraNormal"), for: .normal)
    }
    
    func toggleCameraSwitchButton(isEnabled:Bool) {
        switchCameraButton.isEnabled = isEnabled
    }
    
    func toggleCameraActionButton(isEnabled:Bool){
        cameraActionButton.isEnabled = isEnabled
    }
}
