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

#import <LocalAuthentication/LocalAuthentication.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MiniKeePassAppDelegate.h"
#import "SettingsViewController.h"
#import "SelectionListViewController.h"
#import "KeychainUtils.h"
#import "AppSettings.h"
#import "PasswordUtils.h"

enum {
    SECTION_PIN,
    SECTION_TOUCH_ID,
    SECTION_DELETE_ON_FAILURE,
    SECTION_CLOSE,
    SECTION_REMEMBER_PASSWORDS,
    SECTION_HIDE_PASSWORDS,
    SECTION_SORTING,
    SECTION_PASSWORD_ENCODING,
    SECTION_CLEAR_CLIPBOARD,
    SECTION_WEB_BROWSER
};

enum {
    ROW_PIN_ENABLED,
    ROW_PIN_LOCK_TIMEOUT,
    ROW_PIN_NUMBER
};

enum {
    ROW_TOUCH_ID_ENABLED,
    ROW_TOUCH_ID_NUMBER
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

enum {
    ROW_WEB_BROWSER_INTEGRATED,
    ROW_WEB_BROWSER_NUMBER
};

@interface SettingsViewController ()
@property (nonatomic, strong) AppSettings *appSettings;
@property (nonatomic, strong) NSArray *sections;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.appSettings = [AppSettings sharedInstance];

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

    touchIdEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [touchIdEnabledCell.switchControl addTarget:self
                                         action:@selector(toggleTouchIdEnabled:)
                               forControlEvents:UIControlEventValueChanged];

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

    webBrowserIntegratedCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Integrated", nil)];
    [webBrowserIntegratedCell.switchControl addTarget:self
                                           action:@selector(toggleWebBrowserIntegrated:)
                                 forControlEvents:UIControlEventValueChanged];

    // Add version number to table view footer
    CGFloat viewWidth = CGRectGetWidth(self.tableView.frame);
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 40)];
    
    NSString *text = [NSString stringWithFormat:NSLocalizedString(@"MiniKeePass version %@", nil),
                    [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
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

    // Check if TouchID is supported
    BOOL touchIdEnabled = NO;
    if ([NSClassFromString(@"LAContext") class]) {
        LAContext *context = [[LAContext alloc] init];
        touchIdEnabled = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    }

    // Create the list of supported sections
    if (touchIdEnabled) {
        // Include TouchID in the list of sections
        self.sections = @[
                          [NSNumber numberWithInt:SECTION_PIN],
                          [NSNumber numberWithInt:SECTION_TOUCH_ID],
                          [NSNumber numberWithInt:SECTION_DELETE_ON_FAILURE],
                          [NSNumber numberWithInt:SECTION_CLOSE],
                          [NSNumber numberWithInt:SECTION_REMEMBER_PASSWORDS],
                          [NSNumber numberWithInt:SECTION_HIDE_PASSWORDS],
                          [NSNumber numberWithInt:SECTION_SORTING],
                          [NSNumber numberWithInt:SECTION_PASSWORD_ENCODING],
                          [NSNumber numberWithInt:SECTION_CLEAR_CLIPBOARD],
                          [NSNumber numberWithInt:SECTION_WEB_BROWSER]
                          ];
    } else {
        // Skip TouchID in the list of sections
        self.sections = @[
                          [NSNumber numberWithInt:SECTION_PIN],
                          [NSNumber numberWithInt:SECTION_DELETE_ON_FAILURE],
                          [NSNumber numberWithInt:SECTION_CLOSE],
                          [NSNumber numberWithInt:SECTION_REMEMBER_PASSWORDS],
                          [NSNumber numberWithInt:SECTION_HIDE_PASSWORDS],
                          [NSNumber numberWithInt:SECTION_SORTING],
                          [NSNumber numberWithInt:SECTION_PASSWORD_ENCODING],
                          [NSNumber numberWithInt:SECTION_CLEAR_CLIPBOARD],
                          [NSNumber numberWithInt:SECTION_WEB_BROWSER]
                          ];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Delete the temp pin
    tempPin = nil;
    
    // Initialize all the controls with their settings
    pinEnabledCell.switchControl.on = [self.appSettings pinEnabled];
    [pinLockTimeoutCell setSelectedIndex:[self.appSettings pinLockTimeoutIndex]];

    touchIdEnabledCell.switchControl.on = [self.appSettings touchIdEnabled];

    deleteOnFailureEnabledCell.switchControl.on = [self.appSettings deleteOnFailureEnabled];
    [deleteOnFailureAttemptsCell setSelectedIndex:[self.appSettings deleteOnFailureAttemptsIndex]];
    
    closeEnabledCell.switchControl.on = [self.appSettings closeEnabled];
    [closeTimeoutCell setSelectedIndex:[self.appSettings closeTimeoutIndex]];
    
    rememberPasswordsEnabledCell.switchControl.on = [self.appSettings rememberPasswordsEnabled];
    
    hidePasswordsCell.switchControl.on = [self.appSettings hidePasswords];
    
    sortingEnabledCell.switchControl.on = [self.appSettings sortAlphabetically];
    
    [passwordEncodingCell setSelectedIndex:[self.appSettings passwordEncodingIndex]];
    
    clearClipboardEnabledCell.switchControl.on = [self.appSettings clearClipboardEnabled];
    [clearClipboardTimeoutCell setSelectedIndex:[self.appSettings clearClipboardTimeoutIndex]];

    webBrowserIntegratedCell.switchControl.on = [self.appSettings webBrowserIntegrated];

    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)updateEnabledControls {
    BOOL pinEnabled = [self.appSettings pinEnabled];
    BOOL deleteOnFailureEnabled = [self.appSettings deleteOnFailureEnabled];
    BOOL closeEnabled = [self.appSettings closeEnabled];
    BOOL clearClipboardEnabled = [self.appSettings clearClipboardEnabled];
    
    // Enable/disable the components dependant on settings
    [pinLockTimeoutCell setEnabled:pinEnabled];
    [touchIdEnabledCell setEnabled:pinEnabled];
    [deleteOnFailureEnabledCell setEnabled:pinEnabled];
    [deleteOnFailureAttemptsCell setEnabled:pinEnabled && deleteOnFailureEnabled];
    [closeTimeoutCell setEnabled:closeEnabled];
    [clearClipboardTimeoutCell setEnabled:clearClipboardEnabled];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sections count];
}

- (NSInteger)mappedSection:(NSInteger)section {
    return [((NSNumber *)[self.sections objectAtIndex:section]) integerValue];
}

- (NSIndexPath *)mappedIndexPath:(NSIndexPath *)indexPAth {
    NSInteger section = [self mappedSection:indexPAth.section];
    return [NSIndexPath indexPathForRow:indexPAth.row inSection:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    section = [self mappedSection:section];
    switch (section) {
        case SECTION_PIN:
            return ROW_PIN_NUMBER;

        case SECTION_TOUCH_ID:
            return ROW_TOUCH_ID_NUMBER;

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

        case SECTION_WEB_BROWSER:
            return ROW_WEB_BROWSER_NUMBER;
    }
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    section = [self mappedSection:section];
    switch (section) {
        case SECTION_PIN:
            return NSLocalizedString(@"PIN Protection", nil);

        case SECTION_TOUCH_ID:
            return NSLocalizedString(@"Touch ID", nil);

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

        case SECTION_WEB_BROWSER:
            return NSLocalizedString(@"Web Browser", nil);
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    section = [self mappedSection:section];
    switch (section) {
        case SECTION_PIN:
            return NSLocalizedString(@"Prevent unauthorized access to MiniKeePass with a PIN.", nil);

        case SECTION_TOUCH_ID:
            return NSLocalizedString(@"Use your fingerprint as an alternative to entering a PIN if supported.", nil);

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
            
        case SECTION_WEB_BROWSER:
            return NSLocalizedString(@"Switch between an integrated web browser and Safari.", nil);
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    indexPath = [self mappedIndexPath:indexPath];
    switch (indexPath.section) {
        case SECTION_PIN:
            switch (indexPath.row) {
                case ROW_PIN_ENABLED:
                    return pinEnabledCell;
                case ROW_PIN_LOCK_TIMEOUT:
                    return pinLockTimeoutCell;
            }
            break;

        case SECTION_TOUCH_ID:
            switch (indexPath.row) {
                case ROW_TOUCH_ID_ENABLED:
                    return touchIdEnabledCell;
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
        case SECTION_WEB_BROWSER:
            switch (indexPath.row) {
                case ROW_WEB_BROWSER_INTEGRATED:
                    return webBrowserIntegratedCell;
            }
            break;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    indexPath = [self mappedIndexPath:indexPath];
    if (indexPath.section == SECTION_PIN && indexPath.row == ROW_PIN_LOCK_TIMEOUT && pinEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Lock Timeout", nil);
        selectionListViewController.items = pinLockTimeoutCell.choices;
        selectionListViewController.selectedIndex = [self.appSettings pinLockTimeoutIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS && deleteOnFailureEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Attempts", nil);
        selectionListViewController.items = deleteOnFailureAttemptsCell.choices;
        selectionListViewController.selectedIndex = [self.appSettings deleteOnFailureAttemptsIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_CLOSE && indexPath.row == ROW_CLOSE_TIMEOUT && closeEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Close Timeout", nil);
        selectionListViewController.items = closeTimeoutCell.choices;
        selectionListViewController.selectedIndex = [self.appSettings closeTimeoutIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_PASSWORD_ENCODING && indexPath.row == ROW_PASSWORD_ENCODING_VALUE) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Password Encoding", nil);
        selectionListViewController.items = passwordEncodingCell.choices;
        selectionListViewController.selectedIndex = [self.appSettings passwordEncodingIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_CLEAR_CLIPBOARD && indexPath.row == ROW_CLEAR_CLIPBOARD_TIMEOUT && clearClipboardEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Clear Clipboard Timeout", nil);
        selectionListViewController.items = clearClipboardTimeoutCell.choices;
        selectionListViewController.selectedIndex = [self.appSettings clearClipboardTimeoutIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    }
}

- (void)selectionListViewController:(SelectionListViewController *)controller selectedIndex:(NSInteger)selectedIndex withReference:(id<NSObject>)reference {
    NSIndexPath *indexPath = (NSIndexPath *)reference;
    if (indexPath.section == SECTION_PIN && indexPath.row == ROW_PIN_LOCK_TIMEOUT) {
        // Save the user setting
        [self.appSettings setPinLockTimeoutIndex:selectedIndex];
        
        // Update the cell text
        [pinLockTimeoutCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS) {
        // Save the user setting
        [self.appSettings setDeleteOnFailureAttemptsIndex:selectedIndex];
        
        // Update the cell text
        [deleteOnFailureAttemptsCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_CLOSE && indexPath.row == ROW_CLOSE_TIMEOUT) {
        // Save the user setting
        [self.appSettings setCloseTimeoutIndex:selectedIndex];
        
        // Update the cell text
        [pinLockTimeoutCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_PASSWORD_ENCODING && indexPath.row == ROW_PASSWORD_ENCODING_VALUE) {
        // Save the user setting
        [self.appSettings setPasswordEncodingIndex:selectedIndex];
        
        // Update the cell text
        [passwordEncodingCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_CLEAR_CLIPBOARD && indexPath.row == ROW_CLEAR_CLIPBOARD_TIMEOUT) {
        // Save the user setting
        [self.appSettings setClearClipboardTimeoutIndex:selectedIndex];
        
        // Update the cell text
        [clearClipboardTimeoutCell setSelectedIndex:selectedIndex];
    }
}

- (void)togglePinEnabled:(id)sender {
    if (pinEnabledCell.switchControl.on) {
        PinViewController *pinViewController = [[PinViewController alloc] init];
        pinViewController.titleLabel.text = NSLocalizedString(@"Set PIN", nil);
        pinViewController.delegate = self;
        
        [self presentViewController:pinViewController animated:YES completion:nil];
    } else {
        // Delete the PIN and disable the PIN enabled setting
        [KeychainUtils deleteStringForKey:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin"];
        [self.appSettings setPinEnabled:NO];
        
        // Update which controls are enabled
        [self updateEnabledControls];
    }
}

- (void)toggleTouchIdEnabled:(id)sender {
    // Update the setting
    [self.appSettings setTouchIdEnabled:touchIdEnabledCell.switchControl.on];
}

- (void)toggleDeleteOnFailureEnabled:(id)sender {
    // Update the setting
    [self.appSettings setDeleteOnFailureEnabled:deleteOnFailureEnabledCell.switchControl.on];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleCloseEnabled:(id)sender {
    // Update the setting
    [self.appSettings setCloseEnabled:closeEnabledCell.switchControl.on];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleRememberPasswords:(id)sender {
    // Update the setting
    [self.appSettings setRememberPasswordsEnabled:rememberPasswordsEnabledCell.switchControl.on];
    
    // Delete all database passwords from the keychain
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.passwords"];
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.keyfiles"];
}

- (void)toggleHidePasswords:(id)sender {
    // Update the setting
    [self.appSettings setHidePasswords:hidePasswordsCell.switchControl.on];
}

- (void)toggleSortingEnabled:(id)sender {
    // Update the setting
    [self.appSettings setSortAlphabetically:sortingEnabledCell.switchControl.on];
}

- (void)toggleClearClipboardEnabled:(id)sender {
    // Update the setting
    [self.appSettings setClearClipboardEnabled:clearClipboardEnabledCell.switchControl.on];

    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleWebBrowserIntegrated:(id)sender {
    // Update the setting
    [self.appSettings setWebBrowserIntegrated:webBrowserIntegratedCell.switchControl.on];
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {        
    if (tempPin == nil) {
        tempPin = [pin copy];
        
        controller.titleLabel.text = NSLocalizedString(@"Confirm PIN", nil);
        
        // Clear the PIN entry for confirmation
        [controller clearPin];
    } else if ([tempPin isEqualToString:pin]) {
        tempPin = nil;
        
        // Hash the pin
        NSString *pinHash = [PasswordUtils hashPassword:pin];
        
        // Set the PIN and enable the PIN enabled setting
        [self.appSettings setPinEnabled:pinEnabledCell.switchControl.on];
        [self.appSettings setPin:pinHash];
        
        // Update which controls are enabled
        [self updateEnabledControls];
        
        // Remove the PIN view
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        tempPin = nil;
        
        // Notify the user the PINs they entered did not match
        controller.titleLabel.text = NSLocalizedString(@"PINs did not match. Try again", nil);
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        // Clear the PIN entry to let them try again
        [controller clearPin];
    }
}

@end
