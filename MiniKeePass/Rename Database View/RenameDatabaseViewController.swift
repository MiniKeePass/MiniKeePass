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
    
    var originalUrl: URL!

    var donePressed: ((RenameDatabaseViewController, _ originalUrl: URL, _ newUrl: URL) -> Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameTextField.text = originalUrl.deletingPathExtension().lastPathComponent
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        donePressedAction(nil)
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func donePressedAction(_ sender: UIBarButtonItem?) {
        let name = nameTextField.text;
        if (name == nil || name!.isEmpty) {
            self.presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Filename is invalid", comment: ""))
            return
        }
        
        // Create the new URL
        var newUrl = originalUrl.deletingLastPathComponent()
        newUrl = newUrl.appendingPathComponent(nameTextField.text!)
        newUrl = newUrl.appendingPathExtension(originalUrl.pathExtension)
        
        // Check if the file already exists
        if ((newUrl as NSURL).checkResourceIsReachableAndReturnError(nil)) {
            self.presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("A file already exists with this name", comment: ""))
            return
        }
        
        donePressed?(self, originalUrl, newUrl)
    }
    
    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
