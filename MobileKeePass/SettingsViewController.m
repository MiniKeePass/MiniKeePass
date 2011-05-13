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
#import "MobileKeePassAppDelegate.h"
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
    
    pinEnabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    [pinEnabledSwitch addTarget:self action:@selector(togglePinEnabled:) forControlEvents:UIControlEventValueChanged];
    
    pinLockTimeoutLabels = [[NSArray arrayWithObjects:@"Immediately", @"30 Seconds", @"1 Minute", @"2 Minutes", @"5 Minutes", nil] retain];
    
    deleteOnFailureEnabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    [deleteOnFailureEnabledSwitch addTarget:self action:@selector(toggleDeleteOnFailureEnabled:) forControlEvents:UIControlEventValueChanged];    
    
    deleteOnFailureAttemptsLabels = [[NSArray arrayWithObjects:@"3", @"5", @"10", @"15", nil] retain];
    
    rememberPasswordsEnabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    [rememberPasswordsEnabledSwitch addTarget:self action:@selector(toggleRememberPasswords:) forControlEvents:UIControlEventValueChanged];
    
    hidePasswordsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    [hidePasswordsSwitch addTarget:self action:@selector(toggleHidePasswords:) forControlEvents:UIControlEventValueChanged];
    
    closeDatabaseView = [[UIView alloc] init];
    
    closeDatabaseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    closeDatabaseButton.frame = CGRectMake(10, 10, 300, 44);
    [closeDatabaseButton setTitle:@"Close Current Database" forState:UIControlStateNormal];
    UIImage *image = [[UIImage imageNamed:@"button_red.png"] stretchableImageWithLeftCapWidth:8 topCapHeight:8];
    [closeDatabaseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeDatabaseButton setBackgroundImage:image forState:UIControlStateNormal];
    [closeDatabaseButton addTarget:self action:@selector(closeDatabasePressed:) forControlEvents:UIControlEventTouchUpInside];
    [closeDatabaseView addSubview:closeDatabaseButton];
    
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    closeDatabaseButton.enabled = appDelegate.databaseDocument != nil;
}

- (void)dealloc {
    [pinEnabledSwitch release];
    [pinLockTimeoutLabels release];
    [deleteOnFailureEnabledSwitch release];
    [deleteOnFailureAttemptsLabels release];
    [rememberPasswordsEnabledSwitch release];
    [hidePasswordsSwitch release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Delete the temp pin
    [tempPin release];
    tempPin = nil;
    
    // Initialize all the controls with their settings
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    pinEnabledSwitch.on = [userDefaults boolForKey:@"pinEnabled"];
    deleteOnFailureEnabledSwitch.on = [userDefaults boolForKey:@"deleteOnFailureEnabled"];
    rememberPasswordsEnabledSwitch.on = [userDefaults boolForKey:@"rememberPasswordsEnabled"];
    hidePasswordsSwitch.on = [userDefaults boolForKey:@"hidePasswords"];

    [self updateEnabledControls];
}

- (void)setCellAtRow:(NSInteger)row inSection:(NSInteger)section enabled:(BOOL)enabled {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.enabled = enabled;    
}

- (void)updateEnabledControls {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL pinEnabled = [userDefaults boolForKey:@"pinEnabled"];
    BOOL deleteOnFailureEnabled = [userDefaults boolForKey:@"deleteOnFailureEnabled"];
    
    // Enable/disable the components dependant on dettings
    [self setCellAtRow:ROW_PIN_LOCK_TIMEOUT inSection:SECTION_PIN enabled:pinEnabled];
    [self setCellAtRow:ROW_DELETE_ON_FAILURE_ENABLED inSection:SECTION_DELETE_ON_FAILURE enabled:pinEnabled];
    deleteOnFailureEnabledSwitch.enabled = pinEnabled;
    [self setCellAtRow:ROW_DELETE_ON_FAILURE_ATTEMPTS inSection:SECTION_DELETE_ON_FAILURE enabled:pinEnabled && deleteOnFailureEnabled];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellEditingStyleNone;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    switch (indexPath.section) {
        case SECTION_PIN:
            switch (indexPath.row) {
                case ROW_PIN_ENABLED:
                    cell.textLabel.text = @"Enabled";
                    [cell addSubview:pinEnabledSwitch];
                    break;
                case ROW_PIN_LOCK_TIMEOUT:
                    cell.textLabel.text = [NSString stringWithFormat:@"Lock Timeout: %@", [pinLockTimeoutLabels objectAtIndex:[userDefaults integerForKey:@"pinLockTimeout"]]];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            break;
            
        case SECTION_DELETE_ON_FAILURE:
            switch (indexPath.row) {
                case ROW_DELETE_ON_FAILURE_ENABLED:
                    cell.textLabel.text = @"Enabled";
                    [cell addSubview:deleteOnFailureEnabledSwitch];
                    break;
                case ROW_DELETE_ON_FAILURE_ATTEMPTS:
                    cell.textLabel.text = [NSString stringWithFormat:@"Attempts: %@", [deleteOnFailureAttemptsLabels objectAtIndex:[userDefaults integerForKey:@"deleteOnFailureAttempts"]]];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
            }
            break;
            
        case SECTION_REMEMBER_PASSWORDS:
            switch (indexPath.row) {
                case ROW_REMEMBER_PASSWORDS_ENABLED:
                    cell.textLabel.text = @"Enabled";
                    [cell addSubview:rememberPasswordsEnabledSwitch];
                    break;
            }
            break;
            
        case SECTION_HIDE_PASSWORDS:
            switch (indexPath.row) {
                case ROW_HIDE_PASSWORDS_ENABLED:
                    cell.textLabel.text = @"Hide Passwords";
                    [cell addSubview:hidePasswordsSwitch];
                    break;
            }
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == SECTION_HIDE_PASSWORDS) {
        return 64;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == SECTION_HIDE_PASSWORDS) {
        return closeDatabaseView;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_PIN && indexPath.row == ROW_PIN_LOCK_TIMEOUT && pinEnabledSwitch.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = @"Lock Timeout";
        selectionListViewController.items = pinLockTimeoutLabels;
        selectionListViewController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"pinLockTimeout"];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
        [selectionListViewController release];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS && deleteOnFailureEnabledSwitch.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = @"Attempts";
        selectionListViewController.items = deleteOnFailureAttemptsLabels;
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
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setInteger:selectedIndex forKey:@"pinLockTimeout"];
        
        // Update the cell text
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithFormat:@"Lock Timeout: %@", [pinLockTimeoutLabels objectAtIndex:selectedIndex]];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS) {
        // Save the user setting
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setInteger:selectedIndex forKey:@"deleteOnFailureAttempts"];
        
        // Update the cell text
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithFormat:@"Attempts: %@", [deleteOnFailureAttemptsLabels objectAtIndex:selectedIndex]];
    }    
}

- (void)togglePinEnabled:(id)sender {
    if (pinEnabledSwitch.on) {
        PinViewController* pinViewController = [[PinViewController alloc] initWithText:@"Set PIN"];
        pinViewController.delegate = self;
        [self.navigationController pushViewController:pinViewController animated:YES];
        [pinViewController release];
    } else {
        // Delete the PIN and disable the PIN enabled setting
        [SFHFKeychainUtils deleteItemForUsername:@"PIN" andServiceName:@"net.fizzawizza.MobileKeePass" error:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"pinEnabled"];
        
        // Update which controls are enabled
        [self updateEnabledControls];
    }
}

- (void)toggleDeleteOnFailureEnabled:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:deleteOnFailureEnabledSwitch.on forKey:@"deleteOnFailureEnabled"];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleRememberPasswords:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:rememberPasswordsEnabledSwitch.on forKey:@"rememberPasswordsEnabled"];
}

- (void)toggleHidePasswords:(id)sender {
    // Update the setting
    [[NSUserDefaults standardUserDefaults] setBool:hidePasswordsSwitch.on forKey:@"hidePasswords"];
}

- (void)closeDatabasePressed:(id)sender {
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate closeDatabase];
    
    closeDatabaseButton.enabled = appDelegate.databaseDocument != nil;
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
        [SFHFKeychainUtils storeUsername:@"PIN" andPassword:pin forServiceName:@"net.fizzawizza.MobileKeePass" updateExisting:YES error:nil];
        [[NSUserDefaults standardUserDefaults] setBool:pinEnabledSwitch.on forKey:@"pinEnabled"];
        
        // Update which controls are enabled
        [self updateEnabledControls];
        
        // Remove the PIN view
        [self.navigationController popViewControllerAnimated:YES];
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
