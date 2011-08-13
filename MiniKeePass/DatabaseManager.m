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

@implementation DatabaseManager

@synthesize selectedFilename;
@synthesize animated;

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
    [selectedFilename release];
    [super dealloc];
}

- (void)openDatabaseDocument:(NSString*)filename animated:(BOOL)newAnimated {
    BOOL databaseLoaded = NO;
    
    self.selectedFilename = filename;
    self.animated = newAnimated;
    
    // Get the application delegate
    MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // Get the documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Load the password and keyfile from the keychain
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:selectedFilename andServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
    NSString *keyFile = [SFHFKeychainUtils getPasswordForUsername:selectedFilename andServiceName:@"com.jflan.MiniKeePass.keyfiles" error:nil];
    
    // Try and load the database with the cached password from the keychain
    if (password != nil || keyFile != nil) {
        // Get the absolute path to the database
        NSString *path = [documentsDirectory stringByAppendingPathComponent:selectedFilename];
        
        // Get the absolute path to the keyfile
        NSString *keyFilePath = nil;
        if (keyFile != nil) {
            keyFilePath = [documentsDirectory stringByAppendingPathComponent:keyFile];
        }
        
        // Load the database
        DatabaseDocument *dd = [[DatabaseDocument alloc] init];
        @try {
            [dd open:path password:password keyFile:keyFilePath];
            
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
        PasswordViewController *passwordViewController = [[PasswordViewController alloc] initWithFilename:filename];
        passwordViewController.delegate = self;
        
        // Create a defult keyfile name from the database name
        keyFile = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"key"];
        
        // Select the keyfile if it's in the list
        NSInteger index = [passwordViewController.keyFileCell.choices indexOfObject:keyFile];
        if (index != NSNotFound) {
            passwordViewController.keyFileCell.selectedIndex = index;
        } else {
            passwordViewController.keyFileCell.selectedIndex = 0;
        }
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:passwordViewController];
        
        [appDelegate.window.rootViewController presentModalViewController:navigationController animated:animated];
        
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
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:selectedFilename];
        
        // Get the password
        NSString *password = passwordViewController.passwordTextField.text;
        if ([password isEqualToString:@""]) {
            password = nil;
        }
        
        // Get the keyfile
        NSString *keyFile = [passwordViewController.keyFileCell getSelectedItem];
        if ([keyFile isEqualToString:@"None"]) {
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
            [dd open:path password:password keyFile:keyFilePath];
            
            // Store the password in the keychain
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            if ([userDefaults boolForKey:@"rememberPasswordsEnabled"]) {
                NSError *error;
                [SFHFKeychainUtils storeUsername:selectedFilename andPassword:password forServiceName:@"com.jflan.MiniKeePass.passwords" updateExisting:YES error:&error];
                [SFHFKeychainUtils storeUsername:selectedFilename andPassword:keyFile forServiceName:@"com.jflan.MiniKeePass.keyfiles" updateExisting:YES error:&error];
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
