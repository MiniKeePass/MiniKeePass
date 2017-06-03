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

struct CharacterSet {
    static let UpperCase = 1 << 0
    static let LowerCase = 1 << 1
    static let Digits    = 1 << 2
    static let Minus     = 1 << 3
    static let Underline = 1 << 4
    static let Space     = 1 << 5
    static let Special   = 1 << 6
    static let Brackets  = 1 << 7
    static let Default   = (UpperCase | LowerCase | Digits)
}

class CharacterSetsViewController: UITableViewController {
    @IBOutlet weak var upperCaseSwitch: UISwitch!
    @IBOutlet weak var lowerCaseSwitch: UISwitch!
    @IBOutlet weak var digitsSwitch: UISwitch!
    @IBOutlet weak var minusSwitch: UISwitch!
    @IBOutlet weak var underlineSwitch: UISwitch!
    @IBOutlet weak var spaceSwitch: UISwitch!
    @IBOutlet weak var specialSwitch: UISwitch!
    @IBOutlet weak var bracketsSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        let appSettings = AppSettings.sharedInstance() as AppSettings
        let charSets = appSettings.pwGenCharSets()
        
        upperCaseSwitch.isOn = (charSets & CharacterSet.UpperCase) != 0
        lowerCaseSwitch.isOn = (charSets & CharacterSet.LowerCase) != 0
        digitsSwitch.isOn = (charSets & CharacterSet.Digits) != 0
        minusSwitch.isOn = (charSets & CharacterSet.Minus) != 0
        underlineSwitch.isOn = (charSets & CharacterSet.Underline) != 0
        spaceSwitch.isOn = (charSets & CharacterSet.Space) != 0
        specialSwitch.isOn = (charSets & CharacterSet.Special) != 0
        bracketsSwitch.isOn = (charSets & CharacterSet.Brackets) != 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        var charSets = 0
        if (upperCaseSwitch.isOn) {
            charSets |= CharacterSet.UpperCase
        }
        if (lowerCaseSwitch.isOn) {
            charSets |= CharacterSet.LowerCase
        }
        if (digitsSwitch.isOn) {
            charSets |= CharacterSet.Digits
        }
        if (minusSwitch.isOn) {
            charSets |= CharacterSet.Minus
        }
        if (underlineSwitch.isOn) {
            charSets |= CharacterSet.Underline
        }
        if (spaceSwitch.isOn) {
            charSets |= CharacterSet.Space
        }
        if (specialSwitch.isOn) {
            charSets |= CharacterSet.Special
        }
        if (bracketsSwitch.isOn) {
            charSets |= CharacterSet.Brackets
        }
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
        appSettings.setPwGenCharSets(charSets)
    }
}
