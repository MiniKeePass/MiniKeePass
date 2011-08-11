/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
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

@implementation DatabaseDocument

@synthesize kdbTree;
@synthesize filename;
@synthesize dirty;

- (id)init {
    self = [super init];
    if (self) {
        kdbTree = nil;
        filename = nil;
        dirty = NO;
        kdbPassword = nil;
        documentInteractionController = nil;
    }
    return self;
}


- (void)dealloc {
    [kdbTree release];
    [filename release];
    [kdbPassword release];
    [documentInteractionController release];
    [super dealloc];
}

- (UIDocumentInteractionController *)documentInteractionController {
    if (documentInteractionController == nil) {
        NSURL *url = [NSURL fileURLWithPath:filename];
        documentInteractionController = [[UIDocumentInteractionController interactionControllerWithURL:url] retain];
    }
    return documentInteractionController;
}

- (void)open:(NSString*)newFilename password:(NSString*)password keyFile:(NSString*)keyFile {
    [kdbTree release];
    [filename release];
    [kdbPassword release];
    
    filename = [newFilename retain];
    dirty = NO;

    if (password != nil && keyFile != nil) {
        kdbPassword = [[KdbPassword alloc] initWithPassword:password encoding:NSUTF8StringEncoding keyfile:keyFile];
    } else if (password != nil) {
        kdbPassword = [[KdbPassword alloc] initWithPassword:password encoding:NSUTF8StringEncoding];
    } else if (keyFile != nil) {
        kdbPassword = [[KdbPassword alloc] initWithKeyfile:keyFile];
    } else {
        @throw [NSException exceptionWithName:@"IllegalArgument" reason:@"No password or keyfile specified" userInfo:nil];
    }

    self.kdbTree = [KdbReaderFactory load:filename withPassword:kdbPassword];
}

- (void)save {
    if (dirty) {
        dirty = NO;
        [KdbWriterFactory persist:kdbTree file:filename withPassword:kdbPassword];
    }
}

- (void)searchGroup:(KdbGroup*)group searchText:(NSString*)searchText results:(NSMutableArray*)results {
    for (KdbEntry *entry in group.entries) {
        NSRange range = [entry.title rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            [results addObject:entry];
        }
    }
    
    for (KdbGroup *g in group.groups) {
        [self searchGroup:g searchText:searchText results:results];
    }
}

@end
