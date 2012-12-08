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

#import "DatabaseManager.h"
#import "MiniKeePassAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "PasswordViewController.h"
#import "AppSettings.h"

@implementation DatabaseFile

+ (DatabaseFile*)databaseWithType:(DatabaseType)type path:(NSString *)path andModificationDate:(NSDate *)date {
    DatabaseFile *database = [[[DatabaseFile alloc] init] autorelease];
    database.type = type;
    database.path = path;
    database.modificationDate = date;
    // filename is generated

    return database;
}

+ (DatabaseFile*)databaseWithType:(DatabaseType)type andPath:(NSString *)path {
    return [DatabaseFile databaseWithType:type path:path andModificationDate:nil];
}

- (NSString *)filename {
    return [self.path lastPathComponent];
}

@end

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

- (void)dealloc {
    [_selectedDatabaseFile release];
    [super dealloc];
}

- (void)openDatabaseDocument:(DatabaseFile*)document animated:(BOOL)newAnimated {
    BOOL databaseLoaded = NO;
    
    self.selectedDatabaseFile = document;
    self.animated = newAnimated;
    
    // Get the application delegate
    MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];

    // Create key for retreiving password
    NSString *passwordKey = document.type == DatabaseTypeLocal ? document.filename : document.path;

    // Load the password and keyfile from the keychain
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:passwordKey andServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
    NSString *keyFile = [SFHFKeychainUtils getPasswordForUsername:passwordKey andServiceName:@"com.jflan.MiniKeePass.keyfiles" error:nil];
    
    // Try and load the database with the cached password from the keychain
    if (password != nil || keyFile != nil) {
        // Get the absolute path to the keyfile
        NSString *keyFilePath = nil;
        if (keyFile != nil) {
            keyFilePath = [[document.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:keyFile];
        }
        
        // Load the database
        DatabaseDocument *dd = [[DatabaseDocument alloc] init];
        @try {
            [dd open:document.path password:password keyFile:keyFilePath];
            
            databaseLoaded = YES;
            
            // Set the database document in the application delegate
            appDelegate.databaseDocument = dd;
        } @catch (NSException * exception) {
            // Ignore
        }
        
        [dd release];
    }
    
    // Prompt the user for the password if we haven't loaded the database yet
    if (!databaseLoaded) {
        // Prompt the user for a password
        PasswordViewController *passwordViewController = [[PasswordViewController alloc] initWithFilename:document.filename];
        passwordViewController.delegate = self;
        
        // Create a default keyfile name from the database name
        keyFile = [[document.filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"key"];
        
        // Select the keyfile if it's in the list
        NSInteger index = [passwordViewController.keyFileCell.choices indexOfObject:keyFile];
        if (index != NSNotFound) {
            passwordViewController.keyFileCell.selectedIndex = index;
        } else {
            passwordViewController.keyFileCell.selectedIndex = 0;
        }
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:passwordViewController];
        
        [appDelegate.window.rootViewController presentModalViewController:navigationController animated:self.animated];
        
        [navigationController release];
        [passwordViewController release];
    }
}

- (void)loadDatabaseDocument:(DatabaseDocument*)databaseDocument {
    // Set the database document in the application delegate
    MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.databaseDocument = databaseDocument;
    
    [databaseDocument release];
}

- (void)formViewController:(FormViewController *)controller button:(FormViewControllerButton)button {
    PasswordViewController *passwordViewController = (PasswordViewController*)controller;
    BOOL shouldDismiss = YES;
    
    // Check if the OK button was pressed
    if (button == FormViewControllerButtonOk) {
        // Get the password
        NSString *password = passwordViewController.passwordTextField.text;
        if ([password isEqualToString:@""]) {
            password = nil;
        }
        
        // Get the keyfile
        NSString *keyFile = [passwordViewController.keyFileCell getSelectedItem];
        if ([keyFile isEqualToString:NSLocalizedString(@"None", nil)]) {
            keyFile = nil;
        }
        
        // Get the absolute path to the keyfile
        NSString *keyFilePath = nil;
        if (keyFile != nil) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            keyFilePath = [documentsDirectory stringByAppendingPathComponent:keyFile];
        }
        
        // Load the database
        DatabaseDocument *dd = [[DatabaseDocument alloc] init];
        @try {
            // Open the database
            [dd open:self.selectedDatabaseFile.path password:password keyFile:keyFilePath];
            
            // Store the password in the keychain
            if ([[AppSettings sharedInstance] rememberPasswordsEnabled]) {

                // Create key for retreiving password
                DatabaseFile *document = self.selectedDatabaseFile;
                NSString *passwordKey = document.type == DatabaseTypeLocal ? document.filename : document.path;

                NSError *error;
                [SFHFKeychainUtils storeUsername:passwordKey andPassword:password forServiceName:@"com.jflan.MiniKeePass.passwords" updateExisting:YES error:&error];
                [SFHFKeychainUtils storeUsername:passwordKey andPassword:keyFile forServiceName:@"com.jflan.MiniKeePass.keyfiles" updateExisting:YES error:&error];
            }
            
            // Load the database after a short delay so the push animation is visible
            [self performSelector:@selector(loadDatabaseDocument:) withObject:dd afterDelay:0.01];
        } @catch (NSException *exception) {
            shouldDismiss = NO;
            [passwordViewController showErrorMessage:exception.reason];
            [dd release];
        }
    }
    
    if (shouldDismiss) {
        [passwordViewController dismissModalViewControllerAnimated:YES];
    }
}

@end
