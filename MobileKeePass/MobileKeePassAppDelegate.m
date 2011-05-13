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
#import "OpenViewController.h"
#import "SettingsViewController.h"
#import "EntryViewController.h"
#import "DatabaseManager.h"
#import "SFHFKeychainUtils.h"

#define TIME_INTERVAL_BEFORE_PIN 0

@implementation MobileKeePassAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize databaseDocument;

static NSInteger pinLockTimeoutValues[] = {0, 30, 60, 120, 300};
static NSInteger deleteOnFailureAttemptsValues[] = {3, 5, 10};

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize the images array
    int i;
    for (i = 0; i < 70; i++) {
        images[i] = nil;
    }
    
    databaseDocument = nil;
    
    // Set the user defaults
    NSMutableDictionary *defaultsDict = [NSMutableDictionary dictionary];
    [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:@"pinEnabled"];
    [defaultsDict setValue:[NSNumber numberWithInt:1] forKey:@"pinLockTimeout"];
    [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:@"deleteOnFailureEnabled"];
    [defaultsDict setValue:[NSNumber numberWithInt:1] forKey:@"deleteOnFailureAttempts"];
    [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:@"rememberPasswordsEnabled"];
    [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:@"hidePasswords"];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:defaultsDict];
    
    // Create the root view
    groupViewController = [[GroupViewController alloc] initWithStyle:UITableViewStylePlain];
    groupViewController.title = @"KeePass";
    
    UIBarButtonItem *openButton = [[UIBarButtonItem alloc] initWithTitle:@"Open" style:UIBarButtonItemStyleBordered target:self action:@selector(openPressed:)];
    groupViewController.navigationItem.rightBarButtonItem = openButton;
    [openButton release];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(settingsPressed:)];
    groupViewController.navigationItem.leftBarButtonItem = settingsButton;
    [settingsButton release];
    
    // Create the navigation controller
    navigationController = [[UINavigationController alloc] initWithRootViewController:groupViewController];

    // Create the window
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = navigationController;
    [window makeKeyAndVisible];
    
    [self openLastDatabase];
    
    return YES;
}

- (void)dealloc {
    int i;
    for (i = 0; i < 70; i++) {
        [images[i] release];
    }
    [databaseDocument release];
    [groupViewController release];
    [navigationController release];
    [window release];
    [super dealloc];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Save the database document
    [databaseDocument save];
    
    // Store the current time as when the application exited
    NSDate *currentTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setValue:currentTime forKey:@"exitTime"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Check if the PIN is enabled
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:@"pinEnabled"]) {
        return;
    }

    // Get the time when the application last exited
    NSDate *exitTime = [userDefaults valueForKey:@"exitTime"];
    if (exitTime == nil) {
        return;
    }

    // Get the lock timeout (in seconds)
    NSInteger pinLockTimeout = pinLockTimeoutValues[[userDefaults integerForKey:@"pinLockTimeout"]];
    
    // Check if it's been longer then lock timeout
    NSTimeInterval timeInterval = [exitTime timeIntervalSinceNow];
    if (timeInterval < -pinLockTimeout) {
        [window.rootViewController dismissModalViewControllerAnimated:NO];

        // Present the pin view
        PinViewController *pinViewController = [[PinViewController alloc] init];
        pinViewController.delegate = self;
        [window.rootViewController presentModalViewController:pinViewController animated:YES];
        [pinViewController release];
    }
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    // Prevent PIN view from showing by deleting exitTime
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"exitTime"];
    
    [self closeDatabase];
    
    // Retrieve the Documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *filename = [url lastPathComponent];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    
    NSURL *newUrl = [NSURL fileURLWithPath:path];
    
    // Move input file into documents directory
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:newUrl error:nil];
    [fileManager moveItemAtURL:url toURL:newUrl error:nil];
    [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"Inbox"] error:nil];
    [fileManager release];
    
    // Load the database
    [[DatabaseManager sharedInstance] openDatabaseDocument:path animated:NO];
    
    return YES;
}

- (DatabaseDocument*)databaseDocument {
    return databaseDocument;
}

- (void)setDatabaseDocument:(DatabaseDocument *)newDatabaseDocument {
    databaseDocument = [newDatabaseDocument retain];
    groupViewController.group = [databaseDocument.kdbTree getRoot];
}

- (void)closeDatabase {
    // Clear the last filename
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"lastFilename"];
    
    groupViewController.group = nil;
    
    if ([navigationController.topViewController isKindOfClass:[GroupViewController class]] || [navigationController.topViewController isKindOfClass:[EntryViewController class]]) {
        [navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)openLastDatabase {
    // Get the last filename
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *lastFilename = [userDefaults stringForKey:@"lastFilename"];
    if (lastFilename == nil) {
        return;
    }
    
    [[DatabaseManager sharedInstance] openDatabaseDocument:lastFilename animated:NO];
}

- (UIImage*)loadImage:(int)index {
    if (images[index] == nil) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%d", index] ofType:@"png"];
        images[index] = [[UIImage imageWithContentsOfFile:imagePath] retain];
    }
    
    return images[index];
}

- (void)openPressed:(id)sender {
    OpenViewController *openViewController = [[OpenViewController alloc] initWithStyle:UITableViewStylePlain];
    
    // Push the OpenViewController onto the view stack
    [navigationController pushViewController:openViewController animated:YES];
    [openViewController release];
}

- (void)settingsPressed:(id)sender {    
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    settingsViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(dismissSettingsPage:)];
    
    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    [settingsViewController release];
    
    settingsViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [window.rootViewController presentModalViewController:settingsNavigationController animated:YES];
    [settingsNavigationController release];
}

- (void)dismissSettingsPage:(id)sender {
    [window.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {
    NSError *error;
    NSString *validPin = [SFHFKeychainUtils getPasswordForUsername:@"PIN" andServiceName:@"net.fizzawizza.MobileKeePass" error:&error];
    if (error != nil || validPin == nil) {
        // TODO error/no pin, close database
        return;
    }
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    // Check if the PIN is valid
    if ([pin isEqualToString:validPin]) {
        [userDefaults setInteger:0 forKey:@"pinFailedAttempts"];
        [controller dismissModalViewControllerAnimated:YES];
        return;
    } 
    
    // Vibrate to signify they are a bad user
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    controller.string = @"Incorrect PIN";
    [controller clearEntry];
    
    if ([userDefaults boolForKey:@"deleteOnFailureEnabled"]) {
        // Get the number of failed attempts
        NSInteger pinFailedAttempts = [userDefaults integerForKey:@"pinFailedAttempts"];
        [userDefaults setInteger:++pinFailedAttempts forKey:@"pinFailedAttempts"];

        // Get the number of failed attempts before deleting
        NSInteger deleteOnFailureAttempts = deleteOnFailureAttemptsValues[[userDefaults integerForKey:@"deleteOnFailureAttempts"]];

        // Check if they have failed too many times
        if (pinFailedAttempts >= deleteOnFailureAttempts) {
            // Close the current database
            [self closeDatabase];
            
            // Reset some settings
            [userDefaults setInteger:0 forKey:@"pinFailedAttempts"];
            [userDefaults setBool:NO forKey:@"pinEnabled"];
            
            // Delete all our information from the keychain
            [SFHFKeychainUtils deleteAllItemForServiceName:@"net.fizzawizza.MobileKeePass" error:nil];
            
            // Get the files in the Documents directory
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSArray *files = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
            
            // Delete all the files in the Documents directory
            for (NSString *file in files) {
                [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:file] error:nil];
            }
            
            // Dismiss the pin view
            [controller dismissModalViewControllerAnimated:YES];
        }
    }
}

- (void)pinViewControllerCancelButtonPressed:(PinViewController *)controller {
    NSString* title = @"Canceling PIN entry will lock active database";
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"Close Database" destructiveButtonTitle:nil otherButtonTitles:@"Try Again", nil];
    actionSheet.actionSheetStyle = UIActivityIndicatorViewStyleGray;
    [actionSheet showInView:window];
    [actionSheet release];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self closeDatabase];
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"lastFilename"];
        [window.rootViewController dismissModalViewControllerAnimated:YES];        
    }
}

@end
