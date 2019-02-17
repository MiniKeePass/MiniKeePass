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
import AudioToolbox

class SetPinViewController: UIViewController, PinViewControllerDelegate {
    
    // The PIN keypad will be programatically added to the mainView
    @IBOutlet weak var mainView: UIView!

    fileprivate var appSettings = AppSettings.sharedInstance()
    
    fileprivate var tempPin: String? = nil
    fileprivate var pinViewController: PinViewController = PinViewController()

    
    override func loadView() {
        super.loadView()

        self.pinViewController.titleLabel.text = NSLocalizedString("Set PIN", comment: "")
        self.pinViewController.delegate = self
        
        self.mainView.addSubview(self.pinViewController.view)
        self.pinViewController.didMove(toParentViewController:self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Delete the temp pin
        tempPin = nil
    }
    
    // MARK: - Pin view delegate
    func pinViewController(_ pinViewController: PinViewController!, pinEntered: String!) {
        if (tempPin == nil) {
            tempPin = pinEntered
            
            pinViewController.titleLabel.text = NSLocalizedString("Confirm PIN", comment: "")
            
            // Clear the PIN entry for confirmation
            pinViewController.clearPin()
        } else if (tempPin == pinEntered) {
            tempPin = nil
            
            // Hash the pin
            let pinHash = PasswordUtils.hashPassword(pinEntered)
            
            // Set the PIN and enable the PIN enabled setting
            appSettings?.setPin(pinHash)
            appSettings?.setPinEnabled(true)
            
            // Remove the PIN view
            // dismiss(animated: true, completion: nil)
            navigationController?.popViewController(animated: true)
        } else {
            tempPin = nil
            
            // Notify the user the PINs they entered did not match
            pinViewController.titleLabel.text = NSLocalizedString("PINs did not match. Try again", comment: "")
            
            // Vibrate the phone
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            
            // Clear the PIN entry to let them try again
            pinViewController.clearPin()
        }
    }
    
}
