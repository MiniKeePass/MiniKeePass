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

- (void)addGroup:(KdbGroup *)group {
    group.parent = self;
    [groups addObject:group];
}

- (void)removeGroup:(KdbGroup *)group {
    group.parent = nil;
    [groups removeObject:group];
}

- (void)moveGroup:(KdbGroup *)group toGroup:(KdbGroup *)toGroup {
    [self removeGroup:group];
    [toGroup addGroup:group];
}

- (void)addEntry:(KdbEntry *)entry {
    entry.parent = self;
    [entries addObject:entry];
}

- (void)removeEntry:(KdbEntry *)entry {
    entry.parent = nil;
    [entries removeObject:entry];
}

- (void)moveEntry:(KdbEntry *)entry toGroup:(KdbGroup *)toGroup {
    [self removeEntry:entry];
    [toGroup addEntry:entry];
}

- (BOOL)containsGroup:(KdbGroup *)group {
    // Check trivial case where group is passed to itself
    if (self == group) {
        return YES;
    } else {
        // Check subgroups
        for (KdbGroup *subGroup in groups) {
            if ([subGroup containsGroup:group]) {
                return YES;
            }
        }
        return NO;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"KdbGroup [image=%ld, name=%@, creationTime=%@, lastModificationTime=%@, lastAccessTime=%@, expiryTime=%@]", (long)image, name, creationTime, lastModificationTime, lastAccessTime, expiryTime];
}

@end


@implementation KdbEntry

@synthesize parent;
@synthesize image;
@synthesize creationTime;
@synthesize lastModificationTime;
@synthesize lastAccessTime;
@synthesize expiryTime;

- (NSString *)title {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)setTitle:(NSString *)title {
    [self doesNotRecognizeSelector:_cmd];
}

- (NSString *)username {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)setUsername:(NSString *)username {
    [self doesNotRecognizeSelector:_cmd];
}

- (NSString *)password {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)setPassword:(NSString *)password {
    [self doesNotRecognizeSelector:_cmd];
}

- (NSString *)url {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)setUrl:(NSString *)url {
    [self doesNotRecognizeSelector:_cmd];
}

- (NSString *)notes {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)setNotes:(NSString *)notes {
    [self doesNotRecognizeSelector:_cmd];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"KdbEntry [image=%ld, title=%@, username=%@, password=%@, url=%@, notes=%@, creationTime=%@, lastModificationTime=%@, lastAccessTime=%@, expiryTime=%@]", (long)image, self.title, self.username, self.password, self.url, self.notes, creationTime, lastModificationTime, lastAccessTime, expiryTime];
}

@end


@implementation KdbTree

@synthesize root;

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (KdbEntry*)createEntry:(KdbGroup*)parent {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
