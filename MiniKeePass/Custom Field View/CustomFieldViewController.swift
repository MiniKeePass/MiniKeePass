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
    
    var stringField: StringField?

    var donePressed: ((customFieldViewController: CustomFieldViewController) -> Void)?
    var cancelPressed: ((customFieldViewController: CustomFieldViewController) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.text = stringField!.key
        valueTextField.text = stringField!.value
        inMemoryProtectionSwitch.on = stringField!.protected
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == nameTextField) {
            valueTextField.becomeFirstResponder()
        } else if (textField == valueTextField) {
            self.donePressedAction(nil)
        }
        return true
    }

    // MARK: - Actions

    @IBAction func donePressedAction(sender: UIBarButtonItem?) {
        let name = nameTextField.text;
        if (name == nil || name!.isEmpty) {
            self.presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Name cannot be empty", comment: ""))
            return
        }

        stringField!.key = nameTextField.text
        stringField!.value = valueTextField.text
        stringField!.protected = inMemoryProtectionSwitch.on

        donePressed?(customFieldViewController: self)
    }

    @IBAction func cancelPressedAction(sender: UIBarButtonItem) {
        cancelPressed?(customFieldViewController: self)
    }
}
