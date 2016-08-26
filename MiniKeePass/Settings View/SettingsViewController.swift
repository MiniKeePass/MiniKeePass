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
import LocalAuthentication

class SettingsViewController: UITableViewController, PinViewControllerDelegate {
    @IBOutlet weak var pinEnabledSwitch: UISwitch!
    @IBOutlet weak var pinLockTimeoutCell: UITableViewCell!
    
    @IBOutlet weak var touchIdEnabledCell: UITableViewCell!
    @IBOutlet weak var touchIdEnabledSwitch: UISwitch!
    
    @IBOutlet weak var deleteAllDataEnabledCell: UITableViewCell!
    @IBOutlet weak var deleteAllDataEnabledSwitch: UISwitch!
    @IBOutlet weak var deleteAllDataAttemptsCell: UITableViewCell!
    
    @IBOutlet weak var closeDatabaseEnabledSwitch: UISwitch!
    @IBOutlet weak var closeDatabaseTimeoutCell: UITableViewCell!
    
    @IBOutlet weak var rememberDatabasePasswordsEnabledSwitch: UISwitch!
    
    @IBOutlet weak var hidePasswordsEnabledSwitch: UISwitch!

    @IBOutlet weak var sortingEnabledSwitch: UISwitch!
    
    @IBOutlet weak var passwordEncodingCell: UITableViewCell!
    
    @IBOutlet weak var clearClipboardEnabledSwitch: UISwitch!
    @IBOutlet weak var clearClipboardTimeoutCell: UITableViewCell!
    
    @IBOutlet weak var excludeFromBackupsEnabledSwitch: UISwitch!
    
    @IBOutlet weak var integratedWebBrowserEnabledSwitch: UISwitch!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    private let pinLockTimeouts = [NSLocalizedString("Immediately", comment: ""),
                                   NSLocalizedString("30 Seconds", comment: ""),
                                   NSLocalizedString("1 Minute", comment: ""),
                                   NSLocalizedString("2 Minutes", comment: ""),
                                   NSLocalizedString("5 Minutes", comment: "")]
    
    private let deleteAllDataAttempts = ["3", "5", "10", "15"]
    
    private let closeDatabaseTimeouts = [NSLocalizedString("Immediately", comment: ""),
                                         NSLocalizedString("30 Seconds", comment: ""),
                                         NSLocalizedString("1 Minute", comment: ""),
                                         NSLocalizedString("2 Minutes", comment: ""),
                                         NSLocalizedString("5 Minutes", comment: "")]
    
    private let passwordEncodings = [NSLocalizedString("UTF-8", comment: ""),
                                     NSLocalizedString("UTF-16 Big Endian", comment: ""),
                                     NSLocalizedString("UTF-16 Little Endian", comment: ""),
                                     NSLocalizedString("Latin 1 (ISO/IEC 8859-1)", comment: ""),
                                     NSLocalizedString("Latin 2 (ISO/IEC 8859-2)", comment: ""),
                                     NSLocalizedString("7-Bit ASCII", comment: ""),
                                     NSLocalizedString("Japanese EUC", comment: ""),
                                     NSLocalizedString("ISO-2022-JP", comment: "")]

    private let clearClipboardTimeouts = [NSLocalizedString("30 Seconds", comment: ""),
                                          NSLocalizedString("1 Minute", comment: ""),
                                          NSLocalizedString("2 Minutes", comment: ""),
                                          NSLocalizedString("3 Minutes", comment: "")]
    
    private var appSettings = AppSettings.sharedInstance()
    private var touchIdSupported = false
    private var tempPin: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the version number
        versionLabel.text = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String

        // Check if TouchID is supported
        let laContext = LAContext()
        touchIdSupported = laContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Delete the temp pin
        tempPin = nil
        
        // Initialize all the controls with their settings
        pinEnabledSwitch.on = appSettings.pinEnabled()
        pinLockTimeoutCell.detailTextLabel!.text = pinLockTimeouts[appSettings.pinLockTimeoutIndex()]
        
        touchIdEnabledSwitch.on = touchIdSupported && appSettings.touchIdEnabled()
        
        deleteAllDataEnabledSwitch.on = appSettings.deleteOnFailureEnabled()
        deleteAllDataAttemptsCell.detailTextLabel!.text = deleteAllDataAttempts[appSettings.deleteOnFailureAttemptsIndex()]
        
        closeDatabaseEnabledSwitch.on = appSettings.closeEnabled()
        closeDatabaseTimeoutCell.detailTextLabel!.text = closeDatabaseTimeouts[appSettings.closeTimeoutIndex()]
        
        rememberDatabasePasswordsEnabledSwitch.on = appSettings.rememberPasswordsEnabled()
        
        hidePasswordsEnabledSwitch.on = appSettings.hidePasswords()
        
        sortingEnabledSwitch.on = appSettings.sortAlphabetically()
        
        passwordEncodingCell.detailTextLabel!.text = passwordEncodings[appSettings.passwordEncodingIndex()]
        
        clearClipboardEnabledSwitch.on = appSettings.clearClipboardEnabled()
        clearClipboardTimeoutCell.detailTextLabel!.text = clearClipboardTimeouts[appSettings.clearClipboardTimeoutIndex()]

        excludeFromBackupsEnabledSwitch.on = appSettings.backupDisabled()
        
        integratedWebBrowserEnabledSwitch.on = appSettings.webBrowserIntegrated()
        
        // Update which controls are enabled
        updateEnabledControls()
    }
    
    private func updateEnabledControls() {
        let pinEnabled = appSettings.pinEnabled()
        let deleteOnFailureEnabled = appSettings.deleteOnFailureEnabled()
        let closeEnabled = appSettings.closeEnabled()
        let clearClipboardEnabled = appSettings.clearClipboardEnabled()
        
         // Enable/disable the components dependant on settings
        setCellEnabled(pinLockTimeoutCell, enabled: pinEnabled)
        setCellEnabled(touchIdEnabledCell, enabled: pinEnabled && touchIdSupported)
        touchIdEnabledSwitch.enabled = pinEnabled && touchIdSupported
        setCellEnabled(deleteAllDataEnabledCell, enabled: pinEnabled)
        setCellEnabled(deleteAllDataAttemptsCell, enabled: pinEnabled && deleteOnFailureEnabled)
        setCellEnabled(closeDatabaseTimeoutCell, enabled: closeEnabled)
        setCellEnabled(clearClipboardTimeoutCell, enabled: clearClipboardEnabled)
    }
    
    private func setCellEnabled(cell: UITableViewCell, enabled: Bool) {
        cell.selectionStyle = enabled ? UITableViewCellSelectionStyle.Blue : UITableViewCellSelectionStyle.None
        cell.textLabel!.enabled = enabled
        cell.detailTextLabel?.enabled = enabled
    }

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // Only allow these segues if the setting is enabled
        if (identifier == "PIN Lock Timeout") {
            return pinEnabledSwitch.on
        } else if (identifier == "Delete All Data Attempts") {
            return deleteAllDataEnabledSwitch.on
        } else if (identifier == "Close Database Timeout") {
            return closeDatabaseEnabledSwitch.on
        } else if (identifier == "Clear Clipboard Timeout") {
            return clearClipboardEnabledSwitch.on
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let selectionViewController = segue.destinationViewController as! SelectionViewController
        if (segue.identifier == "PIN Lock Timeout") {
            selectionViewController.items = pinLockTimeouts
            selectionViewController.selectedIndex = appSettings.pinLockTimeoutIndex()
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings.setPinLockTimeoutIndex(selectedIndex)
                self.navigationController?.popViewControllerAnimated(true)
            }
        } else if (segue.identifier == "Delete All Data Attempts") {
            selectionViewController.items = deleteAllDataAttempts
            selectionViewController.selectedIndex = appSettings.deleteOnFailureAttemptsIndex()
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings.setDeleteOnFailureAttemptsIndex(selectedIndex)
                self.navigationController?.popViewControllerAnimated(true)
            }
        } else if (segue.identifier == "Close Database Timeout") {
            selectionViewController.items = closeDatabaseTimeouts
            selectionViewController.selectedIndex = appSettings.closeTimeoutIndex()
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings.setCloseTimeoutIndex(selectedIndex)
                self.navigationController?.popViewControllerAnimated(true)
            }
        } else if (segue.identifier == "Password Encoding") {
            selectionViewController.items = passwordEncodings
            selectionViewController.selectedIndex = appSettings.passwordEncodingIndex()
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings.setPasswordEncodingIndex(selectedIndex)
                self.navigationController?.popViewControllerAnimated(true)
            }
        } else if (segue.identifier == "Clear Clipboard Timeout") {
            selectionViewController.items = clearClipboardTimeouts
            selectionViewController.selectedIndex = appSettings.clearClipboardTimeoutIndex()
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings.setClearClipboardTimeoutIndex(selectedIndex)
                self.navigationController?.popViewControllerAnimated(true)
            }
        } else {
            assertionFailure("Unknown segue")
        }
    }
    
    // MARK: - Actions
    
    @IBAction func donePressedAction(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func pinEnabledChanged(sender: UISwitch) {
        if (pinEnabledSwitch.on) {
            let pinViewController = PinViewController()
            pinViewController.titleLabel.text = NSLocalizedString("Set PIN", comment: "")
            pinViewController.delegate = self
            
            presentViewController(pinViewController, animated: true, completion: nil)
        } else {
            self.appSettings.setPinEnabled(false)
            
            // Delete the PIN from the keychain
            KeychainUtils.deleteStringForKey("PIN", andServiceName: KEYCHAIN_PIN_SERVICE)
            
            // Update which controls are enabled
            updateEnabledControls()
        }
    }
    
    @IBAction func touchIdEnabledChanged(sender: UISwitch) {
        self.appSettings.setTouchIdEnabled(touchIdEnabledSwitch.on)
    }
    
    @IBAction func deleteAllDataEnabledChanged(sender: UISwitch) {
        self.appSettings.setDeleteOnFailureEnabled(deleteAllDataEnabledSwitch.on)
        
        // Update which controls are enabled
        updateEnabledControls()
    }
    
    @IBAction func closeDatabaseEnabledChanged(sender: UISwitch) {
        self.appSettings.setCloseEnabled(closeDatabaseEnabledSwitch.on)

        // Update which controls are enabled
        updateEnabledControls()
    }
    
    @IBAction func rememberDatabasePasswordsEnabledChanged(sender: UISwitch) {
        self.appSettings.setRememberPasswordsEnabled(rememberDatabasePasswordsEnabledSwitch.on)
        
        KeychainUtils.deleteAllForServiceName(KEYCHAIN_PASSWORDS_SERVICE)
        KeychainUtils.deleteAllForServiceName(KEYCHAIN_KEYFILES_SERVICE)
    }
    
    @IBAction func hidePasswordsEnabledChanged(sender: UISwitch) {
        self.appSettings.setHidePasswords(hidePasswordsEnabledSwitch.on)
    }
    
    @IBAction func sortingEnabledChanged(sender: UISwitch) {
        self.appSettings.setSortAlphabetically(sortingEnabledSwitch.on)
    }
    
    @IBAction func clearClipboardEnabledChanged(sender: UISwitch) {
        self.appSettings.setClearClipboardEnabled(clearClipboardEnabledSwitch.on)
        
        // Update which controls are enabled
        updateEnabledControls()
    }
    
    @IBAction func excludeFromBackupEnabledChanged(sender: UISwitch) {
        self.appSettings.setBackupDisabled(excludeFromBackupsEnabledSwitch.on)
    }
    
    @IBAction func integratedWebBrowserEnabledChanged(sender: UISwitch) {
        self.appSettings.setWebBrowserIntegrated(integratedWebBrowserEnabledSwitch.on)
    }
    
    // MARK: - Pin view delegate
    func pinViewController(pinViewController: PinViewController!, pinEntered: String!) {
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
            appSettings.setPin(pinHash)
            appSettings.setPinEnabled(true)
            
            // Update which controls are enabled
            updateEnabledControls()
            
            // Remove the PIN view
            dismissViewControllerAnimated(true, completion: nil)
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
