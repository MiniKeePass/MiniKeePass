//
//  Kdb.m
//  KeePass2
//
//  Created by Qiang Yu on 2/13/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb.h"

@implementation KdbGroup

@synthesize parent;
@synthesize image;
@synthesize name;
@synthesize groups;
@synthesize entries;
@synthesize creationTime;
@synthesize lastModificationTime;
@synthesize lastAccessTime;
@synthesize expiryTime;
@synthesize canAddEntries;

- (id)init {
    self = [super init];
    if (self) {
        groups = [[NSMutableArray alloc] initWithCapacity:8];
        entries = [[NSMutableArray alloc] initWithCapacity:16];
        canAddEntries = YES;
    }
    return self;
}

- (void)dealloc {
    [name release];
    [groups release];
    [entries release];
    [creationTime release];
    [lastModificationTime release];
    [lastAccessTime release];
    [expiryTime release];
    [super dealloc];
}

- (NSUInteger)addGroup:(KdbGroup*)group {
    group.parent = self;
    
    // Get the index where the group should be inserted to maintain sorted order
    NSUInteger index = [groups indexOfObject:group inSortedRange:NSMakeRange(0, [groups count]) options:NSBinarySearchingInsertionIndex usingComparator:^(id obj1, id obj2) {
        NSString *string1 = ((KdbGroup*)obj1).name;
        NSString *string2 = ((KdbGroup*)obj2).name;
        return [string1 localizedCaseInsensitiveCompare:string2];
    }];
    
    // Insert the group to the list of groups
    [groups insertObject:group atIndex:index];
    
    return index;
}

- (void)removeGroup:(KdbGroup*)group {
    group.parent = nil;
    [groups removeObject:group];
}

- (NSUInteger)addEntry:(KdbEntry*)entry {
    entry.parent = self;
    
    // Get the index where the entry should be inserted to maintain sorted order
    NSUInteger index = [entries indexOfObject:entry inSortedRange:NSMakeRange(0, [entries count]) options:NSBinarySearchingInsertionIndex usingComparator:^(id obj1, id obj2) {
        NSString *string1 = ((KdbEntry*)obj1).title;
        NSString *string2 = ((KdbEntry*)obj2).title;
        return [string1 localizedCaseInsensitiveCompare:string2];
    }];
    
    // Insert the entry to the list of entries
    [entries insertObject:entry atIndex:index];
    
    return index;
}

- (void)removeEntry:(KdbEntry*)entry {
    entry.parent = nil;
    [entries removeObject:entry];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"KdbGroup [image=%d, name=%@, creationTime=%@, lastModificationTime=%@, lastAccessTime=%@, expiryTime=%@]", image, name, creationTime, lastModificationTime, lastAccessTime, expiryTime];
}

@end


@implementation KdbEntry

@synthesize parent;
@synthesize image;
@synthesize title;
@synthesize username;
@synthesize password;
@synthesize url;
@synthesize notes;
@synthesize creationTime;
@synthesize lastModificationTime;
@synthesize lastAccessTime;
@synthesize expiryTime;

- (void)dealloc {
    [title release];
    [username release];
    [password release];
    [url release];
    [notes release];
    [creationTime release];
    [lastModificationTime release];
    [lastAccessTime release];
    [expiryTime release];
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"KdbEntry [image=%d, title=%@, username=%@, password=%@, url=%@, notes=%@, creationTime=%@, lastModificationTime=%@, lastAccessTime=%@, expiryTime=%@]", image, title, username, password, url, notes, creationTime, lastModificationTime, lastAccessTime, expiryTime];
}

@end


@implementation KdbTree

@synthesize root;

- (void)dealloc {
    [root release];
    [super dealloc];
}

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (KdbEntry*)createEntry:(KdbGroup*)parent {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
