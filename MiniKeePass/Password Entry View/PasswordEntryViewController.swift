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

    @objc var filename: String!
    
    @objc var keyFiles: [String]!
    fileprivate var selectedKeyFileIndex: Int? = nil {
        didSet {
            if let selectedKeyFileIndex = selectedKeyFileIndex {
                keyFileLabel.text = keyFiles[selectedKeyFileIndex]
            } else {
                keyFileLabel.text = NSLocalizedString("None", comment: "")
            }
        }
    }
    
    @objc var keyFile: String? {
        guard let selectedKeyFileIndex = selectedKeyFileIndex else {
            return nil
        }
        
        return keyFiles[selectedKeyFileIndex]
    }

    @objc var password: String! {
        return passwordTextField.text
    }

    @objc var donePressed: ((PasswordEntryViewController) -> Void)?
    @objc var cancelPressed: ((PasswordEntryViewController) -> Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (keyFileLabel.text == "") {
            let keyFile = ((filename as NSString).deletingPathExtension as NSString).appendingPathExtension("key")
            let idx = keyFiles.index(of: keyFile!)
            selectedKeyFileIndex = idx
        }
        
        passwordTextField.becomeFirstResponder()
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
        keyFileViewController.selectedKeyIndex = selectedKeyFileIndex
        keyFileViewController.keyFileSelected = { (selectedIndex) in
            self.selectedKeyFileIndex = selectedIndex

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
