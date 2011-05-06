//
//  MobileKeePassAppDelegate.m
//  MobileKeePass
//
//  Created by Jason Rush on 4/30/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "MobileKeePassAppDelegate.h"
#import "RootViewController.h"
#import "SFHFKeychainUtils.h"

#define TIME_INTERVAL_BEFORE_PIN 5

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
    
    // FIXME Set the pin here for testing
    NSError *error;
    [SFHFKeychainUtils storeUsername:@"PIN" andPassword:@"1234" forServiceName:@"net.fizzawizza.MobileKeePass" updateExisting:NO error:&error];
    
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Save the database document
    [databaseDocument save];
    
    // Cleanup the database document
    [databaseDocument release];
    databaseDocument = nil;
    
    // Store the current time as when the application exited
    NSDate *currentTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setValue:currentTime forKey:@"exitTime"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Get the time when the application last exited
    NSDate *exitTime = [[NSUserDefaults standardUserDefaults] valueForKey:@"exitTime"];
    if (exitTime == nil) {
        return;
    }
    
    NSTimeInterval timeInterval = [exitTime timeIntervalSinceNow];
    if (timeInterval < -TIME_INTERVAL_BEFORE_PIN) {
        // Present the pin view
        PinViewController *pinViewController = [[PinViewController alloc] init];
        pinViewController.delegate = self;
        [window.rootViewController presentModalViewController:pinViewController animated:YES];
        [pinViewController release];
    }
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

- (BOOL)pinViewController:(PinViewController *)controller checkPin:(NSString *)pin {
    NSError *error = nil;
    
    NSString *validPin = [SFHFKeychainUtils getPasswordForUsername:@"PIN" andServiceName:@"net.fizzawizza.MobileKeePass" error:&error];
    if (error != nil || validPin == nil) {
        return false;
    }
    
    return [pin isEqualToString:validPin];
}

- (void)openLastDatabase {
    // Get the last filename
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *lastFilename = [userDefaults stringForKey:@"lastFilename"];
    if (lastFilename == nil) {
        return;
    }
    
    // Load the password from the keychain
    NSError *error;
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:lastFilename andServiceName:@"net.fizzawizza.MobileKeePass" error:&error];
    if (error != nil || password == nil) {
        return;
    }
    
    // Load the database
    DatabaseDocument *dd = [[DatabaseDocument alloc] init];
    enum DatabaseError databaseError = [dd open:lastFilename password:password];
    if (databaseError == NO_ERROR) {
        self.databaseDocument = dd;
    }
    
    [dd release];
}

@end
