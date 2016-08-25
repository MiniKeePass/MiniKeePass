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

struct CharSet {
    static let LowerCase = "abcdefghijklmnopqrstuvwxyz"
    static let UpperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static let Digits    = "0123456789"
    static let Minus     = "-"
    static let Underline = "_"
    static let Space     = " "
    static let Special   = "!\"#$%&'*+,./:;=?@\\^`"
    static let Brackets  = "(){}[]<>"
}

class PasswordGeneratorViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var lengthCell: UITableViewCell!
    @IBOutlet weak var lengthPickerView: UIPickerView!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var characterSetsCell: UITableViewCell!

    private var lengthPickerHidden = true
    private var length: Int = 0
    private var charSets: Int = 10
    
    var donePressed: ((PasswordGeneratorViewController, password: String) -> Void)?
    var cancelPressed: ((PasswordGeneratorViewController) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        lengthPickerView.dataSource = self
        lengthPickerView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let appSettings = AppSettings.sharedInstance()
        length = appSettings.pwGenLength()
        charSets = appSettings.pwGenCharSets()
        
        lengthCell.detailTextLabel?.text = String(length)
        lengthPickerView.selectRow(length - 1, inComponent: 0, animated: false)
        characterSetsCell.detailTextLabel?.text = createCharSetsDescription()
        
        generatePassword()
    }
    
    func generatePassword() {
        var charSet = ""
    
        if ((charSets & CharacterSet.UpperCase) != 0) {
            charSet += CharSet.UpperCase
        }
        if ((charSets & CharacterSet.LowerCase) != 0) {
            charSet += CharSet.LowerCase
        }
        if ((charSets & CharacterSet.Digits) != 0) {
            charSet += CharSet.Digits
        }
        if ((charSets & CharacterSet.Minus) != 0) {
            charSet += CharSet.Minus
        }
        if ((charSets & CharacterSet.Underline) != 0) {
            charSet += CharSet.Underline
        }
        if ((charSets & CharacterSet.Space) != 0) {
            charSet += CharSet.Space
        }
        if ((charSets & CharacterSet.Special) != 0) {
            charSet += CharSet.Special
        }
        if ((charSets & CharacterSet.Brackets) != 0) {
            charSet += CharSet.Brackets
        }
        
        if (charSet.isEmpty) {
            passwordLabel.text = ""
            return
        }
        
        let cryptoRandomStream = Salsa20RandomStream()

        var password = ""
        for _ in 1...length {
            let idx = Int(cryptoRandomStream.getInt() % UInt32(charSet.characters.count))
            password.append(charSet[charSet.startIndex.advancedBy(idx)])
        }
    
        passwordLabel.text = password
    }
    
    func createCharSetsDescription() -> String {
        var strs = [String]()
    
        if ((charSets & CharacterSet.UpperCase) != 0) {
            strs.append("Upper")
        }
        if ((charSets & CharacterSet.LowerCase) != 0) {
            strs.append("Lower")
        }
        if ((charSets & CharacterSet.Digits) != 0) {
            strs.append("Digits")
        }
        if ((charSets & CharacterSet.Minus) != 0) {
            strs.append("Minus")
        }
        if ((charSets & CharacterSet.Underline) != 0) {
            strs.append("Underline")
        }
        if ((charSets & CharacterSet.Space) != 0) {
            strs.append("Space")
        }
        if ((charSets & CharacterSet.Special) != 0) {
            strs.append("Special")
        }
        if ((charSets & CharacterSet.Brackets) != 0) {
            strs.append("Brackets")
        }
        
        if (strs.isEmpty) {
            return NSLocalizedString("None Selected", comment: "")
        } else {
            return strs.joinWithSeparator(", ")
        }
    }
    
    // MARK: - Table View
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (lengthPickerHidden && indexPath.section == 0 && indexPath.row == 1) {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == 0 && indexPath.row == 0) {
            
            lengthPickerHidden = !lengthPickerHidden
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    // MARK: - Picker View
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 35
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row + 1)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        length = row + 1
        
        lengthCell.detailTextLabel?.text = String(length)
        
        let appSettings = AppSettings.sharedInstance()
        appSettings.setPwGenLength(length)
        
        generatePassword()
    }
    
    // MARK: - Actions
    
    @IBAction func generatePressed(sender: UITapGestureRecognizer) {
        generatePassword()
    }

    @IBAction func donePressedAction(sender: AnyObject) {
        donePressed?(self, password: passwordLabel.text!)
    }
    
    @IBAction func cancelPressedAction(sender: AnyObject) {
        cancelPressed?(self)
    }
    
    func lengthUpdated(len: Int) {
        length = len
        
        let appSettings = AppSettings.sharedInstance()
        appSettings.setPwGenLength(length)
        
        generatePassword()
    }
}
