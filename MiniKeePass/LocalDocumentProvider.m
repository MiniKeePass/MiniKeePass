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

#import "LocalDocumentProvider.h"
#import "DatabaseManager.h"
#import "SFHFKeychainUtils.h"

@interface LocalDocumentProvider () {
    NSMutableArray *_documents;
    NSMutableArray *_keyFiles;
}
@end

@implementation LocalDocumentProvider

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
        NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
        NSDate *modificationDate = [[fileManager attributesOfItemAtPath:path error:nil] fileModificationDate];

        DatabaseFile *database = [DatabaseFile databaseWithType:DatabaseTypeLocal path:path andModificationDate:modificationDate];
        [_documents addObject:database];
    }

    [_keyFiles release];
    _keyFiles = [[NSMutableArray alloc] initWithCapacity:keyFilenames.count];
    for (NSString *filename in keyFilenames) {
        NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
        DatabaseFile *keyFile = [DatabaseFile databaseWithType:DatabaseTypeLocal andPath:path];

        [_keyFiles addObject:keyFile];
    }

    [files release];

    [self.delegate documentProviderDidFinishUpdate:self];
}

- (void)openDocument:(DatabaseFile *)database {
    [[DatabaseManager sharedInstance] openDatabaseDocument:database animated:YES];
}

- (NSError *)renameDocument:(DatabaseFile *)database to:(NSString *)newFilename {
    NSString *oldFilename = [database.filename copy];
    newFilename = [newFilename stringByAppendingPathExtension:[oldFilename pathExtension]];

    // Get the full path of where we're going to move the file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:oldFilename];
    NSString *newPath = [documentsDirectory stringByAppendingPathComponent:newFilename];

    // Check if the file already exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:newPath]) {
        NSDictionary *userInfo = @{@"errorMessage" : NSLocalizedString(@"A file already exists with this name", nil)};
        NSError *error = [NSError errorWithDomain:@"DocumentProvider" code:1 userInfo:userInfo];
        [oldFilename release];
        return error;
    }

    // Move input file into documents directory
    [fileManager moveItemAtPath:oldPath toPath:newPath error:nil];

    database.path = [database.path stringByReplacingOccurrencesOfString:oldFilename withString:newFilename];

    // Load the password and keyfile from the keychain under the old filename
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:oldFilename andServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
    NSString *keyFile = [SFHFKeychainUtils getPasswordForUsername:oldFilename andServiceName:@"com.jflan.MiniKeePass.keyfiles" error:nil];

    // Store the password and keyfile into the keychain under the new filename
    [SFHFKeychainUtils storeUsername:newFilename andPassword:password forServiceName:@"com.jflan.MiniKeePass.passwords" updateExisting:YES error:nil];
    [SFHFKeychainUtils storeUsername:newFilename andPassword:keyFile forServiceName:@"com.jflan.MiniKeePass.keyfiles" updateExisting:YES error:nil];

    // Delete the keychain entries for the old filename
    [SFHFKeychainUtils deleteItemForUsername:oldFilename andServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
    [SFHFKeychainUtils deleteItemForUsername:oldFilename andServiceName:@"com.jflan.MiniKeePass.keychains" error:nil];

    [oldFilename release];

    [self.delegate documentProviderDidFinishUpdate:self];
    return nil;
}

@end
