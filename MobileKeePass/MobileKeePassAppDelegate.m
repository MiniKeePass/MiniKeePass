//
//  MobileKeePassAppDelegate.m
//  MobileKeePass
//
//  Created by Jason Rush on 4/30/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "MobileKeePassAppDelegate.h"
#import "RootViewController.h"

#define DELAY 0

@implementation MobileKeePassAppDelegate

@synthesize databaseDocument;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize the images array
    int i;
    for (i = 0; i < 70; i++) {
        images[i] = nil;
    }
    
    databaseDocument = nil;
    
    // Set the user defaults
    NSDictionary *defaults = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithBool:YES], nil] forKeys:[NSArray arrayWithObjects:@"hidePasswords", nil]];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:defaults];
    
    // Create the root view
    RootViewController *rootViewController = [[RootViewController alloc] initWithStyle:UITableViewStylePlain];
    
    // Create the navigation controller
    navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    [rootViewController release];
    
    // Create the window
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = navigationController;
    [window makeKeyAndVisible];
    
    [self openLastDatabase];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enablePin"]) {
        NSDate *exitTime = [[NSUserDefaults standardUserDefaults] valueForKey:@"exitTime"];
        NSDate *cutoffTime = [exitTime dateByAddingTimeInterval:DELAY];
        
        NSDate *currentTime = [NSDate date];
        NSDate *earlierDate = [currentTime earlierDate:cutoffTime];
        
        if ([earlierDate isEqualToDate:cutoffTime]) {
            // Present the pin view
            PinViewController *pinViewController = [[PinViewController alloc] init];
            pinViewController.delegate = self;
            [window.rootViewController presentModalViewController:pinViewController animated:YES];
            [pinViewController release];
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [databaseDocument save];
    
    NSDate *currentTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setValue:currentTime forKey:@"exitTime"];
}

- (void)dealloc {
    int i;
    for (i = 0; i < 70; i++) {
        [images[i] release];
    }
    [databaseDocument release];
    [navigationController release];
    [window release];
    [super dealloc];
}

- (UIImage*)loadImage:(int)index {
    if (images[index] == nil) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%d", index] ofType:@"png"];
        images[index] = [[UIImage imageWithContentsOfFile:imagePath] retain];
    }

    return images[index];
}

/*
- (BOOL)pinViewController:(PinViewController *)controller checkPin:(NSString *)pin {
    return [pin isEqualToString:@"1234"];
}
*/

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *currentPin = [standardUserDefaults valueForKey:@"pin"];
    if ([pin isEqualToString:currentPin]) {
        [controller dismissModalViewControllerAnimated:YES];
    } else {
        // Vibrate to signify they are a bad user
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        controller.string = @"Incorrect PIN";
        [controller clearEntry];
    }
}

- (void)openLastDatabase {
    // Get the last filename
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *lastFilename = [userDefaults stringForKey:@"lastFilename"];
    
    if (lastFilename != nil) {
        PasswordEntryController *passwordEntryController = [[PasswordEntryController alloc] init];
        passwordEntryController.delegate = self;
        
        [window.rootViewController presentModalViewController:passwordEntryController animated:YES];
        
        [passwordEntryController release];
    }
}

- (BOOL)passwordEntryController:(PasswordEntryController*)controller passwordEntered:(NSString*)password {
    BOOL shouldDismiss = YES;
    
    // Get the last filename
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *lastFilename = [userDefaults stringForKey:@"lastFilename"];
    
    // Load the database
    DatabaseDocument *dd = [[DatabaseDocument alloc] init];
    enum DatabaseError error = [dd open:lastFilename password:password];
    if (error == NO_ERROR) {
        self.databaseDocument = dd;
    } else if (error == WRONG_PASSWORD) {
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
