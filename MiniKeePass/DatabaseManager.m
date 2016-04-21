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
#import "MiniKeePassAppDelegate.h"
#import "KeychainUtils.h"
#import "PasswordViewController.h"
#import "AppSettings.h"

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

- (void)openDatabaseDocument:(NSString*)filename animated:(BOOL)animated {
    BOOL databaseLoaded = NO;
    
    self.selectedFilename = filename;
    
    // Get the application delegate
    MiniKeePassAppDelegate *appDelegate = [MiniKeePassAppDelegate appDelegate];
    
    // Get the documents directory
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
    
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
        PasswordViewController *passwordViewController = [[PasswordViewController alloc] initWithFilename:filename];
        passwordViewController.donePressed = ^(FormViewController *formViewController) {
            [self openDatabaseWithPasswordViewController:(PasswordViewController *)formViewController];
        };
        passwordViewController.cancelPressed = ^(FormViewController *formViewController) {
            [formViewController dismissViewControllerAnimated:YES completion:nil];
        };
        
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
        
        [appDelegate.window.rootViewController presentViewController:navigationController animated:animated completion:nil];
    }
}

- (void)openDatabaseWithPasswordViewController:(PasswordViewController *)passwordViewController {
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:self.selectedFilename];

    // Get the password
    NSString *password = passwordViewController.masterPasswordFieldCell.textField.text;
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
        NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
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
        [passwordViewController dismissViewControllerAnimated:YES completion:^{
            // Set the database document in the application delegate
            MiniKeePassAppDelegate *appDelegate = [MiniKeePassAppDelegate appDelegate];
            appDelegate.databaseDocument = dd;
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
        [passwordViewController showErrorMessage:exception.reason];
    }
}

@end
