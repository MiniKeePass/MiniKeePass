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

#import "MiniKeePassAppDelegate.h"
#import "GroupViewController.h"
#import "SettingsViewController.h"
#import "EntryViewController.h"
#import "AppSettings.h"
#import "DatabaseManager.h"
#import "SFHFKeychainUtils.h"
#import "LockScreenController.h"

@implementation MiniKeePassAppDelegate

@synthesize window;
@synthesize locked;
@synthesize databaseDocument;
@synthesize backgroundSupported;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize the images array
    int i;
    for (i = 0; i < NUM_IMAGES; i++) {
        images[i] = nil;
    }
    
    databaseDocument = nil;
    
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

    [LockScreenController present];

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
    [self dismissActionSheet];
    if (!self.locked) {
        [LockScreenController present];
        NSDate *currentTime = [NSDate date];
        [[AppSettings sharedInstance] setExitTime:currentTime];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Check if we're supposed to open a file
    if (fileToOpen != nil) {
        // Close the current database
        [self closeDatabase];
        
        // Open the file
        [[DatabaseManager sharedInstance] openDatabaseDocument:fileToOpen animated:NO];
        
        [fileToOpen release];
        fileToOpen = nil;
    }

    // Get the time when the application last exited
    AppSettings *appSettings = [AppSettings sharedInstance];
    NSDate *exitTime = [appSettings exitTime];

    // Check if closing the database is enabled
    if ([appSettings closeEnabled] && exitTime != nil) {
        // Get the lock timeout (in seconds)
        NSInteger closeTimeout = [appSettings closeTimeout];

        // Check if it's been longer then lock timeout
        NSTimeInterval timeInterval = [exitTime timeIntervalSinceNow];
        if (timeInterval < -closeTimeout) {
            [self closeDatabase];
        }
    }
}

- (CGFloat)currentScreenWidth {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    return UIInterfaceOrientationIsPortrait(orientation) ? CGRectGetWidth(screenRect) : CGRectGetHeight(screenRect);
}

- (void)openUrl:(NSURL *)url {
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
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [self openUrl:url];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self openUrl:url];
    return YES;
}

- (DatabaseDocument *)databaseDocument {
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
    AppSettings *appSettings = [AppSettings sharedInstance];
    [appSettings setPinFailedAttempts:0];
    [appSettings setPinEnabled:NO];
    
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

- (UIImage *)loadImage:(NSUInteger)index {
    if (index >= NUM_IMAGES) {
        return nil;
    }
    
    if (images[index] == nil) {
        images[index] = [[UIImage imageNamed:[NSString stringWithFormat:@"%d", index]] retain];
    }
    
    return images[index];
}

- (void)handlePasteboardNotification:(NSNotification *)notification {
    // Check if the clipboard has any contents
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (pasteboard.string == nil || [pasteboard.string isEqualToString:@""]) {
        return;
    }
    
    AppSettings *appSettings = [AppSettings sharedInstance];

    // Check if the clearing the clipboard is enabled
    if ([appSettings clearClipboardEnabled]) {
        // Get the "version" of the pasteboard contents
        NSInteger pasteboardVersion = pasteboard.changeCount;

        // Get the clear clipboard timeout (in seconds)
        NSInteger clearClipboardTimeout = [appSettings clearClipboardTimeout];
        
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

- (void)showActionSheet:(UIActionSheet *)actionSheet {
    if (myActionSheet != nil) {
        [myActionSheet dismissWithClickedButtonIndex:myActionSheet.cancelButtonIndex animated:NO];
    }

    myActionSheet = [actionSheet retain];
    myActionSheetDelegate = actionSheet.delegate;
    
    actionSheet.delegate = self;
    [actionSheet showInView:window.rootViewController.view];
    [actionSheet release];
}

- (void)dismissActionSheet {
    if (myActionSheet != nil) {
        [myActionSheet dismissWithClickedButtonIndex:myActionSheet.cancelButtonIndex animated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)]) {
        [myActionSheetDelegate actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)]) {
        [myActionSheetDelegate actionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
    }
    
    myActionSheet = nil;
    myActionSheetDelegate = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)]) {
        [myActionSheetDelegate actionSheet:actionSheet willDismissWithButtonIndex:buttonIndex];
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    if ([myActionSheetDelegate respondsToSelector:@selector(actionSheetCancel:)]) {
        [myActionSheetDelegate actionSheetCancel:actionSheet];
    }
}

@end
