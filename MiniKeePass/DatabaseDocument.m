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

#import "DatabaseDocument.h"
#import "AppSettings.h"
#import "MKPDocumentProvider.h"
#import "LocalDocumentProvider.h"
#import "DropboxDocumentProvider.h"

@interface DatabaseDocument ()
@property (nonatomic, retain) KdbPassword *kdbPassword;
- (BOOL)matchesEntry:(KdbEntry *)entry searchText:(NSString *)searchText;
@end

@implementation DatabaseDocument

@synthesize documentInteractionController = _documentInteractionController;

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}


- (void)dealloc {
    [_kdbTree release];
    [_kdbPassword release];
    [_documentInteractionController release];
    [super dealloc];
}

- (UIDocumentInteractionController *)documentInteractionController {
    if (_documentInteractionController == nil) {
        NSURL *url = [NSURL fileURLWithPath:self.filename];
        _documentInteractionController = [[UIDocumentInteractionController interactionControllerWithURL:url] retain];
    }
    return _documentInteractionController;
}

- (NSString *)filename {
    return self.file.filename;
}

- (void)open:(DatabaseFile *)newFile password:(NSString *)password keyFile:(NSString *)keyFile {
    if (password == nil && keyFile == nil) {
        @throw [NSException exceptionWithName:@"IllegalArgument" reason:@"No password or keyfile specified" userInfo:nil];
    }

    self.dirty = NO;
    self.file = newFile;

    NSStringEncoding passwordEncoding = [[AppSettings sharedInstance] passwordEncoding];
    self.kdbPassword = [[KdbPassword alloc] initWithPassword:password
                                            passwordEncoding:passwordEncoding
                                                     keyFile:keyFile];

    self.kdbTree = [KdbReaderFactory load:self.file.path withPassword:self.kdbPassword];
}

- (void)save {
    if (self.dirty) {
        self.dirty = NO;
        [KdbWriterFactory persist:self.kdbTree file:self.file.path withPassword:self.kdbPassword];
        MKPDocumentProvider *documentProvider = nil;
        switch (self.file.type) {
            case DatabaseTypeLocal:
                documentProvider = [[[LocalDocumentProvider alloc] init] autorelease];
                break;
            case DatabaseTypeDropbox:
                documentProvider = [[[DropboxDocumentProvider alloc] init] autorelease];
                break;
        }
        [documentProvider saveDocument:self.file];
    }
}

- (void)searchGroup:(KdbGroup *)group searchText:(NSString *)searchText results:(NSMutableArray *)results {
    for (KdbEntry *entry in group.entries) {
        if ([self matchesEntry:entry searchText:searchText]) {
            [results addObject:entry];
        }
    }

    for (KdbGroup *g in group.groups) {
        [self searchGroup:g searchText:searchText results:results];
    }
}

- (BOOL)matchesEntry:(KdbEntry *)entry searchText:(NSString *)searchText {
    if ([entry.title rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
        return YES;
    }
    if ([entry.username rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
        return YES;
    }
    if ([entry.url rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
        return YES;
    }
    if ([entry.notes rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
        return YES;
    }
    return NO;
}

@end
