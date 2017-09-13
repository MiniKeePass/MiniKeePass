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

#import "DatabaseManager.h"
#import "AppDelegate.h"
#import "KeychainUtils.h"
#import "AppSettings.h"
#import "MiniKeePass-Swift.h"

@implementation DatabaseManager

static DatabaseManager *sharedInstance;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized)     {
        initialized = YES;
        sharedInstance = [[DatabaseManager alloc] init];
    }
}

+ (DatabaseManager*)sharedInstance {
    return sharedInstance;
}

- (NSArray *)getDatabases {
    NSMutableArray *files = [[NSMutableArray alloc] init];

    // Get the document's directory
    NSString *documentsDirectory = [AppDelegate documentsDirectory];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    // Sort the files into database files and keyfiles
    for (NSString *file in dirContents) {
        NSString *path = [documentsDirectory stringByAppendingPathComponent:file];

        // Check if it's a directory
        BOOL dir = NO;
        [fileManager fileExistsAtPath:path isDirectory:&dir];
        if (!dir) {
            NSString *extension = [[file pathExtension] lowercaseString];
            if ([extension isEqualToString:@"kdb"] || [extension isEqualToString:@"kdbx"]) {
                [files addObject:file];
            }
        }
    }

    // Sort the list of files
    [files sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    return files;
}

- (NSArray *)getKeyFiles {
    NSMutableArray *files = [[NSMutableArray alloc] init];

    // Get the document's directory
    NSString *documentsDirectory = [AppDelegate documentsDirectory];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    // Sort the files into database files and keyfiles
    for (NSString *file in dirContents) {
        NSString *path = [documentsDirectory stringByAppendingPathComponent:file];

        // Check if it's a directory
        BOOL dir = NO;
        [fileManager fileExistsAtPath:path isDirectory:&dir];
        if (!dir) {
            NSString *extension = [[file pathExtension] lowercaseString];
            if (![extension isEqualToString:@"kdb"] && ![extension isEqualToString:@"kdbx"]) {
                [files addObject:file];
            }
        }
    }

    // Sort the list of files
    [files sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    return files;
}

- (NSURL *)getFileUrl:(NSString *)filename {
    // Resolve the filename to a URL
    NSURL *documentsDirectory = [AppDelegate documentsDirectoryUrl];
    return [documentsDirectory URLByAppendingPathComponent:filename];
}

- (NSDate *)getFileLastModificationDate:(NSURL *)url {
    NSDate *date;
    NSError *error;
    [url getResourceValue:&date forKey:NSURLContentModificationDateKey error:&error];
    return date;
}

- (void)deleteFile:(NSString *)filename {
    NSURL *url = [self getFileUrl:filename];
    NSString *path = url.path;

    // Close the current database if we're deleting it's file
    AppDelegate *appDelegate = [AppDelegate getDelegate];
    if ([path isEqualToString:appDelegate.databaseDocument.filename]) {
        [appDelegate closeDatabase];
    }

    // Delete the file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:url error:nil];
}

- (void)newDatabase:(NSURL *)url password:(NSString *)password version:(NSInteger)version {
    // Create the KdbWriter for the requested version
    id<KdbWriter> writer;
    if (version == 1) {
        writer = [[Kdb3Writer alloc] init];
    } else {
        writer = [[Kdb4Writer alloc] init];
    }
    
    // Create the KdbPassword
    KdbPassword *kdbPassword = [[KdbPassword alloc] initWithPassword:password
                                                    passwordEncoding:NSUTF8StringEncoding
                                                             keyFile:nil];
    
    // Create the new database
    [writer newFile:url.path withPassword:kdbPassword];
    
    // Store the password in the keychain
    if ([[AppSettings sharedInstance] rememberPasswordsEnabled]) {
        NSString *filename = url.lastPathComponent;
        [KeychainUtils setString:password forKey:filename andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
    }
}

- (void)renameDatabase:(NSURL *)originalUrl newUrl:(NSURL *)newUrl {
    NSString *oldFilename = originalUrl.lastPathComponent;
    NSString *newFilename = newUrl.lastPathComponent;
    
    // Move input file into documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager moveItemAtURL:originalUrl toURL:newUrl error:nil];
    
    // Check if we should move the saved passwords to the new filename
    if ([[AppSettings sharedInstance] rememberPasswordsEnabled]) {
        // Load the password and keyfile from the keychain under the old filename
        NSString *password = [KeychainUtils stringForKey:oldFilename andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
        NSString *keyFile = [KeychainUtils stringForKey:oldFilename andServiceName:KEYCHAIN_KEYFILES_SERVICE];
        
        // Store the password and keyfile into the keychain under the new filename
        [KeychainUtils setString:password forKey:newFilename andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
        [KeychainUtils setString:keyFile forKey:newFilename andServiceName:KEYCHAIN_KEYFILES_SERVICE];
        
        // Delete the keychain entries for the old filename
        [KeychainUtils deleteStringForKey:oldFilename andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
        [KeychainUtils deleteStringForKey:oldFilename andServiceName:KEYCHAIN_KEYFILES_SERVICE];
    }
}

- (void)openDatabaseDocument:(NSString*)filename animated:(BOOL)animated {
    BOOL databaseLoaded = NO;

    self.selectedFilename = filename;

    // Get the application delegate
    AppDelegate *appDelegate = [AppDelegate getDelegate];

    // Get the documents directory
    NSString *documentsDirectory = [AppDelegate documentsDirectory];

    // Load the password and keyfile from the keychain
    NSString *password = [KeychainUtils stringForKey:self.selectedFilename
                                      andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
    NSString *keyFile = [KeychainUtils stringForKey:self.selectedFilename
                                     andServiceName:KEYCHAIN_KEYFILES_SERVICE];

    // Try and load the database with the cached password from the keychain
    if (password != nil || keyFile != nil) {
        // Get the absolute path to the database
        NSString *path = [documentsDirectory stringByAppendingPathComponent:self.selectedFilename];

        // Get the absolute path to the keyfile
        NSString *keyFilePath = nil;
        if (keyFile != nil) {
            keyFilePath = [documentsDirectory stringByAppendingPathComponent:keyFile];
        }

        // Load the database
        @try {
            DatabaseDocument *dd = [[DatabaseDocument alloc] initWithFilename:path password:password keyFile:keyFilePath];

            databaseLoaded = YES;

            // Set the database document in the application delegate
            appDelegate.databaseDocument = dd;
        } @catch (NSException *exception) {
            // Ignore
        }
    }

    // Prompt the user for the password if we haven't loaded the database yet
    if (!databaseLoaded) {
        // Prompt the user for a password
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PasswordEntry" bundle:nil];
        UINavigationController *navigationController = [storyboard instantiateInitialViewController];

        PasswordEntryViewController *passwordEntryViewController = (PasswordEntryViewController *)navigationController.topViewController;
        passwordEntryViewController.donePressed = ^(PasswordEntryViewController *passwordEntryViewController) {
            [self openDatabaseWithPasswordEntryViewController:passwordEntryViewController];
        };
        passwordEntryViewController.cancelPressed = ^(PasswordEntryViewController *passwordEntryViewController) {
            [passwordEntryViewController dismissViewControllerAnimated:YES completion:nil];
        };

        // Initialize the filename
        passwordEntryViewController.filename = filename;

        // Load the key files
        passwordEntryViewController.keyFiles = [self getKeyFiles];

        [appDelegate.window.rootViewController presentViewController:navigationController animated:animated completion:nil];
    }
}

- (void)openDatabaseWithPasswordEntryViewController:(PasswordEntryViewController *)passwordEntryViewController {
    NSString *documentsDirectory = [AppDelegate documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:self.selectedFilename];

    // Get the password
    NSString *password = passwordEntryViewController.password;
    if ([password isEqualToString:@""]) {
        password = nil;
    }

    // Get the keyfile
    NSString *keyFile = passwordEntryViewController.keyFile;
    NSString *keyFilePath = nil;
    if (keyFile != nil) {
        NSString *documentsDirectory = [AppDelegate documentsDirectory];
        keyFilePath = [documentsDirectory stringByAppendingPathComponent:keyFile];
    }

    // Load the database
    @try {
        // Open the database
        DatabaseDocument *dd = [[DatabaseDocument alloc] initWithFilename:path password:password keyFile:keyFilePath];

        // Store the password in the keychain
        if ([[AppSettings sharedInstance] rememberPasswordsEnabled]) {
            [KeychainUtils setString:password forKey:self.selectedFilename
                      andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
            [KeychainUtils setString:keyFile forKey:self.selectedFilename
                      andServiceName:KEYCHAIN_KEYFILES_SERVICE];
        }

        // Dismiss the view controller, and after animation set the database document
        [passwordEntryViewController dismissViewControllerAnimated:YES completion:^{
            // Set the database document in the application delegate
            AppDelegate *appDelegate = [AppDelegate getDelegate];
            appDelegate.databaseDocument = dd;
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
// FIXME Need a way of showing the error
//        [passwordViewController showErrorMessage:exception.reason];
    }
}

@end
