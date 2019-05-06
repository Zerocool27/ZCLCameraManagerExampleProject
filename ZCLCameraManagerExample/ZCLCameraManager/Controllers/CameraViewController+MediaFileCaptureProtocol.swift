//
//  CameraViewController+MediaFileCaptureProtocol.swift
//  ZCLCameraManagerExample
//
//  Created by fatih on 3/29/19.
//  Copyright © 2019 fatih. All rights reserved.
//

import UIKit
import Foundation

extension CameraViewController: MediaFileCaptureProtocol{
    func didReceiveVideoError(error: Error?) {
        DispatchQueue.main.async {
            self.toggleCameraButtons(isEnabled: true)
        }
    }
    
    func didReceivePhotoError(error: Error?){
        DispatchQueue.main.async {
            self.toggleCameraButtons(isEnabled: true)
        }
    }
    
    func didFinishCapturingVideo(videoUrl: URL?, thumbnail: UIImage?) {
        
        DispatchQueue.main.async { [weak self] in
            if let videoUrl = videoUrl,
                let videoThumbnail = thumbnail{
                //DO WHATEVERY YOU WANT TO DO WITH VIDEO AND VIDEO THUMBNAIL
            }
        }
    }
    
    func didFinishCapturingPhoto(image: UIImage?) {
        
        DispatchQueue.main.async { [weak self] in
            self?.toggleCameraActionButton(isEnabled: true)
            if let image = image {
                //DO WHATEVER YOU WANT TO DO WITH THE IMAGE
            }
        }
    }
}
