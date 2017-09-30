/*
 * Copyright 2016 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit

private let reuseIdentifier = "Cell"

class ImageSelectorViewController: UICollectionViewController {
    private let reuseIdentifier = "ImageCell"
    private var images: [UIImage] = []

    @objc var selectedImage = -1
    
    @objc var imageSelected: ((_ imageSelectorViewController: ImageSelectorViewController, _ selectedImage: Int) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageFactory = ImageFactory.sharedInstance()
        images = imageFactory?.images() as! [UIImage]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (selectedImage != -1) {
            collectionView?.selectItem(at: IndexPath(row: selectedImage, section: 0), animated: animated, scrollPosition: UICollectionViewScrollPosition())
        }
    }

    // MARK: UICollectionView data source

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCell
        cell.imageView.image = images[indexPath.row]
        cell.isSelected = indexPath.row == selectedImage
        return cell
    }
    
    // MARK: UICollectionView delegate
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedImage = -1
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedImage = indexPath.row
        
        imageSelected?(self, selectedImage)
    }
}
