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
#import "TextEntryController.h"

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
    
    // Load the password from the keychain
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:selectedFilename andServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
    
    // Get the application delegate
    MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // Try and load the database with the cached password from the keychain
    if (password != nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:selectedFilename];

        // Load the database
        DatabaseDocument *dd = [[DatabaseDocument alloc] init];
        @try {
            [dd open:path password:password];
            
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
        TextEntryController *textEntryController = [[TextEntryController alloc] init];
        textEntryController.delegate = self;
        textEntryController.secureTextEntry = YES;
        textEntryController.placeholderText = @"Password";
        textEntryController.entryTitle = @"Database Password";
        [appDelegate.window.rootViewController presentModalViewController:textEntryController animated:animated];
        [textEntryController release];
    }
}

- (void)loadDatabaseDocument:(DatabaseDocument*)databaseDocument {
    // Set the database document in the application delegate
    MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.databaseDocument = databaseDocument;
    
    [databaseDocument release];
}

- (void)textEntryController:(TextEntryController*)controller textEntered:(NSString*)string {
    BOOL shouldDismiss = YES;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:selectedFilename];
    
    // Load the database
    DatabaseDocument *dd = [[DatabaseDocument alloc] init];
    @try {
        // Open the database
        [dd open:path password:string];
        
        // Store the password in the keychain
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults boolForKey:@"rememberPasswordsEnabled"]) {
            NSError *error;
            [SFHFKeychainUtils storeUsername:selectedFilename andPassword:string forServiceName:@"com.jflan.MiniKeePass.passwords" updateExisting:YES error:&error];
        }
        
        // Load the database after a short delay so the push animation is visible
        [self performSelector:@selector(loadDatabaseDocument:) withObject:dd afterDelay:0.01];
    } @catch (NSException *exception) {
        shouldDismiss = NO;
        controller.statusLabel.text = exception.reason;
        [dd release];
    }
    
    if (shouldDismiss) {
        [controller dismissModalViewControllerAnimated:YES];
    }
}

- (void)textEntryControllerCancelButtonPressed:(TextEntryController *)controller {
    [controller dismissModalViewControllerAnimated:YES];
}

@end
