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
        password = nil;
        dirty = NO;
    }
    return self;
}


- (void)dealloc {
    [kdbTree release];
    [filename release];
    [password release];
    [super dealloc];
}

- (void)open:(NSString *)newFilename password:(NSString *)newPassword {
    [kdbTree release];
    [filename release];
    [password release];
    
    filename = [newFilename retain];
    password = [newPassword retain];
    dirty = NO;
    
    WrapperNSData *wrapperNSData = [[WrapperNSData alloc] initWithContentsOfMappedFile:filename];
    id<KdbReader> kdbReader = [KdbReaderFactory newKdbReader:wrapperNSData];
    self.kdbTree = [kdbReader load:wrapperNSData withPassword:password];
    [kdbReader release];
    [wrapperNSData release];
}

- (void)save {
    if (dirty) {
        dirty = NO;
        [KdbWriterFactory persist:kdbTree file:filename withPassword:password];
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
