/*
 * Copyright 2017 Tait Smith. All rights reserved.
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

#import "CloudManager.h"
#import "CloudFactory.h"

@implementation CloudManager

+(CloudManager*)sharedInstance {
    return [CloudFactory getCloudManager];
}

-(void) initAPI {[self doesNotRecognizeSelector:_cmd];}
-(BOOL) isClientAuthorized {[self doesNotRecognizeSelector:_cmd]; return NO;}
-(BOOL) getAccountAuthorization:(UIApplication*)app controller:(UIViewController*)controller {[self doesNotRecognizeSelector:_cmd]; return NO;}
-(uint32_t) accountAuthorizationRedirect:(NSURL*)url {[self doesNotRecognizeSelector:_cmd]; return 0;}
-(void) resetAccount {[self doesNotRecognizeSelector:_cmd];}

-(void) loadFileList:(CMrequestCallback)requestCallback {[self doesNotRecognizeSelector:_cmd];}
-(NSMutableArray *) getFileList {[self doesNotRecognizeSelector:_cmd]; return nil;}
-(NSDate *) getFileModifiedDate:(NSString*)file {[self doesNotRecognizeSelector:_cmd];return nil;}
-(void) downloadFile:(NSString*)path requestCallback:(CMrequestCallback)requestCallback {[self doesNotRecognizeSelector:_cmd];}
-(void) uploadFile:(NSString*)path requestCallback:(CMrequestCallback)requestCallback {[self doesNotRecognizeSelector:_cmd];}

// Factory Methods to get paths and URLs.
-(NSString *)getLocalPath:(NSString *)filename {[self doesNotRecognizeSelector:_cmd];return nil;}
-(NSURL *)getLocalURL:(NSString *)filename {[self doesNotRecognizeSelector:_cmd];return nil;}
-(NSString *)getRemotePath:(NSString *)filename {[self doesNotRecognizeSelector:_cmd];return nil;}
-(NSString *)getTempDir {[self doesNotRecognizeSelector:_cmd];return nil;}
/*
- (void) initDropboxAPI {
    
    if( !isInitialized ) {
        // Initialize the Dropbox Client Manager
        @try {
            [DBClientsManager setupWithAppKey:DROPBOX_APP_KEY];
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
            return;
        }
        isInitialized = YES;

//        [self deleteDropboxTempDir];  // Wipeout temp directory to start over from scratch.

        // Initialized the local file metadata.
        [self initializeDropboxRevisions];
        
        // Try to setup the client with a stored access token.
        [self setupClient:nil];
    }
}

-(BOOL) getAccountAuthorization:(UIApplication*)app controller:(UIViewController*)controller {
    
    if( !isInitialized ) return NO;
    
    [DBClientsManager authorizeFromController:app controller:controller
                                      openURL:^(NSURL *url) { [app openURL:url]; }
                                  browserAuth:NO];
    return YES;
}

-(uint32_t) accountAuthorizationRedirect:(NSURL*)url {
    DBOAuthResult *authResult = [DBClientsManager handleRedirectURL:url];
    if (authResult != nil) {
        if ([authResult isSuccess]) {
            NSString *token = authResult.accessToken.accessToken;
            printf("Success! User is logged into Dropbox, token(%s).\n", token.UTF8String );
            [KeychainUtils setString:token forKey:DROPBOX_ACCESS_TOKEN
                          andServiceName:KEYCHAIN_OAUTH2_SERVICE];
            return [self setupClient:token];
        } else if ([authResult isCancel]) {
            printf("Authorization flow was manually canceled by user!\n");
            return DropboxUserCanceled;
        } else if ([authResult isError]) {
            printf("Error in authResult\n" );
            NSLog( @"%@\n", authResult.errorDescription);
            return DropboxError;
        }
    }
    return DropboxNotHandled;
}

-(BOOL) isClientAuthorized {
    if( client == nil || ![client isAuthorized] )
        return NO;
    
    return YES;
}


- (uint32_t)setupClient:(NSString *)token {
    
    if( token == nil ) {
        token = [KeychainUtils stringForKey:DROPBOX_ACCESS_TOKEN andServiceName:KEYCHAIN_OAUTH2_SERVICE];
    }
    
    if( token == nil ) return DropboxNotAuthorized;
    
    client = [[DBUserClient alloc] initWithAccessToken:token];
    if( client == nil ) {
        printf( "Cannot create client from access_token!\n");
        return DropboxNotAuthorized;
    }
    
    if( ![client isAuthorized] ) {
        return DropboxNotAuthorized;
    }
    
    return DropboxOK;
}

-(void) resetAccount {
    [DBClientsManager unlinkAndResetClients];
    client = nil;
    [KeychainUtils deleteStringForKey:DROPBOX_ACCESS_TOKEN andServiceName:KEYCHAIN_OAUTH2_SERVICE];
}

- (NSString *)getLocalPath:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *tempdir = [documentsDirectory stringByAppendingPathComponent:DROPBOX_TEMP_DIR];
    NSString *path = [tempdir stringByAppendingPathComponent:filename];

    return path;
}

- (NSURL *)getLocalURL:(NSString *)filename {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *outputDirectory = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    NSURL *temp_dir = [outputDirectory URLByAppendingPathComponent:DROPBOX_TEMP_DIR];
    NSURL *srcUrl = [temp_dir URLByAppendingPathComponent:filename];

    return srcUrl;
}

- (NSString *)getDropboxPath:(NSString *)filename {
    
    NSString *prefix = @"/";
    NSString *path = [prefix stringByAppendingPathComponent:filename];
    
    return path;
}

- (NSString *)getDropboxTempDir {
    
    return DROPBOX_TEMP_DIR;
}

- (void)initializeDropboxRevisions {

    // Create temp directory if it doesn't exist
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *temp_dir = [self getLocalURL:@""];
    NSError *fm_err;
    if( ![fileManager createDirectoryAtURL:temp_dir withIntermediateDirectories:YES attributes:nil error:&fm_err ]) {
        printf("Cannot create temp directory for dropbox!\n");
        NSLog( @"%@", fm_err );
        return;
    }
    
    // Load the File Metadata Dictionary from the local drive.
    localFileMetadata = [NSMutableDictionary dictionaryWithContentsOfURL:[self getLocalURL:DROPBOX_META_ARCHIVE] ];
    if( localFileMetadata == nil ) {
        localFileMetadata = [[NSMutableDictionary alloc] init];
    }

    // Make sure the local files still exist.
    NSString *tempPath = [self getLocalPath:@""];
    NSMutableDictionary *missingFiles = [NSMutableDictionary dictionaryWithDictionary:localFileMetadata];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:tempPath error:&fm_err];
    if( dirContents == nil ) {
        NSLog( @"%@", fm_err );
        return;
    }
    
    for (NSString *file in dirContents) {
        NSString *path = [self getLocalPath:file];
        
        // Check if it's a directory
        BOOL dir = NO;
        [fileManager fileExistsAtPath:path isDirectory:&dir];
        if (!dir) {
            NSString *extension = [[file pathExtension] lowercaseString];
            if ([extension isEqualToString:@"kdb"] || [extension isEqualToString:@"kdbx"]) {
                if( [localFileMetadata objectForKey:file] != nil ) {
                    // File exists and is in the localFileMetadata
                    [missingFiles removeObjectForKey:file];
                } else {
                    // File exists locally but is not in the localFileMetadata
                    // There is a conflict with the Metadata bookkeeping.
                    // Create a local conflict file.
                    NSString *conflictPath = [self getConflictFilePath:file];
                    if( ![fileManager moveItemAtPath:path toPath:conflictPath error:&fm_err] ) {
                        NSLog( @"%@", fm_err );
                    }
                }
            }
        }
    }

    // Whats left are the missing files and need to be removed from list.
    for( id key in missingFiles.allKeys ) {
        [localFileMetadata removeObjectForKey:key];
    }

    [localFileMetadata writeToURL:[self getLocalURL:DROPBOX_META_ARCHIVE] atomically:YES];
}

- (void)deleteDropboxTempDir {

    // Delete temp directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *temp_dir = [self getLocalURL:@""];
    NSError *fm_err;
    if( ![fileManager removeItemAtURL:temp_dir error:&fm_err ]) {
        printf("Cannot remove temp directory for dropbox!\n");
        NSLog( @"%@", fm_err );
        return;
    }
    
}

- (BOOL)isLocalCopyStale:(NSString *)filename {

    // Check if the locally cached copy of the database is stale.
    // Local copy is stale if it any of:
    // 1. Doesn't exist (obviously)
    // 2. Different revision number than the dropbox revision.
    // 3. Older modified date than the dropbox client_modified date
    // ---
    // If the local copy is newer than the dropbox version then we should
    // make a backup of the local version and move it out of the temp directory
    // so the user can decide what to do with it.

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err;
    
    // Check if local file already exists.
    NSString *localpath = [self getLocalPath:filename ];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:localpath error:&err];
    if( !fileAttributes ) {
        // Local copy does not exist.  Need to download.
        NSLog( @"File does not exist! : %@\n", err );
        return YES;
    }
    
    // Check if the revision of the local copy is different than the revision of the
    // dropbox copy.
    DBFILESFileMetadata *dropboxMetadata = (DBFILESFileMetadata *) dropboxFileMetadata[filename];
    NSDictionary *localData = (NSDictionary *) localFileMetadata[filename];
    if( ![dropboxMetadata.rev isEqualToString:localData[DB_REVISION_CODE]] ) {
        // The dropbox revision numbers do not match!  Need to download a fresh copy.
        return YES;
    }

        // Check that the local file modification date is the same as or older than
        // the dropbox client modified date.
    printf( "Checking modification time on : '%s'\n", localpath.UTF8String );
    NSDate *modificationDate = [fileAttributes fileModificationDate];

//    NSLog( @"Local Date: %@\n", modificationDate);
//    NSLog( @"Dropbox Server Modified Date : %@\n", dropboxMetadata.serverModified );
//    NSLog( @"Dropbox Client Modified Date : %@\n", dropboxMetadata.clientModified );
    
    NSComparisonResult date_diff = [modificationDate compare:dropboxMetadata.clientModified];
    if( date_diff == NSOrderedSame ) {
        // The local modification date and the server modification date are
        // exactly the same.  Local copy is NOT STALE.
        printf( "Local copy is NOT Stale.\n");
        return NO;
    } else if( date_diff == NSOrderedDescending ) {
        // Local copy is newer than the Dropbox copy.
        // This shouldn't happen usually.  It would mean that the network
        // connection was lost to Dropbox when a database save was needed
        // or that the dropbox side database was deleted and replaced with an
        // older copy.
        printf( "Local copy is NEWER THAN DROPBOX!!!\n");
        
        NSString *new_path = [self getConflictFilePath:filename];
        if( ![fileManager moveItemAtPath:localpath toPath:new_path error:&err] ) {
            NSLog( @"%@", err );
            // Don't overwrite local copy because there was an error moving it out
            // of the temp directory.
            return NO;
        }
    }
    // If we get here then the dropbox revision and local copy revision are
    // the same but the modified date on the local copy is older than the client
    // modified date on dropbox.  Download a fresh copy.
    return YES;
}

- (void)setModifiedDate:(DBFILESFileMetadata *)fileMetadata path:(NSString *)path {
    // Changed the newly copied files modification date to the Dropbox side date.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err;
    
    printf("Setting the modified date on the local file to %s.\n", fileMetadata.clientModified.description.UTF8String);

    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:&err];
    if( !fileAttributes ) {
        NSLog( @"%@", err );
        return;
    }
    
    fileAttributes = @{ NSFileModificationDate : fileMetadata.clientModified };
    if( ![fileManager setAttributes:fileAttributes ofItemAtPath:path error:&err] ) {
        NSLog( @"%@", err );
    }
}

- (NSString *) getConflictFilePath:(NSString *)filename {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *basename = [filename stringByDeletingPathExtension];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:basename];
    BOOL foundName = NO;
    BOOL isDir;
    int fileIdx = 0;

    // Look for a conflict filename that is not already used.
    NSString *conflictPath;
    while( !foundName && fileIdx < 100 ) {
        conflictPath = [path stringByAppendingFormat:@"_dropbox_tmp%02d.kdbx", fileIdx];
        printf("Checking if '%s' exists\n", conflictPath.UTF8String );
        if( ![fileManager fileExistsAtPath:conflictPath isDirectory:&isDir]) {
            return conflictPath;
        }
        ++fileIdx;
    }
    
        // Return the "DATABASE_dropbox_tmp99" if we can't find an unused filename!
    return conflictPath;
}

-(void) loadDropboxFileList:(DMrequestCallback)requestCallback {
    
    if( client == nil || ![client isAuthorized] )
        requestCallback( [NSError errorWithDomain:@"DropboxAuthError" code:1 userInfo:nil] );

        // Clear the list of dropbox files.
    dropboxFileMetadata = [[NSMutableDictionary alloc] init];
    [[client.filesRoutes listFolder:@""]
     setResponseBlock:^(DBFILESListFolderResult *response, DBFILESListFolderError *routeError, DBRequestError *error) {
         if (response) {
             NSArray<DBFILESMetadata *> *entries = response.entries;
             BOOL hasMore = [response.hasMore boolValue];
             
             [self addDropboxEntries:entries];
             
             if (hasMore) {
                 NSLog(@"Folder is large enough where we need to call `listFolderContinue:`");
                 
                 printf( "TODO: Handle large folder!\n");
             } else {
                 requestCallback( nil );
             }
         } else {
            NSLog(@"%@\n%@\n", routeError, error);
            requestCallback(error.nsError);
         }
     }];
}

- (void)addDropboxEntries:(NSArray<DBFILESMetadata *> *)entries {
    for (DBFILESMetadata *entry in entries) {
        DBFILESFileMetadata *fileMetadata = (DBFILESFileMetadata *)entry;
        NSString *extension = [[fileMetadata.name pathExtension] lowercaseString];
        if ([extension isEqualToString:@"kdb"] || [extension isEqualToString:@"kdbx"]) {
            // Found a dropbox database.
            dropboxFileMetadata[fileMetadata.name] = fileMetadata;
        }
    }
}

- (NSArray *)getDropboxFileList {
    return [dropboxFileMetadata allKeys];
}

-(NSDate *) getDropboxFileModifiedDate:(NSString*)file {
    
    DBFILESFileMetadata *fileMetadata = (DBFILESFileMetadata *) dropboxFileMetadata[file];
    if( fileMetadata == nil ) {
        return nil;
    }
    
    return fileMetadata.clientModified;
}

- (void)downloadDropboxFile:(NSString*)file requestCallback:(DMrequestCallback)requestCallback {

    if( client == nil || ![client isAuthorized] )
        requestCallback( [NSError errorWithDomain:@"DropboxAuthError" code:1 userInfo:nil] );
    
    printf("Checking if dropbox file is stale: '%s'\n", file.UTF8String );
    
    // Don't download a fresh version if a local copy is not stale.
    if( ![self isLocalCopyStale:file] ) {
        requestCallback( nil );
        return;
    }
    
    NSURL *outputUrl = [[DropboxManager sharedInstance] getLocalURL:file];
    NSString *inpath = [[DropboxManager sharedInstance] getDropboxPath:file];
    
    printf("Downloading '%s' to '%s'.\n", inpath.UTF8String, outputUrl.absoluteString.UTF8String );
    [[client.filesRoutes downloadUrl:inpath overwrite:YES destination:outputUrl]
      setResponseBlock:^(DBFILESFileMetadata *result, DBFILESDownloadError *routeError,
                         DBRequestError *error, NSURL *destination) {
          if (result) {
              NSString *lpath = [self getLocalPath:file];
              // Change modified date for the local copy.
              [self setModifiedDate:result path:lpath];
              NSDictionary *dict = @{ DB_MODIFICATION_DATE : result.clientModified,
                                      DB_REVISION_CODE : result.rev };
              localFileMetadata[file] = dict;
              if( ![localFileMetadata writeToURL:[self getLocalURL:DROPBOX_META_ARCHIVE] atomically:YES] ) {
                  NSLog(@"Error writing local File Metadata Archive\n");
              }
              requestCallback( nil );
          } else {
              NSLog(@"%@\n%@\n", routeError, error);
              requestCallback( error.nsError );
          }
      }];
    
}

-(void) startUploadDropboxFile:(NSString*)file requestCallback:(DMrequestCallback)requestCallback {

    NSString *destpath = [self getDropboxPath:[file lastPathComponent]];
    NSURL *srcUrl = [self getLocalURL:[file lastPathComponent]];
    DBFILESWriteMode *writemode = [[DBFILESWriteMode alloc] initWithOverwrite];
    [[client.filesRoutes uploadUrl:destpath mode:writemode autorename:[NSNumber numberWithBool:NO]
                     clientModified:nil mute:[NSNumber numberWithBool:YES] inputUrl:srcUrl ]
      setResponseBlock:^(DBFILESFileMetadata *result, DBFILESUploadError *routeError, DBRequestError *networkError) {
          if (result) {
              dropboxFileMetadata[file] = result;
              NSDictionary *dict = @{ DB_MODIFICATION_DATE : result.clientModified,
                                      DB_REVISION_CODE : result.rev };
              localFileMetadata[file] = dict;
              if( ![localFileMetadata writeToURL:[self getLocalURL:DROPBOX_META_ARCHIVE] atomically:YES] ) {
                  NSLog(@"Error writing local File Metadata Archive\n");
              }
              requestCallback(nil);
          } else {
              NSLog(@"uploadUrl -- %@\n%@\n", routeError, networkError);
              requestCallback(networkError.nsError);
          }
      }];
}

- (void)uploadDropboxFile:(NSString*)file requestCallback:(DMrequestCallback)requestCallback {

    if( client == nil || ![client isAuthorized] )
        requestCallback( [NSError errorWithDomain:@"DropboxAuthError" code:1 userInfo:nil] );
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // Check if the local revision is the same as the dropbox revision.
    @try {
        [[client.filesRoutes getMetadata:[self getDropboxPath:file]]
         setResponseBlock:^(DBFILESFileMetadata *result, DBFILESGetMetadataError *metaError, DBRequestError *networkError) {
             if (result) {
                 NSDictionary *localData = (NSDictionary *) localFileMetadata[file];
                 if( [result.rev isEqualToString:localData[DB_REVISION_CODE]] ) {
                     // Dropbox file has not changed since we downloaded it.
                     [self startUploadDropboxFile:file requestCallback:requestCallback];
                 } else {
                     // Dropbox file has changed since we downloaded it!  Move local database
                     // for conflict resolution.
                     NSString *new_path = [self getConflictFilePath:file];
                     [fileManager moveItemAtPath:[self getLocalPath:file] toPath:new_path error:nil];
                     requestCallback([NSError errorWithDomain:@"DropboxVersionConflict" code:1 userInfo:nil]);
                 }
             } else {
                 NSLog(@"getMetadata -- %@\n%@\n", metaError, networkError);
                 requestCallback(networkError.nsError);
             }
         }];
    }
    @catch (NSException *exception) {
        requestCallback( [NSError errorWithDomain:exception.description code:1 userInfo:nil] );
    }
}
*/

@end
