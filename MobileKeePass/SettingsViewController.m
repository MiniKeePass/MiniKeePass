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
#import "SettingsViewController.h"
#import "SFHFKeychainUtils.h"

@implementation SettingsViewController

- (void)dealloc {
    [pinSwitch release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    hidePasswordsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    hidePasswordsSwitch.on = [userDefaults boolForKey:@"hidePasswords"];
    [hidePasswordsSwitch addTarget:self action:@selector(toggleHidePasswords:) forControlEvents:UIControlEventValueChanged];

    pinSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    pinSwitch.on = [userDefaults boolForKey:@"pinEnabled"];
    [pinSwitch addTarget:self action:@selector(togglePin:) forControlEvents:UIControlEventValueChanged];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellEditingStyleNone;
    }

    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Hide Passwords";
            [cell addSubview:hidePasswordsSwitch];
            break;
            
        case 1:
            cell.textLabel.text = @"Enable PIN";
            [cell addSubview:pinSwitch];
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)toggleHidePasswords:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:hidePasswordsSwitch.on forKey:@"hidePasswords"];
}

- (void)togglePin:(id)sender {
    if (pinSwitch.on) {
        PinViewController* pinViewController = [[PinViewController alloc] initWithText:@"Set PIN"];
        pinViewController.delegate = self;
        [self presentModalViewController:pinViewController animated:YES];
        [pinViewController release];
    } else {
        [SFHFKeychainUtils deleteItemForUsername:@"PIN" andServiceName:@"net.fizzawizza.MobileKeePass" error:nil];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:pinSwitch.on forKey:@"pinEnabled"];
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
    [pinSwitch setOn:NO animated:YES];

    [SFHFKeychainUtils deleteItemForUsername:@"PIN" andServiceName:@"net.fizzawizza.MobileKeePass" error:nil];
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setBool:NO forKey:@"pinEnabled"];
    
    [tempPin release];
    tempPin = nil;

    [controller dismissModalViewControllerAnimated:YES];
}

@end
