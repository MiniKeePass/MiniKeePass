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
#import "DirectoryChoiceViewController.h"
#import "SFHFKeychainUtils.h"

enum {
    SECTION_PIN,
    SECTION_DELETE_ON_FAILURE,
    SECTION_CLOSE,
    SECTION_REMEMBER_PASSWORDS,
    SECTION_HIDE_PASSWORDS,
    SECTION_DROPBOX,
    SECTION_PASSWORD_ENCODING,
    SECTION_CLEAR_CLIPBOARD,
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
    ROW_CLOSE_ENABLED,
    ROW_CLOSE_TIMEOUT,
    ROW_CLOSE_NUMBER
};

enum {
    ROW_REMEMBER_PASSWORDS_ENABLED,
    ROW_REMEMBER_PASSWORDS_NUMBER
};

enum {
    ROW_HIDE_PASSWORDS_ENABLED,
    ROW_HIDE_PASSWORDS_NUMBER
};

enum {
    ROW_UNLINKED_DROPBOX_LINK_BUTTON,
    ROW_UNLINKED_DROPBOX_NUMBER
};

enum {
    ROW_LINKED_DROPBOX_DIRECTORY_BUTTON,
    ROW_LINKED_DROPBOX_UNLINK_BUTTON,
    ROW_LINKED_DROPBOX_NUMBER
};

enum {
    ROW_PASSWORD_ENCODING_VALUE,
    ROW_PASSWORD_ENCODING_NUMBER
};

enum {
    ROW_CLEAR_CLIPBOARD_ENABLED,
    ROW_CLEAR_CLIPBOARD_TIMEOUT,
    ROW_CLEAR_CLIPBOARD_NUMBER
};

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", nil);
    
    pinEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"PIN Enabled", nil)];
    [pinEnabledCell.switchControl addTarget:self action:@selector(togglePinEnabled:) forControlEvents:UIControlEventValueChanged];
    
    pinLockTimeoutCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Lock Timeout", nil) choices:[NSArray arrayWithObjects:NSLocalizedString(@"Immediately", nil), NSLocalizedString(@"30 Seconds", nil), NSLocalizedString(@"1 Minute", nil), NSLocalizedString(@"2 Minutes", nil), NSLocalizedString(@"5 Minutes", nil), nil] selectedIndex:0];
    
    deleteOnFailureEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [deleteOnFailureEnabledCell.switchControl addTarget:self action:@selector(toggleDeleteOnFailureEnabled:) forControlEvents:UIControlEventValueChanged];    
    
    deleteOnFailureAttemptsCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Attempts", nil) choices:[NSArray arrayWithObjects:@"3", @"5", @"10", @"15", nil] selectedIndex:0];
    
    closeEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Close Enabled", nil)];
    [closeEnabledCell.switchControl addTarget:self action:@selector(toggleCloseEnabled:) forControlEvents:UIControlEventValueChanged];
    
    closeTimeoutCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Close Timeout", nil) choices:[NSArray arrayWithObjects:NSLocalizedString(@"Immediately", nil), NSLocalizedString(@"30 Seconds", nil), NSLocalizedString(@"1 Minute", nil), NSLocalizedString(@"2 Minutes", nil), NSLocalizedString(@"5 Minutes", nil), nil] selectedIndex:0];
    
    rememberPasswordsEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [rememberPasswordsEnabledCell.switchControl addTarget:self action:@selector(toggleRememberPasswords:) forControlEvents:UIControlEventValueChanged];
    
    hidePasswordsCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Hide Passwords", nil)];
    [hidePasswordsCell.switchControl addTarget:self action:@selector(toggleHidePasswords:) forControlEvents:UIControlEventValueChanged];
    
    dropboxLinkCell = [[ButtonCell alloc] initWithLabel:@"Link"];
    dropboxUnlinkCell = [[ButtonCell alloc] initWithLabel:@"Unink"];
    
    dropboxDirectoryCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    dropboxDirectoryCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    passwordEncodingCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Encoding", nil) choices:[NSArray arrayWithObjects:NSLocalizedString(@"UTF-8", nil), NSLocalizedString(@"UTF-16 Big Endian", nil), NSLocalizedString(@"UTF-16 Little Endian", nil), NSLocalizedString(@"Latin 1 (ISO/IEC 8859-1)", nil), NSLocalizedString(@"Latin 2 (ISO/IEC 8859-2)", nil), NSLocalizedString(@"7-Bit ASCII", nil), NSLocalizedString(@"Japanese EUC", nil), NSLocalizedString(@"ISO-2022-JP", nil), nil] selectedIndex:0];

    clearClipboardEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [clearClipboardEnabledCell.switchControl addTarget:self action:@selector(toggleClearClipboardEnabled:) forControlEvents:UIControlEventValueChanged];
    
    clearClipboardTimeoutCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Clear Timeout", nil) choices:[NSArray arrayWithObjects:NSLocalizedString(@"30 Seconds", nil), NSLocalizedString(@"1 Minute", nil), NSLocalizedString(@"2 Minutes", nil), NSLocalizedString(@"3 Minutes", nil), nil] selectedIndex:0];
}

- (void)dealloc {
    [pinEnabledCell release];
    [pinLockTimeoutCell release];
    [deleteOnFailureEnabledCell release];
    [deleteOnFailureAttemptsCell release];
    [closeEnabledCell release];
    [closeTimeoutCell release];
    [rememberPasswordsEnabledCell release];
    [hidePasswordsCell release];
    [dropboxLinkCell release];
    [passwordEncodingCell release];
    [clearClipboardEnabledCell release];
    [clearClipboardTimeoutCell release];
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
    
    closeEnabledCell.switchControl.on = [userDefaults boolForKey:@"closeEnabled"];
    [closeTimeoutCell setSelectedIndex:[userDefaults integerForKey:@"closeTimeout"]];
    
    rememberPasswordsEnabledCell.switchControl.on = [userDefaults boolForKey:@"rememberPasswordsEnabled"];
    
    hidePasswordsCell.switchControl.on = [userDefaults boolForKey:@"hidePasswords"];
    
    [passwordEncodingCell setSelectedIndex:[userDefaults integerForKey:@"passwordEncoding"]];
    
    clearClipboardEnabledCell.switchControl.on = [userDefaults boolForKey:@"clearClipboardEnabled"];
    [clearClipboardTimeoutCell setSelectedIndex:[userDefaults integerForKey:@"clearClipboardTimeout"]];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_DROPBOX] withRowAnimation:UITableViewRowAnimationNone];
    
    dropboxDirectory = [userDefaults stringForKey:@"dropboxDirectory"];
    dropboxDirectoryCell.textLabel.text = [NSString stringWithFormat:@"Folder: %@", dropboxDirectory];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)updateEnabledControls {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL pinEnabled = [userDefaults boolForKey:@"pinEnabled"];
    BOOL deleteOnFailureEnabled = [userDefaults boolForKey:@"deleteOnFailureEnabled"];
    BOOL closeEnabled = [userDefaults boolForKey:@"closeEnabled"];
    BOOL clearClipboardEnabled = [userDefaults boolForKey:@"clearClipboardEnabled"];
    
    // Enable/disable the components dependant on settings
    [pinLockTimeoutCell setEnabled:pinEnabled];
    [deleteOnFailureEnabledCell setEnabled:pinEnabled];
    [deleteOnFailureAttemptsCell setEnabled:pinEnabled && deleteOnFailureEnabled];
    [closeTimeoutCell setEnabled:closeEnabled];
    [clearClipboardTimeoutCell setEnabled:clearClipboardEnabled];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.backgroundSupported) {
        return SECTION_NUMBER - 1;
    }
    
    return SECTION_NUMBER;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SECTION_PIN:
            return ROW_PIN_NUMBER;
            
        case SECTION_DELETE_ON_FAILURE:
            return ROW_DELETE_ON_FAILURE_NUMBER;
            
        case SECTION_CLOSE:
            return ROW_CLOSE_NUMBER;
            
        case SECTION_REMEMBER_PASSWORDS:
            return ROW_REMEMBER_PASSWORDS_NUMBER;
            
        case SECTION_HIDE_PASSWORDS:
            return ROW_HIDE_PASSWORDS_NUMBER;
            
        case SECTION_DROPBOX:
            return [[DBSession sharedSession] isLinked] ? ROW_LINKED_DROPBOX_NUMBER : ROW_UNLINKED_DROPBOX_NUMBER;
        
        case SECTION_PASSWORD_ENCODING:
            return ROW_PASSWORD_ENCODING_NUMBER;
            
        case SECTION_CLEAR_CLIPBOARD:
            return ROW_CLEAR_CLIPBOARD_NUMBER;
    }
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_PIN:
            return NSLocalizedString(@"PIN Protection", nil);
            
        case SECTION_DELETE_ON_FAILURE:
            return NSLocalizedString(@"Delete All Data on PIN Failure", nil);
            
        case SECTION_CLOSE:
            return NSLocalizedString(@"Close Database on Timeout", nil);
            
        case SECTION_REMEMBER_PASSWORDS:
            return NSLocalizedString(@"Remember Database Passwords", nil);
            
        case SECTION_HIDE_PASSWORDS:
            return NSLocalizedString(@"Hide Passwords", nil);

        case SECTION_DROPBOX:
            return @"Dropbox";
            
        case SECTION_PASSWORD_ENCODING:
            return NSLocalizedString(@"Password Encoding", nil);
            
        case SECTION_CLEAR_CLIPBOARD:
            return NSLocalizedString(@"Clear Clipboard on Timeout", nil);
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case SECTION_PIN:
            return NSLocalizedString(@"Prevent unauthorized access to MiniKeePass with a PIN.", nil);
            
        case SECTION_DELETE_ON_FAILURE:
            return NSLocalizedString(@"Delete all files and passwords after too many failed attempts.", nil);
            
        case SECTION_CLOSE:
            return NSLocalizedString(@"Automatically close an open database after the selected timeout.", nil);
            
        case SECTION_REMEMBER_PASSWORDS:
            return NSLocalizedString(@"Stores remembered database passwords in the devices's secure keychain.", nil);
            
        case SECTION_HIDE_PASSWORDS:
            return NSLocalizedString(@"Hides passwords when viewing a password entry.", nil);

        case SECTION_DROPBOX:
            return @"Link with your Dropbox account to keep changes in sync between multiple devices.";
            
        case SECTION_PASSWORD_ENCODING:
            return NSLocalizedString(@"The string encoding used for passwords when converting them to database keys.", nil);
            
        case SECTION_CLEAR_CLIPBOARD:
            return NSLocalizedString(@"Clear the contents of the clipboard after a given timeout upon performing a copy.", nil);
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
            }
            break;
            
        case SECTION_CLOSE:
            switch (indexPath.row) {
                case ROW_CLOSE_ENABLED:
                    return closeEnabledCell;
                case ROW_CLOSE_TIMEOUT:
                    return closeTimeoutCell;
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

        case SECTION_DROPBOX:
            if ([[DBSession sharedSession] isLinked]) {
            switch (indexPath.row) {
                case ROW_LINKED_DROPBOX_DIRECTORY_BUTTON:
                    return dropboxDirectoryCell;
                case ROW_LINKED_DROPBOX_UNLINK_BUTTON:
                    return dropboxUnlinkCell;
            }
            } else {
                switch (indexPath.row) {
                    case ROW_UNLINKED_DROPBOX_LINK_BUTTON:
                        return dropboxLinkCell;
                }
            }
            break;

        case SECTION_PASSWORD_ENCODING:
            switch (indexPath.row) {
                case ROW_PASSWORD_ENCODING_VALUE:
                    return passwordEncodingCell;
            }
            break;
            
        case SECTION_CLEAR_CLIPBOARD:
            switch (indexPath.row) {
                case ROW_CLEAR_CLIPBOARD_ENABLED:
                    return clearClipboardEnabledCell;
                case ROW_CLEAR_CLIPBOARD_TIMEOUT:
                    return clearClipboardTimeoutCell;
            }
            break;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_PIN && indexPath.row == ROW_PIN_LOCK_TIMEOUT && pinEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Lock Timeout", nil);
        selectionListViewController.items = pinLockTimeoutCell.choices;
        selectionListViewController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"pinLockTimeout"];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
        [selectionListViewController release];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS && deleteOnFailureEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Attempts", nil);
        selectionListViewController.items = deleteOnFailureAttemptsCell.choices;
        selectionListViewController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"deleteOnFailureAttempts"];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
        [selectionListViewController release];
    } else if (indexPath.section == SECTION_CLOSE && indexPath.row == ROW_CLOSE_TIMEOUT && closeEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Close Timeout", nil);
        selectionListViewController.items = closeTimeoutCell.choices;
        selectionListViewController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"closeTimeout"];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
        [selectionListViewController release];
    } else if (indexPath.section == SECTION_DROPBOX) {
        if ([[DBSession sharedSession] isLinked]) {
            if (indexPath.row == ROW_LINKED_DROPBOX_DIRECTORY_BUTTON) {
                DirectoryChoiceViewController *directoryChoiceView = [[DirectoryChoiceViewController alloc] initWithPath:dropboxDirectory];
                [self.navigationController pushViewController:directoryChoiceView animated:YES];
                [directoryChoiceView release];
            } else {
                [[DBSession sharedSession] unlinkAll];
                dropboxLinkCell.selected = NO;
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_DROPBOX] withRowAnimation:UITableViewRowAnimationFade];
            }
        } else {
            switch (indexPath.row) {
                case ROW_UNLINKED_DROPBOX_LINK_BUTTON:
                    [[DBSession sharedSession] link];
                    break;
            }
        }
    } else if (indexPath.section == SECTION_PASSWORD_ENCODING && indexPath.row == ROW_PASSWORD_ENCODING_VALUE) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Password Encoding", nil);
        selectionListViewController.items = passwordEncodingCell.choices;
        selectionListViewController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"passwordEncoding"];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
        [selectionListViewController release];
    } else if (indexPath.section == SECTION_CLEAR_CLIPBOARD && indexPath.row == ROW_CLEAR_CLIPBOARD_TIMEOUT && clearClipboardEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Clear Clipboard Timeout", nil);
        selectionListViewController.items = clearClipboardTimeoutCell.choices;
        selectionListViewController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"clearClipboardTimeout"];
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
    } else if (indexPath.section == SECTION_CLOSE && indexPath.row == ROW_CLOSE_TIMEOUT) {
        // Save the user setting
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:selectedIndex forKey:@"closeTimeout"];
        
        // Update the cell text
        [pinLockTimeoutCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_PASSWORD_ENCODING && indexPath.row == ROW_PASSWORD_ENCODING_VALUE) {
        // Save the user setting
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:selectedIndex forKey:@"passwordEncoding"];
        
        // Update the cell text
        [passwordEncodingCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_CLEAR_CLIPBOARD && indexPath.row == ROW_CLEAR_CLIPBOARD_TIMEOUT) {
        // Save the user setting
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:selectedIndex forKey:@"clearClipboardTimeout"];
        
        // Update the cell text
        [clearClipboardTimeoutCell setSelectedIndex:selectedIndex];
    }
}

- (void)togglePinEnabled:(id)sender {
    if (pinEnabledCell.switchControl.on) {
        PinViewController *pinViewController = [[PinViewController alloc] initWithText:NSLocalizedString(@"Set PIN", nil)];
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

- (void)toggleCloseEnabled:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:closeEnabledCell.switchControl.on forKey:@"closeEnabled"];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleRememberPasswords:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:rememberPasswordsEnabledCell.switchControl.on forKey:@"rememberPasswordsEnabled"];
    
    // Delete all database passwords from the keychain
    [SFHFKeychainUtils deleteAllItemForServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
    [SFHFKeychainUtils deleteAllItemForServiceName:@"com.jflan.MiniKeePass.keyfiles" error:nil];
}

- (void)toggleHidePasswords:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:hidePasswordsCell.switchControl.on forKey:@"hidePasswords"];
}

- (void)toggleClearClipboardEnabled:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:clearClipboardEnabledCell.switchControl.on forKey:@"clearClipboardEnabled"];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {        
    if (tempPin == nil) {
        tempPin = [pin copy];
        
        controller.textLabel.text = NSLocalizedString(@"Confirm PIN", nil);
        
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
        controller.textLabel.text = NSLocalizedString(@"PINs did not match. Try again", nil);
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        // Clear the PIN entry to let them try again
        [controller clearEntry];
    }
}


- (void)updateDropboxStatus {    
    if (!restClient) {
        restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    
    if ([[DBSession sharedSession] isLinked]) {
        [restClient loadMetadata:dropboxDirectory];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_DROPBOX] withRowAnimation:UITableViewRowAnimationNone];
    }}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        NSMutableArray *directories = [NSMutableArray array];
        for (DBMetadata *file in metadata.contents) {
            if (file.isDirectory) {
                [directories addObject:file.filename];
            }
        }
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}


@end
