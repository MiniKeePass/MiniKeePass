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

class RenameDatabaseViewController: UITableViewController {
    @IBOutlet weak var nameTextField: UITextField!
    
    var originalUrl: NSURL!

    var donePressed: ((RenameDatabaseViewController, originalUrl: NSURL, newUrl: NSURL) -> Void)?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        nameTextField.text = originalUrl.URLByDeletingPathExtension?.lastPathComponent
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        donePressedAction(nil)
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func donePressedAction(sender: UIBarButtonItem?) {
        let name = nameTextField.text;
        if (name == nil || name!.isEmpty) {
            self.presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Filename is invalid", comment: ""))
            return
        }
        
        // Create the new URL
        var newUrl = originalUrl.URLByDeletingLastPathComponent!
        newUrl = newUrl.URLByAppendingPathComponent(nameTextField.text!)
        newUrl = newUrl.URLByAppendingPathExtension(originalUrl.pathExtension!)
        
        // Check if the file already exists
        if (newUrl.checkResourceIsReachableAndReturnError(nil)) {
            self.presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("A file already exists with this name", comment: ""))
            return
        }
        
        donePressed?(self, originalUrl: originalUrl, newUrl: newUrl)
    }
    
    @IBAction func cancelPressed(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
