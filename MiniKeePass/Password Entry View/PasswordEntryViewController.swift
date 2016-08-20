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

class PasswordEntryViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var showImageView: UIImageView!
    @IBOutlet weak var keyFileLabel: UILabel!

    var filename: String!
    
    var keyFiles: [String]!
    private var selectedKeyFileIndex: Int! = -1

    var donePressed: ((PasswordEntryViewController) -> Void)?
    var cancelPressed: ((PasswordEntryViewController) -> Void)?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (keyFileLabel.text == "") {
            let keyFile = ((filename as NSString).stringByDeletingPathExtension as NSString).stringByAppendingPathExtension("key")
            let idx = keyFiles.indexOf(keyFile!)
            setSelectedKeyFile(idx)
        }
        
        passwordTextField.becomeFirstResponder()
    }
    
    func getPassword() -> String! {
        return passwordTextField.text
    }
    
    func getKeyFile() -> String! {
        if (selectedKeyFileIndex == -1) {
            return nil
        }
        return keyFiles[selectedKeyFileIndex]
    }
    
    func setSelectedKeyFile(selectedIndex: Int!) -> Void {
        if (selectedIndex == nil) {
            selectedKeyFileIndex = -1
        } else {
            selectedKeyFileIndex = selectedIndex
        }
        
        if (selectedKeyFileIndex == -1) {
            keyFileLabel.text = NSLocalizedString("None", comment: "")
        } else {
            keyFileLabel.text = keyFiles[selectedKeyFileIndex]
        }
    }
    
    // MARK: - Actions
    
    @IBAction func donePressedAction(sender: UIBarButtonItem?) {
        donePressed?(self)
    }

    @IBAction func cancelPressedAction(sender: UIBarButtonItem?) {
        cancelPressed?(self)
    }

    @IBAction func showPressed(sender: UITapGestureRecognizer) {
        if (!passwordTextField.secureTextEntry) {
            // Clear the password first, since you can't edit a secure text entry once set
            passwordTextField.text = ""
            passwordTextField.secureTextEntry = true
            
            // Change the image
            showImageView.image = UIImage(named: "eye")
        } else {
            passwordTextField.secureTextEntry = false
            
            // Change the image
            showImageView.image = UIImage(named: "eye-slash")
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.donePressedAction(nil)
        return true
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if (section == 1) {
            return String(format:NSLocalizedString("Enter the password and/or select the keyfile for the %@ database.", comment: ""), filename)
        }
        return nil
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let keyFileViewController = segue.destinationViewController as! KeyFileViewController
        keyFileViewController.keyFiles = keyFiles
        keyFileViewController.selectedIndex = selectedKeyFileIndex
        keyFileViewController.keyFileSelected = { (selectedIndex) in
            self.setSelectedKeyFile(selectedIndex)

            keyFileViewController.navigationController?.popViewControllerAnimated(true)
        }
    }
}
