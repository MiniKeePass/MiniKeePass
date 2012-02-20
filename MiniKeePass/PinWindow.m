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
#import "MiniKeePassAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "PinWindow.h"

@implementation PinWindow

static NSInteger timeoutValues[] = {0, 30, 60, 120, 300};
static NSInteger deleteOnFailureAttemptsValues[] = {3, 5, 10, 15};


- (id)init {
    self = [self initWithFrame:[[UIScreen mainScreen] bounds]];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        pinViewController = [[PinViewController alloc] init];
        pinViewController.delegate = self;
        splashScreenViewController = [[SplashScreenViewController alloc] init];
        self.rootViewController = splashScreenViewController;
        
        appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [pinViewController release];
    [splashScreenViewController release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)show {
    if (splashScreenViewController.view.hidden) {
        splashScreenViewController.view.hidden = NO;
    }
    
    if (!self.isKeyWindow) {
        [self makeKeyAndVisible];
    }
}

- (void)lock {
    [self show];
    if (splashScreenViewController.modalViewController == nil) {
        [splashScreenViewController presentModalViewController:pinViewController animated:YES];
    }
    appDelegate.locked = YES;
}

- (void)hide {
    if (splashScreenViewController.modalViewController != nil ) {
        splashScreenViewController.view.hidden = YES;
        [splashScreenViewController dismissModalViewControllerAnimated:YES];
    } else {
        appDelegate.locked = NO;
        self.hidden = YES;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self show];
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
        NSTimeInterval timeInterval = [exitTime timeIntervalSinceNow];
        if (timeInterval < -pinLockTimeout) {
            [self lock];
        } else {
            [self hide];
        }
    } else {
        [self hide];
    }
}

- (void)pinViewControllerDidAppear:(BOOL)animated {
    NSLog(@"junk");
}

- (void)pinViewControllerDidDisappear:(BOOL)animated {
    [self hide];
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {
    NSString *validPin = [SFHFKeychainUtils getPasswordForUsername:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin" error:nil];
    if (validPin == nil) {
        // Delete all data
        [appDelegate deleteAllData];
        
        // Hide spashscreen
        [self hide];
    } else {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        // Check if the PIN is valid
        if ([pin isEqualToString:validPin]) {
            // Reset the number of pin failed attempts
            [userDefaults setInteger:0 forKey:@"pinFailedAttempts"];
            
            // Dismiss the pin view
            [self hide];
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
                controller.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Incorrect PIN\n%d attempt%@ remaining", nil), remainingAttempts, remainingAttempts > 1 ? @"s" : @""];
                
                // Check if they have failed too many times
                if (pinFailedAttempts >= deleteOnFailureAttempts) {
                    // Delete all data
                    [appDelegate deleteAllData];
                    
                    // Dismiss the pin view
                    [self hide];
                }
            }
        }
    }
}

@end
