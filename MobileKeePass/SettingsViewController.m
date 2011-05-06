//
//  SettingsViewController.m
//  MobileKeePass
//
//  Created by John on 5/4/11.
//  Copyright 2011 Self. All rights reserved.
//

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
