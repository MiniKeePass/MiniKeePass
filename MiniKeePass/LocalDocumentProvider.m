//
//  LocalDocumentProvider.m
//  MiniKeePass
//
//  Created by John on 12/18/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "LocalDocumentProvider.h"
#import "DatabaseManager.h"

@interface LocalDocumentProvider () {
    NSMutableArray *_documents;
    NSMutableArray *_keyFiles;
}
@end

@implementation LocalDocumentProvider

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
        MKPDocument *document = [[MKPDocument alloc] init];
        document.filename = filename;
        document.type = MKPLocalDocument;

        [_documents addObject:document];
    }

    [_keyFiles release];
    _keyFiles = [[NSMutableArray alloc] initWithCapacity:keyFilenames.count];
    for (NSString *filename in databaseFilenames) {
        MKPDocument *document = [[MKPDocument alloc] init];
        document.filename = filename;
        document.type = MKPLocalDocument;

        [_keyFiles addObject:document];
    }

    [files release];
}

- (void)openDocument:(MKPDocument *)document {
    [[DatabaseManager sharedInstance] openDatabaseDocument:document.filename animated:YES];
}

@end
