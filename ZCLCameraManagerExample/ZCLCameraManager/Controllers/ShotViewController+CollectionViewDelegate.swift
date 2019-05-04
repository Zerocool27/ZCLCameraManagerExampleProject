//
//  ShotViewController+CollectionViewDelegate.swift
//  WhatsAround
//
//  Created by fatih on 3/14/19.
//  Copyright © 2019 turquaz. All rights reserved.
//

import Foundation
import UIKit

extension ShotViewController:UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIScrollViewDelegate{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedShotList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = collectionView.bounds.height 
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SavedShotCollectionViewCell.reuseIdentifier, for: indexPath) as! SavedShotCollectionViewCell
        guard let model = savedShotList[safe: indexPath.row] else { return UICollectionViewCell() }
        cell.setupCell(with: model, indexPath: indexPath, isFocused: isCollectionViewFocused)
        cell.delegate = self
        
        return cell
    }
}

//MARK: Saved Shot Cell Delegates and Methods
extension ShotViewController: SavedShotCollectionViewCellDelegate{
    func didTapOnShotCell(_ savedShotCollectionViewCell: SavedShotCollectionViewCell, model: PendingShotModel) {
        let vc = SharePostViewController.initializeViewControllerFromCamera(with: model)
        vc.modalPresentationStyle = UIModalPresentationStyle.custom
        vc.modalTransitionStyle = .crossDissolve
        if let sharePostVC = vc.topViewController as? SharePostViewController{
            sharePostVC.delegate = self
        }
        self.present(viewController: vc, completion: nil)
    }
    
    func didLongPressOnShotCell(_ savedShotCollectionViewCell: SavedShotCollectionViewCell, model: PendingShotModel, indexPath: IndexPath) {
        self.shotIndexPathForDelete = indexPath
        deleteSavedPendingShot()
    }
    
    func deleteSavedPendingShot()  {
        let storyboard = UIStoryboard(name: "Alert", bundle: nil)
        let alertVC = storyboard.instantiateViewController(withIdentifier: "AlertViewControllerStoryboard") as! AlertViewController
        alertVC.setTitle(title: NSLocalizedString("Delete saved post", comment: "Delete saved post"))
        alertVC.setMessage(message: NSLocalizedString("Are you sure to delete saved post?", comment: "Are you sure to delete saved post?"))
        alertVC.doneAction = self.handleDeleteSavedPost
        alertVC.cancelAction = self.cancelDeleteSavedPost
        alertVC.alerModel = .otherAlertModel
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func handleDeleteSavedPost() {
        if let indexPath = self.shotIndexPathForDelete {
            let index = indexPath.row
            guard let pendingShotForDelete = savedShotList[safe: index] else { return }
            PendingShotManager.shared.removeShareFromPendings(pendingShot: pendingShotForDelete)
            self.savedShotCollectionView.performBatchUpdates({
                self.savedShotList.remove(at: index)
                self.savedShotCollectionView.deleteItems(at: [indexPath])
            }) { (success) in
                if success{
                    self.setupAllPendingShots()
                }
            }
        }
    }
    
    func cancelDeleteSavedPost() {
        self.shotIndexPathForDelete = nil
    }
}
