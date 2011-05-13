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
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    pinEnabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    pinEnabledSwitch.on = [userDefaults boolForKey:@"pinEnabled"];
    [pinEnabledSwitch addTarget:self action:@selector(togglePinEnabled:) forControlEvents:UIControlEventValueChanged];
    
    pinLockTimeoutLabels = [[NSArray arrayWithObjects:@"Immediately", @"30 Seconds", @"1 Minute", @"2 Minutes", @"5 Minutes", nil] retain];
    
    deleteOnFailureEnabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    deleteOnFailureEnabledSwitch.on = [userDefaults boolForKey:@"deleteOnFailureEnabled"];
    [deleteOnFailureEnabledSwitch addTarget:self action:@selector(toggleDeleteOnFailureEnabled:) forControlEvents:UIControlEventValueChanged];    
    
    deleteOnFailureAttemptsLabels = [[NSArray arrayWithObjects:@"3", @"5", @"10", @"15", nil] retain];
    
    rememberPasswordsEnabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    rememberPasswordsEnabledSwitch.on = [userDefaults boolForKey:@"rememberPasswordsEnabled"];
    [rememberPasswordsEnabledSwitch addTarget:self action:@selector(toggleRememberPasswords:) forControlEvents:UIControlEventValueChanged];
    
    hidePasswordsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    hidePasswordsSwitch.on = [userDefaults boolForKey:@"hidePasswords"];
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
    [rememberPasswordsEnabledSwitch release];
    [hidePasswordsSwitch release];
    [pinEnabledSwitch release];
    [pinLockTimeoutLabels release];
    [super dealloc];
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

    switch (indexPath.section) {
        case SECTION_PIN:
            switch (indexPath.row) {
                case ROW_PIN_ENABLED:
                    cell.textLabel.text = @"Enabled";
                    [cell addSubview:pinEnabledSwitch];
                    break;
                case ROW_PIN_LOCK_TIMEOUT:
                    cell.textLabel.enabled = pinEnabledSwitch.on;
                    cell.textLabel.text = [NSString stringWithFormat:@"Lock Timeout: %@", [pinLockTimeoutLabels objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"pinLockTimeout"]]];
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
                    cell.textLabel.enabled = deleteOnFailureEnabledSwitch.on;
                    cell.textLabel.text = [NSString stringWithFormat:@"Attempts: %@", [deleteOnFailureAttemptsLabels objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"deleteOnFailureAttempts"]]];
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

- (void)setCellAtRow:(NSInteger)row inSection:(NSInteger)section enabled:(BOOL)enabled {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.enabled = enabled;    
}

- (void)togglePinEnabled:(id)sender {
    if (pinEnabledSwitch.on) {
        PinViewController* pinViewController = [[PinViewController alloc] initWithText:@"Set PIN"];
        pinViewController.delegate = self;
        [self presentModalViewController:pinViewController animated:YES];
        [pinViewController release];
    } else {
        [SFHFKeychainUtils deleteItemForUsername:@"PIN" andServiceName:@"net.fizzawizza.MobileKeePass" error:nil];
        [self setCellAtRow:ROW_PIN_LOCK_TIMEOUT inSection:SECTION_PIN enabled:NO];
        [self setCellAtRow:ROW_DELETE_ON_FAILURE_ENABLED inSection:SECTION_DELETE_ON_FAILURE enabled:NO];
        [self setCellAtRow:ROW_DELETE_ON_FAILURE_ATTEMPTS inSection:SECTION_DELETE_ON_FAILURE enabled:NO];
        deleteOnFailureEnabledSwitch.enabled = NO;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:pinEnabledSwitch.on forKey:@"pinEnabled"];
}

- (void)toggleDeleteOnFailureEnabled:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:deleteOnFailureEnabledSwitch.on forKey:@"deleteOnFailureEnabled"];
    [self setCellAtRow:ROW_DELETE_ON_FAILURE_ATTEMPTS inSection:SECTION_DELETE_ON_FAILURE enabled:deleteOnFailureEnabledSwitch.on];
}

- (void)toggleRememberPasswords:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:rememberPasswordsEnabledSwitch.on forKey:@"rememberPasswordsEnabled"];
}

- (void)toggleHidePasswords:(id)sender {
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
        controller.string = @"Confirm PIN";
        [controller clearEntry];
    } else if ([tempPin isEqualToString:pin]) {
        NSError *error;
        [SFHFKeychainUtils storeUsername:@"PIN" andPassword:pin forServiceName:@"net.fizzawizza.MobileKeePass" updateExisting:YES error:&error];
        
        [tempPin release];
        tempPin = nil;
        
        [self setCellAtRow:ROW_PIN_LOCK_TIMEOUT inSection:SECTION_PIN enabled:YES];
        [self setCellAtRow:ROW_DELETE_ON_FAILURE_ENABLED inSection:SECTION_DELETE_ON_FAILURE enabled:YES];
        [self setCellAtRow:ROW_DELETE_ON_FAILURE_ATTEMPTS inSection:SECTION_DELETE_ON_FAILURE enabled:deleteOnFailureEnabledSwitch.on];
        deleteOnFailureEnabledSwitch.enabled = YES;

        [controller dismissModalViewControllerAnimated:YES];
    } else {
        controller.string = @"PINs did not match. Try again";
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        [tempPin release];
        tempPin = nil;
        
        [controller clearEntry];
    }
}

- (void)pinViewControllerCancelButtonPressed:(PinViewController *)controller {
    [pinEnabledSwitch setOn:NO animated:YES];

    [SFHFKeychainUtils deleteItemForUsername:@"PIN" andServiceName:@"net.fizzawizza.MobileKeePass" error:nil];
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setBool:NO forKey:@"pinEnabled"];
    
    [tempPin release];
    tempPin = nil;
    
    [self setCellAtRow:ROW_PIN_LOCK_TIMEOUT inSection:SECTION_PIN enabled:NO];

    [controller dismissModalViewControllerAnimated:YES];
}

@end
