//
//  ShotViewController+ShareViewDelegate.swift
//  WhatsAround
//
//  Created by fatih on 3/12/19.
//  Copyright © 2019 turquaz. All rights reserved.
//

extension ShotViewController: ShareViewDelegate{
    func shareViewIsDismissed() {
        UIApplication.shared.isStatusBarHidden = true
        self.registerForVolumeChangeButton()
        self.setupPendingShotsEmpty()
        self.savedShotsActivityIndicator.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.savedShotsActivityIndicator.stopAnimating()
            self.setupAllPendingShots()
        }
        self.showSavedShotsCollectionView()
    }
}
