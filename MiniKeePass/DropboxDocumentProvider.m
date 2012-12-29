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

#import "DropboxDocumentProvider.h"
#import "DatabaseManager.h"
#import "AppSettings.h"
#import "secrets.h"

@interface DropboxDocumentProvider () {
    NSMutableArray *_documents;
    NSMutableArray *_keyFiles;
}

@property (nonatomic, retain) DBRestClient *restClient;
@property (nonatomic, copy) NSString *localDir;

@end

@implementation DropboxDocumentProvider

@synthesize documents = _documents;
@synthesize keyFiles = _keyFiles;

- (id)init {
    self = [super init];
    if (self) {
        [self updateFiles];

        DBSession* dbSession = [DBSession sharedSession];
        if (dbSession == nil) {
            dbSession = [[DBSession alloc] initWithAppKey:DROPBOX_APP_KEY appSecret:DROPBOX_APP_SECRET root:kDBRootDropbox];
        }
        [DBSession setSharedSession:dbSession];

        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;

        _documents = nil;
        _keyFiles = nil;

        // Get the document's directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _localDir = [[documentsDirectory stringByAppendingPathComponent:@"DropBox"] copy];

        NSFileManager *fileManager= [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:self.localDir isDirectory:nil]) {
            if(![fileManager createDirectoryAtPath:self.localDir withIntermediateDirectories:YES attributes:nil error:NULL]) {
                NSLog(@"Error: Create folder failed %@", self.localDir);
            }
        }
    }
    return self;
}

- (void)dealloc {
    [_restClient release];
    [_documents release];
    [_keyFiles release];
    [_localDir release];
    [super dealloc];
}

- (void)updateFiles {
    [self.restClient loadMetadata:[[AppSettings sharedInstance] dropboxDirectory]];
}

- (void)openDocument:(DatabaseFile *)database {
    NSString *dropboxDirectory = [[AppSettings sharedInstance] dropboxDirectory];
    NSString *remotePath = [dropboxDirectory stringByAppendingPathComponent:database.filename];
    NSLog(@"%@", remotePath);
    [self.restClient loadFile:remotePath intoPath:[self.localDir stringByAppendingPathComponent:database.filename]];
}

- (void) restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    //[_documents release];
    _documents = [NSMutableArray arrayWithCapacity:metadata.contents.count];

    //[_keyFiles release];
    _keyFiles = [NSMutableArray arrayWithCapacity:metadata.contents.count];

    for (DBMetadata *file in [metadata contents]) {
        NSURL *fileUrl = [NSURL fileURLWithPath:file.path];
        NSString *extension = fileUrl.pathExtension;

        if ([extension isEqualToString:@"kdb"] || [extension isEqualToString:@"kdbx"]) {
            NSString *path = [self.localDir stringByAppendingPathComponent:file.filename];
            NSLog(@"%@", file.path);
            DatabaseFile *database = [DatabaseFile databaseWithType:DatabaseTypeDropbox andPath:path];
            database.customImage = [UIImage imageNamed:@"dropbox"];
            [_documents addObject:database];
        } else {
            NSString *path = [self.localDir stringByAppendingPathComponent:file.filename];
            DatabaseFile *keyFile = [DatabaseFile databaseWithType:DatabaseTypeDropbox andPath:path];
            keyFile.customImage = [UIImage imageNamed:@"dropbox"];
            [_keyFiles addObject:keyFile];
        }
    }

    [self.delegate documentProviderDidFinishUpdate:self];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath {
    DatabaseFile *file = [DatabaseFile databaseWithType:DatabaseTypeDropbox andPath:destPath];
    [[DatabaseManager sharedInstance] openDatabaseDocument:file animated:YES];
}

@end
