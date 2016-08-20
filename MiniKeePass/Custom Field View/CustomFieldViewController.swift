//
//  CustomFieldViewController.swift
//  MiniKeePass
//
//  Created by Jason Rush on 8/20/16.
//  Copyright © 2016 Self. All rights reserved.
//

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
