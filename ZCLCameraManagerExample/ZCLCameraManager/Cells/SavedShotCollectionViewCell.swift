//
//  SavedShotCollectionViewCell.swift
//  WhatsAround
//
//  Created by fatih on 3/14/19.
//  Copyright © 2019 turquaz. All rights reserved.
//

import UIKit

protocol SavedShotCollectionViewCellDelegate{
    func didTapOnShotCell(_ savedShotCollectionViewCell : SavedShotCollectionViewCell, model: PendingShotModel)
    func didLongPressOnShotCell(_ savedShotCollectionViewCell : SavedShotCollectionViewCell, model: PendingShotModel, indexPath: IndexPath)
}

class SavedShotCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "SavedShotCollectionViewCell"

    var delegate : SavedShotCollectionViewCellDelegate?
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var shotThumbnailImage: UIImageView!
    @IBOutlet weak var shotPlayImage: UIImageView!
    var model : PendingShotModel!
    var indexPath : IndexPath!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        self.mainContainer.layer.masksToBounds = true
        self.shotThumbnailImage.layer.masksToBounds = true
        self.mainContainer.layer.cornerRadius = 10
    }
    
    func setupCell(with model: PendingShotModel,indexPath : IndexPath, isFocused: Bool){
        self.model = model
        self.indexPath = indexPath
        
        if !isFocused {
            self.mainContainer.alpha = 0.4
        }else{
            self.mainContainer.alpha = 1.0
        }
        
        if let imagePathComponent = self.model.imageUrlLastPathComponent {
            self.shotThumbnailImage.image = FileManager.getImageFromDocumentsDir(pathComponent: imagePathComponent)
        }
        self.shotThumbnailImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        self.shotThumbnailImage.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress)))
        self.shotThumbnailImage.isUserInteractionEnabled = true
        if self.model.shot.media.type == .videoShot {
            shotPlayImage.isHidden = false
        } else {
            shotPlayImage.isHidden = true
        }
    }
}

//MARK: Gesture Functions
extension SavedShotCollectionViewCell {
    @objc func onTap() {
        delegate?.didTapOnShotCell(self, model: self.model)
    }
    
    @objc func onLongPress() {
        delegate?.didLongPressOnShotCell(self, model: self.model, indexPath: self.indexPath)
    }
}
