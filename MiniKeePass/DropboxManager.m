//
//  DropboxManager.m
//  MiniKeePass
//
//  Created by Albert Choy on 10/12/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "DropboxManager.h"
#import <DropboxSDK/DropboxSDK.h>
#import "DatabaseManager.h"

@interface DropboxManager () <DBSessionDelegate, DBNetworkRequestDelegate,
    DBRestClientDelegate>

- (NSString *) getDocumentPath;

- (NSString *) getCloudDb: (NSString *)dbFile;

- (NSString *) getTargetDb: (NSString *)dbFile;

- (NSString *) getVersionPath: (NSString *)dbFile;

@end

@implementation DropboxManager
{
    BOOL _linkOnce;
    DBRestClient *restClient;
    
    NSString * _syncVersion;
    NSString * _cloudVersion;
    NSString * _localDbFile;
}

@synthesize rootController;
@synthesize syncVersion = _syncVersion;
@synthesize cloudVersion = _cloudVersion;
@synthesize localDb = _localDbFile;

#pragma mark - 
#pragma mark Class methods

+ (DropboxManager *) singleton
{
    static DropboxManager *_singleton = nil;
    
    if (!_singleton)
    {
        _singleton = [[super allocWithZone:nil] init];
    }
    
    return _singleton;
}

#pragma mark - 
#pragma mark Public methods

- (id) init
{
    self = [super init];
    if (self)
    {
        _linkOnce = NO;
    }
    return self;
}

- (BOOL) connect
{
    // Set these variables before launching the app
    NSString* appKey = @"niw3e9tunrhclgg";
	NSString* appSecret = @"nxr049tr0thevlw";
	NSString *root = kDBRootAppFolder; // Should be set to either kDBRootAppFolder or kDBRootDropbox
    
	// You can determine if you have App folder access or Full Dropbox along with your consumer key/secret
	// from https://dropbox.com/developers/apps	
	
	NSString* errorMsg = nil;
	if ([appKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app key correctly";
	} else if ([appSecret rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app secret correctly";
	} else if ([root length] == 0) {
		errorMsg = @"Set your root to use either App Folder of full Dropbox";
	} else {
		NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
		NSData *plistData = [NSData dataWithContentsOfFile:plistPath];
		NSDictionary *loadedPlist =
        [NSPropertyListSerialization
         propertyListFromData:plistData mutabilityOption:0 format:NULL errorDescription:NULL];
		NSString *scheme = [[[[loadedPlist objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
		if ([scheme isEqual:@"db-APP_KEY"]) {
			errorMsg = @"Set your URL scheme correctly";
		}
	}
	
	DBSession* session =
    [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
	session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
	[DBSession setSharedSession:session];
    [session release];
	
	[DBRequest setNetworkRequestDelegate:self];
    
	if (errorMsg != nil) {
		[[[[UIAlertView alloc]
		   initWithTitle:@"Error Configuring Dropbox Session" message:errorMsg
		   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
		  autorelease]
		 show];
        return NO;
	}
    
    return YES;
}

//
// Must be called to initiate dropbox linking
- (BOOL) activateLink: (UIViewController *) viewController
{
    // if we are not connected by client, refuse connection
    if (![self hasLink])
    {
        if (!_linkOnce)
        {
            [[DBSession sharedSession] linkFromController: viewController];
            _linkOnce = YES;
        }
    }
    
    return YES;
}

- (BOOL) hasLink
{
    return ([[DBSession sharedSession] isLinked]);
}


//
// Syncing by using latest date
- (BOOL) syncFrom: (NSString *) dbFile
{
    // if we haven't linked to Dropbox
    if (![self hasLink])
    {
        NSLog(@"Not connected to user dropbox");
        return NO;
    }

    self.localDb = dbFile;
    NSLog(@"SyncFrom: %@", self.localDb);

    // get current version info
    [self loadVersionInfoFromLocal: dbFile];
    
    // load cloud db if it exists
    // continue processing via callbacks
    [[self restClient] loadMetadata: [self getCloudDb: dbFile]];
    
    return YES;
}

#pragma mark -
#pragma Private methods

- (DBRestClient *)restClient {
    if (!restClient) {
        restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

- (NSString *) getCloudDb: (NSString *)dbFile
{
    return [NSString stringWithFormat: @"/%@", dbFile];
}

- (NSString *) getDocumentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];    
}

- (NSString *) getTargetDb: (NSString *)dbFile
{
    return [[self getDocumentPath] stringByAppendingPathComponent: dbFile];
}

- (NSString *) getVersionPath:(NSString *)dbFile
{
    return [[self getTargetDb: dbFile] stringByAppendingPathExtension:@"version"];
}

- (void) loadVersionInfoFromLocal: (NSString *) dbFile
{
    // Locate folder for password and version file
    NSString * versionFile = [self getVersionPath: dbFile ];
    
    // does the version file exist
    if ( [[NSFileManager defaultManager] fileExistsAtPath:versionFile] )
    {
        NSError *error = nil;
        
        self.syncVersion = [[NSString alloc]
                       initWithContentsOfFile:versionFile
                       encoding:NSASCIIStringEncoding
                       error:&error];
        if (!self.syncVersion)
        {
            NSLog(@"Error reading version file %@: %@", versionFile,
                  [error localizedDescription]);
            self.syncVersion = @"";
        }
        else
        {
            NSLog(@"Last version: %@", self.syncVersion);
        }
    }
    else
    {
        NSLog(@"No version file: %@", versionFile);
        self.syncVersion = @"";
    }
}

- (void) writeVersionInfo: (NSString *) newVersion into: (NSString *) outFile
{
    NSError *error = nil;
    
    if ( ![newVersion writeToFile: outFile
                 atomically: YES
                   encoding: NSASCIIStringEncoding
                      error: &error] )
    {
        NSLog(@"Error writing to %@: %@", outFile, [error localizedDescription]);
    }    
}

//
// Called when ready to open the database

- (void) openDatabaseForEdit
{
    // implement open database here
    [[DatabaseManager sharedInstance] openDatabaseDocument: self.localDb animated:YES];
}

#pragma mark DBRestClient delegates

//
// Use this method to sync database, process asynchronously
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    NSLog(@"Folder '%@' contains:", metadata.path);

    if (metadata.isDirectory) {
        for (DBMetadata *file in metadata.contents) {
            NSLog(@"\t%@ rev %@ date %@", file.filename, file.rev, file.lastModifiedDate);
        }
        return;
    }

    NSString *cloudFile = metadata.filename;
    NSString *cloudDb = [self getCloudDb: self.localDb];
    NSLog(@"\t%@ rev %@ date %@", cloudFile, metadata.rev, metadata.lastModifiedDate);

    // Compare if requested the same file as metadata loaded
    if ( ![cloudDb hasSuffix: cloudFile] )
    {
        NSLog(@"File metadata mismatch: '%@' '%@'", cloudDb, cloudFile);
        return;
    }
    self.cloudVersion = metadata.rev;
    
    // if database is newer on the cloud, load it from cloud
    if (([self.syncVersion length] == 0) ||
        ([self.cloudVersion caseInsensitiveCompare: self.syncVersion] == NSOrderedDescending)) {
        // go ahead and load it
        [[self restClient] loadFile: cloudDb intoPath: [self getTargetDb: self.localDb]];
    }
    else
    {
        // we are ready to start with editing
        [self openDatabaseForEdit];
    }
}

//
// Load database successful
- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath
{
    NSString *versionFile = [self getVersionPath: self.localDb ];
    NSLog(@"Loaded Dropbox file %@ version %@", [self getCloudDb: self.localDb], self.cloudVersion);
    
    // create version info for future update
    [self writeVersionInfo: self.cloudVersion into: versionFile];
    
    // now go to editing database
    [self openDatabaseForEdit];
}

//
// Get metadata failed due to some technical difficulty
- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    NSLog(@"Error loading metadata: %@ for %@", [error localizedDescription], [self getCloudDb: self.localDb]);
    
    // go directly to editing database
    [self openDatabaseForEdit];
}

//
// Load database failed with error
- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
    NSLog(@"Error loading file %@, message: %@", [self getCloudDb: self.localDb], [error localizedDescription]);
    
    // go directly to edit database
    [self openDatabaseForEdit];
}

#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId
{
	relinkUserId = [userId retain];
	[[[[UIAlertView alloc]
	   initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self
	   cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil]
	  autorelease]
	 show];
}


#pragma mark -
#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted {
	outstandingRequests++;
	if (outstandingRequests == 1) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
}

- (void)networkRequestStopped {
	outstandingRequests--;
	if (outstandingRequests == 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
	if (index != alertView.cancelButtonIndex) {
		[[DBSession sharedSession] linkUserId:relinkUserId fromController:rootController];
	}
	[relinkUserId release];
	relinkUserId = nil;
}

@end
