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

    var selectedImage = -1
    
    var imageSelected: ((imageSelectorViewController: ImageSelectorViewController, selectedImage: Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageFactory = ImageFactory.sharedInstance()
        images = imageFactory.images() as! [UIImage]
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (selectedImage != -1) {
            collectionView?.selectItemAtIndexPath(NSIndexPath(forRow: selectedImage, inSection: 0), animated: animated, scrollPosition: UICollectionViewScrollPosition.None)
        }
    }

    // MARK: UICollectionView data source

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ImageCell
        cell.imageView.image = images[indexPath.row]
        cell.selected = indexPath.row == selectedImage
        return cell
    }
    
    // MARK: UICollectionView delegate
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        selectedImage = -1
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedImage = indexPath.row
        
        imageSelected?(imageSelectorViewController: self, selectedImage: selectedImage)
    }
}
