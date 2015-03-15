/*
 * Copyright 2011-2014 Jason Rush and John Flanagan. All rights reserved.
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
#import "LockScreenManager.h"
#import "LockViewController.h"
#import "MiniKeePassAppDelegate.h"
#import "AppSettings.h"
#import "KeychainUtils.h"
#import "PinViewController.h"
#import "PasswordUtils.h"

@interface LockScreenManager () <PinViewControllerDelegate>
@property (nonatomic, strong) LockViewController *lockViewController;
@property (nonatomic, strong) PinViewController *pinViewController;
@property (nonatomic, assign) BOOL unlocked;
@end

@implementation LockScreenManager

static LockScreenManager *sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidFinishLaunching:)
                                   name:UIApplicationDidFinishLaunchingNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationWillResignActive:)
                                   name:UIApplicationWillResignActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
    }
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

#pragma mark - Lock/Unlock

- (BOOL)shouldCheckPin {
    // Check if we're unlocked
    if (self.unlocked) {
        return NO;
    }

    // Check if the PIN is enabled
    AppSettings *appSettings = [AppSettings sharedInstance];
    if (![appSettings pinEnabled]) {
        return NO;
    }

    // Get the last time the app exited
    NSDate *exitTime = [appSettings exitTime];
    if (exitTime == nil) {
        return YES;
    }

    // Check if enough time has ellapsed
    NSTimeInterval timeInterval = ABS([exitTime timeIntervalSinceNow]);
    return timeInterval > [appSettings pinLockTimeout];
}

- (void)checkPin {
    // If the PIN view is already visible, just return
    if (self.pinViewController != nil) {
        [self.pinViewController clearPin];
        return;
    }

    // Ensure the lock screen is shown first
    if (self.lockViewController == nil) {
        [self showLockScreen];
    }

    // Show either the PIN view or perform Touch ID
    AppSettings *appSettings = [AppSettings sharedInstance];
    if ([appSettings touchIdEnabled]) {
        [self showTouchId];
    } else {
        [self showPinScreen];
    }
}

- (void)showLockScreen {
    if (self.lockViewController != nil) {
        return;
    }

    self.unlocked = false;

    self.lockViewController = [[LockViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.lockViewController];
    navigationController.toolbarHidden = NO;

    // Hack for iOS 8 to ensure the view is displayed before anything else on launch
    MiniKeePassAppDelegate *appDelegate = [MiniKeePassAppDelegate appDelegate];
    [appDelegate.window addSubview:navigationController.view];

    UIViewController *rootViewController = [LockScreenManager topMostController];
    [rootViewController presentViewController:navigationController animated:NO completion:nil];
}

- (void)hideLockScreen {
    if (self.lockViewController == nil) {
        return;
    }

    self.unlocked = true;

    [self.lockViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        self.lockViewController = nil;
        self.pinViewController = nil;
    }];
}

- (void)showPinScreen {
    self.pinViewController = [[PinViewController alloc] init];
    self.pinViewController.delegate = self;

    [self.lockViewController presentViewController:self.pinViewController animated:YES completion:nil];
}

- (void)showTouchId {
    // Check if TouchID is supported
    if (![NSClassFromString(@"LAContext") class]) {
        // Fallback to the PIN screen
        [self showPinScreen];
        return;
    }

    LAContext *context = [[LAContext alloc] init];
    context.localizedFallbackTitle = @""; // Hide the fallback button

    // Check if Touch ID is available
    NSError *error = nil;
    if (![context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        // Fallback to the PIN screen
        [self showPinScreen];
        return;
    }

    // Authenticate User
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            localizedReason:@"Unlock MiniKeePass" // FIXME translate
                      reply:^(BOOL success, NSError *error) {
                          if (success) {
                              // Dismiss the lock screen
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [self hideLockScreen];
                              });
                          } else {
                              // FIXME display the error message?
                              // FIXME Count this as a login failure?

                              // Failed, show the PIN screen
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [self showPinScreen];
                              });
                          }
                      }];
}

#pragma mark - PinViewController delegate methods

- (void)pinViewController:(PinViewController *)pinViewController pinEntered:(NSString *)pin {
    AppSettings *appSettings = [AppSettings sharedInstance];
    NSString *validPin = [appSettings pin];
    
    if (validPin == nil) {
        [pinViewController clearPin];
        pinViewController.titleLabel.text = NSLocalizedString(@"Error Checking PIN", nil);
    } else {
        // Check if the PIN is valid
        if ([PasswordUtils validatePassword:pin againstHash:validPin]) {
            // Reset the number of pin failed attempts
            [appSettings setPinFailedAttempts:0];

            // Dismiss the PIN screen
            [self hideLockScreen];
        } else {
            // Vibrate to signify they are a bad user
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            [pinViewController clearPin];

            if (![appSettings deleteOnFailureEnabled]) {
                // Update the status message on the PIN view
                pinViewController.titleLabel.text = NSLocalizedString(@"Incorrect PIN", nil);
            } else {
                // Get the number of failed attempts
                NSInteger pinFailedAttempts = [appSettings pinFailedAttempts];
                [appSettings setPinFailedAttempts:++pinFailedAttempts];

                // Get the number of failed attempts before deleting
                NSInteger deleteOnFailureAttempts = [appSettings deleteOnFailureAttempts];

                // Update the status message on the PIN view
                NSInteger remainingAttempts = (deleteOnFailureAttempts - pinFailedAttempts);

                // Update the incorrect pin message
                if (remainingAttempts > 0) {
                    pinViewController.titleLabel.text = [NSString stringWithFormat:@"%@\n%@: %ld", NSLocalizedString(@"Incorrect PIN", nil), NSLocalizedString(@"Attempts Remaining", nil), (long)remainingAttempts];
                } else {
                    pinViewController.titleLabel.text = NSLocalizedString(@"Incorrect PIN", nil);
                }

                // Check if they have failed too many times
                if (pinFailedAttempts >= deleteOnFailureAttempts) {
                    // Delete all data
                    MiniKeePassAppDelegate *appDelegate = [MiniKeePassAppDelegate appDelegate];
                    [appDelegate deleteAllData];

                    // Dismiss the PIN screen
                    [self hideLockScreen];
                }
            }
        }
    }
}

#pragma mark - Application Notification Handlers

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    if ([self shouldCheckPin]) {
        [self showLockScreen];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    AppSettings *appSettings = [AppSettings sharedInstance];
    if ([appSettings pinEnabled]) {
        [appSettings setExitTime:[NSDate date]];

        [self showLockScreen];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if ([self shouldCheckPin]) {
        [self checkPin];
    } else {
        [self hideLockScreen];
    }
}

#pragma mark - Helper method

+ (UIViewController *)topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}

@end
