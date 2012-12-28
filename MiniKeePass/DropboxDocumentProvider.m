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

@interface DropboxDocumentProvider () {
    NSMutableArray *_documents;
    NSMutableArray *_keyFiles;
}
@end

@implementation DropboxDocumentProvider

@synthesize documents = _documents;
@synthesize keyFiles = _keyFiles;

- (id)init {
    self = [super init];
    if (self) {
        [self updateFiles];
    }
    return self;
}

- (void)updateFiles {
    // Get the document's directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    // Strip out all the directories
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for (NSString *file in dirContents) {
        if (![file hasPrefix:@"."]) {
            NSString *path = [documentsDirectory stringByAppendingPathComponent:file];

            BOOL dir = NO;
            [fileManager fileExistsAtPath:path isDirectory:&dir];
            if (!dir) {
                [files addObject:file];
            }
        }
    }

    // Sort the list of files
    [files sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    // Filter the list of files into everything ending with .kdb or .kdbx
    NSArray *databaseFilenames = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self ENDSWITH[c] '.kdb') OR (self ENDSWITH[c] '.kdbx')"]];

    // Filter the list of files into everything not ending with .kdb or .kdbx
    NSArray *keyFilenames = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!((self ENDSWITH[c] '.kdb') OR (self ENDSWITH[c] '.kdbx'))"]];

    [_documents release];
    _documents = [[NSMutableArray alloc] initWithCapacity:databaseFilenames.count];
    for (NSString *filename in databaseFilenames) {
        DatabaseFile *database = [[DatabaseFile alloc] init];
        database.path = [documentsDirectory stringByAppendingPathComponent:filename];
        database.type = DatabaseTypeLocal;

        [_documents addObject:database];
    }

    [_keyFiles release];
    _keyFiles = [[NSMutableArray alloc] initWithCapacity:keyFilenames.count];
    for (NSString *filename in databaseFilenames) {
        DatabaseFile *keyFile = [[DatabaseFile alloc] init];
        keyFile.path = [documentsDirectory stringByAppendingPathComponent:filename];
        keyFile.type = DatabaseTypeLocal;

        [_keyFiles addObject:keyFile];
    }

    [files release];
}

- (void)openDocument:(DatabaseFile *)database {
    [[DatabaseManager sharedInstance] openDatabaseDocument:database animated:YES];
}

@end
