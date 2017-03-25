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

#import "MiniKeePassAppDelegate.h"
#import "DropboxDocument.h"
#import "KeychainUtils.h"
#import "AppSettings.h"

// Api key assigned by Dropbox for this App
#define DROPBOX_APP_KEY          @"<APP-KEY>"

// For the Keychain
#define DROPBOX_ACCESS_TOKEN     @"dropboxAccessToken"

// Dropbox temp directory. Use something unique (like the <APP-KEY>)
#define DROPBOX_TEMP_DIR         @"dropbox_tmp_pjf4il2mxp018"

@interface DropboxDocument ()
@property (nonatomic, strong) KdbPassword *kdbPassword;
@end

@implementation DropboxDocument

- (id)initWithFilename:(NSString *)filename password:(NSString *)password keyFile:(NSString *)keyFile {
    self = [super init];
    if (self) {
        if (password == nil && keyFile == nil) {
            @throw [NSException exceptionWithName:@"IllegalArgument"
                                           reason:NSLocalizedString(@"No password or keyfile specified", nil)
                                         userInfo:nil];
        }

        self.filename = filename;

        NSStringEncoding passwordEncoding = [[AppSettings sharedInstance] passwordEncoding];
        self.kdbPassword = [[KdbPassword alloc] initWithPassword:password
                                                passwordEncoding:passwordEncoding
                                                         keyFile:keyFile];
        
        self.kdbTree = [KdbReaderFactory load:self.filename withPassword:self.kdbPassword];
    }
    return self;
}


- (void)save {
    printf("Saving dropbox temp file..\n");
    [KdbWriterFactory persist:self.kdbTree file:self.filename withPassword:self.kdbPassword];
    
    // Update the file on dropbox.
    DBUserClient *client = [DBClientsManager authorizedClient];
    if( client == nil ) {
        printf( "Cannot create client from access_token!\n");
        return;
    }

    NSString *destpath = [DropboxDocument getDropboxPath:[self.filename lastPathComponent]];
    
    NSURL *srcUrl = [DropboxDocument getLocalURL:[self.filename lastPathComponent]];
    
    DBFILESWriteMode *writemode = [[DBFILESWriteMode alloc] initWithOverwrite];
    
    // Copy the local database to Dropbox overwriting the (now old) one.
    [[[client.filesRoutes uploadUrl:destpath mode:writemode autorename:[NSNumber numberWithBool:NO]
                     clientModified:nil mute:[NSNumber numberWithBool:YES] inputUrl:srcUrl ]
      setResponseBlock:^(DBFILESFileMetadata *result, DBFILESUploadError *routeError, DBRequestError *networkError) {
          if (result) {
              NSLog(@"uploadUrl -- %@\n", result);
          } else {
              NSLog(@"uploadUrl -- %@\n%@\n", routeError, networkError);
          }
      }] setProgressBlock:^(int64_t bytesDownloaded, int64_t totalBytesDownloaded, int64_t totalBytesExpectedToDownload) {
          NSLog(@"%lld\n%lld\n%lld\n", bytesDownloaded, totalBytesDownloaded, totalBytesExpectedToDownload);
      }];
}

+ (NSString *)getLocalPath:(NSString *)filename {

    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
    NSString *tempdir = [documentsDirectory stringByAppendingPathComponent:DROPBOX_TEMP_DIR];
    NSString *path = [tempdir stringByAppendingPathComponent:filename];

    return path;
}

+ (NSURL *)getLocalURL:(NSString *)filename {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *outputDirectory = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    NSURL *temp_dir = [outputDirectory URLByAppendingPathComponent:DROPBOX_TEMP_DIR];
    NSURL *srcUrl = [temp_dir URLByAppendingPathComponent:filename];

    return srcUrl;
}

+ (NSString *)getDropboxPath:(NSString *)filename {
    
    NSString *prefix = @"/";
    NSString *path = [prefix stringByAppendingPathComponent:filename];
    
    return path;
}

+ (NSString *)getDropboxTempDir {
    
    return DROPBOX_TEMP_DIR;
}


+ (BOOL)localCopyIsStale:(DBFILESFileMetadata *)fileMetadata {
    
    // Check if the locally cached copy of the database is stale.
    // Local copy is stale if it either:
    // 1. Doesn't exist (obviously)
    // 2. Older than the dropbox version
    // ---
    // If the local copy is newer than the dropbox version then we should
    // make a backup of the local version and move it out of the temp directory
    // so the user can decide what to do with it.

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err;
    
    // Check if local version already exists.
    NSString *localpath = [DropboxDocument getLocalPath:fileMetadata.name ];

    printf( "Checking modification time on : '%s'\n", localpath.UTF8String );

    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:localpath error:&err];
    if( !fileAttributes ) {
        // Local copy does not exist.
        NSLog( @"File does not exist! : %@\n", err );
        return YES;
    }

    NSDate *modificationDate = [fileAttributes fileModificationDate];

    NSLog( @"Local Date: %@\n", modificationDate);
    NSLog( @"Dropbox Date : %@\n", fileMetadata.serverModified );
    
    NSComparisonResult date_diff = [modificationDate compare:fileMetadata.serverModified];
    if( date_diff == NSOrderedSame ) {
        // The local modification date and the server modification date are
        // exactly the same.  Local copy is NOT STALE.
        printf( "Local copy is NOT Stale.\n");
        return NO;
    } else if( date_diff == NSOrderedDescending ) {
        // Local copy is newer than the Dropbox copy.
        // This shouldn't happen usually.  It would mean that the network
        // connection was lost to Dropbox when a database save was needed.
        printf( "Local copy is NEWER THAN DROPBOX!!!\n");
        
        NSString *new_fname = [fileMetadata.name stringByAppendingString:@"dropbox_temp_bak.kdbx"];
        NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
        NSString *new_path = [ documentsDirectory stringByAppendingPathComponent:new_fname];
        if( ![fileManager moveItemAtPath:localpath toPath:new_path error:&err] ) {
            NSLog( @"%@", err );
            // Don't overwrite local copy because there was an error!
            return NO;
        }
    }
    
    return YES;
}

+ (void)setModifiedDate:(DBFILESFileMetadata *)fileMetadata path:(NSString *)path {
    // Changed the newly copied files modification date to the Dropbox side date.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err;
    
    printf("Setting the modified date on the local file to %s.\n", fileMetadata.serverModified.description.UTF8String);

    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:&err];
    if( !fileAttributes ) {
        NSLog( @"%@", err );
        return;
    }
    
    fileAttributes = @{ NSFileModificationDate : fileMetadata.serverModified };
    if( ![fileManager setAttributes:fileAttributes ofItemAtPath:path error:&err] ) {
        NSLog( @"%@", err );
    }
}

+ (void) storeAccessToken:(NSString *)token {
    [KeychainUtils setString:token forKey:DROPBOX_ACCESS_TOKEN
              andServiceName:KEYCHAIN_OAUTH2_SERVICE];

}

+ (void) initDropboxAPI {
    static BOOL isInitialized = NO;
    
    if( !isInitialized ) {
        // Initialize the Dropbox Client Manager
        [DBClientsManager setupWithAppKey:DROPBOX_APP_KEY];
        
        // Create temp directory if it doesn't exist
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *temp_dir = [DropboxDocument getLocalURL:@""];
        NSError *fm_err;
        if( ![fileManager createDirectoryAtURL:temp_dir withIntermediateDirectories:YES attributes:nil error:&fm_err ]) {
            printf("Cannot create temp directory for dropbox!\n");
            NSLog( @"%@", fm_err );
        }

        isInitialized = YES;
    }
}

+ (DBUserClient *)getClient {
    
    NSString *token = [KeychainUtils stringForKey:DROPBOX_ACCESS_TOKEN andServiceName:KEYCHAIN_OAUTH2_SERVICE];
    DBUserClient *client = [[DBUserClient alloc] initWithAccessToken:token];
    if( client == nil ) {
        printf( "Cannot create client from access_token!\n");
        return nil;
    }

    return client;
}

@end
