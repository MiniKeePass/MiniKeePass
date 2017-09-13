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

class CustomFieldViewController: UITableViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var inMemoryProtectionSwitch: UISwitch!
    
    @objc var stringField: StringField?

    @objc var donePressed: ((_ customFieldViewController: CustomFieldViewController) -> Void)?
    @objc var cancelPressed: ((_ customFieldViewController: CustomFieldViewController) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let stringField = stringField else {
            return
        }
        
        nameTextField.text = stringField.key
        valueTextField.text = stringField.value
        inMemoryProtectionSwitch.isOn = stringField.protected
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == nameTextField) {
            valueTextField.becomeFirstResponder()
        } else if (textField == valueTextField) {
            self.donePressedAction(nil)
        }
        return true
    }

    // MARK: - Actions

    @IBAction func donePressedAction(_ sender: UIBarButtonItem?) {
        guard let name = nameTextField.text, !(name.isEmpty) else {
            self.presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Name cannot be empty", comment: ""))
            return
        }

        if let stringField = stringField {
            stringField.key = nameTextField.text
            stringField.value = valueTextField.text
            stringField.protected = inMemoryProtectionSwitch.isOn
        }

        donePressed?(self)
    }

    @IBAction func cancelPressedAction(_ sender: UIBarButtonItem) {
        cancelPressed?(self)
    }
}
