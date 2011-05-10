//
//  DatabaseManager.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/9/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "DatabaseManager.h"
#import "MobileKeePassAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "PasswordEntryController.h"

@implementation DatabaseManager

@synthesize selectedPath;

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
    [selectedPath release];
    [super dealloc];
}

- (void)openDatabaseDocument:(NSString*)path {
    NSError *error;
    
    self.selectedPath = path;
    
    // Load the password from the keychain
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:path andServiceName:@"net.fizzawizza.MobileKeePass" error:&error];
    if (error != nil) {
        return;
    }

    // Get the application delegate
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];

    // Check if the password was in the keychain
    if (password != nil) {
        // Load the database
        DatabaseDocument *dd = [[DatabaseDocument alloc] init];
        enum DatabaseError databaseError = [dd open:path password:password];
        if (databaseError == NO_ERROR) {
            // Set the database document in the application delegate
            appDelegate.databaseDocument = dd;

            // Store the filename as the last opened database
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setValue:path forKey:@"lastFilename"];
            
            // Pop to the root view
            [appDelegate.navigationController popToRootViewControllerAnimated:NO];
        }
        [dd release];
    } else {
        // Prompt the user for a password
        PasswordEntryController *passwordEntryController = [[PasswordEntryController alloc] init];
        passwordEntryController.delegate = self;
        [appDelegate.navigationController presentModalViewController:passwordEntryController animated:YES];
        [passwordEntryController release];
    }
}

- (BOOL)passwordEntryController:(PasswordEntryController*)controller passwordEntered:(NSString*)password {
    BOOL shouldDismiss = YES;
    
    // Load the database
    DatabaseDocument *dd = [[DatabaseDocument alloc] init];
    enum DatabaseError databaseError = [dd open:selectedPath password:password];
    if (databaseError == NO_ERROR) {
        // Set the database document in the application delegate
        MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        appDelegate.databaseDocument = dd;
        
        // Store the filename as the last opened database
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setValue:selectedPath forKey:@"lastFilename"];
        
        // Store the password in the keychain
        if ([userDefaults boolForKey:@"rememberPasswordsEnabled"]) {
            NSError *error;
            [SFHFKeychainUtils storeUsername:selectedPath andPassword:password forServiceName:@"net.fizzawizza.MobileKeePass" updateExisting:YES error:&error];
        }

        // Pop to the root view
        [appDelegate.navigationController popToRootViewControllerAnimated:NO];
    } else if (databaseError == WRONG_PASSWORD) {
        shouldDismiss = NO;
        controller.statusLabel.text = @"Wrong Password";
    } else {
        shouldDismiss = NO;
        controller.statusLabel.text = @"Failed to open database";
    }
    [dd release];
    
    return shouldDismiss;
}

@end
