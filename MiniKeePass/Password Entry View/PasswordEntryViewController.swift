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
    fileprivate var selectedKeyFileIndex: Int! = -1

    var donePressed: ((PasswordEntryViewController) -> Void)?
    var cancelPressed: ((PasswordEntryViewController) -> Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (keyFileLabel.text == "") {
            let keyFile = ((filename as NSString).deletingPathExtension as NSString).appendingPathExtension("key")
            let idx = keyFiles.index(of: keyFile!)
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
    
    func setSelectedKeyFile(_ selectedIndex: Int!) -> Void {
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
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.donePressedAction(nil)
        return true
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if (section == 1) {
            return String(format:NSLocalizedString("Enter the password and/or select the keyfile for the %@ database.", comment: ""), filename)
        }
        return nil
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let keyFileViewController = segue.destination as! KeyFileViewController
        keyFileViewController.keyFiles = keyFiles
        keyFileViewController.selectedIndex = selectedKeyFileIndex
        keyFileViewController.keyFileSelected = { (selectedIndex) in
            self.setSelectedKeyFile(selectedIndex)

            keyFileViewController.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func donePressedAction(_ sender: UIBarButtonItem?) {
        donePressed?(self)
    }
    
    @IBAction func cancelPressedAction(_ sender: UIBarButtonItem?) {
        cancelPressed?(self)
    }
    
    @IBAction func showPressed(_ sender: UITapGestureRecognizer) {
        if (!passwordTextField.isSecureTextEntry) {
            // Clear the password first, since you can't edit a secure text entry once set
            passwordTextField.text = ""
            passwordTextField.isSecureTextEntry = true
            
            // Change the image
            showImageView.image = UIImage(named: "eye")
        } else {
            passwordTextField.isSecureTextEntry = false
            
            // Change the image
            showImageView.image = UIImage(named: "eye-slash")
        }
    }
}
