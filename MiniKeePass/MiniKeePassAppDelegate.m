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
#import "GroupViewController.h"
#import "SettingsViewController.h"
#import "EntryViewController.h"
#import "DatabaseManager.h"
#import "SFHFKeychainUtils.h"

@implementation MiniKeePassAppDelegate

@synthesize window;
@synthesize databaseDocument;
@synthesize backgroundSupported;

static NSInteger pinLockTimeoutValues[] = {0, 30, 60, 120, 300};
static NSInteger deleteOnFailureAttemptsValues[] = {3, 5, 10};
static NSInteger clearClipboardTimeoutValues[] = {30, 60, 120, 180};

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize the images array
    int i;
    for (i = 0; i < NUM_IMAGES; i++) {
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
    [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:@"clearClipboardEnabled"];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:defaultsDict];
    
    // Create the files view
    FilesViewController *filesViewController = [[FilesViewController alloc] initWithStyle:UITableViewStylePlain];
    navigationController = [[UINavigationController alloc] initWithRootViewController:filesViewController];
    [filesViewController release];
    
    navigationController.toolbarHidden = NO;
    
    // Create the window
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = navigationController;
    [window makeKeyAndVisible];
    
    // Check if backgrounding is supported
    backgroundSupported = FALSE;
    UIDevice* device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
        backgroundSupported = device.multitaskingSupported;
    }
    
    // Add a pasteboard notification listener is backgrounding is supported
    if (backgroundSupported) {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handlePasteboardNotification:) name:UIPasteboardChangedNotification object:nil];
    }
    
    return YES;
}

- (void)dealloc {
    int i;
    for (i = 0; i < NUM_IMAGES; i++) {
        [images[i] release];
    }
    [databaseDocument release];
    [fileToOpen release];
    [navigationController release];
    [window release];
    [super dealloc];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Store the current time as when the application exited
    NSDate *currentTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setValue:currentTime forKey:@"exitTime"];
    
    [self dismissActionSheet];
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
    // Check if we're supposed to open a file
    if (fileToOpen != nil) {
        // Close the current database
        [self closeDatabase];
        
        // Open the file
        [[DatabaseManager sharedInstance] openDatabaseDocument:fileToOpen animated:NO];
        
        [fileToOpen release];
        fileToOpen = nil;
    }
    
    // Check if the PIN is enabled
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"pinEnabled"]) {
        // Get the time when the application last exited
        NSDate *exitTime = [userDefaults valueForKey:@"exitTime"];
        if (exitTime != nil) {
            // Get the lock timeout (in seconds)
            NSInteger pinLockTimeout = pinLockTimeoutValues[[userDefaults integerForKey:@"pinLockTimeout"]];
            
            // Check if it's been longer then lock timeout
            NSTimeInterval timeInterval = [exitTime timeIntervalSinceNow];
            if (timeInterval < -pinLockTimeout) {
                UIViewController *frontViewController = window.rootViewController;
                while (frontViewController.modalViewController != nil) {
                    frontViewController = frontViewController.modalViewController;
                }
                
                // Check if the pin view is already on the screen
                if (![frontViewController isKindOfClass:[PinViewController class]]) {
                    // Present the pin view
                    PinViewController *pinViewController = [[PinViewController alloc] init];
                    pinViewController.delegate = self;
                    [frontViewController presentModalViewController:pinViewController animated:YES];
                    [pinViewController release];            
                }
            }
        }
    }
}

- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    // Get the filename
    NSString *filename = [url lastPathComponent];
    
    // Get the full path of where we're going to move the file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    
    NSURL *newUrl = [NSURL fileURLWithPath:path];
    
    // Move input file into documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:newUrl error:nil];
    [fileManager moveItemAtURL:url toURL:newUrl error:nil];
    [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"Inbox"] error:nil];
    
    // Store the filename to open if it's a database
    [fileToOpen release];
    if ([filename hasSuffix:@".kdb"] || [filename hasSuffix:@".kdbx"]) {
        fileToOpen = [filename copy];
    } else {
        fileToOpen = nil;
        FilesViewController *fileView = [[navigationController viewControllers] objectAtIndex:0];
        [fileView updateFiles];
        [fileView.tableView reloadData];
    }
    
    return YES;
}

- (DatabaseDocument*)databaseDocument {
    return databaseDocument;
}

- (void)setDatabaseDocument:(DatabaseDocument *)newDatabaseDocument {
    if (databaseDocument != nil) {
        [self closeDatabase];
    }
    
    databaseDocument = [newDatabaseDocument retain];
    
    // Create and push on the root group view controller
    GroupViewController *groupViewController = [[GroupViewController alloc] initWithStyle:UITableViewStylePlain];
    groupViewController.title = [[databaseDocument.filename lastPathComponent] stringByDeletingPathExtension];
    groupViewController.group = databaseDocument.kdbTree.root;
    [navigationController pushViewController:groupViewController animated:YES];
    [groupViewController release];
}

- (void)closeDatabase {
    // Close any open database views
    [navigationController popToRootViewControllerAnimated:NO];
    
    [databaseDocument release];
    databaseDocument = nil;
}

- (void)deleteAllData {
    // Close the current database
    [self closeDatabase];
    
    // Reset some settings
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:0 forKey:@"pinFailedAttempts"];
    [userDefaults setBool:NO forKey:@"pinEnabled"];
    
    // Delete the PIN from the keychain
    [SFHFKeychainUtils deleteItemForUsername:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin" error:nil];
    
    // Delete all database passwords from the keychain
    [SFHFKeychainUtils deleteAllItemForServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
    [SFHFKeychainUtils deleteAllItemForServiceName:@"com.jflan.MiniKeePass.keyfiles" error:nil];
    
    // Get the files in the Documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    // Delete all the files in the Documents directory
    for (NSString *file in files) {
        [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:file] error:nil];
    }
}

- (UIImage*)loadImage:(NSUInteger)index {
    if (index >= NUM_IMAGES) {
        return nil;
    }
    
    if (images[index] == nil) {
        images[index] = [[UIImage imageNamed:[NSString stringWithFormat:@"%d", index]] retain];
    }
    
    return images[index];
}

- (void)handlePasteboardNotification:(NSNotification*)notification {
    // Check if the clipboard has any contents
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (pasteboard.string == nil || [pasteboard.string isEqualToString:@""]) {
        return;
    }
    
    // Check if the clearing the clipboard is enabled
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"clearClipboardEnabled"]) {
        // Get the "version" of the pasteboard contents
        NSInteger pasteboardVersion = pasteboard.changeCount;

        // Get the clear clipboard timeout (in seconds)
        NSInteger clearClipboardTimeout = clearClipboardTimeoutValues[[userDefaults integerForKey:@"clearClipboardTimeout"]];
        
        // Initiate a background task
        UIApplication *application = [UIApplication sharedApplication];
        UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            // End the background task
            [application endBackgroundTask:bgTask];
        }];
        
        // Start the long-running task and return immediately.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Sleep until it's time to clean the clipboard
            [NSThread sleepForTimeInterval:clearClipboardTimeout];
            
            // Clear the clipboard if it hasn't changed
            if (pasteboardVersion == pasteboard.changeCount) {
                pasteboard.string = @"";
            }
            
            // End the background task
            [application endBackgroundTask:bgTask];
        });
    }
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {
    NSString *validPin = [SFHFKeychainUtils getPasswordForUsername:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin" error:nil];
    if (validPin == nil) {
        // Delete all data
        [self deleteAllData];
        
        // Dismiss the pin view
        [controller dismissModalViewControllerAnimated:YES];
    } else {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        // Check if the PIN is valid
        if ([pin isEqualToString:validPin]) {
            // Reset the number of pin failed attempts
            [userDefaults setInteger:0 forKey:@"pinFailedAttempts"];
            
            // Dismiss the pin view
            [controller dismissModalViewControllerAnimated:YES];
        } else {
            // Vibrate to signify they are a bad user
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            [controller clearEntry];
            
            if (![userDefaults boolForKey:@"deleteOnFailureEnabled"]) {
                // Update the status message on the PIN view
                controller.textLabel.text = @"Incorrect PIN";
            } else {
                // Get the number of failed attempts
                NSInteger pinFailedAttempts = [userDefaults integerForKey:@"pinFailedAttempts"];
                [userDefaults setInteger:++pinFailedAttempts forKey:@"pinFailedAttempts"];
                
                // Get the number of failed attempts before deleting
                NSInteger deleteOnFailureAttempts = deleteOnFailureAttemptsValues[[userDefaults integerForKey:@"deleteOnFailureAttempts"]];
                
                // Update the status message on the PIN view
                NSInteger remainingAttempts = (deleteOnFailureAttempts - pinFailedAttempts);
                controller.textLabel.text = [NSString stringWithFormat:@"Incorrect PIN\n%d attempt%@ remaining", remainingAttempts, remainingAttempts > 1 ? @"s" : @""];
                
                // Check if they have failed too many times
                if (pinFailedAttempts >= deleteOnFailureAttempts) {
                    // Delete all data
                    [self deleteAllData];
                    
                    // Dismiss the pin view
                    [controller dismissModalViewControllerAnimated:YES];
                }
            }
        }
    }
}

- (void)dismissActionSheet {
    if (myActionSheet != nil) {
        [myActionSheet dismissWithClickedButtonIndex:myActionSheet.cancelButtonIndex animated:YES];
    }
}

- (void)showSettingsView {
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSettingsView)];
    settingsViewController.navigationItem.rightBarButtonItem = doneButton;
    [doneButton release];
    
    UINavigationController *settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    settingsNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [window.rootViewController presentModalViewController:settingsNavController animated:YES];

    [settingsViewController release];
    [settingsNavController release];
}

- (void)dismissSettingsView {
    [window.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)showActionSheet:(UIActionSheet*)actionSheet {
    if (myActionSheet != nil) {
        [myActionSheet dismissWithClickedButtonIndex:myActionSheet.cancelButtonIndex animated:NO];
    }

    myActionSheet = [actionSheet retain];
    myActionSheetDelegate = actionSheet.delegate;
    
    actionSheet.delegate = self;
    [actionSheet showInView:window];
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)]) {
        [myActionSheetDelegate actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
    }
}

- (void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)]) {
        [myActionSheetDelegate actionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    
    myActionSheet = nil;
    myActionSheetDelegate = nil;
}

- (void)actionSheet:(UIActionSheet*)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)]) {
        [myActionSheetDelegate actionSheet:actionSheet willDismissWithButtonIndex:buttonIndex];
    }
}

- (void)actionSheetCancel:(UIActionSheet*)actionSheet {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheetCancel:)]) {
        [myActionSheetDelegate actionSheetCancel:actionSheet];
    }
}

@end
