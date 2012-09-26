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
#import <QuartzCore/QuartzCore.h>
#import "MiniKeePassAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "LockScreenController.h"

#define DURATION 0.3

@implementation LockScreenController

static NSInteger timeoutValues[] = {0, 30, 60, 120, 300};
static NSInteger deleteOnFailureAttemptsValues[] = {3, 5, 10, 15};

- (id)init {
    self = [super init];
    if (self) {
        pinViewController = [[PinViewController alloc] init];
        pinViewController.delegate = self;

        self.view.backgroundColor = [UIColor colorWithRed:0.831372f green:0.843137f blue:0.870588f alpha:1.0f];

        appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self 
                               selector:@selector(applicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [pinViewController release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    BOOL boolean = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || toInterfaceOrientation == UIInterfaceOrientationPortrait;
    return boolean;
}

-(BOOL)pinViewControllerShouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return [self shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (UIViewController *)frontMostViewController {
    UIViewController *frontViewController = appDelegate.window.rootViewController;
    while (frontViewController.modalViewController != nil) {
        frontViewController = frontViewController.modalViewController;
    }
    return frontViewController;
}

- (void)show {
    previousViewController = [self frontMostViewController];
    [previousViewController presentModalViewController:self animated:NO];
}

+ (void)present {
    LockScreenController *pinScreen = [[LockScreenController alloc] init];
    [pinScreen show];
    [pinScreen release];
}

- (void)hide {
    [self dismissModalViewControllerAnimated:NO];
}

- (void)lock {
    if (!appDelegate.locked) {
        pinViewController.textLabel.text = NSLocalizedString(@"Enter your PIN to unlock", nil);
        [self presentModalViewController:pinViewController animated:YES];
    }
}

- (void)unlock {
    appDelegate.locked = NO;
    [previousViewController dismissModalViewControllerAnimated:YES];
}

- (void)pinViewControllerDidShow:(PinViewController *)controller {
    appDelegate.locked = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Get the time when the application last exited
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate *exitTime = [userDefaults valueForKey:@"exitTime"];
    
    // Check if the PIN is enabled
    if ([userDefaults boolForKey:@"pinEnabled"] && exitTime != nil) {
        // Get the lock timeout (in seconds)
        NSInteger pinLockTimeout = timeoutValues[[userDefaults integerForKey:@"pinLockTimeout"]];
        
        // Check if it's been longer then lock timeout
        NSTimeInterval timeInterval = -[exitTime timeIntervalSinceNow];
        if (timeInterval > pinLockTimeout) {
            [self lock];
        } else {
            [self hide];
        }
    } else {
        [self hide];
    }
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {
    NSString *validPin = [SFHFKeychainUtils getPasswordForUsername:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin" error:nil];
    if (validPin == nil) {
        // Delete all data
        [appDelegate deleteAllData];
        
        // Hide spashscreen
        [self unlock];
    } else {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        // Check if the PIN is valid
        if ([pin isEqualToString:validPin]) {
            // Reset the number of pin failed attempts
            [userDefaults setInteger:0 forKey:@"pinFailedAttempts"];
            
            // Dismiss the pin view
            [self unlock];
        } else {
            // Vibrate to signify they are a bad user
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            [controller clearEntry];
            
            if (![userDefaults boolForKey:@"deleteOnFailureEnabled"]) {
                // Update the status message on the PIN view
                controller.textLabel.text = NSLocalizedString(@"Incorrect PIN", nil);
            } else {
                // Get the number of failed attempts
                NSInteger pinFailedAttempts = [userDefaults integerForKey:@"pinFailedAttempts"];
                [userDefaults setInteger:++pinFailedAttempts forKey:@"pinFailedAttempts"];
                
                // Get the number of failed attempts before deleting
                NSInteger deleteOnFailureAttempts = deleteOnFailureAttemptsValues[[userDefaults integerForKey:@"deleteOnFailureAttempts"]];
                
                // Update the status message on the PIN view
                NSInteger remainingAttempts = (deleteOnFailureAttempts - pinFailedAttempts);
                
                NSString *attemptsRemainingString;
                switch (remainingAttempts) {
                    case 1:
                        attemptsRemainingString = @"Incorrect PIN\n1 attempt remaining";
                        break;
                    case 2:
                        attemptsRemainingString = @"Incorrect PIN\n2 attempts remaining";
                        break;
                    case 3:
                        attemptsRemainingString = @"Incorrect PIN\n3 attempts remaining";
                        break;
                    case 4:
                        attemptsRemainingString = @"Incorrect PIN\n4 attempts remaining";
                        break;
                    case 5:
                        attemptsRemainingString = @"Incorrect PIN\n5 attempts remaining";
                        break;
                    case 6:
                        attemptsRemainingString = @"Incorrect PIN\n6 attempts remaining";
                        break;
                    case 7:
                        attemptsRemainingString = @"Incorrect PIN\n7 attempts remaining";
                        break;
                    case 8:
                        attemptsRemainingString = @"Incorrect PIN\n8 attempts remaining";
                        break;
                    case 9:
                        attemptsRemainingString = @"Incorrect PIN\n9 attempts remaining";
                        break;
                    case 10:
                        attemptsRemainingString = @"Incorrect PIN\n10 attempts remaining";
                        break;
                    case 11:
                        attemptsRemainingString = @"Incorrect PIN\n11 attempts remaining";
                        break;
                    case 12:
                        attemptsRemainingString = @"Incorrect PIN\n12 attempts remaining";
                        break;
                    case 13:
                        attemptsRemainingString = @"Incorrect PIN\n13 attempts remaining";
                        break;
                    case 14:
                        attemptsRemainingString = @"Incorrect PIN\n14 attempts remaining";
                        break;
                    default:
                        attemptsRemainingString = @"Incorrect PIN";
                        break;
                }
                
                controller.textLabel.text = NSLocalizedString(attemptsRemainingString, nil);
                
                // Check if they have failed too many times
                if (pinFailedAttempts >= deleteOnFailureAttempts) {
                    // Delete all data
                    [appDelegate deleteAllData];
                    
                    // Dismiss the pin view
                    [self unlock];
                }
            }
        }
    }
}

@end
