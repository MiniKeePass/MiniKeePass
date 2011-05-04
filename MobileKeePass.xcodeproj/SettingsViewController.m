//
//  SettingsViewController.m
//  MobileKeePass
//
//  Created by John on 5/4/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "SettingsViewController.h"

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIButton *dbButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    
    [self.view addSubview:dbButton];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
            
            UISwitch *pinSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 10, 0, 0)];
            pinSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"enablePin"];
            [pinSwitch addTarget:self action:@selector(togglePin:) forControlEvents:UIControlEventValueChanged];
            [cell addSubview:pinSwitch];
            [pinSwitch release];

            break;
            
        default:
            break;
    }
    
    
    return cell;
}

- (void)togglePin:(id)sender {
    UISwitch *pinSwitch = (UISwitch*)sender;
    
    if (pinSwitch.on) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pin"];

        PinViewController* pinViewController = [[PinViewController alloc] initWithText:@"Set PIN"];
        pinViewController.delegate = self;
        [self presentModalViewController:pinViewController animated:YES];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:pinSwitch.on forKey:@"enablePin"];
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *currentPin = [standardUserDefaults valueForKey:@"pin"];
    
    if (currentPin == nil) {
        [standardUserDefaults setValue:pin forKey:@"pin"];
        controller.string = @"Confirm PIN";
        [controller clearEntry];
    } else if ([currentPin isEqualToString:pin]) {
        [controller dismissModalViewControllerAnimated:YES];
    } else {
        controller.string = @"PINs did not match. Try again";
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        [standardUserDefaults removeObjectForKey:@"pin"];
        [controller clearEntry];
    }
}

@end
