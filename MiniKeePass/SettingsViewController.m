/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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
#import "KeychainUtils.h"
#import "AppSettings.h"

enum {
    SECTION_PIN,
    SECTION_DELETE_ON_FAILURE,
    SECTION_CLOSE,
    SECTION_REMEMBER_PASSWORDS,
    SECTION_HIDE_PASSWORDS,
    SECTION_SORTING,
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
    ROW_SORTING_ENABLED,
    ROW_SORTING_NUMBER
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

@interface SettingsViewController () {
    AppSettings *appSettings;
}
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    appSettings = [AppSettings sharedInstance];

    self.title = NSLocalizedString(@"Settings", nil);
    
    pinEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"PIN Enabled", nil)];
    [pinEnabledCell.switchControl addTarget:self
                                     action:@selector(togglePinEnabled:)
                           forControlEvents:UIControlEventValueChanged];
    
    pinLockTimeoutCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Lock Timeout", nil)
                                                   choices:@[NSLocalizedString(@"Immediately", nil),
                                                             NSLocalizedString(@"30 Seconds", nil),
                                                             NSLocalizedString(@"1 Minute", nil),
                                                             NSLocalizedString(@"2 Minutes", nil),
                                                             NSLocalizedString(@"5 Minutes", nil)]
                                             selectedIndex:0];
    
    deleteOnFailureEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [deleteOnFailureEnabledCell.switchControl addTarget:self
                                                 action:@selector(toggleDeleteOnFailureEnabled:)
                                       forControlEvents:UIControlEventValueChanged];
    
    deleteOnFailureAttemptsCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Attempts", nil)
                                                            choices:@[@"3",
                                                                      @"5",
                                                                      @"10",
                                                                      @"15"]
                                                      selectedIndex:0];
    
    closeEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Close Enabled", nil)];
    [closeEnabledCell.switchControl addTarget:self
                                       action:@selector(toggleCloseEnabled:)
                             forControlEvents:UIControlEventValueChanged];
    
    closeTimeoutCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Close Timeout", nil)
                                                 choices:@[NSLocalizedString(@"Immediately", nil),
                                                           NSLocalizedString(@"30 Seconds", nil),
                                                           NSLocalizedString(@"1 Minute", nil),
                                                           NSLocalizedString(@"2 Minutes", nil),
                                                           NSLocalizedString(@"5 Minutes", nil)]
                                           selectedIndex:0];
    
    rememberPasswordsEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [rememberPasswordsEnabledCell.switchControl addTarget:self
                                                   action:@selector(toggleRememberPasswords:)
                                         forControlEvents:UIControlEventValueChanged];
    
    hidePasswordsCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Hide Passwords", nil)];
    [hidePasswordsCell.switchControl addTarget:self
                                        action:@selector(toggleHidePasswords:)
                              forControlEvents:UIControlEventValueChanged];
    
    sortingEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [sortingEnabledCell.switchControl addTarget:self
                                         action:@selector(toggleSortingEnabled:)
                               forControlEvents:UIControlEventValueChanged];

    passwordEncodingCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Encoding", nil)
                                                     choices:@[NSLocalizedString(@"UTF-8", nil),
                                                               NSLocalizedString(@"UTF-16 Big Endian", nil),
                                                               NSLocalizedString(@"UTF-16 Little Endian", nil),
                                                               NSLocalizedString(@"Latin 1 (ISO/IEC 8859-1)", nil),
                                                               NSLocalizedString(@"Latin 2 (ISO/IEC 8859-2)", nil),
                                                               NSLocalizedString(@"7-Bit ASCII", nil),
                                                               NSLocalizedString(@"Japanese EUC", nil),
                                                               NSLocalizedString(@"ISO-2022-JP", nil)]
                                               selectedIndex:0];

    clearClipboardEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [clearClipboardEnabledCell.switchControl addTarget:self
                                                action:@selector(toggleClearClipboardEnabled:)
                                      forControlEvents:UIControlEventValueChanged];
    
    clearClipboardTimeoutCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Clear Timeout", nil)
                                                          choices:@[NSLocalizedString(@"30 Seconds", nil),
                                                                    NSLocalizedString(@"1 Minute", nil),
                                                                    NSLocalizedString(@"2 Minutes", nil),
                                                                    NSLocalizedString(@"3 Minutes", nil)]
                                                    selectedIndex:0];

    // Add version number to table view footer
    CGFloat viewWidth = CGRectGetWidth(self.tableView.frame);
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 40)];
    
    NSString *text = [NSString stringWithFormat:@"MiniKeePass version %@", 
                    [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    UIFont *font = [UIFont boldSystemFontOfSize:17];
    
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 30)];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.backgroundColor = [UIColor clearColor];
    versionLabel.font = font;
    versionLabel.textColor = [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1.0];
    versionLabel.text = text;
    versionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    versionLabel.shadowColor = [UIColor whiteColor];
    versionLabel.shadowOffset = CGSizeMake(0.0, 1.0);

    [tableFooterView addSubview:versionLabel];
    
    self.tableView.tableFooterView = tableFooterView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Delete the temp pin
    tempPin = nil;
    
    // Initialize all the controls with their settings
    pinEnabledCell.switchControl.on = [appSettings pinEnabled];
    [pinLockTimeoutCell setSelectedIndex:[appSettings pinLockTimeoutIndex]];
    
    deleteOnFailureEnabledCell.switchControl.on = [appSettings deleteOnFailureEnabled];
    [deleteOnFailureAttemptsCell setSelectedIndex:[appSettings deleteOnFailureAttemptsIndex]];
    
    closeEnabledCell.switchControl.on = [appSettings closeEnabled];
    [closeTimeoutCell setSelectedIndex:[appSettings closeTimeoutIndex]];
    
    rememberPasswordsEnabledCell.switchControl.on = [appSettings rememberPasswordsEnabled];
    
    hidePasswordsCell.switchControl.on = [appSettings hidePasswords];
    
    sortingEnabledCell.switchControl.on = [appSettings sortAlphabetically];
    
    [passwordEncodingCell setSelectedIndex:[appSettings passwordEncodingIndex]];
    
    clearClipboardEnabledCell.switchControl.on = [appSettings clearClipboardEnabled];
    [clearClipboardTimeoutCell setSelectedIndex:[appSettings clearClipboardTimeoutIndex]];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)updateEnabledControls {
    BOOL pinEnabled = [appSettings pinEnabled];
    BOOL deleteOnFailureEnabled = [appSettings deleteOnFailureEnabled];
    BOOL closeEnabled = [appSettings closeEnabled];
    BOOL clearClipboardEnabled = [appSettings clearClipboardEnabled];
    
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
            
        case SECTION_SORTING:
            return ROW_SORTING_NUMBER;
            
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
            
        case SECTION_SORTING:
            return NSLocalizedString(@"Sorting", nil);
            
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
            
        case SECTION_SORTING:
            return NSLocalizedString(@"Sort Groups and Entries Alphabetically", nil);
            
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
            
        case SECTION_SORTING:
            switch (indexPath.row) {
                case ROW_SORTING_ENABLED:
                    return sortingEnabledCell;
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
        selectionListViewController.selectedIndex = [appSettings pinLockTimeoutIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS && deleteOnFailureEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Attempts", nil);
        selectionListViewController.items = deleteOnFailureAttemptsCell.choices;
        selectionListViewController.selectedIndex = [appSettings deleteOnFailureAttemptsIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_CLOSE && indexPath.row == ROW_CLOSE_TIMEOUT && closeEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Close Timeout", nil);
        selectionListViewController.items = closeTimeoutCell.choices;
        selectionListViewController.selectedIndex = [appSettings closeTimeoutIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_PASSWORD_ENCODING && indexPath.row == ROW_PASSWORD_ENCODING_VALUE) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Password Encoding", nil);
        selectionListViewController.items = passwordEncodingCell.choices;
        selectionListViewController.selectedIndex = [appSettings passwordEncodingIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_CLEAR_CLIPBOARD && indexPath.row == ROW_CLEAR_CLIPBOARD_TIMEOUT && clearClipboardEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Clear Clipboard Timeout", nil);
        selectionListViewController.items = clearClipboardTimeoutCell.choices;
        selectionListViewController.selectedIndex = [appSettings clearClipboardTimeoutIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    }
}

- (void)selectionListViewController:(SelectionListViewController *)controller selectedIndex:(NSInteger)selectedIndex withReference:(id<NSObject>)reference {
    NSIndexPath *indexPath = (NSIndexPath*)reference;
    if (indexPath.section == SECTION_PIN && indexPath.row == ROW_PIN_LOCK_TIMEOUT) {
        // Save the user setting
        [appSettings setPinLockTimeoutIndex:selectedIndex];
        
        // Update the cell text
        [pinLockTimeoutCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS) {
        // Save the user setting
        [appSettings setDeleteOnFailureAttemptsIndex:selectedIndex];
        
        // Update the cell text
        [deleteOnFailureAttemptsCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_CLOSE && indexPath.row == ROW_CLOSE_TIMEOUT) {
        // Save the user setting
        [appSettings setCloseTimeoutIndex:selectedIndex];
        
        // Update the cell text
        [pinLockTimeoutCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_PASSWORD_ENCODING && indexPath.row == ROW_PASSWORD_ENCODING_VALUE) {
        // Save the user setting
        [appSettings setPasswordEncodingIndex:selectedIndex];
        
        // Update the cell text
        [passwordEncodingCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_CLEAR_CLIPBOARD && indexPath.row == ROW_CLEAR_CLIPBOARD_TIMEOUT) {
        // Save the user setting
        [appSettings setClearClipboardTimeoutIndex:selectedIndex];
        
        // Update the cell text
        [clearClipboardTimeoutCell setSelectedIndex:selectedIndex];
    }
}

- (void)togglePinEnabled:(id)sender {
    if (pinEnabledCell.switchControl.on) {
        PinViewController *pinViewController = [[PinViewController alloc] initWithText:NSLocalizedString(@"Set PIN", nil)];
        [pinViewController becomeFirstResponder];
        pinViewController.delegate = self;
        [self presentViewController:pinViewController animated:YES completion:nil];
    } else {
        // Delete the PIN and disable the PIN enabled setting
        [KeychainUtils deleteStringForKey:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin"];
        [appSettings setPinEnabled:NO];
        
        // Update which controls are enabled
        [self updateEnabledControls];
    }
}

- (void)toggleDeleteOnFailureEnabled:(id)sender {
    // Update the setting
    [appSettings setDeleteOnFailureEnabled:deleteOnFailureEnabledCell.switchControl.on];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleCloseEnabled:(id)sender {
    // Update the setting
    [appSettings setCloseEnabled:closeEnabledCell.switchControl.on];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleRememberPasswords:(id)sender {
    // Update the setting
    [appSettings setRememberPasswordsEnabled:rememberPasswordsEnabledCell.switchControl.on];
    
    // Delete all database passwords from the keychain
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.passwords"];
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.keyfiles"];
}

- (void)toggleHidePasswords:(id)sender {
    // Update the setting
    [appSettings setHidePasswords:hidePasswordsCell.switchControl.on];
}

- (void)toggleSortingEnabled:(id)sender {
    // Update the setting
    [appSettings setSortAlphabetically:sortingEnabledCell.switchControl.on];
}

- (void)toggleClearClipboardEnabled:(id)sender {
    // Update the setting
    [appSettings setClearClipboardEnabled:clearClipboardEnabledCell.switchControl.on];
    
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
        tempPin = nil;
        
        // Set the PIN and enable the PIN enabled setting
        [KeychainUtils setString:pin forKey:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin"];
        [appSettings setPinEnabled:pinEnabledCell.switchControl.on];
        
        // Update which controls are enabled
        [self updateEnabledControls];
        
        // Remove the PIN view
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        tempPin = nil;
        
        // Notify the user the PINs they entered did not match
        controller.textLabel.text = NSLocalizedString(@"PINs did not match. Try again", nil);
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        // Clear the PIN entry to let them try again
        [controller clearEntry];
    }
}

-(BOOL)pinViewControllerShouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
