//
//  MobileKeePassAppDelegate.m
//  MobileKeePass
//
//  Created by Jason Rush on 4/30/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "MobileKeePassAppDelegate.h"
#import "RootViewController.h"

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

- (void)applicationWillResignActive:(UIApplication *)application {
    [databaseDocument save];
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
