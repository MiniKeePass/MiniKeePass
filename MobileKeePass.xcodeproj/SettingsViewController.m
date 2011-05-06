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

- (void)dealloc
{
    [pinSwitch release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    pinSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
    pinSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"pinEnabled"];
    [pinSwitch addTarget:self action:@selector(togglePin:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = @"Enable PIN";
            cell.selectionStyle = UITableViewCellEditingStyleNone;
            
            [cell addSubview:pinSwitch];
            [pinSwitch release];

            break;
            
        default:
            break;
    }
    
    
    return cell;
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
