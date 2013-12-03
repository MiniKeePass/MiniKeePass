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
#import "KeychainUtils.h"
#import "LockScreenController.h"

@interface MiniKeePassAppDelegate ()  {
    UINavigationController *navigationController;

    UIImage *images[NUM_IMAGES];
}

@property (nonatomic, copy) NSString *fileToOpen;

@end

@implementation MiniKeePassAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize the images array
    int i;
    for (i = 0; i < NUM_IMAGES; i++) {
        images[i] = nil;
    }
    
    _databaseDocument = nil;
    
    // Create the files view
    FilesViewController *filesViewController = [[FilesViewController alloc] initWithStyle:UITableViewStylePlain];
    navigationController = [[UINavigationController alloc] initWithRootViewController:filesViewController];
    navigationController.toolbarHidden = NO;
    
    // Create the window
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    // Check if backgrounding is supported
    _backgroundSupported = [[UIDevice currentDevice] isMultitaskingSupported];
    
    // Add a pasteboard notification listener is backgrounding is supported
    if (self.backgroundSupported) {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handlePasteboardNotification:) name:UIPasteboardChangedNotification object:nil];
    }

    // Check file protection
    [self checkFileProtection];

    [LockScreenController present];

    return YES;
}

- (void)dealloc {
    int i;
    for (i = 0; i < NUM_IMAGES; i++) {
        images[i] = nil; // FIXME ARC converter recommened deleting this logic, but it seemed unsafe to me -JFF
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (!self.locked) {
        [LockScreenController present];
        NSDate *currentTime = [NSDate date];
        [[AppSettings sharedInstance] setExitTime:currentTime];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Check file protection
    [self checkFileProtection];

    // Check if we're supposed to open a file
    if (self.fileToOpen != nil) {
        // Close the current database
        [self closeDatabase];
        
        // Open the file
        [[DatabaseManager sharedInstance] openDatabaseDocument:self.fileToOpen animated:NO];
        
        self.fileToOpen = nil;
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

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Get the filename
    NSString *filename = [url lastPathComponent];

    // Get the full path of where we're going to move the file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];

    // Move input file into documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:path error:nil];
    [fileManager moveItemAtURL:url toURL:[NSURL fileURLWithPath:path] error:nil];

    // Set file protection on the new file
    [fileManager setAttributes:@{NSFileProtectionKey:NSFileProtectionComplete} ofItemAtPath:path error:nil];

    // Delete the Inbox folder if it exists
    [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"Inbox"] error:nil];

    // Store the filename to open if it's a database
    if ([filename hasSuffix:@".kdb"] || [filename hasSuffix:@".kdbx"]) {
        self.fileToOpen = filename;
    } else {
        self.fileToOpen = nil;
        FilesViewController *fileView = [[navigationController viewControllers] objectAtIndex:0];
        [fileView updateFiles];
        [fileView.tableView reloadData];
    }

    return YES;
}

- (void)setDatabaseDocument:(DatabaseDocument *)newDatabaseDocument {
    if (_databaseDocument != nil) {
        [self closeDatabase];
    }
    
    _databaseDocument = newDatabaseDocument;
    
    // Create and push on the root group view controller
    GroupViewController *groupViewController = [[GroupViewController alloc] initWithGroup:_databaseDocument.kdbTree.root];
    groupViewController.title = [[_databaseDocument.filename lastPathComponent] stringByDeletingPathExtension];
    
    [navigationController pushViewController:groupViewController animated:YES];
}

- (void)closeDatabase {
    // Close any open database views
    [navigationController popToRootViewControllerAnimated:NO];
    
    _databaseDocument = nil;
}

- (void)deleteAllData {
    // Close the current database
    [self closeDatabase];
    
    // Reset some settings
    AppSettings *appSettings = [AppSettings sharedInstance];
    [appSettings setPinFailedAttempts:0];
    [appSettings setPinEnabled:NO];
    
    // Delete the PIN from the keychain
    [KeychainUtils deleteStringForKey:@"PIN" andServiceName:@"com.jflan.MiniKeePass.pin"];
    
    // Delete all database passwords from the keychain
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.passwords"];
    [KeychainUtils deleteAllForServiceName:@"com.jflan.MiniKeePass.keyfiles"];
    
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

- (void)checkFileProtection {
    // Get the document's directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    // Strip out all the directories
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

- (UIImage *)loadImage:(NSUInteger)index {
    if (index >= NUM_IMAGES) {
        return nil;
    }
    
    if (images[index] == nil) {
        images[index] = [UIImage imageNamed:[NSString stringWithFormat:@"%d", index]];
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
    
    [self.window.rootViewController presentModalViewController:settingsNavController animated:YES];
}

- (void)dismissSettingsView {
    [self.window.rootViewController dismissModalViewControllerAnimated:YES];
}

@end
