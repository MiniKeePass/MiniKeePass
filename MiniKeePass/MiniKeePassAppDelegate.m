/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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
<<<<<<< HEAD
<<<<<<< HEAD
#import "SFHFKeychainUtils.h"
#import "LockScreenController.h"
#import "DropboxManager.h"
#import <DropboxSDK/DropboxSDK.h>
=======
#import "KeychainUtils.h"
#import "LockScreenManager.h"
>>>>>>> MiniKeePass/master
||||||| merged common ancestors
#import "SFHFKeychainUtils.h"
#import "LockScreenController.h"
=======
#import "KeychainUtils.h"
#import "LockScreenManager.h"
>>>>>>> MiniKeePass/master

@interface MiniKeePassAppDelegate ()

@property (nonatomic, strong) FilesViewController *filesViewController;;
@property (nonatomic, strong) UINavigationController *navigationController;

@end

@implementation MiniKeePassAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _databaseDocument = nil;

    // Create the files view
<<<<<<< HEAD
<<<<<<< HEAD
    FilesViewController *filesViewController = [[[FilesViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    navigationController = [[UINavigationController alloc] initWithRootViewController:filesViewController];
    navigationController.toolbarHidden = NO;
        
=======
    self.filesViewController = [[FilesViewController alloc] initWithStyle:UITableViewStylePlain];

    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.filesViewController];
    self.navigationController.toolbarHidden = NO;

>>>>>>> MiniKeePass/master
||||||| merged common ancestors
    FilesViewController *filesViewController = [[[FilesViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    navigationController = [[UINavigationController alloc] initWithRootViewController:filesViewController];
    navigationController.toolbarHidden = NO;
    
=======
    self.filesViewController = [[FilesViewController alloc] initWithStyle:UITableViewStylePlain];

    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.filesViewController];
    self.navigationController.toolbarHidden = NO;

>>>>>>> MiniKeePass/master
    // Create the window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
<<<<<<< HEAD
<<<<<<< HEAD

    // Initialize and update the Dropbox manager
    DropboxManager *dropManager = [DropboxManager singleton];
    dropManager.rootController = filesViewController;
    [dropManager connect];

    // Check if backgrounding is supported
    _backgroundSupported = [[UIDevice currentDevice] isMultitaskingSupported];
    
    // Add a pasteboard notification listener is backgrounding is supported
    if (self.backgroundSupported) {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handlePasteboardNotification:) name:UIPasteboardChangedNotification object:nil];
    }
=======
>>>>>>> MiniKeePass/master
||||||| merged common ancestors
    
    // Check if backgrounding is supported
    _backgroundSupported = [[UIDevice currentDevice] isMultitaskingSupported];
    
    // Add a pasteboard notification listener is backgrounding is supported
    if (self.backgroundSupported) {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handlePasteboardNotification:) name:UIPasteboardChangedNotification object:nil];
    }
=======
>>>>>>> MiniKeePass/master

    // Add a pasteboard notification listener to support clearing the clipboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handlePasteboardNotification:)
                               name:UIPasteboardChangedNotification
                             object:nil];

<<<<<<< HEAD
    // Check file protection
    [self checkFileProtection];
||||||| merged common ancestors
    return YES;
}
=======
    [self checkFileProtection];
>>>>>>> MiniKeePass/master

    // Initialize the lock screen manager
    [LockScreenManager sharedInstance];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
<<<<<<< HEAD
    // Check file protection
    [self checkFileProtection];
||||||| merged common ancestors
    // Check if we're supposed to open a file
    if (self.fileToOpen != nil) {
        // Close the current database
        [self closeDatabase];
        
        // Open the file
        [[DatabaseManager sharedInstance] openDatabaseDocument:self.fileToOpen animated:NO];
        
        self.fileToOpen = nil;
    }
=======
    // Check file protection
    [self checkFileProtection];
}
>>>>>>> MiniKeePass/master

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self importUrl:url];

    return YES;
}

<<<<<<< HEAD
        // Check if it's been longer then close timeout
        NSTimeInterval timeInterval = [exitTime timeIntervalSinceNow];
        if (timeInterval < -closeTimeout) {
            [self closeDatabase];
        }
    }
||||||| merged common ancestors
        // Check if it's been longer then lock timeout
        NSTimeInterval timeInterval = [exitTime timeIntervalSinceNow];
        if (timeInterval < -closeTimeout) {
            [self closeDatabase];
        }
    }
=======
+ (MiniKeePassAppDelegate *)appDelegate {
    return [[UIApplication sharedApplication] delegate];
>>>>>>> MiniKeePass/master
}

<<<<<<< HEAD
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self importUrl:url];

    return YES;
}

+ (MiniKeePassAppDelegate *)appDelegate {
    return [[UIApplication sharedApplication] delegate];
||||||| merged common ancestors
- (CGFloat)currentScreenWidth {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    return UIInterfaceOrientationIsPortrait(orientation) ? CGRectGetWidth(screenRect) : CGRectGetHeight(screenRect);
=======
+ (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
>>>>>>> MiniKeePass/master
}

<<<<<<< HEAD
+ (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

- (void)importUrl:(NSURL *)url {
||||||| merged common ancestors
- (void)openUrl:(NSURL *)url {
=======
- (void)importUrl:(NSURL *)url {
>>>>>>> MiniKeePass/master
    // Get the filename
    NSString *filename = [url lastPathComponent];

    // Get the full path of where we're going to move the file
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];

    // Move input file into documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
<<<<<<< HEAD
    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
        if (isDirectory) {
            // Should not have been passed a directory
            return;
        } else {
            [fileManager removeItemAtPath:path error:nil];
        }
    }
    [fileManager moveItemAtURL:url toURL:[NSURL fileURLWithPath:path] error:nil];

<<<<<<< HEAD
- (BOOL) commonHandleURL: (NSURL *) url
{
    // Deal with drop box login method
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked])
        {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
||||||| merged common ancestors
    [fileManager removeItemAtURL:newUrl error:nil];
    [fileManager moveItemAtURL:url toURL:newUrl error:nil];
    [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"Inbox"] error:nil];
    
    // Store the filename to open if it's a database
    if ([filename hasSuffix:@".kdb"] || [filename hasSuffix:@".kdbx"]) {
        self.fileToOpen = [filename copy];
    } else {
        self.fileToOpen = nil;
        FilesViewController *fileView = [[navigationController viewControllers] objectAtIndex:0];
        [fileView updateFiles];
        [fileView.tableView reloadData];
=======
    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
        if (isDirectory) {
            // Should not have been passed a directory
            return;
        } else {
            [fileManager removeItemAtPath:path error:nil];
        }
>>>>>>> MiniKeePass/master
    }
<<<<<<< HEAD
    
    [self openUrl:url];
    return YES;    
}
||||||| merged common ancestors
}
=======
    [fileManager moveItemAtURL:url toURL:[NSURL fileURLWithPath:path] error:nil];
>>>>>>> MiniKeePass/master

<<<<<<< HEAD
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [self commonHandleURL:url];
}
||||||| merged common ancestors
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [self openUrl:url];
    return YES;
}
=======
    // Set file protection on the new file
    [fileManager setAttributes:@{NSFileProtectionKey:NSFileProtectionComplete} ofItemAtPath:path error:nil];
>>>>>>> MiniKeePass/master

<<<<<<< HEAD
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self commonHandleURL:url];
=======
    // Set file protection on the new file
    [fileManager setAttributes:@{NSFileProtectionKey:NSFileProtectionComplete} ofItemAtPath:path error:nil];

    // Delete the Inbox folder if it exists
    [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"Inbox"] error:nil];

    [self.filesViewController updateFiles];
    [self.filesViewController.tableView reloadData];
>>>>>>> MiniKeePass/master
||||||| merged common ancestors
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self openUrl:url];
    return YES;
=======
    // Delete the Inbox folder if it exists
    [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"Inbox"] error:nil];

    [self.filesViewController updateFiles];
    [self.filesViewController.tableView reloadData];
>>>>>>> MiniKeePass/master
}

- (void)setDatabaseDocument:(DatabaseDocument *)newDatabaseDocument {
    if (_databaseDocument != nil) {
        [self closeDatabase];
    }
    
    _databaseDocument = newDatabaseDocument;
    
    // Create and push on the root group view controller
    GroupViewController *groupViewController = [[GroupViewController alloc] initWithGroup:_databaseDocument.kdbTree.root];
    groupViewController.title = [[_databaseDocument.filename lastPathComponent] stringByDeletingPathExtension];
    
    [self.navigationController pushViewController:groupViewController animated:YES];
}

- (void)closeDatabase {
    // Close any open database views
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    _databaseDocument = nil;
}

- (void)deleteKeychainData {
    // Reset some settings
    AppSettings *appSettings = [AppSettings sharedInstance];
    [appSettings setPinFailedAttempts:0];
    [appSettings setPinEnabled:NO];
    [appSettings setTouchIdEnabled:NO];

    // Delete the PIN from the keychain
    [KeychainUtils deleteStringForKey:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin"];

    // Delete all database passwords from the keychain
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.passwords"];
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.keyfiles"];
}

- (void)deleteAllData {
    // Close the current database
    [self closeDatabase];

    // Delete data stored in system keychain
    [self deleteKeychainData];

    // Get the files in the Documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    // Delete all the files in the Documents directory
    for (NSString *file in files) {
        [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:file] error:nil];
    }
}

- (void)checkFileProtection {
    // Get the document's directory
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    // Check all files to see if protection is enabled
    for (NSString *file in dirContents) {
        if (![file hasPrefix:@"."]) {
            NSString *path = [documentsDirectory stringByAppendingPathComponent:file];

            BOOL dir = NO;
            [fileManager fileExistsAtPath:path isDirectory:&dir];
            if (!dir) {
                // Make sure file protecten is turned on
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
                NSString *fileProtection = [attributes valueForKey:NSFileProtectionKey];
                if (![fileProtection isEqualToString:NSFileProtectionComplete]) {
                    [fileManager setAttributes:@{NSFileProtectionKey:NSFileProtectionComplete} ofItemAtPath:path error:nil];
                }
            }
        }
    }
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

        UIApplication *application = [UIApplication sharedApplication];

        // Initiate a background task
        __block UIBackgroundTaskIdentifier bgTask;
        bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
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
    
    UINavigationController *settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    
    [self.window.rootViewController presentViewController:settingsNavController animated:YES completion:nil];
}

- (void)dismissSettingsView {
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
