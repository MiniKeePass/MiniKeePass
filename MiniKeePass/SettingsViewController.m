/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
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

#import <AudioToolbox/AudioToolbox.h>
#import "MiniKeePassAppDelegate.h"
#import "SettingsViewController.h"
#import "SelectionListViewController.h"
#import "SFHFKeychainUtils.h"

enum {
    SECTION_PIN,
    SECTION_DELETE_ON_FAILURE,
    SECTION_REMEMBER_PASSWORDS,
    SECTION_HIDE_PASSWORDS,
    SECTION_NUMBER
};

enum {
    ROW_PIN_ENABLED,
    ROW_PIN_LOCK_TIMEOUT,
    ROW_PIN_NUMBER
};

enum {
    ROW_DELETE_ON_FAILURE_ENABLED,
    ROW_DELETE_ON_FAILURE_ATTEMPTS,
    ROW_DELETE_ON_FAILURE_NUMBER
};

enum {
    ROW_REMEMBER_PASSWORDS_ENABLED,
    ROW_REMEMBER_PASSWORDS_NUMBER
};

enum {
    ROW_HIDE_PASSWORDS_ENABLED,
    ROW_HIDE_PASSWORDS_NUMBER
};

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Settings";
    
    pinEnabledCell = [[SwitchCell alloc] initWithLabel:@"Pin Enabled"];
    [pinEnabledCell.switchControl addTarget:self action:@selector(togglePinEnabled:) forControlEvents:UIControlEventValueChanged];
    
    pinLockTimeoutCell = [[ChoiceCell alloc] initWithLabel:@"Lock Timeout" choices:[NSArray arrayWithObjects:@"Immediately", @"30 Seconds", @"1 Minute", @"2 Minutes", @"5 Minutes", nil] selectedIndex:0];
    
    deleteOnFailureEnabledCell = [[SwitchCell alloc] initWithLabel:@"Enabled"];
    [deleteOnFailureEnabledCell.switchControl addTarget:self action:@selector(toggleDeleteOnFailureEnabled:) forControlEvents:UIControlEventValueChanged];    
    
    deleteOnFailureAttemptsCell = [[ChoiceCell alloc] initWithLabel:@"Attempts" choices:[NSArray arrayWithObjects:@"3", @"5", @"10", @"15", nil] selectedIndex:0];
    
    rememberPasswordsEnabledCell = [[SwitchCell alloc] initWithLabel:@"Enabled"];
    [rememberPasswordsEnabledCell.switchControl addTarget:self action:@selector(toggleRememberPasswords:) forControlEvents:UIControlEventValueChanged];
    
    hidePasswordsCell = [[SwitchCell alloc] initWithLabel:@"Hide Passwords"];
    [hidePasswordsCell.switchControl addTarget:self action:@selector(toggleHidePasswords:) forControlEvents:UIControlEventValueChanged];
}

- (void)dealloc {
    [pinEnabledCell release];
    [pinLockTimeoutCell release];
    [deleteOnFailureEnabledCell release];
    [deleteOnFailureAttemptsCell release];
    [rememberPasswordsEnabledCell release];
    [hidePasswordsCell release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Delete the temp pin
    [tempPin release];
    tempPin = nil;
    
    // Initialize all the controls with their settings
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    pinEnabledCell.switchControl.on = [userDefaults boolForKey:@"pinEnabled"];
    [pinLockTimeoutCell setSelectedIndex:[userDefaults integerForKey:@"pinLockTimeout"]];
    deleteOnFailureEnabledCell.switchControl.on = [userDefaults boolForKey:@"deleteOnFailureEnabled"];
    [deleteOnFailureAttemptsCell setSelectedIndex:[userDefaults integerForKey:@"deleteOnFailureAttempts"]];
    rememberPasswordsEnabledCell.switchControl.on = [userDefaults boolForKey:@"rememberPasswordsEnabled"];
    hidePasswordsCell.switchControl.on = [userDefaults boolForKey:@"hidePasswords"];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)updateEnabledControls {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL pinEnabled = [userDefaults boolForKey:@"pinEnabled"];
    BOOL deleteOnFailureEnabled = [userDefaults boolForKey:@"deleteOnFailureEnabled"];
    
    // Enable/disable the components dependant on settings
    [pinLockTimeoutCell setEnabled:pinEnabled];
    [deleteOnFailureEnabledCell setEnabled:pinEnabled];
    [deleteOnFailureAttemptsCell setEnabled:pinEnabled && deleteOnFailureEnabled];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_NUMBER;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SECTION_PIN:
            return ROW_PIN_NUMBER;
            
        case SECTION_DELETE_ON_FAILURE:
            return ROW_DELETE_ON_FAILURE_NUMBER;
            
        case SECTION_REMEMBER_PASSWORDS:
            return ROW_REMEMBER_PASSWORDS_NUMBER;
            
        case SECTION_HIDE_PASSWORDS:
            return ROW_HIDE_PASSWORDS_NUMBER;
    }
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_PIN:
            return @"PIN Protection";
            
        case SECTION_DELETE_ON_FAILURE:
            return @"Delete All Data on PIN Failure";
            
        case SECTION_REMEMBER_PASSWORDS:
            return @"Remember Database Passwords";
            
        case SECTION_HIDE_PASSWORDS:
            return @"General";
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case SECTION_PIN:
            switch (indexPath.row) {
                case ROW_PIN_ENABLED:
                    return pinEnabledCell;
                case ROW_PIN_LOCK_TIMEOUT:
                    return pinLockTimeoutCell;
            }
            break;
            
        case SECTION_DELETE_ON_FAILURE:
            switch (indexPath.row) {
                case ROW_DELETE_ON_FAILURE_ENABLED:
                    return deleteOnFailureEnabledCell;
                case ROW_DELETE_ON_FAILURE_ATTEMPTS:
                    return deleteOnFailureAttemptsCell;
                    break;
            }
            break;
            
        case SECTION_REMEMBER_PASSWORDS:
            switch (indexPath.row) {
                case ROW_REMEMBER_PASSWORDS_ENABLED:
                    return rememberPasswordsEnabledCell;
            }
            break;
            
        case SECTION_HIDE_PASSWORDS:
            switch (indexPath.row) {
                case ROW_HIDE_PASSWORDS_ENABLED:
                    return hidePasswordsCell;
            }
            break;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_PIN && indexPath.row == ROW_PIN_LOCK_TIMEOUT && pinEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = @"Lock Timeout";
        selectionListViewController.items = pinLockTimeoutCell.choices;
        selectionListViewController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"pinLockTimeout"];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
        [selectionListViewController release];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS && deleteOnFailureEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = @"Attempts";
        selectionListViewController.items = deleteOnFailureAttemptsCell.choices;
        selectionListViewController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"deleteOnFailureAttempts"];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
        [selectionListViewController release];
    }
}

- (void)selectionListViewController:(SelectionListViewController *)controller selectedIndex:(NSInteger)selectedIndex withReference:(id<NSObject>)reference {
    NSIndexPath *indexPath = (NSIndexPath*)reference;
    if (indexPath.section == SECTION_PIN && indexPath.row == ROW_PIN_LOCK_TIMEOUT) {
        // Save the user setting
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:selectedIndex forKey:@"pinLockTimeout"];
        
        // Update the cell text
        [pinLockTimeoutCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS) {
        // Save the user setting
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:selectedIndex forKey:@"deleteOnFailureAttempts"];
        
        // Update the cell text
        [deleteOnFailureAttemptsCell setSelectedIndex:selectedIndex];
    }
}

- (void)togglePinEnabled:(id)sender {
    if (pinEnabledCell.switchControl.on) {
        PinViewController *pinViewController = [[PinViewController alloc] initWithText:@"Set PIN"];
        pinViewController.delegate = self;
        [self presentModalViewController:pinViewController animated:YES];
        [pinViewController release];
    } else {
        // Delete the PIN and disable the PIN enabled setting
        [SFHFKeychainUtils deleteItemForUsername:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin" error:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"pinEnabled"];
        
        // Update which controls are enabled
        [self updateEnabledControls];
    }
}

- (void)toggleDeleteOnFailureEnabled:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:deleteOnFailureEnabledCell.switchControl.on forKey:@"deleteOnFailureEnabled"];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleRememberPasswords:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:rememberPasswordsEnabledCell.switchControl.on forKey:@"rememberPasswordsEnabled"];
    
    // Delete all database passwords from the keychain
    [SFHFKeychainUtils deleteAllItemForServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
}

- (void)toggleHidePasswords:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:hidePasswordsCell.switchControl.on forKey:@"hidePasswords"];
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {        
    if (tempPin == nil) {
        tempPin = [pin copy];
        
        controller.textLabel.text = @"Confirm PIN";
        
        // Clear the PIN entry for confirmation
        [controller clearEntry];
    } else if ([tempPin isEqualToString:pin]) {
        [tempPin release];
        tempPin = nil;
        
        // Set the PIN and enable the PIN enabled setting
        [SFHFKeychainUtils storeUsername:@"PIN" andPassword:pin forServiceName:@"com.jflan.MiniKeePass.pin" updateExisting:YES error:nil];
        [[NSUserDefaults standardUserDefaults] setBool:pinEnabledCell.switchControl.on forKey:@"pinEnabled"];
        
        // Update which controls are enabled
        [self updateEnabledControls];
        
        // Remove the PIN view
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [tempPin release];
        tempPin = nil;
        
        // Notify the user the PINs they entered did not match
        controller.textLabel.text = @"PINs did not match. Try again";
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        // Clear the PIN entry to let them try again
        [controller clearEntry];
    }
}

@end
