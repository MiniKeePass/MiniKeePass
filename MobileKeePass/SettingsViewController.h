//
//  SettingsViewController.h
//  MobileKeePass
//
//  Created by John on 5/4/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PinViewController.h"

@interface SettingsViewController : UITableViewController <PinViewControllerDelegate> {
    UISwitch *hidePasswordsSwitch;
    UISwitch *pinSwitch;
    NSString *tempPin;
}

@end
