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

- (void)addGroup:(KdbGroup*)group {
    group.parent = self;
    [groups addObject:group];
}

- (void)deleteGroup:(KdbGroup*)group {
    group.parent = nil;
    [groups removeObject:group];
}

- (void)addEntry:(KdbEntry*)entry {
    entry.parent = self;
    [entries addObject:entry];
}

- (void)deleteEntry:(KdbEntry*)entry {
    entry.parent = nil;
    [entries removeObject:entry];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"KdbGroup [image=%d, name=%@]", image, name];
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
    return [NSString stringWithFormat:@"KdbEntry [image=%d, title=%@, username=%@, password=%@, url=%@, notes=%@]", image, title, username, password, url, notes];
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
