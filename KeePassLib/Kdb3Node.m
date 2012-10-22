//
//  KDB3Node.m
//  KeePass2
//
//  Created by Qiang Yu on 2/12/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Node.h"
#import "Kdb3Date.h"

@implementation Kdb3Group

@synthesize groupId;
@synthesize flags;
@synthesize metaEntries;

- (id)init {
    self = [super init];
    if (self) {
        metaEntries = [[NSMutableArray alloc] initWithCapacity:4];
    }
    return self;
}

- (void)dealloc {
    [metaEntries release];
    [super dealloc];
}

- (void)addEntry:(KdbEntry*)entry {
    entry.parent = self;
    
    if ([(Kdb3Entry*)entry isMeta]) {
        [metaEntries addObject:entry];
    } else {
        [entries addObject:entry];
    }
}

- (void)removeEntry:(KdbEntry*)entry {
    entry.parent = nil;
    
    if ([(Kdb3Entry*)entry isMeta]) {
        [metaEntries removeObject:entry];
    } else {
        [entries removeObject:entry];
    }
}

@end


@implementation Kdb3Entry

@synthesize uuid;
@synthesize binaryDesc;
@synthesize binary;

- (void)dealloc {
    [uuid release];
    [binaryDesc release];
    [binary release];
    [super dealloc];
}

- (BOOL)isMeta {
    if (!binary || binary.length == 0) {
        return NO;
    }
    if (!notes || ![notes length]) {
        return NO;
    }
    if (!binaryDesc || [binaryDesc compare:@"bin-stream"]) {
        return NO;
    }
    if (!title || [title compare:@"Meta-Info"]) {
        return NO;
    }
    if (!username || [username compare:@"SYSTEM"]) {
        return NO;
    }
    if (!url || [url compare:@"$"]) {
        return NO;
    }
    if (image) {
        return NO;
    }
    return YES;
}

@end


@implementation Kdb3Tree

@synthesize rounds;

- (id)init {
    self = [super init];
    if (self) {
        self.rounds = DEFAULT_TRANSFORMATION_ROUNDS;
    }
    return self;
}

- (BOOL)isGroupIdUnique:(Kdb3Group*)group groupId:(uint32_t)groupId {
    if (group.groupId == groupId) {
        return NO;
    }
    
    for (Kdb3Group *g in group.groups) {
        if (![self isGroupIdUnique:g groupId:groupId]) {
            return NO;
        }
    }
    
    return YES;
}

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    Kdb3Group *group = [[Kdb3Group alloc] init];
    group.parent = parent;
    
    do {
        group.groupId = random();
    } while (![self isGroupIdUnique:(Kdb3Group*)root groupId:group.groupId]);
    
    return [group autorelease];
}

- (KdbEntry*)createEntry:(KdbGroup*)parent {
    Kdb3Entry *entry = [[Kdb3Entry alloc] init];
    entry.parent = parent;
    entry.uuid = [[[UUID alloc] init] autorelease];
    
    return [entry autorelease];
}

@end
