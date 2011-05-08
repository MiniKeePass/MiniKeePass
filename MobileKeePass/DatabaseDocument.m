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
#import "Kdb3.h"

@implementation DatabaseDocument

@synthesize database;
@synthesize filename;
@synthesize dirty;

- (id)init {
    self = [super init];
    if (self) {
        database = nil;
        filename = nil;
        dirty = NO;
    }
    return self;
}


- (void)dealloc {
    [database release];
    [filename release];
    [super dealloc];
}

- (enum DatabaseError)open:(NSString *)path password:(NSString *)password {
    [database release];
    [filename release];
    
    filename = [path retain];
    dirty = NO;
    database = [[Kdb3 alloc] init];
    
    return [database openDatabase:filename password:password];
}

- (enum DatabaseError)new:(NSString *)path password:(NSString *)passowrd {
    [database release];
    [filename release];
    
    filename = [path retain];
    dirty = NO;
    database = [[Kdb3 alloc] init];
    
    return [database newDatabase:filename password:passowrd];
}

- (enum DatabaseError)save {
    if (dirty) {
        dirty = NO;
        return [database saveDatabase:filename];
    }
    return NO_ERROR;
}

@end
