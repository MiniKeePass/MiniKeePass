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

protocol NewDatabaseDelegate {
    func newDatabaseCreated(filename: String)
}

class NewDatabaseViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var versionSegmentedControl: UISegmentedControl!

    var delegate: NewDatabaseDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameTextField.becomeFirstResponder()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == nameTextField) {
            passwordTextField.becomeFirstResponder()
        } else if (textField == passwordTextField) {
            confirmPasswordTextField.becomeFirstResponder()
        } else if (textField == confirmPasswordTextField) {
            donePressedAction(nil)
        }
        return true
    }
    
    // MARK: - Actions

    @IBAction func donePressedAction(_ sender: UIBarButtonItem?) {
        // Check to make sure the name was supplied
        guard let name = nameTextField.text, !(name.isEmpty) else {
            presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Database name is required", comment: ""))
            return
        }

        // Check the passwords
        guard let password1 = passwordTextField.text, !(password1.isEmpty),
            let password2 = confirmPasswordTextField.text, !(password2.isEmpty) else {
                presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Password is required", comment: ""))
                return
        }

        if (password1 != password2) {
            presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Passwords do not match", comment: ""))
            return
        }

        var version: Int
        var extention: String

        if (versionSegmentedControl.selectedSegmentIndex == 0) {
            version = 1
            extention = "kdb"
        } else {
            version = 2
            extention = "kdbx"
        }
        
        // Create a URL to the file
        var url = AppDelegate.documentsDirectoryUrl()
        url = url?.appendingPathComponent("\(name).\(extention)")
        
        if url == nil {
            presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Could not create file path", comment: ""))
            return
        }

        // Check if the file already exists
        do {
            if try url!.checkResourceIsReachable() {
                presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("A file already exists with this name", comment: ""))
                return
            }
        } catch {
        }

        // Create the new database
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager?.newDatabase(url, password: password1, version: version)
        
        delegate?.newDatabaseCreated(filename: url!.lastPathComponent)
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
