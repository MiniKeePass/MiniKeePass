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
#import "GroupViewController.h"
#import "SearchViewController.h"
#import "SettingsViewController.h"
#import "EntryViewController.h"
#import "DatabaseManager.h"
#import "SFHFKeychainUtils.h"

@implementation MobileKeePassAppDelegate

@synthesize window;
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
        
    // Create the files view
    filesViewController = [[FilesViewController alloc] initWithStyle:UITableViewStylePlain];
    filesViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Files" image:[UIImage imageNamed:@"tab_files.png"] tag:2];
    UINavigationController *filesNavController = [[UINavigationController alloc] initWithRootViewController:filesViewController];
    
    // Create the search view
    searchViewController = [[SearchViewController alloc] init];
    searchViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Search" image:[UIImage imageNamed:@"tab_search.png"] tag:1];
    UINavigationController *searchNavController = [[UINavigationController alloc] initWithRootViewController:searchViewController];
    
    // Create the settings view
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    settingsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage imageNamed:@"tab_gear.png"] tag:3];
    UINavigationController *settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    [settingsViewController release];
    
    // Create the tab bar controller
    tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = [NSArray arrayWithObjects:filesNavController, searchNavController, settingsNavController, nil];
    
    [filesNavController release];
    [searchNavController release];
    [settingsNavController release];
    
    // Create the window
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = tabBarController;
    [window makeKeyAndVisible];
    
    return YES;
}

- (void)dealloc {
    int i;
    for (i = 0; i < 70; i++) {
        [images[i] release];
    }
    [databaseDocument release];
    [fileToOpen release];
    [filesViewController release];
    [searchViewController release];
    [tabBarController release];
    [window release];
    [super dealloc];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Store the current time as when the application exited
    NSDate *currentTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setValue:currentTime forKey:@"exitTime"];
    
    [self dismissActionSheet];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Check if we're supposed to open a file
    if (fileToOpen != nil) {
        [tabBarController setSelectedIndex:0];
        
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

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Get the filename
    NSString *filename = [url lastPathComponent];
    
    // Get the full path of where we're going to move the file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    
    NSURL *newUrl = [NSURL fileURLWithPath:path];
    
    // Move input file into documents directory
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:newUrl error:nil];
    [fileManager moveItemAtURL:url toURL:newUrl error:nil];
    [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"Inbox"] error:nil];
    [fileManager release];
    
    // Store the filename to open
    [fileToOpen release];
    fileToOpen = [filename copy];
    
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
    [filesViewController.navigationController pushViewController:groupViewController animated:YES];
    [groupViewController release];
    
    // Clear the search view controller
    [searchViewController clearResults];
}

- (void)closeDatabase {
    // Close any open database views
    [filesViewController.navigationController popToRootViewControllerAnimated:NO];
    
    // Clear the search view controller
    [searchViewController clearResults];
    
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
    [SFHFKeychainUtils deleteItemForUsername:@"PIN" andServiceName:@"net.fizzawizza.MobileKeePass.pin" error:nil];
    
    // Delete all database passwords from the keychain
    [SFHFKeychainUtils deleteAllItemForServiceName:@"net.fizzawizza.MobileKeePass.passwords" error:nil];
    
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

- (UIImage*)loadImage:(int)index {
    if (images[index] == nil) {
        images[index] = [[UIImage imageNamed:[NSString stringWithFormat:@"%d.png", index]] retain];
    }
    
    return images[index];
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {
    NSString *validPin = [SFHFKeychainUtils getPasswordForUsername:@"PIN" andServiceName:@"net.fizzawizza.MobileKeePass.pin" error:nil];
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

-(void)dismissActionSheet {
    if (myActionSheet != nil) {
        [myActionSheet dismissWithClickedButtonIndex:myActionSheet.cancelButtonIndex animated:YES];
    }
}

-(void)showActionSheet:(UIActionSheet *)actionSheet {
    if (myActionSheet != nil) {
        [myActionSheet dismissWithClickedButtonIndex:myActionSheet.cancelButtonIndex animated:NO];
    }

    myActionSheet = [actionSheet retain];
    myActionSheetDelegate = actionSheet.delegate;
    
    actionSheet.delegate = self;
    [actionSheet showInView:window];
    [actionSheet release];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)]) {
        [myActionSheetDelegate actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)]) {
        [myActionSheetDelegate actionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    
    myActionSheet = nil;
    myActionSheetDelegate = nil;
}

-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex{
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)]) {
        [myActionSheetDelegate actionSheet:actionSheet willDismissWithButtonIndex:buttonIndex];
    }
}

-(void)actionSheetCancel:(UIActionSheet *)actionSheet {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheetCancel:)]) {
        [myActionSheetDelegate actionSheetCancel:actionSheet];
    }
}

@end
