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
    
    @IBOutlet weak var biometricIdEnabledCell: UITableViewCell!
    @IBOutlet weak var biometricIdLabel: UILabel!
    @IBOutlet weak var biometricIdEnabledSwitch: UISwitch!
    
    @IBOutlet weak var deleteAllDataEnabledCell: UITableViewCell!
    @IBOutlet weak var deleteAllDataEnabledLabel: UILabel!
    @IBOutlet weak var deleteAllDataEnabledSwitch: UISwitch!
    @IBOutlet weak var deleteAllDataAttemptsCell: UITableViewCell!
    
    @IBOutlet weak var closeDatabaseEnabledSwitch: UISwitch!
    @IBOutlet weak var closeDatabaseTimeoutCell: UITableViewCell!
    
    @IBOutlet weak var rememberDatabasePasswordsCell: UITableViewCell!
    
    @IBOutlet weak var hidePasswordsEnabledSwitch: UISwitch!

    @IBOutlet weak var sortingEnabledSwitch: UISwitch!

    @IBOutlet weak var searchTitleOnlySwitch: UISwitch!
    
    @IBOutlet weak var passwordEncodingCell: UITableViewCell!
    
    @IBOutlet weak var clearClipboardEnabledSwitch: UISwitch!
    @IBOutlet weak var clearClipboardTimeoutCell: UITableViewCell!
    
    @IBOutlet weak var excludeFromBackupsEnabledSwitch: UISwitch!
    
    @IBOutlet weak var integratedWebBrowserEnabledSwitch: UISwitch!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    fileprivate let pinLockTimeouts = [NSLocalizedString("Immediately", comment: ""),
                                   NSLocalizedString("30 Seconds", comment: ""),
                                   NSLocalizedString("1 Minute", comment: ""),
                                   NSLocalizedString("2 Minutes", comment: ""),
                                   NSLocalizedString("5 Minutes", comment: "")]

    fileprivate let rememberPasswords = [NSLocalizedString("Never", comment: ""),
                                         NSLocalizedString("When Configured", comment: ""),
                                         NSLocalizedString("Always", comment: "")]
    
    fileprivate let deleteAllDataAttempts = ["3", "5", "10", "15"]
    
    fileprivate let closeDatabaseTimeouts = [NSLocalizedString("Immediately", comment: ""),
                                         NSLocalizedString("30 Seconds", comment: ""),
                                         NSLocalizedString("1 Minute", comment: ""),
                                         NSLocalizedString("2 Minutes", comment: ""),
                                         NSLocalizedString("5 Minutes", comment: "")]
    
    fileprivate let passwordEncodings = [NSLocalizedString("UTF-8", comment: ""),
                                     NSLocalizedString("UTF-16 Big Endian", comment: ""),
                                     NSLocalizedString("UTF-16 Little Endian", comment: ""),
                                     NSLocalizedString("Latin 1 (ISO/IEC 8859-1)", comment: ""),
                                     NSLocalizedString("Latin 2 (ISO/IEC 8859-2)", comment: ""),
                                     NSLocalizedString("7-Bit ASCII", comment: ""),
                                     NSLocalizedString("Japanese EUC", comment: ""),
                                     NSLocalizedString("ISO-2022-JP", comment: "")]

    fileprivate let clearClipboardTimeouts = [NSLocalizedString("30 Seconds", comment: ""),
                                          NSLocalizedString("1 Minute", comment: ""),
                                          NSLocalizedString("2 Minutes", comment: ""),
                                          NSLocalizedString("3 Minutes", comment: "")]
    
    fileprivate var appSettings = AppSettings.sharedInstance()
    fileprivate var biometricIdSupported = false
    fileprivate var tempPin: String? = nil
    
    // This is used for compatiblity of biometric IDs prior to iOS 11
    fileprivate enum BiometricType {
        case none
        case touch
        case face
    }

    // This is used for compatiblity of biometric IDs prior to iOS 11
    fileprivate func biometricType() -> BiometricType {
        let authContext = LAContext()
        if #available(iOS 11, *) {
            let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch(authContext.biometryType) {
            case .none:
                return .none
            case .touchID:
                return .touch
            case .faceID:
                return .face
            }
        } else {
            return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touch : .none
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the version number
        versionLabel.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        // Check if Biometric ID is supported
        let laContext = LAContext()
        biometricIdSupported = laContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil)
        
        switch (biometricType()) {
        case .none:
            biometricIdLabel.text = NSLocalizedString("Biometric ID", comment: "")
        case .touch:
            biometricIdLabel.text = NSLocalizedString("Touch ID", comment: "")
        case .face:
            biometricIdLabel.text = NSLocalizedString("Face ID", comment: "")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Delete the temp pin
        tempPin = nil
        
        if let appSettings = appSettings {
            // Initialize all the controls with their settings
            pinEnabledSwitch.isOn = appSettings.pinEnabled()
            pinLockTimeoutCell.detailTextLabel!.text = pinLockTimeouts[appSettings.pinLockTimeoutIndex()]
            
            biometricIdEnabledSwitch.isOn = biometricIdSupported && appSettings.biometricIdEnabled()
            
            deleteAllDataEnabledSwitch.isOn = appSettings.deleteOnFailureEnabled()
            deleteAllDataAttemptsCell.detailTextLabel!.text = deleteAllDataAttempts[appSettings.deleteOnFailureAttemptsIndex()]
            
            closeDatabaseEnabledSwitch.isOn = appSettings.closeEnabled()
            closeDatabaseTimeoutCell.detailTextLabel!.text = closeDatabaseTimeouts[appSettings.closeTimeoutIndex()]
            
            rememberDatabasePasswordsCell.detailTextLabel!.text = rememberPasswords[appSettings.rememberPasswordsIndex()]
            
            hidePasswordsEnabledSwitch.isOn = appSettings.hidePasswords()
            
            sortingEnabledSwitch.isOn = appSettings.sortAlphabetically()

            searchTitleOnlySwitch.isOn = appSettings.searchTitleOnly()
            
            passwordEncodingCell.detailTextLabel!.text = passwordEncodings[appSettings.passwordEncodingIndex()]
            
            clearClipboardEnabledSwitch.isOn = appSettings.clearClipboardEnabled()
            clearClipboardTimeoutCell.detailTextLabel!.text = clearClipboardTimeouts[appSettings.clearClipboardTimeoutIndex()]
            
            excludeFromBackupsEnabledSwitch.isOn = appSettings.backupDisabled()
            
            integratedWebBrowserEnabledSwitch.isOn = appSettings.webBrowserIntegrated()
        }
        
        // Update which controls are enabled
        updateEnabledControls()
    }
    
    fileprivate func updateEnabledControls() {
        guard let appSettings = appSettings else {
            return
        }
        
        let pinEnabled = appSettings.pinEnabled()
        let deleteOnFailureEnabled = appSettings.deleteOnFailureEnabled()
        let closeEnabled = appSettings.closeEnabled()
        let clearClipboardEnabled = appSettings.clearClipboardEnabled()
        
         // Enable/disable the components dependant on settings
        setCellEnabled(pinLockTimeoutCell, enabled: pinEnabled)
        setCellEnabled(biometricIdEnabledCell, enabled: pinEnabled && biometricIdSupported)
        biometricIdLabel.isEnabled = pinEnabled && biometricIdSupported
        biometricIdEnabledSwitch.isEnabled = pinEnabled && biometricIdSupported
        setCellEnabled(deleteAllDataEnabledCell, enabled: pinEnabled)
        deleteAllDataEnabledLabel.isEnabled = pinEnabled
        deleteAllDataEnabledSwitch.isEnabled = pinEnabled
        setCellEnabled(deleteAllDataAttemptsCell, enabled: pinEnabled && deleteOnFailureEnabled)
        setCellEnabled(closeDatabaseTimeoutCell, enabled: closeEnabled)
        setCellEnabled(clearClipboardTimeoutCell, enabled: clearClipboardEnabled)
    }
    
    fileprivate func setCellEnabled(_ cell: UITableViewCell, enabled: Bool) {
        cell.selectionStyle = enabled ? UITableViewCellSelectionStyle.blue : UITableViewCellSelectionStyle.none
        cell.textLabel!.isEnabled = enabled
        cell.detailTextLabel?.isEnabled = enabled
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // Only allow these segues if the setting is enabled
        if (identifier == "PIN Lock Timeout") {
            return pinEnabledSwitch.isOn
        } else if (identifier == "Delete All Data Attempts") {
            return deleteAllDataEnabledSwitch.isOn && pinEnabledSwitch.isOn
        } else if (identifier == "Close Database Timeout") {
            return closeDatabaseEnabledSwitch.isOn
        } else if (identifier == "Clear Clipboard Timeout") {
            return clearClipboardEnabledSwitch.isOn
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectionViewController = segue.destination as! SelectionViewController
        if (segue.identifier == "PIN Lock Timeout") {
            selectionViewController.items = pinLockTimeouts
            selectionViewController.selectedIndex = (appSettings?.pinLockTimeoutIndex())!
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings?.setPinLockTimeoutIndex(selectedIndex)
                self.navigationController?.popViewController(animated: true)
            }
        } else if (segue.identifier == "Delete All Data Attempts") {
            selectionViewController.items = deleteAllDataAttempts
            selectionViewController.selectedIndex = (appSettings?.deleteOnFailureAttemptsIndex())!
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings?.setDeleteOnFailureAttemptsIndex(selectedIndex)
                self.navigationController?.popViewController(animated: true)
            }
        } else if (segue.identifier == "Close Database Timeout") {
            selectionViewController.items = closeDatabaseTimeouts
            selectionViewController.selectedIndex = (appSettings?.closeTimeoutIndex())!
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings?.setCloseTimeoutIndex(selectedIndex)
                self.navigationController?.popViewController(animated: true)
            }
        } else if (segue.identifier == "Password Encoding") {
            selectionViewController.items = passwordEncodings
            selectionViewController.selectedIndex = (appSettings?.passwordEncodingIndex())!
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings?.setPasswordEncoding(selectedIndex)
                self.navigationController?.popViewController(animated: true)
            }
        } else if (segue.identifier == "Clear Clipboard Timeout") {
            selectionViewController.items = clearClipboardTimeouts
            selectionViewController.selectedIndex = (appSettings?.clearClipboardTimeoutIndex())!
            selectionViewController.itemSelected = { (selectedIndex) in
                self.appSettings?.setClearClipboardTimeoutIndex(selectedIndex)
                self.navigationController?.popViewController(animated: true)
            }
        } else if (segue.identifier == "Remember Passwords") {
            selectionViewController.items = rememberPasswords
            selectionViewController.selectedIndex = (appSettings?.rememberPasswordsIndex())!
            selectionViewController.itemSelected = { (selectedIndex) in

                self.appSettings?.setRememberPasswordsIndex(selectedIndex)
                let rememberPasswords = self.appSettings?.rememberPasswords()
                switch rememberPasswords {
                case .some(RememberPasswords.Always), .some(RememberPasswords.WhenConfigured):
                    break;
                case .some(RememberPasswords.Never), .none:
                    KeychainUtils.deleteAll(forServiceName: KEYCHAIN_PASSWORDS_SERVICE)
                    KeychainUtils.deleteAll(forServiceName: KEYCHAIN_KEYFILES_SERVICE)
                }

                self.navigationController?.popViewController(animated: true)
            }
        } else {
            assertionFailure("Unknown segue")
        }
    }
    
    // MARK: - Actions
    
    @IBAction func donePressedAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pinEnabledChanged(_ sender: UISwitch) {
        if (pinEnabledSwitch.isOn) {
            let pinViewController = PinViewController()
            pinViewController.titleLabel.text = NSLocalizedString("Set PIN", comment: "")
            pinViewController.delegate = self
            
            // Background is clear for lock screen blur, set to white to set the pin.
            pinViewController.view.backgroundColor = UIColor.white
            
            present(pinViewController, animated: true, completion: nil)
        } else {
            self.appSettings?.setPinEnabled(false)
            
            // Delete the PIN from the keychain
            KeychainUtils.deleteString(forKey: "PIN", andServiceName: KEYCHAIN_PIN_SERVICE)
            
            // Update which controls are enabled
            updateEnabledControls()
        }
    }
    
    @IBAction func biometricIdEnabledChanged(_ sender: UISwitch) {
        self.appSettings?.setBiometricIdEnabled(biometricIdEnabledSwitch.isOn)
    }
    
    @IBAction func deleteAllDataEnabledChanged(_ sender: UISwitch) {
        self.appSettings?.setDeleteOnFailureEnabled(deleteAllDataEnabledSwitch.isOn)
        
        // Update which controls are enabled
        updateEnabledControls()
    }
    
    @IBAction func closeDatabaseEnabledChanged(_ sender: UISwitch) {
        self.appSettings?.setCloseEnabled(closeDatabaseEnabledSwitch.isOn)

        // Update which controls are enabled
        updateEnabledControls()
    }
    
    @IBAction func hidePasswordsEnabledChanged(_ sender: UISwitch) {
        self.appSettings?.setHidePasswords(hidePasswordsEnabledSwitch.isOn)
    }
    
    @IBAction func sortingEnabledChanged(_ sender: UISwitch) {
        self.appSettings?.setSortAlphabetically(sortingEnabledSwitch.isOn)
    }

    @IBAction func searchTitleOnlyChanged(_ sender: UISwitch) {
        self.appSettings?.setSearchTitleOnly(searchTitleOnlySwitch.isOn)
    }

    @IBAction func clearClipboardEnabledChanged(_ sender: UISwitch) {
        self.appSettings?.setClearClipboardEnabled(clearClipboardEnabledSwitch.isOn)
        
        // Update which controls are enabled
        updateEnabledControls()
    }
    
    @IBAction func excludeFromBackupEnabledChanged(_ sender: UISwitch) {
        self.appSettings?.setBackupDisabled(excludeFromBackupsEnabledSwitch.isOn)
    }
    
    @IBAction func integratedWebBrowserEnabledChanged(_ sender: UISwitch) {
        self.appSettings?.setWebBrowserIntegrated(integratedWebBrowserEnabledSwitch.isOn)
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
            
            // Update which controls are enabled
            updateEnabledControls()
            
            // Remove the PIN view
            dismiss(animated: true, completion: nil)
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
