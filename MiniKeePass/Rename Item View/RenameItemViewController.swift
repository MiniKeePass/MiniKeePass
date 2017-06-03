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

class RenameItemViewController: UITableViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    var donePressed: ((_ renameItemViewController: RenameItemViewController) -> Void)?
    var cancelPressed: ((_ renameItemViewController: RenameItemViewController) -> Void)?

    var group: KdbGroup?
    var entry: KdbEntry?
    
    fileprivate var selectedImageIndex: Int = -1 {
        didSet {
            let imageFactory = ImageFactory.sharedInstance()
            imageView.image = imageFactory?.image(for: selectedImageIndex)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if (group != nil) {
            nameTextField.text = group!.name
            selectedImageIndex = group!.image
        } else if (entry != nil) {
            nameTextField.text = entry!.title()
            selectedImageIndex = entry!.image
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        donePressedAction(nil)
        return true
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let imageSelectorViewController = segue.destination as! ImageSelectorViewController
        imageSelectorViewController.selectedImage = selectedImageIndex
        imageSelectorViewController.imageSelected = { (imageSelectorViewController: ImageSelectorViewController, selectedImage: Int) in
            self.selectedImageIndex = selectedImage
        }
    }

    // MARK: - Actions
    
    @IBAction func donePressedAction(_ sender: UIBarButtonItem?) {
        // Validate the name is valid
        let name = nameTextField.text
        if (name == nil || name!.isEmpty) {
            presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("New name is invalid", comment: ""))
            return;
        }

        // Update the group/entry
        if group != nil {
            group!.name = name
            group!.image = selectedImageIndex
            group!.lastModificationTime = Date()
        } else if entry != nil {
            entry!.setTitle(name)
            entry!.image = selectedImageIndex
            entry!.lastModificationTime = Date()
        }

        // Save the database
        let appDelegate = AppDelegate.getDelegate()
        let databaseDocument = appDelegate?.databaseDocument
        databaseDocument?.save()

        donePressed?(self)

        dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelPressedAction(_ sender: UIBarButtonItem) {
        cancelPressed?(self)

        dismiss(animated: true, completion: nil)
    }
}
