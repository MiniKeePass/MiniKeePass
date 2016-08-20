//
//  RenameItemViewController.swift
//  MiniKeePass
//
//  Created by Jason Rush on 8/20/16.
//  Copyright © 2016 Self. All rights reserved.
//

import UIKit

class RenameItemViewController: UITableViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    var donePressed: ((renameItemViewController: RenameItemViewController) -> Void)?
    var cancelPressed: ((renameItemViewController: RenameItemViewController) -> Void)?

    var group: KdbGroup?
    var entry: KdbEntry?
    
    private var selectedImageIndex: Int = -1 {
        didSet {
            let imageFactory = ImageFactory.sharedInstance()
            imageView.image = imageFactory.imageForIndex(selectedImageIndex)
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        donePressedAction(nil)
        return true
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let imageSelectorViewController = segue.destinationViewController as! ImageSelectorViewController
        imageSelectorViewController.selectedImage = selectedImageIndex
        imageSelectorViewController.imageSelected = { (imageSelectorViewController: ImageSelectorViewController, selectedImage: Int) in
            self.selectedImageIndex = selectedImage
        }
    }

    // MARK: - Actions
    
    @IBAction func donePressedAction(sender: UIBarButtonItem?) {
        // Validate the name is valid
        let name = nameTextField.text
        if (name == nil || name!.isEmpty) {
            presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("New name is invalid", comment: ""))
            return;
        }

        // Update the group/entry
        if (group != nil) {
            group!.name = name
            group!.image = selectedImageIndex
        } else if (entry != nil) {
            entry!.setTitle(name)
            entry!.image = selectedImageIndex
        }
        
        donePressed?(renameItemViewController: self)
    }

    @IBAction func cancelPressedAction(sender: UIBarButtonItem) {
        cancelPressed?(renameItemViewController: self)
    }
}
